//implement caesar cipher
#include <bits/stdc++.h>
using namespace std;

string caesar_cipher(const string& text, int shift)
{
    string result = "";
    shift = (shift % 26 + 26) % 26;
    for (char c : text)
    {
        if (isalpha(c))
        {
            char base = isupper(c) ? 'A' : 'a';
            result += (char)((c - base + shift) % 26 + base);
        }
        else
        {
            result += c;
        }
    }
    return result;
}

int main()
{
    string text = "Hello World!";
    int shift = 3;
    string encrypted = caesar_cipher(text, shift);
    cout << encrypted << "\n";
    string decrypted = caesar_cipher(encrypted, -shift);
    cout << decrypted << "\n";
    return 0;
}
