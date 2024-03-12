# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Vincenzo Maisto <vincenzo.maisto2@unina.it>

#################
## RVV Testing ##
#################

## NOTE: this is very much not the correct way to do it, but time is tight...
## NOTE2: DO NOT initialize here bender defs. Use the makefrag in target/common instead

# FPGA (it influences sw only)
FPGA           ?= 1
EXTENSIVE_TEST ?= 1
PRINTF         ?= 1
# EEW
EEW ?= 8
# Test macros
RVV_TEST_MAGIC 			?= f0f0f0f0f0f0f0f0
RVV_TEST_ARA_NR_LANES 	?= 2 4 8
# Align to AxiDataWidth of VLSU
ALIGN_VSTORES := $(shell echo "32 * $(ARA_NR_LANES) / 8" | bc -l | sed -E "s/\..+//g")

# Software artifacts
CHS_SW_RVV_TEST_DIR ?= $(CHS_SW_DIR)/tests
CHS_SW_RVV_TEST_HDRS := $(CHS_SW_RVV_TEST_DIR)/rvv_test.h

RVV_TEST_SRC 	?= $(wildcard $(CHS_SW_RVV_TEST_DIR)/rvv_test_*.c)
RVV_TEST_ELF 	?= $(RVV_TEST_SRC:.c=.spm.elf)

CHS_RVV_TEST_RESULT_DIR := $(CHS_ROOT)/rvv_test_results

# Run all the tests
# Run RVV_TEST_ELF for all RVV_TEST_ARA_NR_LANES configurations
rvv-test-run-all:
	for elf in $(RVV_TEST_ELF); do 						\
		for nrlanes in $(RVV_TEST_ARA_NR_LANES); do 	\
			RVV_TEST_ELF=$$elf ARA_NR_LANES=$$nrlanes	\
				$(MAKE) rvv-test-run; 					\
		done											\
	done

