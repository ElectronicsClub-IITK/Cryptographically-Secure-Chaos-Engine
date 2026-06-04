#include <bits/stdc++.h>
using namespace std;

vector<uint8_t> character_to_bytes(const string& characters)
{
    vector<uint8_t> ret;
    for (size_t i = 0; i < characters.size(); i++)
    {
            ret.push_back(characters[i]);
    }
    return ret;
}

vector<uint8_t> repeating_key_xor(const string& ciphertext, const string& key)
{
    vector<uint8_t> plaintext;
    for (size_t i = 0; i < ciphertext.size(); i++)
    {
        plaintext.push_back(ciphertext[i] ^ key[i % key.size()]);
    }
    return plaintext;
}
string bytes_to_hex(const vector<uint8_t>& bytes)
{
    string ret = "";
    for(size_t i=0;i<bytes.size();i++)
    {
        int high = bytes[i] / 16;
        int low = bytes[i] % 16;
        
        // Convert the number to a character properly (0-9 -> '0'-'9', 10-15 -> 'a'-'f')
        if (high < 10) ret += (high + '0');
        else ret += (high - 10 + 'a');
        
        if (low < 10) ret += (low + '0');
        else ret += (low - 10 + 'a');
    }
    return ret;
}

int main() {
    string plaintext = "";
    string key = "ICE";
    
    char c;
    while (cin.get(c)) 
    {
        plaintext += c;
    }

    while (!plaintext.empty() && (plaintext.back() == '\n' || plaintext.back() == '\r')) {
        plaintext.pop_back();
    }
    
    vector<uint8_t> ciphertext = repeating_key_xor(plaintext, key);
    string hex_str = bytes_to_hex(ciphertext);
    cout << hex_str << "\n";
    return 0;
}