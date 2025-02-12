module islip_allocator # (
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic                                      clk,
    input logic                                      rst,
    input logic     [NUM_REQ - 1: 0][NUM_REQ - 1: 0] req,
    output logic    [NUM_REQ - 1: 0][NUM_REQ - 1: 0] gnt
);

logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0] l1_arb_out;
logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0] l2_arb_in;
logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0] l2_arb_out;


for(genvar i = 0; i < NUM_REQ; i++) begin
    matrix_arb l1_arb # (
        .PORTS (PORTS),
        .CHANNELS (CHANNELS)
    ) (
        .clk    (clk),
        .rst    (rst),
        .req    (req[i]),
        .gnt    (l1_arb_out[i]),
        .adj    (gnt[i])
    )
end


l1l2_transpose u_l1l2_transpose # (
    .PORTS (PORTS),
    .CHANNELS (CHANNELS)
) (
    .l1 (l1_arb_out),
    .l2 (l2_arb_in)
);


for(genvar i = 0; i < NUM_REQ; i++) begin
    matrix_arb l2_arb # (
        .PORTS (PORTS),
        .CHANNELS (CHANNELS)
    ) (
        .clk    (clk),
        .rst    (rst),
        .req    (l2_arb_in[i]),
        .gnt    (l2_arb_out[i]),
        .adj    (1'b1)
    )
end


l1l2_transpose gnt_transpose # (
    .PORTS (PORTS),
    .CHANNELS (CHANNELS)
) (
    .l1 (l2_arb_out),
    .l2 (gnt)
);


endmodule


module l1l2_transpose # (
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic     [NUM_REQ - 1: 0][NUM_REQ - 1: 0]    l1,
    output logic    [NUM_REQ - 1: 0][NUM_REQ - 1: 0]    l2
);

always_comb begin
    for(int i = 0; i < NUM_REQ; i++)
        for(int j = 0; j < NUM_REQ; j++)
            l2[j][i] = l1[i][j];
end


endmodule