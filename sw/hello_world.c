/*
 * helloworld.c -- Cora Z7 Hardware/Software Co-Verification
 *
 * - Multi-block support for AES-128.
 * - Hardware vs Software cross-verification for every block.
 * - Compiles cleanly without xtime_l.h.
 */

#include "xil_io.h"
#include "xil_printf.h"
#include "xparameters.h"
#include <string.h>
#include <stdint.h>

// ============================================================================
// HARDWARE DEFINITIONS
// ============================================================================
#define CRYPTO_BASEADDR   XPAR_CRYPTO_IP_V1_0_0_BASEADDR

#define REG_CTRL          0x00
#define REG_STATUS        0x04
#define REG_INPUT(n)      (0x08 + 4*(n))   /* n = 0..15 */
#define REG_OUTPUT(n)     (0x48 + 4*(n))   /* n = 0..7  */

#define CTRL_START        (1 << 0)
#define CTRL_MODE_SHA256  (1 << 1)
#define CTRL_SOFT_RESET   (1 << 2)
#define STATUS_BUSY       (1 << 1)         

static inline void reg_write(u32 off, u32 val) { Xil_Out32(CRYPTO_BASEADDR + off, val); }
static inline u32  reg_read (u32 off)          { return Xil_In32(CRYPTO_BASEADDR + off); }


// ============================================================================
// FORWARD DECLARATIONS
// ============================================================================
static int get_line(char *buf, int maxlen);


// ============================================================================
// SOFTWARE CRYPTO IMPLEMENTATIONS (For Co-Verification)
// ============================================================================

/* --- AES-128 SOFTWARE --- */
static const uint8_t sbox[256] = {
  0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
  0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
  0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
  0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
  0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
  0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
  0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
  0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
  0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
  0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
  0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
  0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
  0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
  0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
  0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
  0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};
static const uint8_t rcon[11] = { 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36 };

static void sw_aes_encrypt_block(const uint8_t* key, const uint8_t* in, uint8_t* out) {
    uint8_t state[4][4], roundKey[176];
    int i, j, round;
    for (i = 0; i < 16; i++) roundKey[i] = key[i];
    for (i = 1; i < 11; i++) {
        uint8_t temp[4] = { roundKey[(i-1)*16+13], roundKey[(i-1)*16+14], roundKey[(i-1)*16+15], roundKey[(i-1)*16+12] };
        for (j = 0; j < 4; j++) temp[j] = sbox[temp[j]];
        temp[0] ^= rcon[i];
        for (j = 0; j < 4; j++) roundKey[i*16+j] = roundKey[(i-1)*16+j] ^ temp[j];
        for (j = 4; j < 16; j++) roundKey[i*16+j] = roundKey[(i-1)*16+j] ^ roundKey[i*16+j-4];
    }
    for (i = 0; i < 4; i++) for (j = 0; j < 4; j++) state[j][i] = in[i*4+j];
    for (i = 0; i < 4; i++) for (j = 0; j < 4; j++) state[i][j] ^= roundKey[j*4+i];
    for (round = 1; round <= 10; round++) {
        for (i = 0; i < 4; i++) for (j = 0; j < 4; j++) state[i][j] = sbox[state[i][j]];
        uint8_t temp;
        temp = state[1][0]; state[1][0] = state[1][1]; state[1][1] = state[1][2]; state[1][2] = state[1][3]; state[1][3] = temp;
        temp = state[2][0]; state[2][0] = state[2][2]; state[2][2] = temp; temp = state[2][1]; state[2][1] = state[2][3]; state[2][3] = temp;
        temp = state[3][3]; state[3][3] = state[3][2]; state[3][2] = state[3][1]; state[3][1] = state[3][0]; state[3][0] = temp;
        if (round < 10) {
            for (i = 0; i < 4; i++) {
                uint8_t a[4], b[4];
                for (j = 0; j < 4; j++) { a[j] = state[j][i]; b[j] = (state[j][i]<<1) ^ ((state[j][i]&0x80)?0x1b:0); }
                state[0][i] = b[0] ^ a[1] ^ b[1] ^ a[2] ^ a[3];
                state[1][i] = a[0] ^ b[1] ^ a[2] ^ b[2] ^ a[3];
                state[2][i] = a[0] ^ a[1] ^ b[2] ^ a[3] ^ b[3];
                state[3][i] = a[0] ^ b[0] ^ a[1] ^ a[2] ^ b[3];
            }
        }
        for (i = 0; i < 4; i++) for (j = 0; j < 4; j++) state[i][j] ^= roundKey[round*16 + j*4 + i];
    }
    for (i = 0; i < 4; i++) for (j = 0; j < 4; j++) out[i*4+j] = state[j][i];
}

