module queueing_arb # (
    parameter VID_BITS = 6,
    parameter PORTS = 5,
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS,
    localparam ARRIVAL_INTERVAL = 1,
    localparam DEL_ARRIVAL_MAX = 2 * NUM_REQ * NUM_REQ,
    localparam TMR_WIDTH = $clog2(DEL_ARRIVAL_MAX / ARRIVAL_INTERVAL)
) (
    input logic                         clk,
    input logic                         rst,
    input logic     [NUM_REQ - 1: 0]    req,
    output logic    [NUM_REQ - 1: 0]    gnt,
    output logic    [VID_BITS - 1: 0]   gnt_idx
);

logic                   [TMR_WIDTH - 1: 0]              timer;
logic [NUM_REQ   - 1: 0][TMR_WIDTH + VID_BITS - 1: 0]  t_stamp;

logic [29: 0][TMR_WIDTH + VID_BITS - 1: 0]  l1_a, l1_b;
logic [29: 0][TMR_WIDTH + VID_BITS - 1: 0]  l1_result;  // down to 30
logic [14: 0][TMR_WIDTH + VID_BITS - 1: 0]  l2_a, l2_b;
logic [14: 0][TMR_WIDTH + VID_BITS - 1: 0]  l2_result;  // down to 15
logic [ 6: 0][TMR_WIDTH + VID_BITS - 1: 0]  l3_a, l3_b;
logic        [TMR_WIDTH + VID_BITS - 1: 0]  l3_c, l3_x;
logic [ 6: 0][TMR_WIDTH + VID_BITS - 1: 0]  l3_result;  // down to 7
logic [ 2: 0][TMR_WIDTH + VID_BITS - 1: 0]  l4_a, l4_b;
logic        [TMR_WIDTH + VID_BITS - 1: 0]  l4_c, l4_x;
logic [ 2: 0][TMR_WIDTH + VID_BITS - 1: 0]  l4_result;  // down to 3
logic        [TMR_WIDTH + VID_BITS - 1: 0]  l5_x;
logic                    [VID_BITS - 1: 0]  result_idx;


// take time stamp when req is set, offset idx by 1 to prevent false gnt on idx 0
for(genvar i = 0; i < NUM_REQ; i ++)
    always_ff @ (posedge clk) begin
        if(rst)
            t_stamp[i] <= '0;
        else begin
            if(gnt[i])
                t_stamp[i] <= '0;
            else if(req[i])
                t_stamp[i] <= {i[5:0] + 1, timer};
            else
                t_stamp[i] <= t_stamp[i];
        end            
    end

// layer 1 comparator tree
for(genvar i = 0; i < 30; i++)
    always_comb begin
        l1_result = '0;
        l1_a[i] = {t_stamp[2*i][TMR_WIDTH + VID_BITS - 1: TMR_WIDTH],     // index
                    // XNOR time stamp msb with timer msb
                    ~(t_stamp[2*i][TMR_WIDTH - 1] ^ timer[TMR_WIDTH - 1]), t_stamp[2*i][TMR_WIDTH - 2: 0]};
        l1_b[i] = {t_stamp[2*i + 1][TMR_WIDTH + VID_BITS - 1: TMR_WIDTH],     // index
                    // XNOR time stamp msb with timer msb
                    ~(t_stamp[2*i + 1][TMR_WIDTH - 1] ^ timer[TMR_WIDTH - 1]), t_stamp[2*i + 1][TMR_WIDTH - 2: 0]};
        if(l1_a[i] < l1_b[i])
            l1_result[i] = l1_a[i];
        else 
            l1_result[i] = l1_b[i];
    end

// layer 2 comparator tree
for(genvar i = 0; i < 15; i++)
    always_comb begin
        l2_result = '0;
        l2_a[i] = l1_result[2*i];
        l2_b[i] = l1_result[2*i + 1];
        if(l2_a[i] < l2_b[i])
            l2_result[i] = l2_a[i];
        else
            l2_result[i] = l2_b[i];
    end

// layer 3 comparator tree
for(genvar i = 0; i < 6; i++)
    always_comb begin
        l3_result = '0;
        l3_a[i] = l2_result[2*i];
        l3_b[i] = l2_result[2*i + 1];
        if(l3_a[i] < l3_b[i])
            l3_result[i] = l3_a[i];
        else
            l3_result[i] = l3_b[i];
    end

// layer 3 7th branch compares 3 inputs
always_comb begin
    l3_result[6] = '0;
    l3_a[6] = l2_result[12];
    l3_b[6] = l2_result[13];
    l3_c = l2_result[14];
    if(l3_a[6] < l3_b[6])
        l3_x = l3_a[6];
    else
        l3_x = l3_b[6];
    if(l3_x < l3_c)
        l3_result[6] = l3_x;
    else
        l3_result[6] = l3_c;      
end

// layer 4 comparator tree
for(genvar i = 0; i < 2; i++)
    always_comb begin
        l4_result = '0;
        l4_a[i] = l3_result[2*i];
        l4_b[i] = l3_result[2*i + 1];
        if(l4_a[i] < l4_b[i])
            l4_result[i] = l4_a[i];
        else
            l4_result[i] = l4_b[i];
    end

// layer 4 3rd branch compares 3 inputs
always_comb begin
    l4_result[2] = '0;
    l4_a[2] = l3_result[4];
    l4_b[2] = l3_result[5];
    l4_c = l3_result[6];
    if(l4_a[2] < l4_b[2])
        l4_x = l4_a[2];
    else
        l4_x = l4_b[2];
    if(l4_x < l4_c)
        l4_result[2] = l4_x;
    else
        l4_result[2] = l4_c;
end

// layer 5 compares 3 inputs
always_comb begin
    result_idx = '0;
    l5_x = '0;
    if(l4_result[0] < l4_result[1])
        l5_x = l4_result[0];
    else
        l5_x = l4_result[1];
    if(l5_x < l4_result[2])
        result_idx = l5_x[TMR_WIDTH + VID_BITS - 1: TMR_WIDTH];
    else
        result_idx = l4_result[2][TMR_WIDTH + VID_BITS - 1: TMR_WIDTH];
end

// gnt decoder
always_comb begin
    gnt = '0;
    gnt_idx = result_idx - 1;
    if(|result_idx)
        gnt[(result_idx - 1)] = 1'b1;
end


endmodule