`timescale 1ns / 1ps
module cache_tb();

localparam TOTAL_WORD_NUM       = %d;
localparam TOTAL_TEST_NUM       = %d;

// cache test
reg [31:0]  i_addr_rom   [TOTAL_TEST_NUM];
reg [31:0]  d_addr_rom   [TOTAL_TEST_NUM];
reg [31:0]  data_ram     [TOTAL_WORD_NUM];
reg [4:0]   mem_type_rom [TOTAL_TEST_NUM];
reg [31:0]  wdata_rom    [TOTAL_TEST_NUM];

reg clk = 1'b1, rstn = 1'b0;

initial #5 rstn = 1'b1; 
always #1 clk = ~clk;

// generate data_ram
initial begin
    for(integer i = 0; i < TOTAL_WORD_NUM; i++)begin
        data_ram[i] = i;
    end
end
initial begin
/* SPLIT */
end

wire [ 0:0] i_cache_miss, d_cache_miss;
wire [31:0] i_rdata, d_rdata;

wire [ 0:0] i_commit, d_commit;

/* icache simulation */
reg  [31:0] i_index_testing     = 0;
reg  [31:0] i_index_tested      = 0;
wire [31:0] i_rdata_ref         = data_ram[i_addr_rom[i_index_tested][$clog2(TOTAL_WORD_NUM)+1:2]];

wire [31:0] i_addr              = i_addr_rom[i_index_testing];
wire        i_rvalid            = 1'b1;

reg         i_is_error          = 0;
reg         i_is_pass           = 0;

// set i_index_tested
always @(posedge clk) begin
    if(i_commit && !(i_is_pass || i_is_error)) begin
        // check the result
        if(i_rdata != i_rdata_ref)begin
            i_is_error <= 1;
        end
        else begin
            if(i_index_tested == TOTAL_TEST_NUM - 1)begin
                i_is_pass <= 1;
            end
            else begin
                i_index_tested <= i_is_error ? i_index_tested : i_index_tested + 1;
            end
        end
    end
end

// set i_index_testing
always @(posedge clk) begin
    if(!i_cache_miss && !(i_is_pass || i_is_error)) begin
        i_index_testing <= i_index_testing + 1;
    end
end

/* dcache simulation */
reg  [31:0] d_index_testing     = 0;
reg  [31:0] d_index_tested      = 0;
wire [31:0] d_rdata_ref_temp    = data_ram[d_addr_rom[d_index_tested][$clog2(TOTAL_WORD_NUM)+1:2]] >> (d_addr_rom[d_index_tested][1:0] * 8);
reg  [31:0] d_rdata_ref         = d_rdata_ref_temp;
wire [ 4:0] d_mem_type_ref      = mem_type_rom[d_index_tested];
wire [31:0] d_wdata_ref         = wdata_rom[d_index_tested];

wire [31:0] d_addr              = d_addr_rom[d_index_testing];
wire [ 4:0] d_mem_type          = mem_type_rom[d_index_testing];
wire [31:0] d_wdata             = wdata_rom[d_index_testing];

reg         d_is_error          = 0;
reg         d_is_pass           = 0;

// generate d_rdata_ref
always @(*) begin
    case(d_mem_type_ref[2:0])
    3'b000: d_rdata_ref = {{24{d_rdata_ref_temp[7]}}, d_rdata_ref_temp[7:0]};
    3'b001: d_rdata_ref = {{16{d_rdata_ref_temp[15]}}, d_rdata_ref_temp[15:0]};
    endcase
end

// set d_index_tested
always @(posedge clk) begin
    if(d_commit && !(d_is_pass || d_is_error)) begin
        // check the result
        if(d_rdata != d_rdata_ref && d_mem_type_ref[3])begin
            d_is_error <= 1;
        end
        else begin
            if(d_index_tested == TOTAL_TEST_NUM - 1)begin
                d_is_pass <= 1;
            end
            else begin
                d_index_tested <= d_is_error ? d_index_tested : d_index_tested + 1;
            end
        end
    end
end

// set d_index_testing
always @(posedge clk) begin
    if(!d_cache_miss && !(d_is_pass || d_is_error)) begin
        d_index_testing <= d_index_testing + 1;
    end
end


// mem unit
Cache_Top  Cache_Top_inst (
    .clk                    (clk),
    .rstn                   (rstn),
    .i_addr                 (i_addr),
    .i_rvalid               (i_rvalid),
    .i_cache_miss           (i_cache_miss),
    .i_rdata                (i_rdata),
    .i_commit               (i_commit),        

    .d_addr                 (d_addr),
    .d_mem_type             (d_mem_type),
    .d_wdata_pipe           (d_wdata),
    .d_cache_miss           (d_cache_miss),
    .d_rdata                (d_rdata),
    .d_commit               (d_commit)
);
endmodule