module matrix_arb # (
    parameter PORTS = 5.
    parameter CHANNELS = 12,
    localparam NUM_REQ = PORTS * CHANNELS
) (
    input logic                     clk,
    input logic                     rst,
    input logic    [NUM_REQ - 1: 0] req,
    output logic   [NUM_REQ - 1: 0] gnt,
    input logic    [NUM_REQ - 1: 0] adj,
);

// outer dimension is column, inner row
logic [NUM_REQ - 1 : 0][NUM_REQ - 1 : 0]    weight;
logic [NUM_REQ - 1 : 0]                     dis;


always_ff @ (posedge clk) begin
    if(rst) begin
        // through each column
        for(int i = 0; i < NUM_REQ; i++)
            // iterate by row
            for(int j = 0; j < NUM_REQ; j++)
                if(i >= j)
                    weight[i][j] <= 1'b1;
                else
                    weight[i][j] <= 1'b0;              
    end
    else begin
        // through each column
        for(int i = 0; i < NUM_REQ; i++)
            // iterate by row
            for(int j = 0; j < NUM_REQ; j++)
                // set by gnt[col{weight}], clear by gnt[row{weight}]
                if(i != j)
                    weight[i][j] <= gnt[j] & adj[j] ? 1'b1 : gnt[i] & adj[i] ? 1'b0 : weight[i][j];
    end
end


always_comb begin : disable
    for(int i = 0; i < NUM_REQ; i++)
        if(i == 0)
            dis[i] = |(weight[i][NUM_REQ - 1: 1] & req[NUM_REQ - 1: 1]);
        else if (i == NUM_REQ - 1)
            dis[i] = |(weight[i][NUM_REQ - 2: 0] & req[NUM_REQ - 2: 0]);
        else
            dis[i] = |({weight[i][NUM_REQ - 1: i + 1], weight[i][i - 1: 0]} 
                    & {req[NUM_REQ - 1: i + 1], req[i - 1: 0]});
end

assign gnt = req & !dis;


endmodule