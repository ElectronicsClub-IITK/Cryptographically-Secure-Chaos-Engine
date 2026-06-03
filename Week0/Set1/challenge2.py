# Challenge 2

def fixed_xor(buf1: bytes, buf2: bytes) -> bytes:
    if len(buf1) != len(buf2):
        raise ValueError("Buffers must have equal length")

    return bytes(a ^ b for a, b in zip(buf1, buf2))


hex1 = "1c0111001f010100061a024b53535009181c"
hex2 = "686974207468652062756c6c277320657965"

buf1 = bytes.fromhex(hex1)
buf2 = bytes.fromhex(hex2)

result = fixed_xor(buf1, buf2)

print(result.hex())
