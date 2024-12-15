module l2_l3_xbar # (
    parameter integer PORTS = 64,
    parameter integer CHANNEL_WIDTH = 18
) (
    input logic     [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l2_out_ch,
    output logic    [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l3_in_ch
);

// 4 sections, 4 nodes each
//  mapping
//   s1.node1 -  0,  4,  8, 12
//   s1.node2 -  1,  5,  9, 13
//   s1.node3 -  2,  6, 10, 14
//   s1.node4 -  3,  7, 11, 15

// section 1-4 mapping
always_comb begin
    for(int k = 0; k < 4; k++) begin
        for(int i = 0; i < 4; i++) begin
            for(int j = 0; j < 4; j++) begin
                l3_in_ch[4*i + j + 16*k] = l2_out_ch[4*j + i + 16*k];
            end
        end
    end
end

// // section 2 mapping
// always_comb begin
//     for(int i = 0; i < 4; i++) begin
//         for(int j = 0; j < 4; j++) begin
//             l3_in_ch[4*i + j + 16] = l2_out_ch[4*j + i + 16];
//         end
//     end
// end

// // section 3 mapping
// always_comb begin
//     for(int i = 0; i < 4; i++) begin
//         for(int j = 0; j < 4; j++) begin
//             l3_in_ch[4*i + j + 32] = l2_out_ch[4*j + i + 32];
//         end
//     end
// end

// // section 4 mapping
// always_comb begin
//     for(int i = 0; i < 4; i++) begin
//         for(int j = 0; j < 4; j++) begin
//             l3_in_ch[4*i + j + 48] = l2_out_ch[4*j + i + 48];
//         end
//     end
// end

endmodule