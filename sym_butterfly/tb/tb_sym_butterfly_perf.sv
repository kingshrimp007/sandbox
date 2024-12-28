// constrained random performance analysis
// varies duty cycle, source port, dest port
// traffic shall be sent continuously
// in order to achieve duty cycle variance,
//  lambda = 1 represents all inputs generating traffic
//  lambda = .5 represents 32 inputs generating traffic
//  lambda = 0 represents no inputs generating traffic
// avg latency as a function of offered traffic is computed as p-0/p-3
// load network with desired duty cycle for 24 cycles at each rate
// allow traffic to flush out with waiting period of 50 cycles
// monitors traffic to see which packets dropped on output and resends

class automatic randPckt;
  randc logic [1:0] dest_1;
  randc logic [1:0] dest_2;
  randc logic [1:0] dest_3;
  randc logic [15:0] word;
  randc logic coin_flip;
endclass


module tb_sym_butterfly_perf ();

localparam HDR_TYPE = 2'b11;
localparam PCK_TYPE = 2'b10;
// localparam HEADER_O0 = {HDR_TYPE, 2'b00, 14'h0};
// localparam HEADER_O1 = {HDR_TYPE, 2'b01, 14'h0};
// localparam HEADER_02 = {HDR_TYPE, 2'b10, 14'h0};
// localparam HEADER_03 = {HDR_TYPE, 2'b11, 14'h0};


logic                clk;
logic [63:0][17:0]   in_ch;
logic [63:0][17:0]   out_ch;

typedef struct packed {
  logic [1:0] p_type;
  logic [5:0] d_adr;
  logic [9:0] null_field;
} s_packet;

// queue of associative arrays
s_packet q_net_traffic [$][int];

int tx_cnt, rx_cnt, dropped_cnt;
real duty_cycle;
randPckt random_packet = new;

sym_butterfly_wrapper DUT (
    .clk    ( clk    ),
    .in_ch  ( in_ch  ),
    .out_ch ( out_ch )
);

initial begin 
  clk = 1'b1;
  in_ch = '0;
  tx_cnt = 0;
  rx_cnt = 0;
  duty_cycle = 0;
end

always #5 clk = ~clk;


task tick(input int count);
  for(int i = 0; i < count; i++)
    @(negedge clk);
endtask


// send header wtih randomized dest adr
task automatic sendhdr(input int s_port, output logic [17:0] pckt);
  random_packet.randomize();
  pckt = {HDR_TYPE, random_packet.dest_1, random_packet.dest_2, random_packet.dest_3, 10'h0};
  in_ch[s_port] = pckt;
endtask

// send traffic at requested duty cycle
//  divides ports into groups based on the duty cycle
//  sends 1 pckt per div_group based on coin flip
task tx_traffic(input real duty_cycle_in);
  // inititalize local s_pckt_arr associative array
  s_packet loc_s_pckt_arr[int];
  logic div_group_done = '0;
  int div_group = 0;
  div_group = 1 / duty_cycle_in;
  for(int i = 0; i < 64 / div_group; i++) begin
    // flip the coin
    random_packet.randomize();
    div_group_done = random_packet.coin_flip;
    for(int j = 0; j < div_group; j++) begin
      // loop reached end of div_group without sending a packet
      if(j == div_group - 1 && div_group_done == 1'b0) begin
        // sends a packet from input port at current index
        //  and adds element to local s_pckt_arr storage
        sendhdr(div_group * i + j, loc_s_pckt_arr[div_group * i + j]);
        tx_cnt++; 
      end
      // randomize until coin flip lands on heads
      else if(div_group_done == 1'b0) begin
        random_packet.randomize();
        div_group_done = random_packet.coin_flip;
      end
      // coin flip landed on heads, send packet, incr tx_cnt, and break loop
      else if(div_group_done == 1'b1) begin
        // sends a packet from input port at current index
        //  and adds element to local s_pckt_arr storage
        sendhdr(div_group * i + j, loc_s_pckt_arr[div_group * i + j]);
        tx_cnt++;
        // stop iterating through div_group
        break;
      end
    end
  end
  // add this tb_traffic cycle to the traffic queue
  q_net_traffic.push_back(loc_s_pckt_arr);
  tick(1);
  in_ch = '0;
endtask


// monitor received traffic
task rx_traffic();
  for(int i = 0; i < 64; i++)
    if(out_ch[i][17:16] == HDR_TYPE)
      rx_cnt++;
endtask


task send_and_flush(input real duty_cycle);
// reset counters
  tx_cnt = 0;
  rx_cnt = 0;
// send traffic
  for(int i = 0; i < 24; i++) begin
    rx_traffic();
    tx_traffic(duty_cycle);
  end
// flush buffers and count
  for(int i = 0; i < 50; i++) begin
    rx_traffic();
    tick(1);
  end
// clear tb_net_traffic memory

endtask


function compute_dest(input logic [5:0] d_adr, output int o_port);
  logic [5:0] d_adr_rev;
  d_adr_rev = {<<{d_adr}};
  o_port = d_adr_rev;
endfunction


initial begin
    $dumpfile("tb_sym_butterfly_perf.vcd");
    $dumpvars(1);
    $dumpvars(1, tb_sym_butterfly_perf.DUT);

    tick(4);

    duty_cycle = 0.03125;
    send_and_flush(duty_cycle);

    duty_cycle = 0.0625;
    send_and_flush(duty_cycle);

    duty_cycle = 0.125;
    send_and_flush(duty_cycle);

    duty_cycle = 0.25;
    send_and_flush(duty_cycle);

    duty_cycle = 0.5;
    send_and_flush(duty_cycle);

    duty_cycle = 1;
    send_and_flush(duty_cycle);

    $finish;

end

endmodule