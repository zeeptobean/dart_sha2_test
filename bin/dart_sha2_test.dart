import 'package:ansicolor/ansicolor.dart';
import 'package:dart_sha2_test/core.dart';
import 'package:dart_sha2_test/system_bench.dart' as bench1;
import 'package:dart_sha2_test/system_bench2.dart' as bench2;

void main(List<String> arguments) async {
  ansiColorDisabled = false;

  benchSha256(iterations: 100);
  bench1.benchSystemSha256(iterations: 100);
  await bench2.benchSystemSha256(iterations: 100);
}
