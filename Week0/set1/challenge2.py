def fixed_xor(buf1, buf2):
    if len(buf1) != len(buf2):
        raise ValueError("Buffers must have equal length")

    result = []

    for b1, b2 in zip(buf1, buf2):
        result.append(b1 ^ b2)

    return bytes(result)
hex1 = "1c0111001f010100061a024b53535009181c"
hex2 = "686974207468652062756c6c277320657965"

buf1 = bytes.fromhex(hex1)
buf2 = bytes.fromhex(hex2)

output = fixed_xor(buf1, buf2)

print(output.hex())