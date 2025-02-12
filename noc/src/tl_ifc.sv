module tl_ifc # (
    parameter AXI_D_WIDTH = 24,
    parameter D_WIDTH = 32,
    parameter VID_BITS = 6,
    parameter TYPE_BITS = 2,
    parameter CREDIT_BITS = 4,
    parameter DEST_BITS = 4,
    parameter PORTS = 1,
    parameter CHANNELS = 12,
    parameter BUF_DEPTH = 12,
    localparam NUM_REQ = PORTS * CHANNELS,
    localparam TL_CREDITS = BUF_DEPTH * NUM_REQ
) (
    input logic                                        clk,
    input logic                                        rst,

    input logic                  [AXI_D_WIDTH - 1: 0]  in_tdata,
    input logic                                        in_tvalid,
    input logic                                        in_tlast,
    output logic                                       in_tready,
    input logic                    [DEST_BITS - 1: 0]  in_tuser,
    
    output logic                 [AXI_D_WIDTH - 1: 0]  out_tdata,
    output logic                                       out_tvalid,
    output logic                                       out_tlast,
    input logic                                        out_tready
    
    input logic  [NUM_REQ - 1: 0]   [VID_BITS - 1: 0]  vid,
    output logic [NUM_REQ - 1: 0]    [D_WIDTH - 1: 0]  vc_inbuf_dout,
         
    output logic [NUM_REQ - 1: 0]                      rc_req,
    input logic  [NUM_REQ - 1: 0]                      rc_gnt,
    output logic [NUM_REQ - 1: 0]                      vc_req,
    input logic  [NUM_REQ - 1: 0]                      vc_gnt,
    output logic [NUM_REQ - 1: 0]                      sa_req,
    input logic  [NUM_REQ - 1: 0]                      sa_gnt,
     
    output logic [NUM_REQ - 1: 0]             [ 2: 0]  g_state,
    input logic  [NUM_REQ - 1: 0]  [DEST_BITS - 1: 0]  g_route_i,
    output logic [NUM_REQ - 1: 0]  [DEST_BITS - 1: 0]  g_route_o,
    input logic  [NUM_REQ - 1: 0]   [VID_BITS - 1: 0]  g_ovid_i,
    output logic [NUM_REQ - 1: 0]   [VID_BITS - 1: 0]  g_ovid_o,
    output logic [NUM_REQ - 1: 0][CREDIT_BITS - 1: 0]  g_credits
);

// logic declarations
logic    [NUM_REQ - 1: 0][D_WIDTH - 1: 0]           vc_inbuf_din;
logic    [NUM_REQ - 1: 0]                           b_full;
logic    [NUM_REQ/2 - 1: 0][$clog2(NUM_REQ) - 1: 0] l1_result;
logic    [NUM_REQ/4 - 1: 0][$clog2(NUM_REQ) - 1: 0] l2_result;
logic                    [$clog2(NUM_REQ) - 1: 0]   l3_x, l3_result, iu_ptr;
logic                    [2*CREDIT_BITS - 1: 0]     total_credits;
logic                                               in_tsop;
logic                    [D_WIDTH - 1: 0]           inbuf_shift_in;

// input AXI stream tready
always_comb begin
    total_credits = g_credits[0] + g_credits[1] + g_credits[2] +
                    g_credits[3] + g_credits[4] + g_credits[5] +
                    g_credits[6] + g_credits[7] + g_credits[8] +
                    g_credits[9] + g_credits[] + g_credits[11];
    if(total_credits < TL_CREDITS && !b_full[iu_ptr])
        in_tready = 1'b1;
end

// comparator tree layer 1
for(genvar i = 0; i < NUM_REQ/2; i++)
    always_comb begin
        if(g_credits[i] > g_credits[2*i])
            l1_result[i] = g_credits[i];
        else
            l1_result[i] = g_credits[2*i];
    end

// comparator tree layer 2
for(genvar i = 0; i < NUM_REQ/4; i++)
    always_comb begin
        if(l1_result[i] > l1_result[2*i])
            l2_result[i] = l1_result[i];
        else
            l2_result[i] = l1_result[2*i];
    end

// comparator tree layer 3
always_comb begin
    if(l2_result[0] > l2_result[1])
        l3_x = l2_result[0];
    else
        l3_x = l2_result[1];
    if(l3_x > l2_result[2])
        l3_result = l3_x;
    else
        l3_result = l2_result[2];
end

// capture l3_result in iu_ptr on last packet flit
always_ff @ (posedge clk) begin
    if(rst)
        iu_ptr <= '0;
    else
        if(in_tlast && in_tready)
            iu_ptr <= l3_result;
        else
            iu_ptr <= iu_ptr;
end

// input AXI stream tdata
always_comb begin
    vc_inbuf_din = '0;
    vc_inbuf_din[iu_ptr] = {(D_WIDTH - AXI_D_WIDTH)'{1'b0}, in_tdata};
end

// in_tsop - 
always_ff @ (posedge clk) begin
    if(rst)
        in_tsop <= 1'b1;
    else
        in_tsop <= in_tsop;
        case(in_tsop)
            1'b0:
                if(in_tlast)
                    in_tsop <= 1'b1;
            1'b1:
                // single cycle payload, keep in_tsop HI
                if(in_tvalid && !in_tlast)
                    in_tsop <= 1'b0;
        endcase
end


for(genvar i = 0; i < NUM_REQ; i++) begin
    vc_inbufs # (
        .D_WIDTH (D_WIDTH),
        .VID_BITS (VID_BITS),
        .TYPE_BITS (TYPE_BITS),
        .CREDIT_BITS (CREDIT_BITS),
        .DEST_BITS (DEST_BITS)
    ) (
        .clk (clk),
        .rst (rst),
        .vid (vid),
        .vc_inbuf_din (vc_inbuf_din),
        .vc_inbuf_dout (vc_inbuf_dout),
        .rc_req (rc_req),
        .rc_gnt (rc_gnt),
        .vc_req (vc_req),
        .vc_gnt (vc_gnt),
        .sa_req (sa_req),
        .sa_gnt (sa_gnt),
        .b_full (b_full),
        .g_state (g_state),
        .g_route_i (g_route_i),
        .g_route_o (g_route_o),
        .g_ovid_i (g_ovid_i),
        .g_ovid_o (g_ovid_o),
        .g_credits (g_credits)
    );
end


endmodule