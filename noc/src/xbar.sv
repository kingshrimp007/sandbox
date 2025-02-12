// TODO evaluate if switch allocation and switch traversal can occur in the same cycle
// if timing is too critical, add pipeline stage here for inputs
module xbar # (
    parameter D_WIDTH = 32,
    parameter VID_BITS = 6,
    parameter PORTS = 5,
    paramater CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic     [NUM_REQ - 1: 0][VID_BITS - 1: 0]   g_ovid,
    input logic     [NUM_REQ - 1: 0]                    sa_gnt,
    input logic     [NUM_REQ - 1: 0][D_WIDTH - 1: 0]    vc_inbuf_dout,
    output logic    [NUM_REQ - 1: 0][D_WIDTH - 1: 0]    vc_outbuf_din
);

logic [NUM_REQ - 1: 0][NUM_REQ - 1: 0][D_WIDTH - 1: 0]  enc_out;
logic [NUM_REQ - 1: 0][D_WIDTH - 1: 0][NUM_REQ - 1: 0]  enc_out_t;

// priority encoders for each NUM_REQ input
for(genvar i = 0; i < NUM_REQ; i++) begin
    always_comb begin
        enc_out[i] = '0;
        for(int j = 0; j < NUM_REQ; j++) begin
            if(sa_gnt[i] && g_ovid[i] == j) begin
                enc_out[i][j] = {g_ovid[i], vc_inbuf_dout[i][D_WIDTH - VID_BITS - 1: 0]};
                break;
            end
        end
    end
end

// transpose inner 2 dimensions to prepare for bitwise OR
for(genvar i = 0; i < NUM_REQ; i++) begin
    always_comb begin
        for(int j = 0; j < NUM_REQ; j++)
            for(int k = 0; k < D_WIDTH; k++)
                enc_out_t[i][j][k] = enc_out[i][k][j];
    end
end

// bitwise OR'ing for all encoder outputs by each flit digit
for(genvar i = 0; i < NUM_REQ; i++) begin
    always_comb begin
        for(int j = 0; j < D_WIDTH; j++)
            vc_outbuf_din[i][j] = |enc_out_t[i][j];
    end
end


endmodule