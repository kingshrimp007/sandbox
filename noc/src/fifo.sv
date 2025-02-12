module fifo # (
    PARAMETER D_WIDTH = 16,
    PARAMETER DEPTH = 12
) (
    input logic                         clk,
    input logic                         rst,
    input logic                         wr_en,
    input logic                         rd_en,
    input logic     [D_WIDTH - 1: 0]    wr_data,
    output logic    [D_WIDTH - 1: 0]    rd_data,
    output logic                        full,
    output logic                        empty,
    output logic    [$clog2(DEPTH): 0]  count
);

// logic declarations
logic [D_WIDTH - 1: 0]          mem [DEPTH];
logic [$clog2(DEPTH) - 1: 0]    wr_ptr;
logic [$clog2(DEPTH) - 1: 0]    rd_ptr;

// process
always_ff @(posedge clk and posedge rst) begin
    if(rst) begin
        rd_data <= '0;
        full <= '0;
        empty <= '0;
        wr_ptr <= '0;
        rd_ptr <= '0;
        count <= '0;
    end
    else begin
        rd_data <= mem[rd_ptr];
        full <= (count == DEPTH);
        empty <= (count == 0);
        wr_ptr <= wr_en && !full ? wr_ptr + 1 : wr_ptr;
        rd_ptr <= rd_en && !empty ? rd_ptr + 1 : rd_ptr;

        // simultaneous write and read is legal, keep count
        count <= wr_en && !full && rd_en && !empty ? count :
                    wr_en && !full ? count + 1 :
                    rd_en && !empty ? count - 1 : count;

        // prevent overwrite
        if(wr_en && !full)
            mem[wr_ptr] <= wr_data;
    end
end


endmodule