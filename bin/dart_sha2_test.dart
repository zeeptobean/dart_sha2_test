import 'package:ansicolor/ansicolor.dart';
import 'package:dart_sha2_test/core.dart';

void main(List<String> arguments) {
  ansiColorDisabled = false;

  runTestSha256();
  runMonteSha256();
  runTestSha512();
  runMonteSha512();
  runTestSha224();
  runMonteSha224();
  runTestSha384();
  runMonteSha384();
  runTestSha512_224();
  runMonteSha512_224();
  runTestSha512_256();
  runMonteSha512_256();
}
