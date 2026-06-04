#include <bits/stdc++.h>
using namespace std;
vector<uint8_t> character_to_bytes(const string& characters)
{
    vector<uint8_t> out;
    string b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    vector<int> T(256, -1);
    for (int i=0; i<64; i++) T[b64chars[i]] = i; 

    int val=0, valb=-8;
    for (uint8_t c : characters)
    {
        if (T[c] == -1) continue; 
        val = (val<<6) + T[c];
        valb += 6;
        if (valb>=0)
        {
            out.push_back(uint8_t((val>>valb)&0xFF));
            valb-=8;
        }
    }
    return out;
}
int hamming_distance(vector<uint8_t>&a,vector<uint8_t>&b)
{
    int distance=0;
    for(size_t i=0;i<a.size();i++)
    {
        distance += __builtin_popcount(a[i] ^ b[i]);
    }
    return distance;
}
double normalized_distance(vector<uint8_t>file,int keysize)
{
    double distance=0;
    int count=0;
    for(size_t i=0; i + 2 * keysize <= file.size(); i += 2 * keysize)
    {
        vector<uint8_t> a(file.begin() + i, file.begin() + i + keysize);
        vector<uint8_t> b(file.begin() + i + keysize, file.begin() + i + 2 * keysize);
        distance+=(double)(hamming_distance(a,b))/(double)keysize;
        count++;
    }      
    if (count == 0) return 1000000.0;
    return distance/(double)count;
}
int score(const vector<uint8_t>& data)
{
    int score = 0;
    string common_chars = "etaoinshrdlucmpfwgvbkyjxqz ETAOINSHRDLUCMPFWGVBKYJXQZ ";
    for (uint8_t b : data)
    {
        if (b < 32)
        {
            score -= 2;
        }
        else if (b > 127)
        {
            score -= 1;
        }
        else
        {
            char c = (char)b;
            if (common_chars.find(c) != std::string::npos)
            {
                score += 1;
            }
        }
    }
    return score;
}
char score_english(const vector<uint8_t>& data)
{
    int best_score=-1000000;
    char best_key;
    for (int key = 0; key < 256; ++key)
    {
        vector<uint8_t> plaintext;
        for (uint8_t b : data)
        {
            plaintext.push_back(b ^ key);
        }
        int s = score(plaintext);
        if (s > best_score)
        {
            best_score = s;
            best_key =(char)key;
        }
    }
    return best_key;
}
int main() 
{
    string file,str;
    while(cin>>str)
    {
        file+=str;
    }
    auto bytes=character_to_bytes(file);
    int keysize=0;
    double min_distance=1000000;
    for(int i=2;i<=40;i++)
    {
        double distance=normalized_distance(bytes,i);
        if(distance<min_distance)
        {
            min_distance=distance;
            keysize=i;
        }   
    }
    cout<<min_distance<<" "<<keysize<<endl;
    for(int i=0;i<keysize;i++)
    {
        vector<uint8_t> chunk;
        for(int j=i;j<bytes.size();j+=keysize)
        {
            chunk.push_back(bytes[j]);
        }
        char key=score_english(chunk);
        cout<<key;
    }
    cout<<endl;
    return 0;
}