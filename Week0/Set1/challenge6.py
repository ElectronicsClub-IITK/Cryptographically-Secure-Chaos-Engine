# Challenge 6

import base64


def hamming_distance(a: bytes, b: bytes) -> int:
    if len(a) != len(b):
        raise ValueError("Inputs must have equal length")

    return sum(
        (x ^ y).bit_count()
        for x, y in zip(a, b)
    )


with open("chaosengine/6.txt") as f:
    ciphertext = base64.b64decode(f.read())


def normalized_distance(ciphertext, keysize):
    chunks = [
        ciphertext[i:i+keysize]
        for i in range(0, keysize * 8, keysize)
    ]

    pairs = zip(chunks, chunks[1:])

    distances = [
        hamming_distance(a, b) / keysize
        for a, b in pairs
    ]

    return sum(distances) / len(distances)


candidates = []

for keysize in range(2, 41):
    score = normalized_distance(ciphertext, keysize)
    candidates.append((score, keysize))

candidates.sort()

print(candidates[:5])


def transpose_blocks(ciphertext, keysize):
    blocks = [ciphertext[i:i+keysize]
              for i in range(0, len(ciphertext), keysize)]

    return [
        bytes(block[i]
              for block in blocks
              if i < len(block))
        for i in range(keysize)
    ]


FREQ = {
    'e': 12.7,
    't': 9.1,
    'a': 8.2,
    'o': 7.5,
    'i': 7.0,
    'n': 6.7,
    ' ': 13.0
}


def score(text):
    total = 0

    for b in text:
        c = chr(b).lower()

        if c in FREQ:
            total += FREQ[c]

        elif 32 <= b <= 126:
            total += 0

        else:
            total -= 20

    return total


def break_single_byte_xor(data):
    best_score = float('-inf')
    best_key = None

    for key in range(256):
        plaintext = bytes(b ^ key for b in data)

        s = score(plaintext)

        if s > best_score:
            best_score = s
            best_key = key

    return best_key


def recover_key(ciphertext, keysize):
    transposed = transpose_blocks(ciphertext, keysize)

    key = bytes(
        break_single_byte_xor(block)
        for block in transposed
    )

    return key


def repeating_key_xor(data, key):
    return bytes(
        b ^ key[i % len(key)]
        for i, b in enumerate(data)
    )


best_key = None
best_plaintext = None
best_score = float('-inf')

for _, keysize in candidates[:3]:

    key = recover_key(ciphertext, keysize)

    plaintext = repeating_key_xor(ciphertext, key)

    s = score(plaintext)

    if s > best_score:
        best_score = s
        best_key = key
        best_plaintext = plaintext

print("Key:", best_key.decode())
print(best_plaintext.decode())
