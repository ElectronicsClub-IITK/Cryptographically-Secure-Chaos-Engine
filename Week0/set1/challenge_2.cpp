#include <iostream>
#include <string>
#include <vector>
#include <cctype>

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
vector<uint8_t> xor_bytes(const vector<uint8_t>& a, const vector<uint8_t>& b)
{
    vector<uint8_t> ret;
    for (size_t i = 0; i < a.size(); i++)
    {
        ret.push_back(a[i] ^ b[i]);
    }
    return ret;
}
int main()
{
    string hex1="1c0111001f010100061a024b53535009181c";
    string hex2="686974207468652062756c6c277320657965";
    auto bytes1=hex_to_bytes(hex1);
    auto bytes2=hex_to_bytes(hex2);
    auto result_bytes=xor_bytes(bytes1,bytes2);
    for(uint8_t b:result_bytes)
    {
        cout<<std::hex<<(int)b;
    }
    cout<<endl;
    return 0;
}