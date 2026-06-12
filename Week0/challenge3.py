ciphertext = bytes.fromhex("1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736")

# Approximate English letter frequency table (lowercase)
freq = {
    'a': 8.2, 'b': 1.5, 'c': 2.8, 'd': 4.3, 'e': 12.7, 'f': 2.2, 'g': 2.0,
    'h': 6.1, 'i': 7.0, 'j': 0.15, 'k': 0.77, 'l': 4.0, 'm': 2.4, 'n': 6.7,
    'o': 7.5, 'p': 1.9, 'q': 0.095, 'r': 6.0, 's': 6.3, 't': 9.1, 'u': 2.8,
    'v': 0.98, 'w': 2.4, 'x': 0.15, 'y': 2.0, 'z': 0.074, ' ': 13.0
}

def score(text):
    return sum(freq.get(chr(b).lower(), 0) for b in text)

best_score = -1
best_key = None
best_plain = None

for key in range(256):
    plain = bytes(b ^ key for b in ciphertext)
    s = score(plain)
    if s > best_score:
        best_score = s
        best_key = key
        best_plain = plain

print(f"Key: {best_key} ('{chr(best_key)}')")
print(f"Plaintext: {best_plain.decode()}")