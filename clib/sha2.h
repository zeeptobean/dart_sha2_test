#ifndef ZEEPT_SHA2_H
#define ZEEPT_SHA2_H

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#include <stdint.h>

EXTERNC int sha256_str(const char*, uint64_t, char[65]);
EXTERNC int sha512_str(const char*, uint64_t, char[129]);
EXTERNC int sha224_str(const char*, uint64_t, char[57]);
EXTERNC int sha384_str(const char*, uint64_t, char[97]);
EXTERNC int sha512_224_str(const char*, uint64_t, char[57]);
EXTERNC int sha512_256_str(const char*, uint64_t, char[65]);

#endif