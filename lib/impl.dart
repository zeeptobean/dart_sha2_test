import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:convert/convert.dart';
import 'package:dart_sha2_test/colortext.dart';
import 'package:dart_sha2_test/expected.dart';

//int(const char*, uint64_t, char*)
typedef ShaCFunc = ffi.Int Function(
  ffi.Pointer<ffi.Int8> inputBuffer, 
  ffi.Uint64 inputInt, 
  ffi.Pointer<ffi.Char> outputBuffer
);

typedef ShaDartFunc = int Function(
  ffi.Pointer<ffi.Int8> inputBuffer, 
  int inputInt, 
  ffi.Pointer<ffi.Char> outputBuffer
);

class TestUnit {
  final int length;
  final Uint8List input;
  final String digest;
  final bool isValid;
  const TestUnit({required this.length, required this.input, required this.digest}) : isValid = true;
  TestUnit.invalid() : length = 0, input = Uint8List(0), digest = '', isValid = false;
  factory TestUnit.fromJson(Map<String, dynamic> json) {
    try {
      final lengthBit = json['Len'] as int;
      if(lengthBit % 8 != 0) {
        return TestUnit.invalid();
      }
      final lengthByte = lengthBit ~/ 8;
      final inputHex = json['Msg'] as String;
      final digest = json['MD'] as String;
      final inputBytes = Uint8List.fromList(hex.decode(inputHex));
      final inputBytesTrunc = inputBytes.sublist(0, lengthByte);
      return TestUnit(length: lengthByte, input: inputBytesTrunc, digest: digest);
    } catch(_) {
      return TestUnit.invalid();
    }
  }
}

class MonteTest {
  final Uint8List seed;
  final List<Uint8List> digests;
  final List<int> counts;
  final bool isValid;
  const MonteTest({required this.seed, required this.digests, required this.counts}) : isValid = true;
  MonteTest.invalid() : seed = Uint8List(0), digests = [], counts = [], isValid = false;
  factory MonteTest.fromJson(Map<String, dynamic> json) {
    try {
      final seedStr = json['seed'] as String;
      final seed = Uint8List.fromList(hex.decode(seedStr));
      final data = json['data'] as List<dynamic>;
      final digests = <Uint8List>[];
      final counts = <int>[];
      for(final item in data) {
        final entry = item as Map<String, dynamic>;
        final digest = entry['MD'] as String;
        final count = entry['COUNT'] as int;
        digests.add(Uint8List.fromList(hex.decode(digest)));
        counts.add(count);
      }
      if(digests.isEmpty || counts.isEmpty || digests.length != counts.length) {
        return MonteTest.invalid();
      }
      return MonteTest(seed: seed, digests: digests, counts: counts);
    } catch(_) {
      return MonteTest.invalid();
    }
  }
}

Expected<String> _shaFuncWrapper(ShaDartFunc func, Uint8List input, int digestSize) {
  final inputPtr = malloc.allocate<ffi.Int8>(input.length);
  final outputPtr = malloc.allocate<ffi.Char>(digestSize + 1);
  String result;
  try {
    inputPtr.asTypedList(input.length).setAll(0, input);
    if(func(inputPtr, input.length, outputPtr) == 0) {
      throw Exception("C function error");
    }
    result = outputPtr.cast<Utf8>().toDartString();
  } catch(e) {
    return Expected.failure(e.toString());
  } finally {
    malloc.free(inputPtr);
    malloc.free(outputPtr);
  }
  return Expected.success(result);
}

