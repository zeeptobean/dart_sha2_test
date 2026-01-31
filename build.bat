@echo off
cd clib
gcc -c -fPIC sha2.c -Wall -pedantic -O2 -march=native -o sha2.o
gcc -shared -o libmysha2.dll sha2.o
cd ..
dart pub get
dart compile exe bin/dart_sha2_test.dart -o dart_sha2_test.exe