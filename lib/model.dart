import 'dart:typed_data';
import 'package:convert/convert.dart';

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