`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// aes128_core.v
// AES-128 ECB encryption, single block, iterative (1 round per clock,
// 12 cycles total). Each round is 5 combinational stages resolved in
// one clock: (1) next round key, (2) SubBytes, (3) ShiftRows,
// (4) MixColumns, (5) AddRoundKey -- registered together at the clock
// edge. The key schedule is derived one round key per cycle from the
// previous round key, not unrolled across all 11 keys up front, to
// keep the per-cycle combinational depth (and Fmax) reasonable.
//-----------------------------------------------------------------------------

module aes128_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] key,
    input  wire [127:0] data_in,
    output reg  [127:0] data_out,
    output reg           done,
    output reg           busy
);

    // ---------------------------------------------------------------
    // S-box (256 x 8)
    // ---------------------------------------------------------------
    reg [7:0] SBOX [0:255];
    initial begin
        SBOX[8'h00]=8'h63; SBOX[8'h01]=8'h7c; SBOX[8'h02]=8'h77; SBOX[8'h03]=8'h7b; SBOX[8'h04]=8'hf2; SBOX[8'h05]=8'h6b; SBOX[8'h06]=8'h6f; SBOX[8'h07]=8'hc5;
        SBOX[8'h08]=8'h30; SBOX[8'h09]=8'h01; SBOX[8'h0a]=8'h67; SBOX[8'h0b]=8'h2b; SBOX[8'h0c]=8'hfe; SBOX[8'h0d]=8'hd7; SBOX[8'h0e]=8'hab; SBOX[8'h0f]=8'h76;
        SBOX[8'h10]=8'hca; SBOX[8'h11]=8'h82; SBOX[8'h12]=8'hc9; SBOX[8'h13]=8'h7d; SBOX[8'h14]=8'hfa; SBOX[8'h15]=8'h59; SBOX[8'h16]=8'h47; SBOX[8'h17]=8'hf0;
        SBOX[8'h18]=8'had; SBOX[8'h19]=8'hd4; SBOX[8'h1a]=8'ha2; SBOX[8'h1b]=8'haf; SBOX[8'h1c]=8'h9c; SBOX[8'h1d]=8'ha4; SBOX[8'h1e]=8'h72; SBOX[8'h1f]=8'hc0;
        SBOX[8'h20]=8'hb7; SBOX[8'h21]=8'hfd; SBOX[8'h22]=8'h93; SBOX[8'h23]=8'h26; SBOX[8'h24]=8'h36; SBOX[8'h25]=8'h3f; SBOX[8'h26]=8'hf7; SBOX[8'h27]=8'hcc;
        SBOX[8'h28]=8'h34; SBOX[8'h29]=8'ha5; SBOX[8'h2a]=8'he5; SBOX[8'h2b]=8'hf1; SBOX[8'h2c]=8'h71; SBOX[8'h2d]=8'hd8; SBOX[8'h2e]=8'h31; SBOX[8'h2f]=8'h15;
        SBOX[8'h30]=8'h04; SBOX[8'h31]=8'hc7; SBOX[8'h32]=8'h23; SBOX[8'h33]=8'hc3; SBOX[8'h34]=8'h18; SBOX[8'h35]=8'h96; SBOX[8'h36]=8'h05; SBOX[8'h37]=8'h9a;
        SBOX[8'h38]=8'h07; SBOX[8'h39]=8'h12; SBOX[8'h3a]=8'h80; SBOX[8'h3b]=8'he2; SBOX[8'h3c]=8'heb; SBOX[8'h3d]=8'h27; SBOX[8'h3e]=8'hb2; SBOX[8'h3f]=8'h75;
        SBOX[8'h40]=8'h09; SBOX[8'h41]=8'h83; SBOX[8'h42]=8'h2c; SBOX[8'h43]=8'h1a; SBOX[8'h44]=8'h1b; SBOX[8'h45]=8'h6e; SBOX[8'h46]=8'h5a; SBOX[8'h47]=8'ha0;
        SBOX[8'h48]=8'h52; SBOX[8'h49]=8'h3b; SBOX[8'h4a]=8'hd6; SBOX[8'h4b]=8'hb3; SBOX[8'h4c]=8'h29; SBOX[8'h4d]=8'he3; SBOX[8'h4e]=8'h2f; SBOX[8'h4f]=8'h84;
        SBOX[8'h50]=8'h53; SBOX[8'h51]=8'hd1; SBOX[8'h52]=8'h00; SBOX[8'h53]=8'hed; SBOX[8'h54]=8'h20; SBOX[8'h55]=8'hfc; SBOX[8'h56]=8'hb1; SBOX[8'h57]=8'h5b;
        SBOX[8'h58]=8'h6a; SBOX[8'h59]=8'hcb; SBOX[8'h5a]=8'hbe; SBOX[8'h5b]=8'h39; SBOX[8'h5c]=8'h4a; SBOX[8'h5d]=8'h4c; SBOX[8'h5e]=8'h58; SBOX[8'h5f]=8'hcf;
        SBOX[8'h60]=8'hd0; SBOX[8'h61]=8'hef; SBOX[8'h62]=8'haa; SBOX[8'h63]=8'hfb; SBOX[8'h64]=8'h43; SBOX[8'h65]=8'h4d; SBOX[8'h66]=8'h33; SBOX[8'h67]=8'h85;
        SBOX[8'h68]=8'h45; SBOX[8'h69]=8'hf9; SBOX[8'h6a]=8'h02; SBOX[8'h6b]=8'h7f; SBOX[8'h6c]=8'h50; SBOX[8'h6d]=8'h3c; SBOX[8'h6e]=8'h9f; SBOX[8'h6f]=8'ha8;
        SBOX[8'h70]=8'h51; SBOX[8'h71]=8'ha3; SBOX[8'h72]=8'h40; SBOX[8'h73]=8'h8f; SBOX[8'h74]=8'h92; SBOX[8'h75]=8'h9d; SBOX[8'h76]=8'h38; SBOX[8'h77]=8'hf5;
        SBOX[8'h78]=8'hbc; SBOX[8'h79]=8'hb6; SBOX[8'h7a]=8'hda; SBOX[8'h7b]=8'h21; SBOX[8'h7c]=8'h10; SBOX[8'h7d]=8'hff; SBOX[8'h7e]=8'hf3; SBOX[8'h7f]=8'hd2;
        SBOX[8'h80]=8'hcd; SBOX[8'h81]=8'h0c; SBOX[8'h82]=8'h13; SBOX[8'h83]=8'hec; SBOX[8'h84]=8'h5f; SBOX[8'h85]=8'h97; SBOX[8'h86]=8'h44; SBOX[8'h87]=8'h17;
        SBOX[8'h88]=8'hc4; SBOX[8'h89]=8'ha7; SBOX[8'h8a]=8'h7e; SBOX[8'h8b]=8'h3d; SBOX[8'h8c]=8'h64; SBOX[8'h8d]=8'h5d; SBOX[8'h8e]=8'h19; SBOX[8'h8f]=8'h73;
        SBOX[8'h90]=8'h60; SBOX[8'h91]=8'h81; SBOX[8'h92]=8'h4f; SBOX[8'h93]=8'hdc; SBOX[8'h94]=8'h22; SBOX[8'h95]=8'h2a; SBOX[8'h96]=8'h90; SBOX[8'h97]=8'h88;
        SBOX[8'h98]=8'h46; SBOX[8'h99]=8'hee; SBOX[8'h9a]=8'hb8; SBOX[8'h9b]=8'h14; SBOX[8'h9c]=8'hde; SBOX[8'h9d]=8'h5e; SBOX[8'h9e]=8'h0b; SBOX[8'h9f]=8'hdb;
        SBOX[8'ha0]=8'he0; SBOX[8'ha1]=8'h32; SBOX[8'ha2]=8'h3a; SBOX[8'ha3]=8'h0a; SBOX[8'ha4]=8'h49; SBOX[8'ha5]=8'h06; SBOX[8'ha6]=8'h24; SBOX[8'ha7]=8'h5c;
        SBOX[8'ha8]=8'hc2; SBOX[8'ha9]=8'hd3; SBOX[8'haa]=8'hac; SBOX[8'hab]=8'h62; SBOX[8'hac]=8'h91; SBOX[8'had]=8'h95; SBOX[8'hae]=8'he4; SBOX[8'haf]=8'h79;
        SBOX[8'hb0]=8'he7; SBOX[8'hb1]=8'hc8; SBOX[8'hb2]=8'h37; SBOX[8'hb3]=8'h6d; SBOX[8'hb4]=8'h8d; SBOX[8'hb5]=8'hd5; SBOX[8'hb6]=8'h4e; SBOX[8'hb7]=8'ha9;
        SBOX[8'hb8]=8'h6c; SBOX[8'hb9]=8'h56; SBOX[8'hba]=8'hf4; SBOX[8'hbb]=8'hea; SBOX[8'hbc]=8'h65; SBOX[8'hbd]=8'h7a; SBOX[8'hbe]=8'hae; SBOX[8'hbf]=8'h08;
        SBOX[8'hc0]=8'hba; SBOX[8'hc1]=8'h78; SBOX[8'hc2]=8'h25; SBOX[8'hc3]=8'h2e; SBOX[8'hc4]=8'h1c; SBOX[8'hc5]=8'ha6; SBOX[8'hc6]=8'hb4; SBOX[8'hc7]=8'hc6;
        SBOX[8'hc8]=8'he8; SBOX[8'hc9]=8'hdd; SBOX[8'hca]=8'h74; SBOX[8'hcb]=8'h1f; SBOX[8'hcc]=8'h4b; SBOX[8'hcd]=8'hbd; SBOX[8'hce]=8'h8b; SBOX[8'hcf]=8'h8a;
        SBOX[8'hd0]=8'h70; SBOX[8'hd1]=8'h3e; SBOX[8'hd2]=8'hb5; SBOX[8'hd3]=8'h66; SBOX[8'hd4]=8'h48; SBOX[8'hd5]=8'h03; SBOX[8'hd6]=8'hf6; SBOX[8'hd7]=8'h0e;
        SBOX[8'hd8]=8'h61; SBOX[8'hd9]=8'h35; SBOX[8'hda]=8'h57; SBOX[8'hdb]=8'hb9; SBOX[8'hdc]=8'h86; SBOX[8'hdd]=8'hc1; SBOX[8'hde]=8'h1d; SBOX[8'hdf]=8'h9e;
        SBOX[8'he0]=8'he1; SBOX[8'he1]=8'hf8; SBOX[8'he2]=8'h98; SBOX[8'he3]=8'h11; SBOX[8'he4]=8'h69; SBOX[8'he5]=8'hd9; SBOX[8'he6]=8'h8e; SBOX[8'he7]=8'h94;
        SBOX[8'he8]=8'h9b; SBOX[8'he9]=8'h1e; SBOX[8'hea]=8'h87; SBOX[8'heb]=8'he9; SBOX[8'hec]=8'hce; SBOX[8'hed]=8'h55; SBOX[8'hee]=8'h28; SBOX[8'hef]=8'hdf;
        SBOX[8'hf0]=8'h8c; SBOX[8'hf1]=8'ha1; SBOX[8'hf2]=8'h89; SBOX[8'hf3]=8'h0d; SBOX[8'hf4]=8'hbf; SBOX[8'hf5]=8'he6; SBOX[8'hf6]=8'h42; SBOX[8'hf7]=8'h68;
        SBOX[8'hf8]=8'h41; SBOX[8'hf9]=8'h99; SBOX[8'hfa]=8'h2d; SBOX[8'hfb]=8'h0f; SBOX[8'hfc]=8'hb0; SBOX[8'hfd]=8'h54; SBOX[8'hfe]=8'hbb; SBOX[8'hff]=8'h16;
    end

    function [7:0] get_rcon;
        input integer n;
        begin
            case (n)
                1:  get_rcon = 8'h01;
                2:  get_rcon = 8'h02;
                3:  get_rcon = 8'h04;
                4:  get_rcon = 8'h08;
                5:  get_rcon = 8'h10;
                6:  get_rcon = 8'h20;
                7:  get_rcon = 8'h40;
                8:  get_rcon = 8'h80;
                9:  get_rcon = 8'h1b;
                10: get_rcon = 8'h36;
                default: get_rcon = 8'h00;
            endcase
        end
    endfunction

    // ---------------------------------------------------------------
    // Key schedule -- generated one round key per cycle (pipeline
    // stage 1 of the round), not unrolled across all 11 round keys.
    // round_key_reg holds RK[r-1] on entry to round r; next_round_key
    // is RK[r], derived combinationally from round_key_reg and
    // consumed by AddRoundKey the same cycle, then latched for the
    // next round's derivation. This keeps the SubWord/Rcon chain to
    // a single stage per clock instead of a 10-deep unrolled chain.
    // ---------------------------------------------------------------
    reg [127:0] round_key_reg;

    wire [31:0] rk_w0 = round_key_reg[127:96];
    wire [31:0] rk_w1 = round_key_reg[95:64];
    wire [31:0] rk_w2 = round_key_reg[63:32];
    wire [31:0] rk_w3 = round_key_reg[31:0];

    wire [31:0] rk_rotword = {rk_w3[23:0], rk_w3[31:24]};
    wire [31:0] rk_subword = {SBOX[rk_rotword[31:24]], SBOX[rk_rotword[23:16]],
                                SBOX[rk_rotword[15:8]],  SBOX[rk_rotword[7:0]]};
    wire [31:0] rk_rconw   = {get_rcon(round_cnt), 24'h0};

    wire [31:0] nk_w0 = rk_w0 ^ rk_subword ^ rk_rconw;
    wire [31:0] nk_w1 = nk_w0 ^ rk_w1;
    wire [31:0] nk_w2 = nk_w1 ^ rk_w2;
    wire [31:0] nk_w3 = nk_w2 ^ rk_w3;

    wire [127:0] next_round_key = {nk_w0, nk_w1, nk_w2, nk_w3};

    // ---------------------------------------------------------------
    // Byte-level transforms
    // ---------------------------------------------------------------
    function [7:0] getb;
        input [127:0] v;
        input integer idx;
        begin
            getb = v[127-8*idx -: 8];
        end
    endfunction

    function [127:0] sub_bytes;
        input [127:0] s;
        integer k;
        reg [127:0] res;
        begin
            for (k = 0; k < 16; k = k + 1)
                res[127-8*k -: 8] = SBOX[s[127-8*k -: 8]];
            sub_bytes = res;
        end
    endfunction

    function [127:0] shift_rows;
        input [127:0] s;
        reg [7:0] b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15;
        begin
            b0=getb(s,0);   b1=getb(s,1);   b2=getb(s,2);   b3=getb(s,3);
            b4=getb(s,4);   b5=getb(s,5);   b6=getb(s,6);   b7=getb(s,7);
            b8=getb(s,8);   b9=getb(s,9);   b10=getb(s,10); b11=getb(s,11);
            b12=getb(s,12); b13=getb(s,13); b14=getb(s,14); b15=getb(s,15);
            shift_rows = {b0,b5,b10,b15, b4,b9,b14,b3, b8,b13,b2,b7, b12,b1,b6,b11};
        end
    endfunction

    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = {a[6:0], 1'b0} ^ (a[7] ? 8'h1b : 8'h00);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] a;
        begin
            mul3 = xtime(a) ^ a;
        end
    endfunction

    function [127:0] mix_columns;
        input [127:0] s;
        reg [7:0] b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15;
        reg [7:0] o0,o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15;
        begin
            b0=getb(s,0);   b1=getb(s,1);   b2=getb(s,2);   b3=getb(s,3);
            b4=getb(s,4);   b5=getb(s,5);   b6=getb(s,6);   b7=getb(s,7);
            b8=getb(s,8);   b9=getb(s,9);   b10=getb(s,10); b11=getb(s,11);
            b12=getb(s,12); b13=getb(s,13); b14=getb(s,14); b15=getb(s,15);

            o0  = xtime(b0)^mul3(b1)^b2^b3;
            o1  = b0^xtime(b1)^mul3(b2)^b3;
            o2  = b0^b1^xtime(b2)^mul3(b3);
            o3  = mul3(b0)^b1^b2^xtime(b3);

            o4  = xtime(b4)^mul3(b5)^b6^b7;
            o5  = b4^xtime(b5)^mul3(b6)^b7;
            o6  = b4^b5^xtime(b6)^mul3(b7);
            o7  = mul3(b4)^b5^b6^xtime(b7);

            o8  = xtime(b8)^mul3(b9)^b10^b11;
            o9  = b8^xtime(b9)^mul3(b10)^b11;
            o10 = b8^b9^xtime(b10)^mul3(b11);
            o11 = mul3(b8)^b9^b10^xtime(b11);

            o12 = xtime(b12)^mul3(b13)^b14^b15;
            o13 = b12^xtime(b13)^mul3(b14)^b15;
            o14 = b12^b13^xtime(b14)^mul3(b15);
            o15 = mul3(b12)^b13^b14^xtime(b15);

            mix_columns = {o0,o1,o2,o3, o4,o5,o6,o7, o8,o9,o10,o11, o12,o13,o14,o15};
        end
    endfunction

    // ---------------------------------------------------------------
    // Round FSM
    // ---------------------------------------------------------------
    localparam ST_IDLE = 2'd0, ST_ROUND = 2'd1, ST_DONE = 2'd2;

    reg [1:0]   state;
    reg [3:0]   round_cnt;
    reg [127:0] cur_state;

    // round_cnt indicates which round key next_round_key currently
    // represents (Rcon index), so it must be valid before round_key_reg
    // is read combinationally above -- declared here, used above by name.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            round_cnt     <= 4'd0;
            cur_state     <= 128'd0;
            round_key_reg <= 128'd0;
            data_out      <= 128'd0;
            done          <= 1'b0;
            busy          <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // RK0 = original key, consumed directly (no SubWord needed)
                        round_key_reg <= key;
                        cur_state     <= data_in ^ key;
                        round_cnt     <= 4'd1;
                        busy          <= 1'b1;
                        state         <= ST_ROUND;
                    end
                end

                ST_ROUND: begin
                    // Stage 1 (key gen)      : next_round_key = RK[round_cnt]
                    // Stage 2 (SubBytes)      : sub_bytes(cur_state)
                    // Stage 3 (ShiftRows)     : shift_rows(...)
                    // Stage 4 (MixColumns)    : mix_columns(...)   -- skipped on final round
                    // Stage 5 (AddRoundKey)   : ^ next_round_key, registered below
                    if (round_cnt < 4'd10) begin
                        cur_state     <= mix_columns(shift_rows(sub_bytes(cur_state))) ^ next_round_key;
                        round_key_reg <= next_round_key;
                        round_cnt     <= round_cnt + 4'd1;
                    end else begin
                        cur_state <= shift_rows(sub_bytes(cur_state)) ^ next_round_key;
                        state     <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    data_out <= cur_state;
                    done     <= 1'b1;
                    busy     <= 1'b0;
                    state    <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
