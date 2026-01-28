#include <bits/stdc++.h>
#include "sha2.h"
using namespace std;

int main() {
    string input = "Hello, Dart FFI!";
    // getline(cin, input);

    char hash_output[65];
    sha256_str(input.c_str(), input.length(), hash_output);

    cout << "SHA-256 Hash: " << hash_output << endl;

    return 0;
}