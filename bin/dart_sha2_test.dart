import 'package:ansicolor/ansicolor.dart';
import 'package:dart_sha2_test/core.dart';
import 'package:dart_sha2_test/system_bench2.dart';

void main(List<String> arguments) async {
  ansiColorDisabled = false;

  benchSha256(iterations: 50);
  await benchSystemSha256(iterations: 50);
}