rvv-test-run rvv-test-report: RVV_TEST_NAME=$(shell basename $(RVV_TEST_ELF) .spm.elf)
rvv-test-run rvv-test-report: RVV_TEST_RESULT_DIR=$(CHS_RVV_TEST_RESULT_DIR)/$(RVV_TEST_NAME)
rvv-test-run rvv-test-report: RVV_TEST_RESULT_FILE=$(RVV_TEST_RESULT_DIR)/results.txt
rvv-test-run rvv-test-report: RVV_TEST_RESULT_DIR_LANES=$(RVV_TEST_RESULT_DIR)/ara_$(ARA_NR_LANES)_lanes
rvv-test-run rvv-test-report: RVV_TEST_TRACE=$(RVV_TEST_RESULT_DIR)/ara_$(ARA_NR_LANES)_lanes/trace_hart_0.log
rvv-test-run rvv-test-report: VSIM_ROOT=$(RVV_TEST_RESULT_DIR_LANES)
#	TODO: add switch to stop on first failure
rvv-test-run: chs-sw-all $(RVV_TEST_ELF)
#	Clear old results
	rm -rf $(RVV_TEST_RESULT_DIR_LANES)/*
	mkdir -p $(RVV_TEST_RESULT_DIR_LANES)
	mkdir -p $(VSIM_ROOT)
	BINARY=$(RVV_TEST_ELF) 					\
	EEW=$(EEW)                              \
	FPGA=$(FPGA)                            \
	EXTENSIVE_TEST=$(EXTENSIVE_TEST)        \
	PRINTF=$(PRINTF)                        \
	VSIM_ROOT=$(VSIM_ROOT) 					\
		$(MAKE) chs-sim-clean chs-sim-run
	RVV_TEST_NAME=$(RVV_TEST_NAME) $(MAKE) rvv-test-report

DATE_FORMAT ?= "+%Y-%b-%d %H:%M"
TEST_COMMENT ?= "None"
REPORT_FILE_ALL ?= $(CHS_RVV_TEST_RESULT_DIR)/report_all.txt
rvv-test-report: $(RVV_TEST_TRACE)
#	Compose test report
	@printf "$(RVV_TEST_NAME)," 					>> $(RVV_TEST_RESULT_FILE)
	@printf " ARA_NR_LANES=$(ARA_NR_LANES)," 	>> $(RVV_TEST_RESULT_FILE)
	@printf " $(shell date $(DATE_FORMAT))," 	>> $(RVV_TEST_RESULT_FILE)
	@printf " Notes: \"$(TEST_COMMENT)\", " 		>> $(RVV_TEST_RESULT_FILE)
	@printf " VSIM_ROOT=$(VSIM_ROOT)" 			>> $(RVV_TEST_RESULT_FILE)
	@printf "\n"									>> $(RVV_TEST_RESULT_FILE)
# 	Dump to general result report and terminal
	@tail -n1 $(RVV_TEST_RESULT_FILE) >> $(REPORT_FILE_ALL)
	@printf "[INFO] Test report: "; tail -n1 $(RVV_TEST_RESULT_FILE)
	@echo "[INFO] Check trace log at : $(RVV_TEST_TRACE)"
	@echo "[INFO] Check transcript at: $(RVV_TEST_RESULT_DIR)/transcript"
	@echo "[INFO] Check waves with   :"
	@echo "	make chs-sim-waves VSIM_ROOT=$(RVV_TEST_RESULT_DIR_LANES)"


rvv-test-clean:
	rm -rf $(RVV_TEST_RESULT_DIR)

rvv-test-clean-all:
	rm -rf $(CHS_RVV_TEST_RESULT_DIR)

##############
## Cleaning ##
##############

# Spare IPs from clean
chs-xil-util-clean:
# 	Vivado products in target/
	rm -rf $(CHS_XIL_DIR)/$(PROJECT)
# 	Viviado files from top directory
	rm -rf *.mcs *.prm .Xil/
# 	NOTE: Keep Vivado logs

############
## Vivado ##
############

# Board in      {vcu128, genesys2}
BOARD        := vcu128
XILINX_HOST  := bordcomputer
# IIS bordcomputer has a fixed vivado version for the hw_server
VIVADO_BORDCOMPUTER := vitis-2020.2 vivado
VCU128 ?= 2
# GDB ?= riscv64-unknown-elf-gdb
GDB ?= /usr/scratch/fenga3/vmaisto/cva6-sdk_fork_backup/buildroot/output/host/bin/riscv64-buildroot-linux-gnu-gdb

# Select board specific variables
ifeq ($(BOARD),vcu128)
	VIVADO       := vitis-2022.1 vivado
	XILINX_PART  := xcvu37p-fsvh2892-2L-e
	XILINX_BOARD := xilinx.com:vcu128:part0:1.0
	FPGA_DEVICE	 := xcvu37p_0
	IPS_NAMES    := xlnx_vio xlnx_mig_ddr4 xlnx_clk_wiz
# 	VCU128-01 (broken flash)
	ifeq ($(VCU128),1)
		XILINX_PORT	 := 3231
		FPGA_PATH	 := xilinx_tcf/Xilinx/091847100576A
		GDB_LOCAL_PORT  := 3337
		GDB_REMOTE_PORT := 3337
#		Force BSCANE2 on board 1, since no JTAG dongle is placed there
		INT_JTAG		:= 1
	endif
# 	VCU128-02
	ifeq ($(VCU128),2)
		XILINX_PORT	 := 3232
		FPGA_PATH	 := xilinx_tcf/Xilinx/091847100638A
		GDB_LOCAL_PORT  := 3333
		GDB_REMOTE_PORT := 3334
	endif
#	Choose whether to use BSCANE2 or external scanchain for the debug module
	ifeq ($(DEBUG_RUN),0)
		PROJECT := $(PROJECT)_DEBUG_RUN_0
	endif
endif

DEBUG_RUN ?= 1
DEBUG_NETS ?= 1
IMPL_STRATEGY ?= Performance_ExtraTimingOpt
SYNTH_STRATEGY ?= Flow_PerfOptimized_high

TCL_DIR := $(CHS_XIL_DIR)/scripts/tcl
VIVADOENV :=  $(VIVADOENV) 						\
              ARA=$(ARA)   				   		\
              TCL_DIR=$(TCL_DIR)   		   		\
              FPGA_DEVICE=$(FPGA_DEVICE)    	\
              IMPL_STRATEGY=$(IMPL_STRATEGY) 	\
              SYNTH_STRATEGY=$(SYNTH_STRATEGY) 	\
              DEBUG_RUN=$(DEBUG_RUN)        	\
			  DEBUG_NETS=$(DEBUG_NETS)			\
              LTX="$(LTX)"


# Redirect to xilinx.mk targets
chs-xil-top:
	$(MAKE) chs-xil-ips -j; make chs-xil-all

chs-xil-ips: $(ips)

# Add to xilinx.mk targets
chs-xil-clean: chs-xil-util-clean

chs-xil-all: chs-xil-report

chs-xil-bit: $(BIT)

# Local targets
chs-xil-report: $(BIT)
	cd $(CHS_XIL_DIR)/$(PROJECT); $(VIVADOENV) $(VIVADO) -mode batch $(PROJECT).xpr -source $(TCL_DIR)/get_run_info.tcl | grep " \[REPORT]" > $(CHS_XIL_DIR)/$(PROJECT)/reports/report.tmp
	grep " cheshire_top_xilinx " $(CHS_XIL_DIR)/$(PROJECT)/reports/$(PROJECT).utilization.rpt | sed -E "s/.+top\) //g" >>  $(CHS_XIL_DIR)/$(PROJECT)/reports/report.tmp
	cp $(CHS_XIL_DIR)/$(PROJECT)/reports/report.tmp $(out)/$(PROJECT).report

chs-xil-tcl:
	@echo "Starting $(VIVADO) TCL"
	cd $(CHS_XIL_DIR)/$(PROJECT); $(VIVADOENV) $(VIVADO) -nojournal -mode tcl $(PROJECT).xpr

util-debug-gui: chs-xil-debug-gui
chs-xil-debug-gui:
	@echo "Starting $(VIVADO) GUI for debug"
	$(VIVADOENV) $(VIVADO_BORDCOMPUTER) -nojournal -mode gui -source $(TCL_DIR)/debug_gui.tcl &

%.gdb: FORCE
	sed -E -i "s|file.+install64V?|file $(CHS_SW_DIR)/boot/install64$(IS_RVV)|g" $*.gdb

util-launch-gdb: scripts/gdb/running_kernel.gdb scripts/gdb/in_memory_boot.gdb
	-ssh -L $(GDB_LOCAL_PORT):localhost:$(GDB_REMOTE_PORT) -C -N -f -l $$USER $(XILINX_HOST)
	$(GDB) -ex "target extended-remote :$(GDB_LOCAL_PORT)"

chs-xil-clean-ips:
	rm -rf $(CHS_XIL_DIR)/*.xci
	cd  $(CHS_XIL_DIR)/xilinx; $(foreach ip, $(ips-names), make -C $(ip) clean;)

# Call all the clean targets
chs-xil-clean-all: chs-xil-util-clean chs-xil-clean-ips

#############
## Utility ##
#############

all:

# Complete fpga run
util-fpga-run:
# 	NOTE: these targets must run sequentially
	$(MAKE) -j1 chs-linux-clean
	$(MAKE) -j1 chs-linux-img
	$(MAKE) -j1 chs-xil-flash
	$(MAKE) -j1 chs-linux-clean chs-linux-img chs-xil-flash chs-xil-program

# Quick workaround for cva6-sdk not finding the DTB/FDT in this repo
# Expose a target to update it (just touching would not work)
dtb:
	dtc -I dts -O dtb -i $(CHS_SW_DIR)/boot $(CHS_SW_DIR)/boot/cheshire_$(BOARD).dts -o $(CHS_SW_DIR)/boot/cheshire_$(BOARD).dtb

# Force rule to override the target timestamps
FORCE:
