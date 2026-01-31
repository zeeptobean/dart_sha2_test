import 'package:ansicolor/ansicolor.dart';
import 'package:dart_sha2_test/core.dart';
import 'package:dart_sha2_test/system_bench.dart';

void main(List<String> arguments) {
  ansiColorDisabled = false;

  benchSha512(iterations: 50);
  benchSystemSha512(iterations: 50);
}
