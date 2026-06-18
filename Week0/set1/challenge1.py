  ##1
import base64

hex_string = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d"

raw_bytes = bytes.fromhex(hex_string)

base64_string = base64.b64encode(raw_bytes).decode('ascii')

print(base64_string)

##2
def fixed_xor(hex1, hex2):
   
    bytes1 = bytes.fromhex(hex1)
    bytes2 = bytes.fromhex(hex2)

    
    if len(bytes1) != len(bytes2):
        raise ValueError("Buffers must have equal length")
 result = bytes(b1 ^ b2 for b1, b2 in zip(bytes1, bytes2))
return result.hex()
s1 = "1c0111001f010100061a024b53535009181c"
s2 = "686974207468652062756c6c277320657965"

print(fixed_xor(s1, s2))

##3
def score_english(text):
    frequencies = {
        'e': 12.7, 't': 9.1, 'a': 8.2, 'o': 7.5,
        'i': 7.0, 'n': 6.7, ' ': 13.0,
        's': 6.3, 'h': 6.1, 'r': 6.0,
        'd': 4.3, 'l': 4.0, 'u': 2.8
    }

    score = 0

    for char in text.lower():
        score += frequencies.get(char, 0)

    return score


def single_byte_xor(ciphertext, key):
    return bytes(c ^ key for c in ciphertext)


def break_single_byte_xor(hex_string):
    ciphertext = bytes.fromhex(hex_string)

    best_score = float('-inf')
    best_key = None
    best_plaintext = None

    for key in range(256):
        plaintext_bytes = single_byte_xor(ciphertext, key)

        try:
            plaintext = plaintext_bytes.decode('ascii')
        except UnicodeDecodeError:
            continue

        score = score_english(plaintext)

        if score > best_score:
            best_score = score
            best_key = key
            best_plaintext = plaintext

    return best_key, best_plaintext, best_score


cipher = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736"

key, plaintext, score = break_single_byte_xor(cipher)

print("Key:", key)
print("Character:", chr(key))
print("Plaintext:", plaintext)
print("Score:", score)

##4
def score_english(text):
    freq = {
        'e': 12.7, 't': 9.1, 'a': 8.2, 'o': 7.5,
        'i': 7.0, 'n': 6.7, ' ': 13.0,
        's': 6.3, 'h': 6.1, 'r': 6.0,
        'd': 4.3, 'l': 4.0, 'u': 2.8
    }

    score = 0

    for c in text.lower():
        score += freq.get(c, 0)

    return score


def decrypt_single_byte_xor(hex_string):
    ciphertext = bytes.fromhex(hex_string)

    best_score = -1
    best_key = 0
    best_plaintext = ""

    for key in range(256):
        plaintext = bytes(b ^ key for b in ciphertext)

        try:
            text = plaintext.decode("ascii")
        except:
            continue

        score = score_english(text)

        if score > best_score:
            best_score = score
            best_key = key
            best_plaintext = text

    return best_score, best_key, best_plaintext


best_score = -1
best_key = 0
best_plaintext = ""

with open("4.txt") as f:
    for line in f:
        score, key, plaintext = decrypt_single_byte_xor(line.strip())

        if score > best_score:
            best_score = score
            best_key = key
            best_plaintext = plaintext

print("Key:", best_key)
print("Character:", chr(best_key))
print("Message:", best_plaintext)


##5
def repeating_key_xor(plaintext, key):
    plaintext = plaintext.encode()
    key = key.encode()

    ciphertext = bytes(
        plaintext[i] ^ key[i % len(key)]
        for i in range(len(plaintext))
    )

    return ciphertext.hex()


text = """Burning 'em, if you ain't quick and nimble
I go crazy when I hear a cymbal"""

key = "ICE"

result = repeating_key_xor(text, key)
print(result)


##7
from Cryptodome.Cipher import AES
import base64

key = b"YELLOW SUBMARINE"

with open("7.txt", "r") as f:
    ciphertext = base64.b64decode(f.read())

cipher = AES.new(key, AES.MODE_ECB)
plaintext = cipher.decrypt(ciphertext)

print(plaintext.decode())


##8
def count_repeated_blocks(hex_string, block_size=16):
    data = bytes.fromhex(hex_string)

    blocks = [
        data[i:i + block_size]
        for i in range(0, len(data), block_size)
    ]

    return len(blocks) - len(set(blocks))


best_line = None
max_repeats = 0

with open("8.txt") as f:
    for line_num, line in enumerate(f, start=1):
        line = line.strip()

        repeats = count_repeated_blocks(line)

        if repeats > max_repeats:
            max_repeats = repeats
            best_line = line
            best_line_num = line_num

print("Line Number:", best_line_num)
print("Repeated Blocks:", max_repeats)
print("Ciphertext:")
print(best_line)
