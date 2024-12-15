module l1_l2_xbar # (
    parameter integer PORTS = 64,
    parameter integer CHANNEL_WIDTH = 18
) (
    input logic     [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l1_out_ch,
    output logic    [PORTS - 1 : 0][CHANNEL_WIDTH - 1 : 0] l2_in_ch
);

// 4 sections, 4 nodes each
//  mapping
//   s1.node1 -  0, 16, 32, 48 
//   s1.node2 -  4, 20, 36, 52
//   s1.node3 -  8, 24, 40, 56
//   s1.node4 - 12, 28, 44, 60
//   s2.node1 -  1, 17, 33, 49
//   s2.node2 -  5, 21, 37, 53
//   s2.node3 -  9, 25, 41, 57
//   s2.node4 - 13, 29, 45, 61
// ...

// section 1-4 mapping
always_comb begin
    for(int k = 0; k < 4; k++) begin
        for(int i = 0; i < 4; i++) begin
            for(int j = 0; j < 4; j++) begin
                l2_in_ch[4*i + j + 16*k] = l1_out_ch[4*i + 16*j + k];
            end
        end
    end
end

// // section 2 mapping
// always_comb begin
//     for(int i = 0; i < 4; i++) begin
//         for(int j = 0; j < 4; j++) begin
//             l2_in_ch[4*i + j + 16] = l1_out_ch[4*i + 16*j + 1];
//         end
//     end
// end

// // section 3 mapping
// always_comb begin
//     for(int i = 0; i < 4; i++) begin
//         for(int j = 0; j < 4; j++) begin
//             l2_in_ch[4*i + j + 32] = l1_out_ch[4*i + 16*j + 2];
//         end
//     end
// end

// // section 4 mapping
// always_comb begin
//     for(int i = 0; i < 4; i++) begin
//         for(int j = 0; j < 4; j++) begin
//             l2_in_ch[4*i + j + 48] = l1_out_ch[4*i + 16*j + 3];
//         end
//     end
// end


endmodule