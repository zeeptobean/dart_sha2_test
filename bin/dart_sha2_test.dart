import 'package:ansicolor/ansicolor.dart';
import 'package:dart_sha2_test/core.dart';

void main(List<String> arguments) {
  ansiColorDisabled = false;

  runTest("sha256_str", 64, "sha256");
  runTest("sha512_str", 128, "sha512");
  runTest("sha224_str", 56, "sha224");
  runTest("sha384_str", 96, "sha384");
  runTest("sha512_224_str", 56, "sha512_224");
  runTest("sha512_256_str", 64, "sha512_256");
}
