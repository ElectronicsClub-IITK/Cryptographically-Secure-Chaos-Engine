#include <bits/stdc++.h>
using namespace std;

int modInverse(int a, int m)
{
    a = a % m;
    for (int x = 1; x < m; x++)
        if ((a * x) % m == 1)
            return x;
    return -1;
}

string affine_encrypt(const string& text, int a, int b)
{
    string result = "";
    for (char c : text)
    {
        if (isalpha(c))
        {
            char base = isupper(c) ? 'A' : 'a';
            result += (char)((((c - base) * a) + b) % 26 + base);
        }
        else
        {
            result += c;
        }
    }
    return result;
}

string affine_decrypt(const string& text, int a, int b)
{
    string result = "";
    int a_inv = modInverse(a, 26);
    if (a_inv == -1) return "Error: 'a' and 26 are not coprime.";
    
    for (char c : text)
    {
        if (isalpha(c))
        {
            char base = isupper(c) ? 'A' : 'a';
            int val = ((c - base) - b) % 26;
            if (val < 0) val += 26;
            result += (char)((val * a_inv) % 26 + base);
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
    int a = 5;
    int b = 8;
    string encrypted = affine_encrypt(text, a, b);
    cout << encrypted << "\n";
    string decrypted = affine_decrypt(encrypted, a, b);
    cout << decrypted << "\n";
    return 0;
}
