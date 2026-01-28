#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

const uint32_t SHA256_INITIAL[8]        = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
const uint32_t SHA224_INITIAL[8]        = {0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939, 0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4};

const uint64_t SHA512_INITIAL[8]        = {0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1, 0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179};
const uint64_t SHA384_INITIAL[8]        = {0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17, 0x152fecd8f70e5939, 0x67332667ffc00b31, 0x8eb44a8768581511, 0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4};
const uint64_t SHA512_224_INITIAL[8]    = {0x8c3d37c819544da2, 0x73e1996689dcd4d6, 0x1dfab7ae32ff9c82, 0x679dd514582f9fcf, 0x0f6d2b697bd44da8, 0x77e36f7304C48942, 0x3f9d85a86a1d36C8, 0x1112e6ad91d692a1};
const uint64_t SHA512_256_INITIAL[8]    = {0x22312194fc2bf72c, 0x9f555fa3c84c64c2, 0x2393b86b6f53b151, 0x963877195940eabd, 0x96283ee2a88effe3, 0xbe5e1e2553863992, 0x2b0199fc2c85b8aa, 0x0eb72ddC81c52ca2};
const uint64_t SHA512_T_INITIAL[8]      = {0xcfac43c256196cad, 0x1ec20b20216f029e, 0x99cb56d75b315d8e, 0x00ea509ffab89354, 0xf4abf7da08432774, 0x3ea0cd298e9bc9ba, 0xba267c0e5ee418ce, 0xfe4568bcb6db84dc};

static void internal_memset(void *dst, int val, size_t sz) {
    void* (*const volatile volatile_memset)(void*, int, size_t) = memset;
    volatile_memset(dst, val, sz);
}

static int internal_free2(void **ptr, size_t size_in_byte) {
    if(ptr != NULL || *ptr != NULL) {
        internal_memset(*ptr, 0, size_in_byte);
        free(*ptr);
        *ptr = NULL;
        return 1;
    }
    return 0;
}

static int internal_free(void *ptr, size_t size_in_byte) {
    if(ptr != NULL) {
        internal_memset(ptr, 0, size_in_byte);
        free(ptr);
        return 1;
    }
    return 0;
}

static void swap_bit_endian(uint8_t *_x) {
    uint8_t tmp = 0;
    for(int i=0;;) {
        tmp |= (*_x & 1);
        i++;
        if(i == 8) break;
        tmp <<= 1;
        *_x >>= 1;
    }
    *_x = tmp; 
}

static uint32_t swap_byte_endian_32(uint32_t x) {
    uint32_t tmp = (x & 255) << 24;
    tmp |= (((x >> 8) & 255) << 16);
    tmp |= (((x >> 16) & 255) << 8);
    tmp |= ((x >> 24) & 255);
    return tmp;
}

static uint64_t swap_byte_endian_64(uint64_t x) {
    uint64_t tmp = (x & 255) << 56;
    tmp |= (((x >> 8) & 255) << 48);
    tmp |= (((x >> 16) & 255) << 40);
    tmp |= (((x >> 24) & 255) << 32);
    tmp |= (((x >> 32) & 255) << 24);
    tmp |= (((x >> 40) & 255) << 16);
    tmp |= (((x >> 48) & 255) << 8);
    tmp |= ((x >> 56) & 255);
    return tmp;
}

static uint32_t rotr32(uint32_t c, uint8_t n) {
    return (c >> n) | (c << (32-n));
}

static uint64_t rotr64(uint64_t c, uint8_t n) {
    return (c >> n) | (c << (64-n));
}

