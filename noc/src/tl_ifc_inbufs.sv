module tl_ifc_inbufs # (
    parameter D_WIDTH = 32,
    parameter VID_BITS = 6,
    parameter TYPE_BITS = 2,
    parameter CREDIT_BITS = 4,
    parameter DEST_BITS = 4,
    localparam HDR_NULL_BITS = D_WIDTH - VID_BITS - TYPE_BITS - CREDIT_BITS - DEST_BITS
) (
    input  logic                        clk,
    input  logic                        rst,
    input  logic    [VID_BITS - 1: 0]   vid,
    input  logic     [D_WIDTH - 1: 0]   vc_inbuf_din,
    output logic     [D_WIDTH - 1: 0]   vc_inbuf_dout,
    
    output logic                        rc_req,
    input  logic                        rc_gnt,
    output logic                        vc_req,
    input  logic                        vc_gnt,
    output logic                        sa_req,
    input  logic                        sa_gnt,

    input  logic                        b_wr_en,
    output logic                        b_full,

    output logic              [ 2: 0]   g_state,
    input  logic   [DEST_BITS - 1: 0]   g_route_i,
    output logic   [DEST_BITS - 1: 0]   g_route_o,
    input  logic    [VID_BITS - 1: 0]   g_ovid_i,
    output logic    [VID_BITS - 1: 0]   g_ovid_o,
    output logic [CREDIT_BITS - 1: 0]   g_credits
);

// parameter declarations
localparam  RC_BID = 3'b001,
            VC_BID = 3'b010,
            SA_BID = 3'b100;

localparam  T_HDR   = {VID_BITS'{1'b0}. 
                        2'b11, 
                        CREDIT_BITS'{1'b0},
                        DEST_BITS'{1'b0},
                        HDR_NULL_BITS'{1'b0}};
localparam  T_BODY  = {VID_BITS'{1'b0}. 
                        2'b10, 
                        CREDIT_BITS'{1'b0},
                        DEST_BITS'{1'b0},
                        HDR_NULL_BITS'{1'b0}};
localparam  T_TAIL  = {VID_BITS'{1'b0}. 
                        2'b01, 
                        CREDIT_BITS'{1'b0},
                        DEST_BITS'{1'b0},
                        HDR_NULL_BITS'{1'b0}};


// logic declarations
logic wr_en, rd_en;
logic full, empty;
logic [CREDIT_BITS - 1: 0] count;

// logic definition
assign rc_req = ~empty & g_state[0];
assign vc_req = ~empty & g_state[1];
assign sa_req = ~empty & g_state[2];

assign g_credits = count;

assign b_full = full;

assign rd_en = sa_gnt;

always_ff @ (posedge clk) begin
    if(rst)
        g_state <= RC_BID;
    else begin
        g_state <= g_state;
        case(g_state)
            RC_BID: begin
                if(rc_gnt)
                    g_state <= VC_BID;
            end
            VC_BID: begin
                if(vc_gnt)
                    g_state <= SA_BID;
            end
            SA_BID: begin
                if(sa_gnt && (vc_inbuf_dout & T_TAIL == T_TAIL))
                    g_state <= RC_BID;
            end
            default: begin
                g_state <= RC_BID;
            end
        endcase
    end
end

always_ff @ (posedge clk) begin
    if(rst)
        g_route_o <= '0;
    else
        g_route_o <= rc_gnt ? g_route_i : g_route_o;
end

always_ff @ (posedge clk) begin
    if(rst)
        g_ovid_o <= '0;
    else
        g_ovid_o <= vc_gnt ? g_ovid_i : g_ovid_o;
end


fifo vc_inbuf # (
    .D_WIDTH (D_WIDTH)
) (
    .clk (clk),
    .rst (rst),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .wr_data (vc_inbuf_din),
    .rd_data (vc_inbuf_dout),
    .full (full),
    .empty (empty),
    .count (count)
);


endmodule