// symmetrical butterfly switch using 3 layers of 16 4-radix switch nodes

module sym_butterfly # (
    parameter integer PORTS = 64,
    parameter integer CHANNEL_WIDTH = 18
) (
    input   logic                                               clk,
    input   logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  in_ch,
    output  logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  out_ch
);

// layer 1 - 
switch_node_4rad u_switch_node_4rad(
    .clk    ( clk       ),
    .r_adr  ( r_adr     ),
    .in_ch  ( in_ch     ),
    .out_ch ( out_ch    )
);

endmodule