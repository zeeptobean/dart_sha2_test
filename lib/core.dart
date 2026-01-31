import "package:dart_sha2_test/impl.dart";

void runTestSha256() => runTest(funcName: "sha256_str", digestSize: 64, testSuiteName: "sha256");
void runTestSha512() => runTest(funcName: "sha512_str", digestSize: 128, testSuiteName: "sha512");
void runTestSha224() => runTest(funcName: "sha224_str", digestSize: 56, testSuiteName: "sha224");
void runTestSha384() => runTest(funcName: "sha384_str", digestSize: 96, testSuiteName: "sha384");
void runTestSha512_224() => runTest(funcName: "sha512_224_str", digestSize: 56, testSuiteName: "sha512_224");
void runTestSha512_256() => runTest(funcName: "sha512_256_str", digestSize: 64, testSuiteName: "sha512_256");

void runMonteSha256() => runMonte(funcName: "sha256_str", digestSize: 64, testSuiteName: "sha256");
void runMonteSha512() => runMonte(funcName: "sha512_str", digestSize: 128, testSuiteName: "sha512");
void runMonteSha224() => runMonte(funcName: "sha224_str", digestSize: 56, testSuiteName: "sha224");
void runMonteSha384() => runMonte(funcName: "sha384_str", digestSize: 96, testSuiteName: "sha384");
void runMonteSha512_224() => runMonte(funcName: "sha512_224_str", digestSize: 56, testSuiteName: "sha512_224");
void runMonteSha512_256() => runMonte(funcName: "sha512_256_str", digestSize: 64, testSuiteName: "sha512_256");

void benchSha256({int iterations = 1}) => runMonte(funcName: "sha256_str", digestSize: 64, testSuiteName: "sha256", iterations: iterations);
void benchSha512({int iterations = 1}) => runMonte(funcName: "sha512_str", digestSize: 128, testSuiteName: "sha512", iterations: iterations);
void benchSha224({int iterations = 1}) => runMonte(funcName: "sha224_str", digestSize: 56, testSuiteName: "sha224", iterations: iterations);
void benchSha384({int iterations = 1}) => runMonte(funcName: "sha384_str", digestSize: 96, testSuiteName: "sha384", iterations: iterations);
void benchSha512_224({int iterations = 1}) => runMonte(funcName: "sha512_224_str", digestSize: 56, testSuiteName: "sha512_224", iterations: iterations);
void benchSha512_256({int iterations = 1}) => runMonte(funcName: "sha512_256_str", digestSize: 64, testSuiteName: "sha512_256", iterations: iterations);