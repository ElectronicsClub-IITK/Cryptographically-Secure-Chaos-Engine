`timescale 1 ns / 1 ps
//-----------------------------------------------------------------------------
// crypto_ip_v1_0_S00_AXI.v
// AXI4-Lite slave, based on the Vivado "Create and Package IP" AXI4
// peripheral template, extended with the register map documented in
// docs/register_map.md.
//-----------------------------------------------------------------------------

module crypto_ip_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7
) (
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire [2:0]                        S_AXI_AWPROT,
    input  wire                              S_AXI_AWVALID,
    output wire                              S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output wire                              S_AXI_WREADY,
    output wire [1:0]                        S_AXI_BRESP,
    output wire                              S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire [2:0]                        S_AXI_ARPROT,
    input  wire                              S_AXI_ARVALID,
    output wire                              S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
    output wire [1:0]                        S_AXI_RRESP,
    output wire                              S_AXI_RVALID,
    input  wire                              S_AXI_RREADY
);

    // AXI4LITE signals
    reg  [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                            axi_awready;
    reg                            axi_wready;
    reg  [1:0]                     axi_bresp;
    reg                            axi_bvalid;
    reg  [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg                            axi_arready;
    reg  [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg  [1:0]                     axi_rresp;
    reg                            axi_rvalid;

    localparam integer ADDR_LSB       = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 4; // 32 registers -> 5 bit index

    // ---------------------------------------------------------------
    // Register file: index 0..31, word aligned
    //  0            : CTRL    [0]=START(pulse) [1]=MODE [2]=SOFT_RESET(pulse)
    //  1            : STATUS  [0]=DONE  [1]=BUSY   (read-only, live)
    //  2  .. 17     : INPUT_DATA0..15  (INPUT_DATA0 = MSB word)
    //  18 .. 25     : OUTPUT_DATA0..7  (read-only, live, OUTPUT_DATA0 = MSB word)
    //  26 .. 31     : reserved / scratch
    // ---------------------------------------------------------------
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg [0:31];
    integer li;

    wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    wire slv_reg_rden = axi_arready && S_AXI_ARVALID && ~axi_rvalid;

    wire [4:0] wr_index = axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
    wire [4:0] rd_index = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];

    // ---------------------------------------------------------------
    // Crypto engine instance
    // ---------------------------------------------------------------
    reg  start_pulse;
    reg  soft_reset_pulse;
    wire engine_rst_n = S_AXI_ARESETN & ~soft_reset_pulse;
    wire engine_done, engine_busy;
    wire [255:0] engine_result;
    wire engine_mode = slv_reg[0][1];

    wire [511:0] engine_input = {
        slv_reg[2],  slv_reg[3],  slv_reg[4],  slv_reg[5],
        slv_reg[6],  slv_reg[7],  slv_reg[8],  slv_reg[9],
        slv_reg[10], slv_reg[11], slv_reg[12], slv_reg[13],
        slv_reg[14], slv_reg[15], slv_reg[16], slv_reg[17]
    };

    crypto_engine u_engine (
        .clk         (S_AXI_ACLK),
        .rst_n       (engine_rst_n),
        .start       (start_pulse),
        .mode        (engine_mode),
        .input_block (engine_input),
        .result      (engine_result),
        .done        (engine_done),
        .busy        (engine_busy)
    );

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            start_pulse <= 1'b0;
        else if (slv_reg_wren && (wr_index == 5'd0) && S_AXI_WDATA[0] && S_AXI_WSTRB[0])
            start_pulse <= 1'b1;
        else
            start_pulse <= 1'b0;
    end

    // soft_reset_pulse holds engine_rst_n low for one cycle whenever
    // CTRL bit 2 is written as 1 -- lets software recover a stuck core
    // (e.g. FSM parked mid-round from a prior faulted run) without a
    // full board power cycle.
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            soft_reset_pulse <= 1'b0;
        else if (slv_reg_wren && (wr_index == 5'd0) && S_AXI_WDATA[2] && S_AXI_WSTRB[0])
            soft_reset_pulse <= 1'b1;
        else
            soft_reset_pulse <= 1'b0;
    end

    // ---------------------------------------------------------------
    // Write address channel
    // ---------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            axi_awaddr  <= 0;
        end else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
            axi_awready <= 1'b1;
            axi_awaddr  <= S_AXI_AWADDR;
        end else begin
            axi_awready <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // Write data channel
    // ---------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_wready <= 1'b0;
        else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
    end

    // ---------------------------------------------------------------
    // Register writes
    // ---------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            for (li = 0; li < 32; li = li + 1)
                slv_reg[li] <= 32'd0;
        end else if (slv_reg_wren) begin
            if (S_AXI_WSTRB[0]) slv_reg[wr_index][7:0]   <= S_AXI_WDATA[7:0];
            if (S_AXI_WSTRB[1]) slv_reg[wr_index][15:8]  <= S_AXI_WDATA[15:8];
            if (S_AXI_WSTRB[2]) slv_reg[wr_index][23:16] <= S_AXI_WDATA[23:16];
            if (S_AXI_WSTRB[3]) slv_reg[wr_index][31:24] <= S_AXI_WDATA[31:24];
        end
    end

    // ---------------------------------------------------------------
    // Write response channel
    // ---------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end else if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b00;
        end else if (S_AXI_BREADY && axi_bvalid) begin
            axi_bvalid <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // Read address channel
    // ---------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else if (~axi_arready && S_AXI_ARVALID) begin
            axi_arready <= 1'b1;
            axi_araddr  <= S_AXI_ARADDR;
        end else begin
            axi_arready <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // Read data channel
    // ---------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
        end else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b00;
        end else if (axi_rvalid && S_AXI_RREADY) begin
            axi_rvalid <= 1'b0;
        end
    end

    always @(*) begin
        if (rd_index == 5'd1) begin
            axi_rdata = {30'd0, engine_busy, engine_done};
        end else if (rd_index >= 5'd18 && rd_index <= 5'd25) begin
            case (rd_index)
                5'd18: axi_rdata = engine_result[255:224];
                5'd19: axi_rdata = engine_result[223:192];
                5'd20: axi_rdata = engine_result[191:160];
                5'd21: axi_rdata = engine_result[159:128];
                5'd22: axi_rdata = engine_result[127:96];
                5'd23: axi_rdata = engine_result[95:64];
                5'd24: axi_rdata = engine_result[63:32];
                5'd25: axi_rdata = engine_result[31:0];
                default: axi_rdata = 32'd0;
            endcase
        end else begin
            axi_rdata = slv_reg[rd_index];
        end
    end

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

endmodule
