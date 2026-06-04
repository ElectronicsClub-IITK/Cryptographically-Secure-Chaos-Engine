#include <iostream>
#include <string>
#include <cctype>

using namespace std;

string encrypt(string text, string key) {
    string out;
    int j = 0;
    for (int i = 0; i < text.length(); i++) {
        char c = text[i];
        if (isalpha(c)) {
            char base = islower(c) ? 'a' : 'A';
            int shift = toupper(key[j % key.length()]) - 'A';
            c = (c - base + shift) % 26 + base;
            j++;
        }
        out += c;
    }
    return out;
}

string decrypt(string text, string key) {
    string out;
    int j = 0;
    for (int i = 0; i < text.length(); i++) {
        char c = text[i];
        if (isalpha(c)) {
            char base = islower(c) ? 'a' : 'A';
            int shift = toupper(key[j % key.length()]) - 'A';
            c = (c - base - shift + 26) % 26 + base;
            j++;
        }
        out += c;
    }
    return out;
}

int main() {
    string mode, text, key;
    if (cin >> mode >> key) {
        cin.ignore();
        getline(cin, text);
        if (mode == "encrypt") {
            cout << encrypt(text, key) << "\n";
        } else if (mode == "decrypt") {
            cout << decrypt(text, key) << "\n";
        }
    }
    return 0;
}
