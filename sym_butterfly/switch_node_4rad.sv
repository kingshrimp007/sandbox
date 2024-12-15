// design overview
// 1st stage register inputs
// 2nd stage allocator and mux
// 3rd stage shifter
// 4th stage output register

module switch_node_4rad # (
    localparam integer PORTS = 4,
    parameter integer CHANNEL_WIDTH = 18
) (
    input   logic                                               clk,
    input   logic                      [$clog2(PORTS) - 1 : 0]  r_adr,
    input   logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  in_ch,
    output  logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  out_ch
);

// ---------------------------------
// logic declarations
// ---------------------------------
logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  in_ch_flops;
logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  out_ch_flops;

logic       [PORTS - 1 : 0]                [3 : 0]  in_ch_hdr_msn;
logic       [PORTS - 1 : 0]        [PORTS - 1 : 0]  sel;
logic       [PORTS - 1 : 0]                         shift;

logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  mux_dout;
logic       [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0]  shift_dout;

// tap header most significant nibble (type and route)
for(genvar i = 0; i < PORTS; i++) begin
    assign in_ch_hdr_msn[i] = in_ch_flops[i][17:14];
end

// allocator instantiation
for(genvar i = 0; i < PORTS; i++) begin
    allocator u_allocator (
        .clk            ( clk           ),
        .r_adr          ( r_adr         ),                         
        .in_ch_hdr_msn  ( in_ch_hdr_msn ),     
        .sel            ( sel[i]        ),
        .shift          ( shift[i]      )
    );
end

// mux logic
for(genvar i = 0; i < PORTS; i++) begin
    always_comb begin : mux_dout_n
        case(sel[i])
            4'b0001 : mux_dout[i] = in_ch_flops[0];
            4'b0010 : mux_dout[i] = in_ch_flops[1];
            4'b0100 : mux_dout[i] = in_ch_flops[2];
            4'b1000 : mux_dout[i] = in_ch_flops[3];
            default : mux_dout[i] = '0;
        endcase
    end
end


// shifter logic
assign shift_dout[0] = shift[0] ? {mux_dout[0][17:16], mux_dout[0][13:10], mux_dout[0][15:14], mux_dout[0][9:0]}
                                : mux_dout[0];
assign shift_dout[1] = shift[1] ? {mux_dout[1][17:16], mux_dout[1][13:10], mux_dout[1][15:14], mux_dout[1][9:0]}
                                : mux_dout[1];
assign shift_dout[2] = shift[2] ? {mux_dout[2][17:16], mux_dout[2][13:10], mux_dout[2][15:14], mux_dout[2][9:0]}
                                : mux_dout[2];
assign shift_dout[3] = shift[3] ? {mux_dout[3][17:16], mux_dout[3][13:10], mux_dout[3][15:14], mux_dout[3][9:0]}
                                : mux_dout[3];


// synchronous logic
always_ff @ (posedge clk) begin
    in_ch_flops <= in_ch;
    out_ch_flops <= shift_dout;
end

assign out_ch = out_ch_flops;


endmodule