import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:convert/convert.dart';
import 'package:dart_sha2_test/mylogger.dart';
import 'package:dart_sha2_test/model.dart';
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
  final ShaDartFunc func = _dylib.lookupFunction<ShaCFunc, ShaDartFunc>(funcName);
  logger.logInfo("Regular test: Loading $testSuiteName for $funcName...");
  File f = File("test_vectors/$testSuiteName/$testSuiteName.json");
  final jsonString = f.readAsStringSync();
  final jsonData = jsonDecode(jsonString) as List<dynamic>;
  logger.log("Detected ${jsonData.length} tests");
  List<TestUnit> tests = [];
  for(final item in jsonData) {
    final testUnit = TestUnit.fromJson(item as Map<String, dynamic>);
    if(testUnit.isValid) {
      tests.add(testUnit);
    }
  }
  if(tests.length != jsonData.length) {
    logger.logWarning("Warning: Some tests were invalid and have been skipped");
  }
  logger.logInfo("Loaded ${tests.length} valid tests");

  int correct = 0;
  final stopwatch = Stopwatch()..start();
  for(int i=0; i < tests.length; i++) {
    final test = tests[i];
    final result = _shaFuncWrapper(func, test.input, digestSize);
    if(result.isFailure) {
      logger.logError("Test #$i failed: ${result.getErrorString}");
    } else {
      final hash = result.getData!;
      if(hash != test.digest) {
        logger.logError("Test #$i failed:");
        logger.logError("   Expected: ${test.digest}");
        logger.logError("   Got     : $hash");
      } else {
        correct++;
      }
    }
  }
  stopwatch.stop();

  if(correct == tests.length) {
    logger.logSuccess("All tests passed for $funcName!");
  }
  logger.logInfo("Test completed: $correct / ${tests.length} correct");
  logger.log("Time elapsed: ${stopwatch.elapsedMilliseconds} ms");
}

Uint8List _concatMonte(Uint8List a, Uint8List b, Uint8List c) {
  final result = Uint8List(a.length + b.length + c.length);
  result.setAll(0, a);
  result.setAll(a.length, b);
  result.setAll(a.length + b.length, c);
  return result;
}

final _dylib = () {
  if(Platform.isWindows) {
    return ffi.DynamicLibrary.open('./clib/libmysha2.dll');
  } else if(Platform.isLinux || Platform.isAndroid) {
    return ffi.DynamicLibrary.open('./clib/libmysha2.so');
  } else {
    throw UnsupportedError("Unsupported platform");
  }
}();

void runMonte({required String funcName, required int digestSize, required String testSuiteName, int iterations = 1}) {
  final ShaDartFunc func = _dylib.lookupFunction<ShaCFunc, ShaDartFunc>(funcName);
  logger.logInfo("Monte test: Loading $testSuiteName for $funcName...");

  File f = File("test_vectors/$testSuiteName/${testSuiteName}_monte.json");
  final jsonString = f.readAsStringSync();
  final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
  final monteTest = MonteTest.fromJson(jsonData);
  if(monteTest.isValid == false) {
    logger.logError("Failed to load valid Monte test data");
    return;
  } else {
    logger.logInfo("Loaded Monte test data with ${monteTest.digests.length} entries");
  }

  if(iterations < 1) {
    iterations = 1;
  }
  if(iterations > 1) {
    logger.logInfo("Repeating Monte test $iterations times");
  }

  final stopwatch = Stopwatch();
  for(int k=1; k <= iterations; k++) {
  int correct = 0;
  stopwatch.start();
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
        logger.logError("Monte test failed at outer #$j, inner #$i: ${d.getErrorString}");
        break;
      } else {
        c = Uint8List.fromList(hex.decode(d.getData!));
      }
    }
    final gotDigest = hex.encode(Uint8List.fromList(c));
    final expectedDigest = hex.encode(Uint8List.fromList(monteTest.digests[j]));
    if(gotDigest != expectedDigest) {
      logger.logError("Monte test failed at outer #$j:");
      logger.logError("   Expected: $expectedDigest");
      logger.logError("   Got     : $gotDigest");
    } else {
      correct++;
    }

    a = Uint8List.fromList(c);
    b = Uint8List.fromList(c);
    c = Uint8List.fromList(c);
  }
  stopwatch.stop();
  logger.logInfo("Iteration $k completed: $correct / ${monteTest.digests.length} correct");
  }
  logger.log("Time elapsed: ${stopwatch.elapsedMilliseconds} ms");

}