void runTest({required String funcName, required int digestSize, required String testSuiteName}) {
  final dylib = ffi.DynamicLibrary.open('./clib/libmysha2.so');
  final ShaDartFunc func = dylib.lookupFunction<ShaCFunc, ShaDartFunc>(funcName);
  print(ColorText.info("Regular test: Loading $testSuiteName for $funcName..."));

  File f = File("test_vectors/$testSuiteName/$testSuiteName.json");
  final jsonString = f.readAsStringSync();
  final jsonData = jsonDecode(jsonString) as List<dynamic>;
  print("Detected ${jsonData.length} tests");
  List<TestUnit> tests = [];
  for(final item in jsonData) {
    final testUnit = TestUnit.fromJson(item as Map<String, dynamic>);
    if(testUnit.isValid) {
      tests.add(testUnit);
    }
  }
  if(tests.length != jsonData.length) {
    print(ColorText.warning("Warning: Some tests were invalid and have been skipped"));
  }
  print("Loaded ${tests.length} valid tests");

  int correct = 0;
  final stopwatch = Stopwatch()..start();
  for(int i=0; i < tests.length; i++) {
    final test = tests[i];
    final result = _shaFuncWrapper(func, test.input, digestSize);
    if(result.isFailure) {
      print(ColorText.error("Test #$i failed: ${result.getErrorString}"));
    } else {
      final hash = result.getData!;
      if(hash != test.digest) {
        print(ColorText.error("Test #$i failed:"));
        print("   Expected: ${test.digest}");
        print("   Got     : $hash");
      } else {
        correct++;
      }
    }
  }
  stopwatch.stop();

  if(correct == tests.length) {
    print(ColorText.success("All tests passed for $funcName!"));
  }
  print(ColorText.info("Test completed: $correct / ${tests.length} correct"));
  print("Time elapsed: ${stopwatch.elapsedMilliseconds} ms");
}

Uint8List _concatMonte(Uint8List a, Uint8List b, Uint8List c) {
  final result = Uint8List(a.length + b.length + c.length);
  result.setAll(0, a);
  result.setAll(a.length, b);
  result.setAll(a.length + b.length, c);
  return result;
}

void runMonte({required String funcName, required int digestSize, required String testSuiteName}) {
  final dylib = ffi.DynamicLibrary.open('./clib/libmysha2.so');
  final ShaDartFunc func = dylib.lookupFunction<ShaCFunc, ShaDartFunc>(funcName);
  print(ColorText.info("Monte test: Loading $testSuiteName for $funcName..."));

  File f = File("test_vectors/$testSuiteName/${testSuiteName}_monte.json");
  final jsonString = f.readAsStringSync();
  final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
  final monteTest = MonteTest.fromJson(jsonData);
  if(monteTest.isValid == false) {
    print(ColorText.error("Failed to load valid Monte test data"));
    return;
  } else {
    print("Loaded Monte test with ${monteTest.digests.length} iterations");
  }

  int correct = 0;
  final stopwatch = Stopwatch()..start();
  Uint8List a, b, c;
  a = Uint8List.fromList(monteTest.seed);
  b = Uint8List.fromList(monteTest.seed);
  c = Uint8List.fromList(monteTest.seed);
  for(int j=0; j < monteTest.counts.length; j++) {
    for(int i=3; i < 1003; i++) {
      var temp = _concatMonte(a, b, c);
      var d = _shaFuncWrapper(func, temp, digestSize);
      a = b;
      b = c;
      if(d.isFailure) {
        print(ColorText.error("Monte test failed at outer #$j, inner #$i: ${d.getErrorString}"));
        break;
      } else {
        c = Uint8List.fromList(hex.decode(d.getData!));
      }
    }
    final gotDigest = hex.encode(Uint8List.fromList(c));
    final expectedDigest = hex.encode(Uint8List.fromList(monteTest.digests[j]));
    if(gotDigest != expectedDigest) {
      print(ColorText.error("Monte test failed at outer #$j:"));
      print("   Expected: $expectedDigest");
      print("   Got     : $gotDigest");
    } else {
      correct++;
    }

    a = Uint8List.fromList(c);
    b = Uint8List.fromList(c);
    c = Uint8List.fromList(c);
  }
  stopwatch.stop();
  if(correct == monteTest.digests.length) {
    print(ColorText.success("All Monte test iterations passed!"));
  }
  print(ColorText.info("Test completed: $correct / ${monteTest.digests.length} correct"));
  print("Time elapsed: ${stopwatch.elapsedMilliseconds} ms");

}