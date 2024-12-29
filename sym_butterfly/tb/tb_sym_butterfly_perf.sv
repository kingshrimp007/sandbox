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
  // bit order is msb -> lsb
  //  must be streamed backwards to logic assignment
  //  for switch node address mapping
  rand logic [5:0] d_adr;
endclass

class automatic randSequence;
  rand int ch_idx[];
  
  constraint idx_range {foreach (ch_idx[i]) {
                          ch_idx[i] > 0;
                          ch_idx[i] < 64;	}
                       }

  function new(input int array_size);
	  ch_idx = new[array_size];
  endfunction
                        
endclass

typedef struct packed {
  logic [1:0] p_type;
  logic [5:0] d_adr;
  logic [9:0] null_field;
} s_packet;

typedef struct packed {
  s_packet [63:0] packets;
  int packet_cnt;
} s_mbx_packets;


module tb_sym_butterfly_perf ();
// ------------------------------------------------
// parameter and logic declarations
// ------------------------------------------------
localparam HDR_TYPE = 2'b11;
localparam PCK_TYPE = 2'b10;

logic                clk;
logic [63:0][17:0]   in_ch;
logic [63:0][17:0]   out_ch;

// queue of associative arrays
s_packet q_net_traffic [$][int];

mailbox #(s_mbx_packets) resend_packets = new();

int network_queue_size, queue_current_cycle_packet_vol;
int tx_cnt, rx_cnt, dropped_cnt;
real duty_cycle;

randPckt random_packet = new;
randSequence random_sequence;

// ------------------------------------------------
// subprogram definitions
// ------------------------------------------------
// runs clock for input count cycles
task tick(input int count);
  for(int i = 0; i < count; i++)
    @(negedge clk);
endtask


// send header wtih randomized destination address
task automatic sendhdr(input int s_port, output logic [17:0] pckt);
  random_packet.randomize();
  pckt = {HDR_TYPE, {<<{random_packet.d_adr}}, 10'h0};
  in_ch[s_port] = pckt;
endtask

// resend packet, no randomization needed
task automatic resendhdr(input int s_port, input logic [17:0] pckt);
  in_ch[s_port] = pckt;
endtask

// send traffic at requested duty cycle with randomized I/O
task tx_traffic(input real duty_cycle_in);
  // inititalize local s_pckt_arr associative array
  s_packet tx_s_pckt_arr[int];
  s_mbx_packets resend_pckt_arr;
  resend_pckt_arr = 0;

    // saturate network for 24 cycles
    for(int i = 0; i < 24; i++) begin
      // check mail
      resend_packets.try_get(resend_pckt_arr);
      // randomize ch_idx sequence, extend sequence for resending packets as needed
      random_sequence = new(64 * duty_cycle_in + resend_pckt_arr.packet_cnt);
      random_sequence.randomize();
      $display("[%0t] Iteration %0d, payload vol: %0d, random sequence: ", $time, i, random_sequence.ch_idx.size(), random_sequence.ch_idx);
      foreach(random_sequence.ch_idx[j]) begin
        // resend packets first
        if(resend_pckt_arr.packet_cnt > 0) begin
          // top element resent then popped
          resendhdr(random_sequence.ch_idx[j], resend_pckt_arr.packets[resend_pckt_arr.packet_cnt - 1]);
          tx_s_pckt_arr[random_sequence.ch_idx[j]] = resend_pckt_arr.packets[resend_pckt_arr.packet_cnt - 1];
            $display("[%0t] Iteration %0d, rand_seq idx %0d, Resent Packet => Payload {tx_s_pckt_arr[random_sequence.ch_idx[%0d]]}: 0x%0h, O_port {random_sequence.ch_idx[%0d]}: 0x%0h", $time, i, j, j, tx_s_pckt_arr[random_sequence.ch_idx[j]], j, random_sequence.ch_idx[j]);
          resend_pckt_arr.packets[resend_pckt_arr.packet_cnt - 1] = 0;
          resend_pckt_arr.packet_cnt--;
          tx_cnt++;
        end
        // no more packets to resend
        else begin
          // sends a packet from input port at current index
          //  and adds element to local s_pckt_arr storage
          sendhdr(random_sequence.ch_idx[j], tx_s_pckt_arr[random_sequence.ch_idx[j]]);
            $display("[%0t] Iteration %0d, rand_seq idx %0d, Sent Packet => Payload {tx_s_pckt_arr[random_sequence.ch_idx[%0d]]}: 0x%0h, O_port {random_sequence.ch_idx[%0d]}: 0x%0h", $time, i, j, j, tx_s_pckt_arr[random_sequence.ch_idx[j]], j, random_sequence.ch_idx[j]);
          tx_cnt++;
        end
      end

      // add this traffic cycle to the traffic queue
      q_net_traffic.push_back(tx_s_pckt_arr);
      tick(1);
      // clear memories
      resend_pckt_arr = 0;
      random_sequence = null;
    end

  // stop driving input
  in_ch = '0;
endtask

// monitor received traffic, resend packets with mailbox
task rx_traffic();
  // initialize packet arrays
  s_packet rx_s_pckt_arr[int];
  s_mbx_packets resend_pckt_arr;
  resend_pckt_arr = 0;
  // wait until out_ch has valid data
  // while(|out_ch == 0);
  tick(6);
  // update rx_cnt and stage packets to be resent
  while(q_net_traffic.size() > 0) begin
    network_queue_size = q_net_traffic.size();
    rx_s_pckt_arr = q_net_traffic.pop_front();
    queue_current_cycle_packet_vol = rx_s_pckt_arr.size();
    foreach(rx_s_pckt_arr[i])
      if(rx_s_pckt_arr[i] == out_ch[o_adr(rx_s_pckt_arr[i].d_adr)])
        rx_cnt++;
      else begin
        resend_pckt_arr.packets[resend_pckt_arr.packet_cnt] = rx_s_pckt_arr[i];
        resend_pckt_arr.packet_cnt++;
        dropped_cnt++;
      end
    // mailing packets to be resent!
    if(resend_pckt_arr.packet_cnt > 0)
      resend_packets.put(resend_pckt_arr);

    tick(1);
  end

  // resend_packets = null;
endtask

// 
task flush();
// reset counters
  tx_cnt = 0;
  rx_cnt = 0;

// clear tb_net_traffic memory

endtask

// convert input logic vector d_adr to integer 
function int o_adr(input logic [5:0] d_adr);
  int o_port;
  o_port = {26'h0, {<<{d_adr}}};
  return o_port;
endfunction

// ------------------------------------------------
// DUT instantiation
// ------------------------------------------------
sym_butterfly_wrapper DUT (
    .clk    ( clk    ),
    .in_ch  ( in_ch  ),
    .out_ch ( out_ch )
);

// ------------------------------------------------
// processes
// ------------------------------------------------
// initialize testbench variables and setup vcd dump
initial begin 
  $dumpfile("tb_sym_butterfly_perf.vcd");
  $dumpvars(1);
  $dumpvars(1, tb_sym_butterfly_perf.DUT);
  clk = 1'b1;
  in_ch = '0;
  tx_cnt = 0;
  rx_cnt = 0;
  dropped_cnt = 0;
  network_queue_size = 0;
  queue_current_cycle_packet_vol = 0;
  duty_cycle = 0;
end

// generate clock
always #5 clk = ~clk;

// main testbench process
initial begin

    tick(4);

    duty_cycle = 0.03125;
    fork
      tx_traffic(duty_cycle);
      rx_traffic();
    join
    tick(50);

    $finish;

end

endmodule