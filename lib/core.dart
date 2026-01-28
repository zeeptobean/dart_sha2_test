import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:convert/convert.dart';
import 'package:dart_sha2_test/colortext.dart';

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
  }
}

void runTest(String funcName, int digestSize, String testSuiteName) {
  final dylib = ffi.DynamicLibrary.open('./clib/libmysha2.so');
  final ShaDartFunc func = dylib.lookupFunction<ShaCFunc, ShaDartFunc>(funcName);
  print(ColorText.info("Loading $testSuiteName for $funcName..."));


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
  for(int i=0; i < tests.length; i++) {
    final test = tests[i];
    final inputPtr = malloc.allocate<ffi.Int8>(test.length);
    final outputPtr = malloc.allocate<ffi.Char>(digestSize + 1);
    try {
      inputPtr.asTypedList(test.length).setAll(0, test.input);
      if(func(inputPtr, test.length, outputPtr) == 0) {
        throw Exception("C function error");
      }
      final hash = outputPtr.cast<Utf8>().toDartString();
      if(hash != test.digest) {
        print(ColorText.error("Test #$i failed:"));
      } else {
        print(ColorText.success("Test #$i passed"));
        correct++;
      }
      print("   Expected: ${test.digest}");
      print("   Got     : $hash");
    } catch(e) {
      print(ColorText.error("Test #$i error: $e"));
    } finally {
      malloc.free(inputPtr);
      malloc.free(outputPtr);
    }
  }

  print(ColorText.info("Test completed: $correct / ${tests.length} correct"));
}