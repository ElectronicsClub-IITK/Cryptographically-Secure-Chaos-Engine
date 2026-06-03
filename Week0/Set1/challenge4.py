from string import printable

# English frequency table
freq = {
    'e': 12.7, 't': 9.1, 'a': 8.2, 'o': 7.5,
    'i': 7.0, 'n': 6.7, ' ': 13.0
}


def score(text):
    s = 0

    for c in text.lower():
        s += freq.get(chr(c), 0)

    # Penalize weird characters
    for c in text:
        if chr(c) not in printable:
            s -= 50

    return s


def crack_single_byte_xor(ciphertext):
    best_score = float('-inf')
    best_key = None
    best_plaintext = None

    for key in range(256):
        plaintext = bytes(b ^ key for b in ciphertext)

        current_score = score(plaintext)

        if current_score > best_score:
            best_score = current_score
            best_key = key
            best_plaintext = plaintext

    return best_score, best_key, best_plaintext


best_score = float('-inf')
best_line = None
best_key = None
best_plaintext = None

with open("chaosengine/4.txt") as f:
    for line in f:
        ciphertext = bytes.fromhex(line.strip())

        score_, key_, plaintext_ = crack_single_byte_xor(ciphertext)

        if score_ > best_score:
            best_score = score_
            best_line = line.strip()
            best_key = key_
            best_plaintext = plaintext_

print("Ciphertext:", best_line)
print("Key:", best_key, f"({chr(best_key)})")
print("Plaintext:", best_plaintext.decode())
