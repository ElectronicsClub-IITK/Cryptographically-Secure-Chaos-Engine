`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// sha256_core.v
// SHA-256 compression, single 512-bit block (caller performs padding).
// 1 round per clock, 64 cycles total. Each round resolves 5 stages in
// the same cycle, registered together at the clock edge:
//   Stage 1 (schedule/"key" gen) : W[t] from the 16-word circular buffer
//   Stage 2                      : Sigma1(e), Ch(e,f,g)
//   Stage 3                      : Sigma0(a), Maj(a,b,c)
//   Stage 4                      : T1, T2 partial sums (balanced, not a
//                                   single 5-deep serial add chain)
//   Stage 5                      : a..h register update, Wbuf writeback
// The message schedule is generated one word per cycle from the
// circular buffer rather than unrolled across all 64 words, and the
// T1/T2 adds are arranged as two parallel partial sums instead of one
// long serial chain, to keep the per-cycle combinational depth down.
//-----------------------------------------------------------------------------

module sha256_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [511:0] block_in,
    output reg  [255:0] hash,
    output reg           done,
    output reg           busy
);

    localparam [31:0] H0c = 32'h6a09e667, H1c = 32'hbb67ae85,
                       H2c = 32'h3c6ef372, H3c = 32'ha54ff53a,
                       H4c = 32'h510e527f, H5c = 32'h9b05688c,
                       H6c = 32'h1f83d9ab, H7c = 32'h5be0cd19;

    reg [31:0] K [0:63];
    initial begin
        K[0]=32'h428a2f98; K[1]=32'h71374491; K[2]=32'hb5c0fbcf; K[3]=32'he9b5dba5;
        K[4]=32'h3956c25b; K[5]=32'h59f111f1; K[6]=32'h923f82a4; K[7]=32'hab1c5ed5;
        K[8]=32'hd807aa98; K[9]=32'h12835b01; K[10]=32'h243185be; K[11]=32'h550c7dc3;
        K[12]=32'h72be5d74; K[13]=32'h80deb1fe; K[14]=32'h9bdc06a7; K[15]=32'hc19bf174;
        K[16]=32'he49b69c1; K[17]=32'hefbe4786; K[18]=32'h0fc19dc6; K[19]=32'h240ca1cc;
        K[20]=32'h2de92c6f; K[21]=32'h4a7484aa; K[22]=32'h5cb0a9dc; K[23]=32'h76f988da;
        K[24]=32'h983e5152; K[25]=32'ha831c66d; K[26]=32'hb00327c8; K[27]=32'hbf597fc7;
        K[28]=32'hc6e00bf3; K[29]=32'hd5a79147; K[30]=32'h06ca6351; K[31]=32'h14292967;
        K[32]=32'h27b70a85; K[33]=32'h2e1b2138; K[34]=32'h4d2c6dfc; K[35]=32'h53380d13;
        K[36]=32'h650a7354; K[37]=32'h766a0abb; K[38]=32'h81c2c92e; K[39]=32'h92722c85;
        K[40]=32'ha2bfe8a1; K[41]=32'ha81a664b; K[42]=32'hc24b8b70; K[43]=32'hc76c51a3;
        K[44]=32'hd192e819; K[45]=32'hd6990624; K[46]=32'hf40e3585; K[47]=32'h106aa070;
        K[48]=32'h19a4c116; K[49]=32'h1e376c08; K[50]=32'h2748774c; K[51]=32'h34b0bcb5;
        K[52]=32'h391c0cb3; K[53]=32'h4ed8aa4a; K[54]=32'h5b9cca4f; K[55]=32'h682e6ff3;
        K[56]=32'h748f82ee; K[57]=32'h78a5636f; K[58]=32'h84c87814; K[59]=32'h8cc70208;
        K[60]=32'h90befffa; K[61]=32'ha4506ceb; K[62]=32'hbef9a3f7; K[63]=32'hc67178f2;
    end

    function [31:0] rotr;
        input [31:0] x;
        input integer n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    function [31:0] shr;
        input [31:0] x;
        input integer n;
        begin
            shr = x >> n;
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = rotr(x,7) ^ rotr(x,18) ^ shr(x,3);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = rotr(x,17) ^ rotr(x,19) ^ shr(x,10);
        end
    endfunction

    // ---------------------------------------------------------------
    // Stage 1 -- message schedule ("key gen") stage
    // 16-deep circular buffer, one new word produced per cycle. At
    // round t (t>=16), Wbuf[t mod 16] still holds W[t-16] (written 16
    // cycles earlier) right up until it is overwritten this cycle, so
    // the extension formula reads the old value and writes the new
    // one to the same slot in a single step. The two source pairs are
    // summed in parallel and combined last so the stage is 2 adds
    // deep rather than a 3-deep serial chain.
    // ---------------------------------------------------------------
    reg [31:0] Wbuf [0:15];

    localparam ST_IDLE = 2'd0, ST_ROUND = 2'd1, ST_DONE = 2'd2;

    reg [1:0]  state;
    reg [6:0]  t_cnt;
    reg [31:0] a,b,c,d,e,f,g,h;

    wire [3:0] idx_t   = t_cnt[3:0];
    wire [3:0] idx_t2  = t_cnt[3:0] + 4'd14; // (t-2)  mod 16
    wire [3:0] idx_t7  = t_cnt[3:0] + 4'd9;  // (t-7)  mod 16
    wire [3:0] idx_t15 = t_cnt[3:0] + 4'd1;  // (t-15) mod 16

    wire [31:0] w_pair_a = sigma1(Wbuf[idx_t2])  + Wbuf[idx_t7]; // parallel
    wire [31:0] w_pair_b = sigma0(Wbuf[idx_t15]) + Wbuf[idx_t];  // parallel
    wire [31:0] w_ext    = w_pair_a + w_pair_b;                  // combine
    wire [31:0] w_t      = (t_cnt < 7'd16) ? Wbuf[idx_t] : w_ext;

    // ---------------------------------------------------------------
    // Stage 2 -- Sigma1(e), Ch(e,f,g)
    // ---------------------------------------------------------------
    wire [31:0] Sigma1e = rotr(e,6) ^ rotr(e,11) ^ rotr(e,25);
    wire [31:0] Ch      = (e & f) ^ (~e & g);

    // ---------------------------------------------------------------
    // Stage 3 -- Sigma0(a), Maj(a,b,c)
    // ---------------------------------------------------------------
    wire [31:0] Sigma0a = rotr(a,2) ^ rotr(a,13) ^ rotr(a,22);
    wire [31:0] Maj     = (a & b) ^ (a & c) ^ (b & c);

    // ---------------------------------------------------------------
    // Stage 4 -- T1/T2, arranged as two parallel partial sums per
    // term (3 adds deep) instead of one 4-deep serial chain, then
    // combined with T2 for the new 'a'.
    // ---------------------------------------------------------------
    wire [31:0] t1_partial_a = h + Sigma1e;
    wire [31:0] t1_partial_b = Ch + K[t_cnt];
    wire [31:0] Tstep1       = t1_partial_a + t1_partial_b + w_t;
    wire [31:0] Tstep2       = Sigma0a + Maj;

    integer li;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            t_cnt <= 7'd0;
            {a,b,c,d,e,f,g,h} <= 256'd0;
            hash  <= 256'd0;
            done  <= 1'b0;
            busy  <= 1'b0;
            for (li = 0; li < 16; li = li + 1)
                Wbuf[li] <= 32'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a <= H0c; b <= H1c; c <= H2c; d <= H3c;
                        e <= H4c; f <= H5c; g <= H6c; h <= H7c;
                        for (li = 0; li < 16; li = li + 1)
                            Wbuf[li] <= block_in[511-32*li -: 32];
                        t_cnt <= 7'd0;
                        busy  <= 1'b1;
                        state <= ST_ROUND;
                    end
                end

                ST_ROUND: begin
                    // Stage 5 -- register update, all latched together
                    h <= g;
                    g <= f;
                    f <= e;
                    e <= d + Tstep1;
                    d <= c;
                    c <= b;
                    b <= a;
                    a <= Tstep1 + Tstep2;

                    if (t_cnt >= 7'd16)
                        Wbuf[idx_t] <= w_ext;

                    if (t_cnt == 7'd63)
                        state <= ST_DONE;
                    else
                        t_cnt <= t_cnt + 7'd1;
                end

                ST_DONE: begin
                    hash <= {H0c+a, H1c+b, H2c+c, H3c+d, H4c+e, H5c+f, H6c+g, H7c+h};
                    done <= 1'b1;
                    busy <= 1'b0;
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
