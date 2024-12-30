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

// randomization for output port assignment
class automatic randAdr;
  // bit order is msb -> lsb
  //  must be streamed backwards to logic assignment
  //  for switch node address mapping
  rand logic [5:0] d_adr;
endclass

// randomization for input port assignment
class automatic uniformSequence;
  int ch_idx[];

  function new(input int array_size);
    if(array_size < 64)
      linspace(ch_idx, array_size);
    else
      linspace(ch_idx, 64);
  endfunction

  function automatic void linspace(ref int linspaced_array[], input int array_size);
    int step;
    linspaced_array = new[array_size];
    step = 64/array_size;
    for(int i = 0; i < array_size; i++)
      linspaced_array[i] = i * step;
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

shortint tx_cnt, rx_cnt, dropped_cnt;
real duty_cycle;

randAdr random_address = new;
uniformSequence uniform_sequence;

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
  random_address.randomize();
  pckt = {HDR_TYPE, random_address.d_adr, 10'h0};
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
  $display("[%0t] Starting new tx traffic cycle, duty cycle: %0f", $time, duty_cycle_in);

    // saturate network for 24 cycles
    for(int i = 0; i < 24; i++) begin
      // check mail
      resend_packets.try_get(resend_pckt_arr);
      // create ch_idx input port sequence, extend sequence for packets to be resent as needed
      uniform_sequence = new(64 * duty_cycle_in + resend_pckt_arr.packet_cnt);
      $display("[%0t] Tx Traffic Cycle %0d, tx payload vol: %0d, uniform sequence: ", $time, i, uniform_sequence.ch_idx.size(), uniform_sequence.ch_idx);
      foreach(uniform_sequence.ch_idx[j]) begin
        // resend packets first
        if(resend_pckt_arr.packet_cnt > 0) begin
          // top element resent then popped
          resendhdr(uniform_sequence.ch_idx[j], resend_pckt_arr.packets[resend_pckt_arr.packet_cnt - 1]);
          tx_s_pckt_arr[uniform_sequence.ch_idx[j]] = resend_pckt_arr.packets[resend_pckt_arr.packet_cnt - 1];
            $display("\tResent Packet %0d => Payload {tx_s_pckt_arr[%0d]}: 0x%0h, I_port {uniform_sequence.ch_idx[%0d]}: %0d, O_port {tx_s_pckt_arr[%0d].d_adr}: %0d", j, uniform_sequence.ch_idx[j], tx_s_pckt_arr[uniform_sequence.ch_idx[j]], j, uniform_sequence.ch_idx[j], uniform_sequence.ch_idx[j], tx_s_pckt_arr[uniform_sequence.ch_idx[j]].d_adr);
          resend_pckt_arr.packets[resend_pckt_arr.packet_cnt - 1] = 0;
          resend_pckt_arr.packet_cnt--;
          tx_cnt++;
        end
        // no more packets to resend
        else begin
          // sends a packet from input port at current index
          //  and adds element to local s_pckt_arr storage
          sendhdr(uniform_sequence.ch_idx[j], tx_s_pckt_arr[uniform_sequence.ch_idx[j]]);
            $display("\tSent Packet %0d => Payload {tx_s_pckt_arr[%0d]}: 0x%0h, I_port {uniform_sequence.ch_idx[%0d]}: %0d, O_port {tx_s_pckt_arr[%0d].d_adr}: %0d", j, uniform_sequence.ch_idx[j], tx_s_pckt_arr[uniform_sequence.ch_idx[j]], j, uniform_sequence.ch_idx[j], uniform_sequence.ch_idx[j], tx_s_pckt_arr[uniform_sequence.ch_idx[j]].d_adr);
          tx_cnt++;
        end
      end

      // add this traffic cycle to the traffic queue
      q_net_traffic.push_back(tx_s_pckt_arr);
      tick(1);
      // clear memories
      tx_s_pckt_arr.delete();
      uniform_sequence = null;
    end

  // stop driving input
  in_ch = '0;
endtask

// monitor received traffic, resend packets with mailbox
task rx_traffic();
  // initialize packet arrays
  s_packet rx_s_pckt_arr[int];
  s_mbx_packets resend_pckt_arr;
  int iteration;
  resend_pckt_arr = 0;
  iteration = 0;
  // timeout for zero-load latency
  tick(6);
  // update rx_cnt and stage packets to be resent
  while(q_net_traffic.size() > 0) begin
    rx_s_pckt_arr = q_net_traffic.pop_front();
    $display("[%0t] Rx Traffic Cycle %0d, rx payload vol %0d", $time, iteration, rx_s_pckt_arr.size());
    foreach(rx_s_pckt_arr[i]) begin
      if(rx_s_pckt_arr[i] == out_ch[rx_s_pckt_arr[i].d_adr]) begin
        rx_cnt++;
          $display("\tReceived Packet %0d\t=> I_port: %0d, O_port {rx_s_pckt_arr[%0d].d_adr)}: %0d, Expected Packet => Payload {rx_s_pckt_arr[%0d]}: 0x%0h, Received Packet => Payload {out_ch[%0d].d_adr} 0x%0h", rx_cnt, i, i, rx_s_pckt_arr[i].d_adr, i, rx_s_pckt_arr[i], rx_s_pckt_arr[i].d_adr, out_ch[rx_s_pckt_arr[i].d_adr]);
      end
      else begin
        resend_pckt_arr.packets[resend_pckt_arr.packet_cnt] = rx_s_pckt_arr[i];
        resend_pckt_arr.packet_cnt++;
        dropped_cnt++;
          $display("\tDROPPED Packet %0d\t=> I_port: %0d, O_port {rx_s_pckt_arr[%0d].d_adr)}: %0d, Expected Packet => Payload {rx_s_pckt_arr[%0d]}: 0x%0h, Received Packet => Payload {out_ch[%0d].d_adr} 0x%0h", dropped_cnt, i, i, rx_s_pckt_arr[i].d_adr, i, rx_s_pckt_arr[i], rx_s_pckt_arr[i].d_adr, out_ch[rx_s_pckt_arr[i].d_adr]);
      end
    end
    // mailing packets to be resent!
    if(resend_pckt_arr.packet_cnt > 0)
      resend_packets.put(resend_pckt_arr);

    iteration++;
    tick(1);

    // clear memories
    rx_s_pckt_arr.delete();
    resend_pckt_arr = 0;
  end

  // resend_packets = null;
endtask

// reset counters
task flush();
  tx_cnt = 0;
  rx_cnt = 0;
  dropped_cnt = 0;
  resend_packets = new();
  q_net_traffic.delete();
  $display("\n");
endtask


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
    flush();

    duty_cycle = 0.0625;
    fork
      tx_traffic(duty_cycle);
      rx_traffic();
    join
    tick(50);
    flush();

    duty_cycle = 0.125;
    fork
      tx_traffic(duty_cycle);
      rx_traffic();
    join
    tick(50);
    flush();

    duty_cycle = 0.25;
    fork
      tx_traffic(duty_cycle);
      rx_traffic();
    join
    tick(50);
    flush();

    duty_cycle = 0.5;
    fork
      tx_traffic(duty_cycle);
      rx_traffic();
    join
    tick(50);
    flush();

    $finish;

end

endmodule