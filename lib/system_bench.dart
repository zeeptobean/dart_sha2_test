import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_sha2_test/model.dart';
import 'package:dart_sha2_test/mylogger.dart';

void benchSystemSha256({int iterations = 1}) => _runSystemMonte(name: "sha256", iterations: iterations);
void benchSystemSha512({int iterations = 1}) => _runSystemMonte(name: "sha512", iterations: iterations);
void benchSystemSha224({int iterations = 1}) => _runSystemMonte(name: "sha224", iterations: iterations);
void benchSystemSha384({int iterations = 1}) => _runSystemMonte(name: "sha384", iterations: iterations);
void benchSystemSha512_224({int iterations = 1}) => _runSystemMonte(name: "sha512_224", iterations: iterations);
void benchSystemSha512_256({int iterations = 1}) => _runSystemMonte(name: "sha512_256", iterations: iterations);

Uint8List _concatMonte(Uint8List a, Uint8List b, Uint8List c) {
  final result = Uint8List(a.length + b.length + c.length);
  result.setAll(0, a);
  result.setAll(a.length, b);
  result.setAll(a.length + b.length, c);
  return result;
}

final _funcMap = {
  "sha256": (Uint8List input) => sha256.convert(input).bytes,
  "sha512": (Uint8List input) => sha512.convert(input).bytes,
  "sha224": (Uint8List input) => sha224.convert(input).bytes,
  "sha384": (Uint8List input) => sha384.convert(input).bytes,
  "sha512_224": (Uint8List input) => sha512224.convert(input).bytes,
  "sha512_256": (Uint8List input) => sha512256.convert(input).bytes,
};

void _runSystemMonte({required String name, int iterations = 1}) {
  logger.logInfo("Monte test: Using crypto pub.dev function. Loading $name ...");

  final func = _funcMap[name];
  if(func == null) {
    logger.logError("No such function '$name' in system");
    return;
  }

  File f = File("test_vectors/$name/${name}_monte.json");
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
      var d = func(temp);
      a = b;
      b = c;
      c = Uint8List.fromList(d);
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