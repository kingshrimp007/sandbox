module routing_engine # (
    parameter VID_BITS = 6,
    parameter DEST_BITS = 4,
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    parameter NODES_XY = 4,
    localparam NUM_REQ = PORTS + CHANNELS
) (
    input logic                                         clk,
    input logic                                         rst,
    input logic                  [DEST_BITS/2 - 1: 0]   pos_x,
    input logic                  [DEST_BITS/2 - 1: 0]   pos_y,
    input logic  [NUM_REQ - 1: 0]                       rc_req,
    output logic [NUM_REQ - 1: 0]                       rc_gnt,
    input logic  [NUM_REQ - 1: 0][DEST_BITS - 1: 0]     g_dest,
    output logic [NUM_REQ - 1: 0][DEST_BITS - 1: 0]     g_route
);

localparam LFSR_BITS = 10;

// logic declaration
logic          [LFSR_BITS - 1: 0]  lfsr_x, lfsr_y;
logic                              psrb_x, psrb_y;
logic           [VID_BITS - 1: 0]  gnt_idx;
logic        [DEST_BITS/2 - 1: 0]  dest_x, dest_y;
logic        [DEST_BITS/2 - 1: 0]  m_x, m_y;
logic signed [DEST_BITS/2 - 1: 0]  del_x, del_y;
logic                              dir_x, dir_y;
logic                              exit_x, exit_y;

// psrb sequence generator
always_ff @ (posedge clk) begin
    psrb_x <= lfsr_x[LFSR_BITS - 1];
    psrb_y <= lfsr_y[LFSR_BITS - 1];
    if(rst) begin
        lfsr_x <= {1'b1, (LFSR_BITS - 1)'{1'b0}};
        lfsr_y <= {1'b1, (LFSR_BITS - 1)'{1'b0}};
    end
    else begin
        lfsr_x <= {lfsr_x[LFSR_BITS - 2: 0], lfsr_x[LFSR_BITS - 1] ^ lfsr_x[LFSR_BITS/2]};
        lfsr_y <= {lfsr_y[LFSR_BITS - 2: 0], lfsr_x[LFSR_BITS - 1] ^ lfsr_y[0]};
    end
end

// First-Come First-Serve arbitration
queueing_arb u_queueing_arb # (
    .VID_BITS (VID_BITS),
    .PORTS (PORTS),
    .CHANNELS (CHANNELS)
) (
    .clk     (clk),
    .rst     (rst),
    .req     (rc_req),
    .gnt     (rc_gnt),
    .gnt_idx (gnt_idx)
);

// granted input destination assignment
assign {dest_y, dest_x} = g_dest[gnt_idx];

// route computer
// calculate unsigned distance
always_comb begin
    m_x = dest_x - pos_x;
    m_y = dest_y - pos_y;
    if(m_x == 0)
        exit_x = 1'b1;
    else
        exit_x = 1'b0;
    if(m_y == 0)
        exit_y = 1'b1;
    else
        exit_y = 1'b0;
end

// calcuate direction vector
always_comb begin
    if(m_x > NODES_XY/2)
        del_x = m_x - NODES_XY;
    else
        del_x = m_x;
    if(m_y > NODES_XY/2)
        del_y = m_y - NODES_XY;
    else
        del_y = m_y;
end

// calculate normalized direction vector
always_comb begin
    if(del_x == -NODES_XY/2 || del_x == NODES_XY/2)
        dir_x = psrb_x;
    else
        dir_x = del_x[DEST_BITS/2 - 1];
    if(del_y == -NODES_XY/2 || del_y == NODES_XY/2)
        dir_y = psrb_y;
    else
        dir_y = del_y[DEST_BITS/2 - 1];  
end

// encode preferred routes
always_comb begin
    g_route = '0;
    if(!exit_x) begin
        g_route[gnt_idx][DEST_BITS/2 - 1: 0] = {dir_x, ~dir_x};
    end
    if(!exit_y) begin
        g_route[gnt_idx][DEST_BITS - 1: DEST_BITS/2] = {dir_y, ~dir_y};
    end
end


endmodule