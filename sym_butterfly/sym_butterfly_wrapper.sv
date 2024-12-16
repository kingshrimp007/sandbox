module sym_butterfly_wrapper #(
    parameter integer PORTS = 64,
    parameter integer CHANNEL_WIDTH = 18
) (
    input   logic                                         clk,
    input   logic [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  in_ch,
    output  logic [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  out_ch
);


sym_butterfly u_sym_butterfly (
    .clk    ( clk    ),
    .in_ch  ( in_ch  ),
    .out_ch ( out_ch )
);


endmodule