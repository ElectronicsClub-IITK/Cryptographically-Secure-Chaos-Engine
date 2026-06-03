from math import gcd


def mod_inverse(a, m):
    for x in range(m):
        if (a * x) % m == 1:
            return x
    raise ValueError(f"No modular inverse exists for {a}")


def affine_encrypt(text, a, b):
    if gcd(a, 26) != 1:
        raise ValueError("a must be coprime with 26")

    result = []

    for char in text:
        if char.isalpha():
            base = ord('A') if char.isupper() else ord('a')
            x = ord(char) - base

            y = (a * x + b) % 26

            result.append(chr(y + base))
        else:
            result.append(char)

    return ''.join(result)


def affine_decrypt(ciphertext, a, b):
    if gcd(a, 26) != 1:
        raise ValueError("a must be coprime with 26")

    a_inv = mod_inverse(a, 26)

    result = []

    for char in ciphertext:
        if char.isalpha():
            base = ord('A') if char.isupper() else ord('a')
            y = ord(char) - base

            x = (a_inv * (y - b)) % 26

            result.append(chr(x + base))
        else:
            result.append(char)

    return ''.join(result)
