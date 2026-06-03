
import base64
hex_input = input('Enter hex string here: ')


def hex_to_base64(hex_string):
    raw_bytes = bytes.fromhex(hex_string)
    base64_bytes = base64.b64encode(raw_bytes)
    return base64_bytes.decode('utf-8')


print(hex_to_base64(hex_input))
