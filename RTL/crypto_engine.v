`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// crypto_engine.v
// Mode-selected wrapper around aes128_core / sha256_core.
//
// mode = 0 : AES-128, input_block[511:384]=key, input_block[383:256]=plaintext
//            result[255:128]=ciphertext, result[127:0]=0
// mode = 1 : SHA-256, input_block[511:0]=padded message block
//            result[255:0]=digest
//-----------------------------------------------------------------------------

module crypto_engine (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire         mode,
    input  wire [511:0] input_block,
    output reg  [255:0] result,
    output reg           done,
    output reg           busy
);

    wire         aes_start = start & ~mode;
    wire         sha_start = start &  mode;

    wire [127:0] aes_out;
    wire         aes_done, aes_busy;

    wire [255:0] sha_out;
    wire         sha_done, sha_busy;

    aes128_core u_aes (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (aes_start),
        .key      (input_block[511:384]),
        .data_in  (input_block[383:256]),
        .data_out (aes_out),
        .done     (aes_done),
        .busy     (aes_busy)
    );

    sha256_core u_sha (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (sha_start),
        .block_in (input_block),
        .hash     (sha_out),
        .done     (sha_done),
        .busy     (sha_busy)
    );

    always @(*) begin
        if (mode) begin
            done   = sha_done;
            busy   = sha_busy;
            result = sha_out;
        end else begin
            done   = aes_done;
            busy   = aes_busy;
            result = {aes_out, 128'h0};
        end
    end

endmodule