static void sha256_impl(uint32_t arr[16], uint32_t state[8]) {
    const uint32_t k[64] = {0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
    uint32_t *h = (uint32_t*) malloc(32);
    memcpy(h, state, 32);
    uint32_t *w = (uint32_t*) malloc(256);
    memcpy(w, arr, 64);
    for(int i=16; i < 64; i++) {
        uint32_t s0 = rotr32(w[i-15], 7) ^ rotr32(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = rotr32(w[i-2], 17) ^ rotr32(w[i-2], 19) ^ (w[i-2] >> 10);
        w[i] = s0 + s1 + w[i-7] + w[i-16];
    }

    for(int i=0; i < 64; i++) {
        uint32_t sum0, sum1, temp1, temp2, maj, ch;
        sum0 = rotr32(h[0], 2) ^ rotr32(h[0], 13) ^ rotr32(h[0], 22);
        sum1 = rotr32(h[4], 6) ^ rotr32(h[4], 11) ^ rotr32(h[4], 25);
        maj = (h[0] & h[1]) ^ (h[0] & h[2]) ^ (h[1] & h[2]);
        ch = (h[4] & h[5]) ^ ((~h[4]) & h[6]);
        temp1 = sum1 + ch + k[i] + w[i] + h[7];
        temp2 = sum0 + maj;

        memmove(h+1, h, 28);
        h[0] = temp1 + temp2;
        h[4] += temp1;
    }
    for(int i=0; i < 8; i++) state[i] += h[i];

    internal_free(h, 32);
    internal_free(w, 256);
}

static void sha512_impl(uint64_t arr[16], uint64_t state[8]) {
    const uint64_t k[80] = {0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538, 
                            0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe, 
                            0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 
                            0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 
                            0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab, 
                            0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725, 
                            0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 
                            0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b, 
                            0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218, 
                            0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 
                            0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 
                            0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec, 
                            0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c, 
                            0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6, 
                            0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 
                            0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817};

    uint64_t *h = (uint64_t*) malloc(64);
    memcpy(h, state, 64);
    uint64_t *w = (uint64_t*) malloc(5120);
    memcpy(w, arr, 128);
    for(int i=16; i < 80; i++) {
        uint64_t s0 = rotr64(w[i-15], 1) ^ rotr64(w[i-15], 8) ^ (w[i-15] >> 7);
        uint64_t s1 = rotr64(w[i-2], 19) ^ rotr64(w[i-2], 61) ^ (w[i-2] >> 6);
        w[i] = s0 + s1 + w[i-7] + w[i-16];
    }

    for(int i=0; i < 80; i++) {
        uint64_t sum0, sum1, temp1, temp2, maj, ch;
        sum0 = rotr64(h[0], 28) ^ rotr64(h[0], 34) ^ rotr64(h[0], 39);
        sum1 = rotr64(h[4], 14) ^ rotr64(h[4], 18) ^ rotr64(h[4], 41);
        maj = (h[0] & h[1]) ^ (h[0] & h[2]) ^ (h[1] & h[2]);
        ch = (h[4] & h[5]) ^ ((~h[4]) & h[6]);
        temp1 = sum1 + ch + k[i] + w[i] + h[7];
        temp2 = sum0 + maj;

        memmove(h+1, h, 56);
        h[0] = temp1 + temp2;
        h[4] += temp1;
    }
    for(int i=0; i < 8; i++) state[i] += h[i];

    internal_free(h, 64);
    internal_free(w, 5120);
}

//Byte version for sha512 only support at most (2^61) bytes
int sha512_bytes(const char *input_arr, uint64_t no_of_bytes, const uint64_t initial_state[8], uint64_t output_state[8]) {
    if(no_of_bytes > (1ULL << 61)) return 0;
    
    uint64_t *state = (uint64_t*) malloc(64);
    memcpy(state, initial_state, 64);
    uint64_t no_of_bits = no_of_bytes*8;
    uint64_t aligned_bits = ((no_of_bits+129)/1024 + ((no_of_bits+129) % 1024 != 0))*1024;
    uint64_t aligned_qwords = aligned_bits/64;
    uint64_t *arr = (uint64_t*) calloc(aligned_qwords, 8);
    memcpy(arr, input_arr, no_of_bytes);
    arr[no_of_bytes/8] |= ((uint64_t) 0x80 << 8*(no_of_bytes % 8));
    for(uint64_t i=0; i < aligned_qwords; i++) arr[i] = swap_byte_endian_64(arr[i]);
    arr[aligned_qwords-1] = no_of_bits;
    arr[aligned_qwords-2] = 0;

    for(uint64_t i=0; i < aligned_qwords; i+=16) sha512_impl(&arr[i], state);
    memcpy(output_state, state, 64);

    internal_free(arr, aligned_qwords*8);
    internal_free(state, 64);
    return 1;
}

//bits versions are not tested yet...
/*
// void sha512_bits(char *input_arr, uint64_t no_of_bits_lo, uint64_t no_of_bits_hi, uint64_t output_state[8]) {}
void sha256_bits(char *input_arr, uint64_t no_of_bits, uint32_t output_state[8]) {
    uint32_t *state = (uint32_t*) malloc(32);
    state[0] = (uint32_t) 0x6a09e667;
    state[1] = (uint32_t) 0xbb67ae85;
    state[2] = (uint32_t) 0x3c6ef372;
    state[3] = (uint32_t) 0xa54ff53a;
    state[4] = (uint32_t) 0x510e527f;
    state[5] = (uint32_t) 0x9b05688c;
    state[6] = (uint32_t) 0x1f83d9ab;
    state[7] = (uint32_t) 0x5be0cd19;

    uint64_t no_of_bytes = no_of_bits / 8;
    uint64_t no_of_rem_bit = no_of_bits % 8;
    uint64_t aligned_bits = ((no_of_bits+65)/512 + ((no_of_bits+65) % 512 != 0))*512;
    uint64_t aligned_dwords = aligned_bits/32;

    uint32_t *arr = (uint32_t*) calloc(aligned_dwords, 4);
    memcpy(arr, input_arr, no_of_bytes + (no_of_rem_bit != 0));

    uint8_t *the_byte_need_change = &((uint8_t*) arr)[no_of_bytes];
    *the_byte_need_change &= (uint8_t) ((1 << no_of_rem_bit)-1);
    *the_byte_need_change |= (1 << no_of_rem_bit);
    swap_bit_endian(the_byte_need_change);

    for(uint64_t i=0; i < aligned_dwords; i++) arr[i] = swap_byte_endian_32(arr[i]);

    arr[aligned_dwords-1] = (uint32_t) no_of_bits;
    arr[aligned_dwords-2] = (uint32_t) (no_of_bits >> 32);

    for(uint64_t i=0; i < aligned_dwords; i+=16) sha256_impl(&arr[i], state);

    memcpy(output_state, state, 32);

    memset(arr, 0, aligned_dwords*4);
    free(arr);
    memset(state, 0, 32);
    free(state);
}
*/

//Byte version for sha256 only support at most (2^61) bytes
int sha256_bytes(const char *input_arr, uint64_t no_of_bytes, const uint32_t initial_state[8], uint32_t output_state[8]) {
    if(no_of_bytes > (1ULL << 61)) return 0;

    uint32_t *state = (uint32_t*) malloc(32);
    memcpy(state, initial_state, 32);
    uint64_t no_of_bits = no_of_bytes*8;
    uint64_t aligned_bits = ((no_of_bits+65)/512 + ((no_of_bits+65) % 512 != 0))*512;
    uint64_t aligned_dwords = aligned_bits/32;
    uint32_t *arr = (uint32_t*) calloc(aligned_dwords, 4);
    memcpy(arr, input_arr, no_of_bytes);
    arr[no_of_bytes/4] |= ((uint32_t) 0x80 << 8*(no_of_bytes % 4));
    for(uint64_t i=0; i < aligned_dwords; i++) arr[i] = swap_byte_endian_32(arr[i]);
    arr[aligned_dwords-1] = (uint32_t) no_of_bits;
    arr[aligned_dwords-2] = (uint32_t) (no_of_bits >> 32);

    for(uint64_t i=0; i < aligned_dwords; i+=16) sha256_impl(&arr[i], state);
    memcpy(output_state, state, 32);

    internal_free(arr, aligned_dwords*4);
    internal_free(state, 32);
    return 1;
}

/*
int sha512_224_bytes(const char *input_arr, uint64_t no_of_bytes, uint32_t output_block[7]) {
    uint64_t state[8] = {0};
    if(!sha512_bytes(input_arr, no_of_bytes, SHA512_224_INITIAL, state)) return 0;
    for(int i=0; i < 3; i++) {
        output_block[i*2]   = (uint32_t) ( state[i] >> 32 );
        output_block[i*2+1] = (uint32_t) ( state[i] &= ((1ULL << 32)-1) );
    }
    output_block[6] = (uint32_t) (state[3] >> 32);
    internal_memset(state, 0, sizeof(state));
    return 1;
}

int sha512_256_bytes(const char *input_arr, uint64_t no_of_bytes, uint64_t output_block[4]) {
    uint64_t state[8] = {0};
    if(!sha512_bytes(input_arr, no_of_bytes, SHA512_256_INITIAL, state)) return 0;
    memcpy(output_block, state, 32);
    internal_memset(state, 0, sizeof(state));
    return 1;
}


//Generate SHA-512/t
// @param input_arr
// @param no_of_bytes
// @param bit specified length in bits
// @param output_block return hash output in bits. Pointer to dynamically allocated memory with the size of (int64(bit/64)+1)*8 bytes. Unused bits are mark zero
// @return 1 if hash function is completed. 0 if illegal bit number specified, which is 384 or outside the range (0, 512)
int sha512t(const char *input_arr, uint64_t no_of_bytes, int bit, uint64_t **ptr_output_block) {
    uint64_t *output_block = 0; 
    if(bit >= 512 || bit <= 0 || bit == 384) return 0;
    else if(bit == 256) {
        uint64_t toutput[4];
        sha512_256(input_arr, no_of_bytes, toutput);
        output_block = (uint64_t*) calloc(40, 1);
        memcpy(output_block, toutput, 32);
        *ptr_output_block = output_block;
        internal_memset(toutput, 0, sizeof(toutput));
        return 1;
    }
    else if(bit == 224) {
        uint64_t toutput[8];
        sha512_bytes(input_arr, no_of_bytes, SHA512_224_INITIAL, toutput);
        output_block = (uint64_t*) calloc(32, 1);
        memcpy(output_block, toutput, 32);
        output_block[3] &= ~((1ULL << 32)-1);
        *ptr_output_block = output_block;
        internal_memset(toutput, 0, sizeof(toutput));
        return 1;
    }

    char tarr[101];
    uint64_t newh[8], final_block[8];
    memset(tarr, 0, sizeof(tarr));
    snprintf(tarr, 100, "SHA-512/%d", bit);
    sha512_bytes(tarr, strlen(tarr), SHA512_T_INITIAL, newh);
    sha512_bytes(input_arr, no_of_bytes, newh, final_block);
    int whole_block = bit / 64;
    int rem_block = bit % 64;
    output_block = (uint64_t*) calloc((size_t) whole_block+1, 8);
    memcpy(output_block, final_block, (size_t) whole_block*8);
    output_block[whole_block] = final_block[whole_block] & ~((1ULL << (64-rem_block))-1);

    internal_memset(tarr, 0, sizeof(tarr));
    internal_memset(newh, 0, sizeof(newh));
    internal_memset(final_block, 0, sizeof(final_block));
    whole_block = 0;
    rem_block = 0;

    *ptr_output_block = output_block;
    return 1;
}

*/

int sha256_str(const char *input_arr, uint64_t no_of_bytes, char str[65]) {
    uint32_t *state = (uint32_t*) malloc(32);
    if(!sha256_bytes(input_arr, no_of_bytes, SHA256_INITIAL, state)) return 0;
    memset(str, 0, 65);
    char tstr[10];
    for(int i=0; i < 8; i++) {
        internal_memset(tstr, 0, sizeof(tstr));
        snprintf(tstr, 9, "%.8x", state[i]);
        strcat(str, tstr);
        internal_memset(tstr, 0, sizeof(tstr));
    }

    internal_free(state, 32);
    return 1;
}

int sha512_str(const char *input_arr, uint64_t no_of_bytes, char str[129]) {
    uint64_t *state = (uint64_t*) malloc(64);
    if(!sha512_bytes(input_arr, no_of_bytes, SHA512_INITIAL, state)) return 0;
    memset(str, 0, 129);
    char tstr[20];
    for(int i=0; i < 8; i++) {
        internal_memset(tstr, 0, sizeof(tstr));
        snprintf(tstr, 17, "%.16llx", (unsigned long long) state[i]);    //cast to avoid warning on linux
        strcat(str, tstr);
        internal_memset(tstr, 0, sizeof(tstr));
    }

    internal_free(state, 64);
    return 1;
}

int sha224_str(const char *input_arr, uint64_t no_of_bytes, char str[57]) {
    uint32_t *state = (uint32_t*) malloc(32);
    if(!sha256_bytes(input_arr, no_of_bytes, SHA224_INITIAL, state)) return 0;
    memset(str, 0, 57);
    char tstr[10];
    for(int i=0; i < 7; i++) {
        internal_memset(tstr, 0, sizeof(tstr));
        snprintf(tstr, 9, "%.8x", state[i]);
        strcat(str, tstr);
        internal_memset(tstr, 0, sizeof(tstr));
    } 

    internal_free(state, 32);
    return 1;
}

int sha384_str(const char *input_arr, uint64_t no_of_bytes, char str[97]) {
    uint64_t *state = (uint64_t*) malloc(64);
    if(!sha512_bytes(input_arr, no_of_bytes, SHA384_INITIAL, state)) return 0;
    memset(str, 0, 97);
    char tstr[20];
    for(int i=0; i < 6; i++) {
        internal_memset(tstr, 0, sizeof(tstr));
        snprintf(tstr, 17, "%.16llx", (unsigned long long) state[i]);
        strcat(str, tstr);
        internal_memset(tstr, 0, sizeof(tstr));
    }

    internal_free(state, 64);
    return 1;
}

int sha512_224_str(const char *input_arr, uint64_t no_of_bytes, char str[57]) {
    uint64_t state[8] = {0};
    memset(str, 0, 57);
    if(!sha512_bytes(input_arr, no_of_bytes, SHA512_224_INITIAL, state)) return 0;
    char tstr[20];
    for(int i=0; i < 3; i++) {
        internal_memset(tstr, 0, sizeof(tstr));
        snprintf(tstr, 17, "%.16llx", (unsigned long long)state[i]);
        strcat(str, tstr);
        internal_memset(tstr, 0, sizeof(tstr));
    }
    internal_memset(tstr, 0, sizeof(tstr));
    snprintf(tstr, 10, "%.8x", (uint32_t) (state[3] >> 32));
    strcat(str, tstr);
    internal_memset(tstr, 0, sizeof(tstr));
    internal_memset(state, 0, sizeof(state));

    return 1;
}

int sha512_256_str(const char *input_arr, uint64_t no_of_bytes, char str[65]) {
    uint64_t state[8] = {0};
    memset(str, 0, 65);
    memset(state, 0, sizeof(state));
    if(!sha512_bytes(input_arr, no_of_bytes, SHA512_256_INITIAL, state)) return 0;
    char tstr[20];
    for(int i=0; i < 4; i++) {
        internal_memset(tstr, 0, sizeof(tstr));
        snprintf(tstr, 17, "%.16llx", (unsigned long long) state[i]);
        strcat(str, tstr);
        internal_memset(tstr, 0, sizeof(tstr));
    }
    internal_memset(state, 0, sizeof(state));

    return 1;
}