/* --- SHA-256 SOFTWARE --- */
#define ROTRIGHT(word,bits) (((word) >> (bits)) | ((word) << (32-(bits))))
#define CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x) (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x) (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x) (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

static const uint32_t sha256_k[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static void sw_sha256_single_block(const uint8_t* msg, int len, uint32_t* digest) {
    uint8_t buf[64] = {0};
    uint32_t m[64];
    uint32_t state[8] = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 };
    int i;
    for (i = 0; i < len; i++) buf[i] = msg[i];
    buf[len] = 0x80;
    uint64_t bitlen = (uint64_t)len * 8;
    for (i = 0; i < 8; i++) buf[63 - i] = (uint8_t)(bitlen >> (i * 8));
    for (i = 0; i < 16; ++i) m[i] = (buf[i*4]<<24) | (buf[i*4+1]<<16) | (buf[i*4+2]<<8) | (buf[i*4+3]);
    for (i = 16; i < 64; ++i) m[i] = SIG1(m[i-2]) + m[i-7] + SIG0(m[i-15]) + m[i-16];
    uint32_t a = state[0], b = state[1], c = state[2], d = state[3], e = state[4], f = state[5], g = state[6], h = state[7];
    for (i = 0; i < 64; ++i) {
        uint32_t t1 = h + EP1(e) + CH(e,f,g) + sha256_k[i] + m[i];
        uint32_t t2 = EP0(a) + MAJ(a,b,c);
        h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
    }
    digest[0] = state[0] + a; digest[1] = state[1] + b; digest[2] = state[2] + c; digest[3] = state[3] + d;
    digest[4] = state[4] + e; digest[5] = state[5] + f; digest[6] = state[6] + g; digest[7] = state[7] + h;
}


// ============================================================================
// HARDWARE WRAPPERS
// ============================================================================
static void crypto_soft_reset(void) { reg_write(REG_CTRL, CTRL_SOFT_RESET); }

static int run_and_wait_hw(int mode_sha256) {
    u32 timeout = 1000000;
    reg_write(REG_CTRL, CTRL_START | (mode_sha256 ? CTRL_MODE_SHA256 : 0));
    while ((reg_read(REG_STATUS) & STATUS_BUSY) != 0) {
        if (--timeout == 0) {
            xil_printf("\r\nTIMEOUT waiting for BUSY. STATUS=%08x -- soft reset\r\n", reg_read(REG_STATUS));
            crypto_soft_reset();
            return -1;
        }
    }
    return 0;
}

static void bytes_to_words_be(const u8 *bytes, int nbytes, u32 *words, int nwords) {
    int i;
    for (i = 0; i < nwords; i++) {
        int off = i * 4;
        words[i] = ((u32)bytes[off]<<24) | ((u32)bytes[off+1]<<16) | ((u32)bytes[off+2]<<8) | ((u32)bytes[off+3]);
    }
    (void)nbytes; // Suppress unused parameter warning
}


// ============================================================================
// CO-VERIFICATION FUNCTIONS
// ============================================================================

static void verify_aes128_multiblock(const char *text, int len) {
    char key_text[64];
    u8  key_block[16] = {0};
    u32 key_words[4];
    u8  key_bytes[16];
    int i, key_len, block_idx;
    
    // 1. Prompt for Key
    xil_printf("Enter 16-character key: ");
    key_len = get_line(key_text, sizeof(key_text));
    
    if (key_len > 16) key_len = 16;
    for (i = 0; i < key_len; i++) key_block[i] = (u8)key_text[i];
    bytes_to_words_be(key_block, 16, key_words, 4);

    for (i = 0; i < 4; i++) {
        key_bytes[i*4]   = key_words[i]>>24; 
        key_bytes[i*4+1] = key_words[i]>>16;
        key_bytes[i*4+2] = key_words[i]>>8;  
        key_bytes[i*4+3] = key_words[i];
    }

    int num_blocks = (len + 15) / 16; 
    if (num_blocks == 0) num_blocks = 1;

    xil_printf("\r\n\r\n-- AES-128 Multi-Block Co-Verification --\r\n");
    xil_printf("Processing %d blocks (%d bytes total)\r\n", num_blocks, len);
    xil_printf("Key Used (hex) : ");
    for(i=0; i<16; i++) xil_printf("%02x", key_bytes[i]);
    xil_printf("\r\n");

    // Write the key to hardware once
    for (i = 0; i < 4; i++) reg_write(REG_INPUT(i), key_words[i]);

    // 2. Loop through blocks
    for (block_idx = 0; block_idx < num_blocks; block_idx++) {
        u8  block[16] = {0};
        u32 pt_words[4];
        u8  hw_out[16];
        u8  sw_out[16];

        // Extract 16 bytes for this specific block (zero pad if short)
        int offset = block_idx * 16;
        for (i = 0; i < 16; i++) {
            if ((offset + i) < len) block[i] = (u8)text[offset + i];
            else block[i] = 0x00;
        }
        bytes_to_words_be(block, 16, pt_words, 4);

        xil_printf("\r\n[Block %02d]\r\n", block_idx);
        xil_printf("  Text (hex) : ");
        for(i=0; i<16; i++) xil_printf("%02x", block[i]);
        xil_printf("\r\n");

        // Run Hardware
        for (i = 0; i < 4; i++) reg_write(REG_INPUT(4+i), pt_words[i]);
        if (run_and_wait_hw(0) != 0) return;
        
        for (i = 0; i < 4; i++) {
            u32 w = reg_read(REG_OUTPUT(i));
            hw_out[i*4] = w>>24; hw_out[i*4+1] = w>>16; hw_out[i*4+2] = w>>8; hw_out[i*4+3] = w;
        }

        // Run Software
        sw_aes_encrypt_block(key_bytes, block, sw_out);

        // Compare
        xil_printf("  HW Result  : ");
        for(i=0; i<16; i++) xil_printf("%02x", hw_out[i]);
        xil_printf("\r\n  SW Result  : ");
        for(i=0; i<16; i++) xil_printf("%02x", sw_out[i]);
        
        if (memcmp(hw_out, sw_out, 16) == 0) {
            xil_printf("\r\n  -> MATCH!\r\n");
        } else {
            xil_printf("\r\n  -> ERROR: Mismatch detected.\r\n");
        }
    }
}

