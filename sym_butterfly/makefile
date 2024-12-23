TEST = tb_sym_butterfly_perf
# WAVE_FILE = wave_test.do

# PREFIX = europractice questa 10.6c
RTLDIR = ./src
TBDIR = ./tb
WAVEDIR = ./waves

VLATOR = verilator
SIM = gtkwave
VLATOR_OPTS = -Wall --trace -Wno-fatal -cc --binary


# compile all sources
src = $(RTLDIR)/allocator.sv  \
	$(RTLDIR)/fair_allocator.sv \
	$(RTLDIR)/resent_pckt_pri_allocator.sv \
	$(RTLDIR)/switch_node_4rad.sv  \
	$(RTLDIR)/l1_l2_xbar.sv  \
	$(RTLDIR)/l2_l3_xbar.sv  \
	$(RTLDIR)/sym_butterfly.sv  \
	$(RTLDIR)/sym_butterfly_wrapper.sv

rtl:
	${VLATOR} ${VLATOR_OPTS} ${src}
	

# compile verification environment
compile-all:
	${VLATOR} ${VLATOR_OPTS} ${src} $(TBDIR)/$(TEST) --top $(TEST)
	./obj_dir/V$(TEST)

# run simulator in GUI mode 
run:
	${SIM} $(TEST).vcd &

	
clean:
	rm -rf obj_dir