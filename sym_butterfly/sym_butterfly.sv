// symmetrical butterfly switch using 3 layers of 16 4-radix switch nodes

module sym_butterfly # (
    parameter integer ports = 64,
    parameter integer channel_width = 18
) (
    input   logic                                               clk,
    input   logic       [ports - 1 : 0][channel_width - 1 : 0]  in_ch,
    output  logic       [ports - 1 : 0][channel_width - 1 : 0]  out_ch
);



endmodule