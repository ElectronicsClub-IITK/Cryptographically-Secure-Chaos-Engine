#include <iostream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;

bool embed(const string& input_image, const string& output_image, const string& message) {
    ifstream in(input_image, ios::binary);
    if (!in) {
        cerr << "Error opening input image: " << input_image << endl;
        return false;
    }

    vector<char> header(54);
    if (!in.read(header.data(), 54)) {
        cerr << "Error reading image header. Is it a valid BMP?" << endl;
        return false;
    }

    vector<char> data((istreambuf_iterator<char>(in)), istreambuf_iterator<char>());
    in.close();

    uint32_t msg_len = message.length();
    
    size_t bits_needed = 32 + msg_len * 8;
    if (data.size() < bits_needed) {
        cerr << "Image is too small to hold the message." << endl;
        return false;
    }

    vector<int> bits;
    
    for (int i = 31; i >= 0; --i) {
        bits.push_back((msg_len >> i) & 1);
    }
    
    for (char c : message) {
        for (int i = 7; i >= 0; --i) {
            bits.push_back((c >> i) & 1);
        }
    }

    for (size_t i = 0; i < bits.size(); ++i) {
        data[i] = (data[i] & ~1) | bits[i];
    }

    ofstream out(output_image, ios::binary);
    if (!out) {
        cerr << "Error creating output image: " << output_image << endl;
        return false;
    }
    
    out.write(header.data(), 54);
    out.write(data.data(), data.size());
    out.close();

    cout << "Message successfully embedded in " << output_image << endl;
    return true;
}

string extract(const string& stego_image) {
    ifstream in(stego_image, ios::binary);
    if (!in) {
        cerr << "Error opening stego image: " << stego_image << endl;
        return "";
    }

    in.seekg(54, ios::beg);

    uint32_t msg_len = 0;
    char byte;
    for (int i = 0; i < 32; ++i) {
        if (!in.get(byte)) {
            cerr << "Error reading image data while extracting length." << endl;
            return "";
        }
        msg_len = (msg_len << 1) | (byte & 1);
    }

    if (msg_len > 10000000) {
        cerr << "Extracted message length seems invalid or too large." << endl;
        return "";
    }

    string message = "";
    for (uint32_t i = 0; i < msg_len; ++i) {
        char c = 0;
        for (int j = 0; j < 8; ++j) {
            if (!in.get(byte)) {
                cerr << "Error reading image data while extracting message." << endl;
                return message;
            }
            c = (c << 1) | (byte & 1);
        }
        message += c;
    }
    in.close();

    return message;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cout << "Steganography using Least Significant Bit (LSB) on BMP images." << endl;
        cout << "Usage: " << endl;
        cout << "  To embed:  " << argv[0] << " embed <input.bmp> <output.bmp> \"<secret message>\"" << endl;
        cout << "  To extract: " << argv[0] << " extract <stego.bmp>" << endl;
        return 1;
    }

    string mode = argv[1];

    if (mode == "embed" && argc == 5) {
        string input_image = argv[2];
        string output_image = argv[3];
        string message = argv[4];
        embed(input_image, output_image, message);
    } else if (mode == "extract" && argc == 3) {
        string stego_image = argv[2];
        string msg = extract(stego_image);
        if (!msg.empty()) {
            cout << "Extracted Message: " << msg << endl;
        } else {
            cout << "No message extracted." << endl;
        }
    } else {
        cout << "Invalid arguments." << endl;
        cout << "Usage: " << endl;
        cout << "  To embed:  " << argv[0] << " embed <input.bmp> <output.bmp> \"<secret message>\"" << endl;
        cout << "  To extract: " << argv[0] << " extract <stego.bmp>" << endl;
    }

    return 0;
}
