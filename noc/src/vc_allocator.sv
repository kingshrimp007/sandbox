module vc_allocator # (
    parameter VID_BITS = 6,
    parameter DEST_BITS = 4,
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic                                         clk,
    input logic                                         rst,
    input logic  [NUM_REQ - 1: 0][$clog2(PORTS) - 1: 0] g_route,
    input logic  [NUM_REQ - 1: 0]                       vc_req,
    output logic [NUM_REQ - 1: 0]                       vc_gnt,
    input logic  [NUM_REQ - 1: 0]                       ovid_avail,
    output logic [NUM_REQ - 1: 0][VID_BITS - 1: 0]      g_ovid
);

localparam N_EAST = 0,
            N_NORTH = 1,
            N_WEST = 2,
            N_SOUTH = 3,
            N_EXIT = 4;

logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0]  req_x, req;
logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0]  gnt;


// request all channels mapped to assigned route
always_comb begin
    req_x = '0;
    for(int i = 0; i < NUM_REQ; i++)
        if(g_route[i] == '0)
            req_x[i][(N_EXIT + 1)*CHANNELS - 1: N_EXIT*CHANNELS] = vc_req[i] & {CHANNELS'{1'b1}};
        else begin
            // x-preferred-direction
            case(g_route[i][DEST_BITS/2 - 1: 0])
                2'b01:
                    req_x[i][(N_EAST + 1)*CHANNELS - 1: N_EAST*CHANNELS] = vc_req[i] & {CHANNELS'{1'b1}};
                2'b10:
                    req_x[i][(N_WEST + 1)*CHANNELS - 1: N_WEST*CHANNELS] = vc_req[i] & {CHANNELS'{1'b1}};
            endcase
            // y-preferred-direction
            case(g_route[i][DEST_BITS - 1: DEST_BITS/2])
                2'b01:
                    req_x[i][(N_NORTH + 1)*CHANNELS - 1: N_NORTH*CHANNELS] = vc_req[i] & {CHANNELS'{1'b1}};
                2'b10:
                    req_x[i][(N_SOUTH + 1)*CHANNELS - 1: N_SOUTH*CHANNELS] = vc_req[i] & {CHANNELS'{1'b1}};
            endcase
        end
end

// mask request with output VID availability
always_comb begin
    for(int i = 0; i < NUM_REQ; i++)
        for(int j = 0; j < NUM_REQ; j++)
            req[i][j] = req_x[i][j] & ovid_avail[j];
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
    assign vc_gnt[i] = |gnt[i];


// priority encoder for each requester
for(genvar i = 0; i < NUM_REQ; i++) begin
    always_comb begin
        g_ovid[i] = '0;
        for(int j = 0; j < NUM_REQ; j++)
            if(gnt[i][j] == 1'b1) begin
                g_ovid[i] = j;
                break;
            end
    end
end


endmodule