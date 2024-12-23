// very simple fixed priority arbitration based allocator
// corner case in which a single input port can constantly hold output port
//  and lead to other channels being starved

module allocator #(
    localparam integer PORTS = 4
) (
    input   logic                                           clk,
    input   logic                [$clog2(PORTS) - 1 : 0]    r_adr,
    input   logic [PORTS - 1 : 0]                [3 : 0]    in_ch_hdr_msn,
    input   logic [PORTS - 1 : 0]                           priority_field,
    output  logic [PORTS - 1 : 0]                           sel,
    output  logic                                           shift
);

// logic declarations
logic [PORTS - 1 : 0]   req;
logic [PORTS - 1 : 0]   priority_flag;
logic [PORTS - 1 : 0]   match;
logic [PORTS - 1 : 0]   gnt;
logic [PORTS - 1 : 0]   payload;
logic                   avail;
logic [PORTS - 1 : 0]   hold;
logic [PORTS - 1 : 0]   last;

// static declarations
localparam HEADER_TYPE = 2'b11;
localparam PAYLOAD_TYPE = 2'b10;
localparam NULL_TYPE = 2'b00;

// decoder logic
// any number of request or payload signals may be HI simultaneously
for(genvar i = 0; i < PORTS; i++) begin
    always_comb begin : decoder
        req[i] = '0;
        payload[i] = '0;
        match[i] = (in_ch_hdr_msn[i][1:0] == r_adr) ? 1'b1 : 1'b0;
        priority_flag[i] = {priority_field[i] == 1'b1} ? 1'b1 : 1'b0;

        if(in_ch_hdr_msn[i][3:2] == HEADER_TYPE)
            req[i] = match[i];
        else if(in_ch_hdr_msn[i][3:2] == PAYLOAD_TYPE)
            payload[i] = 1'b1;
    
    end
end

// fixed-priority arbiter
// only one bit of gnt vector may be HI at a time
always_comb begin : arbiter
    gnt[0] = req[0] & avail;
    for(int i = 1; i < PORTS; i++) begin
        gnt[i] = ~req[i - 1] & ~priority_flag[i - 1] & (req[i]);
    end
end

// hold logic
// holds output port for requesting input port for duration of packet
for(genvar i = 0; i < PORTS; i++) begin
    always_comb begin : mux_select
        hold[i] = last[i] & payload[i];
    end
end

assign avail = ~(|hold);

// synchronous logic
always_ff @ (posedge clk) begin
    last <= gnt;
end

// mux_select logic
for(genvar i = 0; i < PORTS; i++) begin
    always_comb begin : mux_select
        sel[i] = gnt[i] | hold[i] ? 1'b1 : 1'b0;
    end
end

assign shift = |gnt;


endmodule