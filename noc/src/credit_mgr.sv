module credit_mgr # (
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic                         clk,
    input logic                         rst,
    output logic    [NUM_REQ - 1: 0]    ovid_avail,
    
);


endmodule