static void verify_sha256(const char *text, int len) {
    u8  buf[64] = {0};
    u32 block[16];
    u32 sw_digest[8];
    u32 hw_digest[8];
    int i;

    // Pad / truncate input for HW
    if (len > 55) len = 55;
    for(i=0; i<len; i++) buf[i] = text[i];
    buf[len] = 0x80;
    u64 bitlen = (u64)len * 8;
    for (i = 0; i < 8; i++) buf[63 - i] = (u8)(bitlen >> (8 * i));
    bytes_to_words_be(buf, 64, block, 16);

    xil_printf("\r\n\r\n-- SHA-256 Co-Verification --\r\n");
    xil_printf("Text Length: %d bytes\r\n", len);

    // 1. RUN HARDWARE
    for (i = 0; i < 16; i++) reg_write(REG_INPUT(i), block[i]);
    if (run_and_wait_hw(1) != 0) return;
    for (i = 0; i < 8; i++) hw_digest[i] = reg_read(REG_OUTPUT(i));

    // 2. RUN SOFTWARE
    sw_sha256_single_block((const u8*)text, len, sw_digest);

    // 3. COMPARE & PRINT
    xil_printf("HW Result: ");
    for(i=0; i<8; i++) xil_printf("%08x", hw_digest[i]);
    xil_printf("\r\nSW Result: ");
    for(i=0; i<8; i++) xil_printf("%08x", sw_digest[i]);
    
    if (memcmp(hw_digest, sw_digest, 32) == 0) {
        xil_printf("\r\n-> MATCH!\r\n");
    } else {
        xil_printf("\r\n-> ERROR: Mismatch detected.\r\n");
    }
}


// ============================================================================
// MAIN LOOP
// ============================================================================
static int get_line(char *buf, int maxlen) {
    int n = 0; char c;
    while (n < maxlen - 1) {
        c = inbyte();
        if (c == '\r' || c == '\n') { xil_printf("\r\n"); break; }
        if ((c == 8 || c == 127) && n > 0) { n--; xil_printf("\b \b"); continue; }
        if (c < 32 || c > 126) continue;
        buf[n++] = c;
        xil_printf("%c", c);
    }
    buf[n] = '\0';
    return n;
}

int main(void) {
    char mode_c;
    char text[256]; /* Buffer for longer text */
    int  len;

    xil_printf("\r\n==========================================\r\n");
    xil_printf("  Crypto IP Hardware/Software Testing\r\n");
    xil_printf("==========================================\r\n");

    while (1) {
        xil_printf("\r\nSelect mode:\r\n");
        xil_printf("  0 = AES-128 (Multi-Block Support)\r\n");
        xil_printf("  1 = SHA-256 (Single Block Limit)\r\n");
        xil_printf("Choice: ");
        
        mode_c = inbyte();
        if (mode_c == '\r' || mode_c == '\n') continue;
        xil_printf("%c\r\n", mode_c);

        if (mode_c != '0' && mode_c != '1') {
            xil_printf("Invalid selection\r\n");
            continue;
        }

        xil_printf("Enter text: ");
        len = get_line(text, sizeof(text));

        if (mode_c == '0')
            verify_aes128_multiblock(text, len);
        else
            verify_sha256(text, len);
    }

    return 0;
}
