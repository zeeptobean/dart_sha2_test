Testing my own SHA2 implementation written in C, running in Dart using FFI
Currently Linux is guarenteed to work

Test vectors originate from [CAVP for SHA](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/secure-hashing)

Run instruction
1. Navigate to `clib` folder and run make to build library
2. Install library: `dart pub get`
3. Navigate back to rootdir and run `dart run`