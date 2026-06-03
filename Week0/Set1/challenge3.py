from string import printable

cipher_hex = "1b37373331363f78151b7f2b783431333d78397828372d36" \
             "3c78373e783a393b3736"

cipher = bytes.fromhex(cipher_hex)

# Approximate English letter frequencies
freq = {
    'e': 12.7, 't': 9.1, 'a': 8.2, 'o': 7.5,
    'i': 7.0, 'n': 6.7, ' ': 13.0
}


def score(text):
    s = 0

    for c in text.lower():
        s += freq.get(chr(c), 0)

    # Penalize non-printable characters
    for c in text:
        if chr(c) not in printable:
            s -= 50

    return s


best_score = float('-inf')
best_key = None
best_plaintext = None

for key in range(256):
    plaintext = bytes(b ^ key for b in cipher)

    current_score = score(plaintext)

    if current_score > best_score:
        best_score = current_score
        best_key = key
        best_plaintext = plaintext

print("Key:", best_key)
print("Character:", chr(best_key))
print("Plaintext:", best_plaintext.decode())
