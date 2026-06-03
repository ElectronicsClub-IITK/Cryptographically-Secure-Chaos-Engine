# Challenge 5
def repeating_key_xor(plaintext: bytes, key: bytes) -> bytes:
    return bytes(
        p ^ key[i % len(key)]
        for i, p in enumerate(plaintext)
    )


plaintext = (
    b"Burning 'em, if you ain't quick and nimble\n"
    b"I go crazy when I hear a cymbal"
)

key = b"ICE"

ciphertext = repeating_key_xor(plaintext, key)

print(ciphertext.hex())
