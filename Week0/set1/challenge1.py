import base64

hex_string = (
    "49276d206b696c6c696e6720796f757220627261696e206c696b65206120"
    "706f69736f6e6f7573206d757368726f6f6d"
)

# Convert hex to raw bytes
raw_bytes = bytes.fromhex(hex_string)

# Convert raw bytes to Base64
base64_string = base64.b64encode(raw_bytes).decode()

print(base64_string)