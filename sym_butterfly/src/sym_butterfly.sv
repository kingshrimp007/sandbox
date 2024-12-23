// symmetrical butterfly switch using 3 layers of 16 4-radix switch nodes

`define LAYERS 3
`define RADIX 4
`define NODES 16

module sym_butterfly # (
    parameter integer PORTS = 64,
    parameter integer CHANNEL_WIDTH = 18
) (
    input   logic                                               clk,
    input   logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  in_ch,
    output  logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  out_ch
);


logic [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l1_out_ch;
logic [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l2_in_ch;
logic [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l2_out_ch;
logic [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l3_in_ch;


// layer 1
for(genvar i = 0; i < NODES; i++) begin
    switch_node_4rad u_switch_node_4rad(
        .clk    ( clk           ),
        .in_ch  ( in_ch[4*i + 3 : 4*i]      ),
        .out_ch ( l1_out_ch[4*i +3 : 4*i]   )
    );
end


l1_l2_xbar u_l1_l2_xbar (
    .l1_out_ch ( l1_out_ch ),
    .l2_in_ch  ( l2_in_ch  )
);


// layer 2
for(genvar i = 0; i < NODES; i++) begin
    switch_node_4rad u_switch_node_4rad(
        .clk    ( clk           ),
        .in_ch  ( l2_in_ch[4*i + 3 : 4*i]   ),
        .out_ch ( l2_out_ch[4*i + 3 : 4*i]  )
    );
end


l2_l3_xbar u_l2_l3_xbar (
    .l2_out_ch ( l2_out_ch ),
    .l3_in_ch  ( l3_in_ch  )
);


// layer 3
for(genvar i = 0; i < NODES; i++) begin
    switch_node_4rad u_switch_node_4rad(
        .clk    ( clk           ),
        .in_ch  ( l3_in_ch[4*i + 3 : 4*i]   ),
        .out_ch ( out_ch[4*i + 3 : 4*i]     )
    );
end


endmodule