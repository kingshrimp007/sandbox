`timescale 1ns/100ps
`define PERIOD 10

module tb_switch_node_4rad ();

logic               clk;
logic [3:0][17:0]   in_ch;
logic [3:0][17:0]   out_ch;

localparam HDR_TYPE = 2'b11;
localparam PCK_TYPE = 2'b10;

localparam HEADER_O0 = {HDR_TYPE, 2'b00, 14'h0};
localparam HEADER_O1 = {HDR_TYPE, 2'b01, 14'h0};
localparam HEADER_02 = {HDR_TYPE, 2'b10, 14'h0};
localparam HEADER_03 = {HDR_TYPE, 2'b11, 14'h0};
localparam NULL_PCKT = 18'h0;

localparam WORD1 = 16'hDEAD;
localparam WORD2 = 16'hBEEF;
localparam WORD3 = 16'hDEFE;
localparam WORD4 = 16'hCA7E;
localparam WORD5 = 16'h8BAD;
localparam WORD6 = 16'hF00D;


switch_node_4rad DUT(
    .clk    ( clk       ),
    .in_ch  ( in_ch     ),
    .out_ch ( out_ch    )
);


always #PERIOD/2 clk = ~clk;



initial begin
    clk = 1'b1;
    @(negedge clk);
    in_ch = {{HEADER_O0}, NULL_PCKT, NULL_PCKT, NULL_PCKT};
    @(negedge clk);
    in_ch = {{PCK_TYPE, WORD1}, NULL_PCKT, NULL_PCKT, NULL_PCKT};
    @(negedge clk);
    in_ch = {NULL_PCKT, NULL_PCKT, NULL_PCKT, NULL_PCKT};

    @(negedge clk);

    @(negedge clk);

    @(negedge clk);

end

endmodule

// edaplayground version (generating a clock causes issues)
/*
`timescale 1ns/100ps
`define PERIOD 10

module tb_switch_node_4rad ();

logic               clk;
logic [3:0][17:0]   in_ch;
logic [3:0][17:0]   out_ch;

localparam HDR_TYPE = 2'b11;
localparam PCK_TYPE = 2'b10;

localparam HEADER_O0 = {HDR_TYPE, 2'b00, 14'h0};
localparam HEADER_O1 = {HDR_TYPE, 2'b01, 14'h0};
localparam HEADER_02 = {HDR_TYPE, 2'b10, 14'h0};
localparam HEADER_03 = {HDR_TYPE, 2'b11, 14'h0};
localparam NULL_PCKT = 18'h0;

localparam WORD1 = 16'hDEAD;
localparam WORD2 = 16'hBEEF;
localparam WORD3 = 16'hDEFE;
localparam WORD4 = 16'hCA7E;
localparam WORD5 = 16'h8BAD;
localparam WORD6 = 16'hF00D;


switch_node_4rad DUT(
    .clk    ( clk       ),
    .in_ch  ( in_ch     ),
    .out_ch ( out_ch    )
);


// always #PERIOD/2 clk = ~clk;


initial begin
  $dumpfile("dump.vcd");
  $dumpvars(1);
  $dumpvars(1, tb_switch_node_4rad.DUT);
  //$dumpvars(1, tb_switch_node_4rad.DUT.u_allocator);
    clk = 1'b1;
  	#5 clk = '0;
    in_ch = {{HEADER_O0}, NULL_PCKT, NULL_PCKT, NULL_PCKT};

    #5 clk = 1'b1;
  	#5 clk = '0;
  	in_ch = {{PCK_TYPE, WORD1}, NULL_PCKT, NULL_PCKT, NULL_PCKT};

    #5 clk = 1'b1;
  	#5 clk = '0;    
  	in_ch = {NULL_PCKT, NULL_PCKT, NULL_PCKT, NULL_PCKT};

    #5 clk = 1'b1;
  	#5 clk = '0;    


    #5 clk = 1'b1;
  	#5 clk = '0;    


    #5 clk = 1'b1;
  	#5 clk = '0;    

end

endmodule
*/