module input_unit # (
    parameter D_WIDTH = 32,
    parameter VID_BITS = 6,
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (

);


assign b_wr_en = vc_inbuf_din[31:26] == vid;

endmodule