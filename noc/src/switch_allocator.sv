module switch_allocator # (
    parameter VID_BITS = 6,
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic                                         clk,
    input logic                                         rst,
    input logic  [NUM_REQ - 1: 0][VID_BITS - 1: 0]      g_ovid,
    input logic  [NUM_REQ - 1: 0]                       sa_req,
    output logic [NUM_REQ - 1: 0]                       sa_gnt
);

logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0]  req;
logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0]  gnt;

// decode output vid to req[i] array
always_comb begin
    req = '0;
    for(int i = 0; i < NUM_REQ; i++)
        for(int j = 0; j < NUM_REQ; j++)
            req[i][j] = g_ovid[i] == j ? sa_req[i]: 1'b0; 
end


islip_allocator u_islip_allocator # (
    .PORTS (PORTS),
    .CHANNELS (CHANNELS)
) (
    .clk (clk),
    .rst (rst),
    .req (req),
    .gnt (gnt)
);


for(genvar i = 0; i < NUM_REQ; i++)
    assign sa_gnt[i] = |gnt[i];


endmodule