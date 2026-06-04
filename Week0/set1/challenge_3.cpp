#include <iostream>
#include <string>
#include <vector>
#include <cctype>
#include <algorithm>
using namespace std;

vector<uint8_t> hex_to_bytes(const string& hex)
{
    vector<uint8_t> ret;
    for (size_t i = 0; i < hex.size(); i += 2)
    {
        string byte_hex = hex.substr(i, 2);
        uint8_t b = (uint8_t)stoi(byte_hex, nullptr, 16);
        ret.push_back(b);
    }
    return ret;
}

int score_english(const vector<uint8_t>& data) {
    int score = 0;
    string common_chars = "etaoinshrdlucmpfwgvbkyjxqz ETAOINSHRDLUCMPFWGVBKYJXQZ ";
    for (uint8_t b : data)
    {
        if (b < 32) {
            score -= 2;
        } else if (b > 127) {
            score -= 1;
        } else {
            char c = (char)b;
            if (common_chars.find(c) != std::string::npos) {
                score += 1;
            }
        }
    }
    return score;
}

int main() 
{
    string hex_str = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    auto ciphertext = hex_to_bytes(hex_str);

    int best_score = -1000000;
    uint8_t best_key = 0;
    vector<uint8_t> best_plaintext;

    for (int key = 0; key < 256; ++key)
    {
        vector<uint8_t> plaintext;
        for (uint8_t b : ciphertext)
        {
            plaintext.push_back(b ^ key);
        }

        int s = score_english(plaintext);
        if (s > best_score) {
            best_score = s;
            best_key = key;
            best_plaintext = plaintext;
        }
    }

    cout << "Key (char): '" << (char)best_key << "'\n";
    cout << "Key (hex): 0x" << std::hex << (int)best_key << "\n";

    cout << "Plaintext: ";
    for (uint8_t b : best_plaintext) {
        if (b >= 32 && b <= 126) {
            cout << (char)b;
        } else {
            cout << '?';
        }
    }
    cout << "\n";

    return 0;
}
