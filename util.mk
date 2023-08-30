# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Vincenzo Maisto <vincenzo.maisto2@unina.it>

#############
## Utility ##
#############

all: util-patches

# Complete fpga run
util-fpga-run:
# 	NOTE: these target must be run sequentially
	$(MAKE) -j1 chs-linux-clean chs-linux-img chs-xil-flash chs-xil-program

# This is a temporary solution to avoid a mess with bender
# Also keeping the patches separated for single files helps keeping things simple
util-patches: 
	-patch $(shell bender path cva6)/Bender.yml patches/bender_git_checkouts_cva6_Bender.yml.patch
	-patch $(shell bender path cva6)/common/local/util/instr_trace_item.svh patches/bender_git_checkouts_cva6_common_local_util_instr_trace_item.svh.patch
	-patch $(shell bender path ara)/Bender.yml patches/bender_git_checkouts_ara_Bender.yml.patch 
	-patch $(shell bender path ara)/hardware/src/vlsu/vlsu.sv patches/bender_git_checkouts_ara_hardware_src_vlsu_vlsu.sv.patch
	
# Quick workaround for cva6-sdk not finding the DTB/FDT in this repo
# Expose a target to update it (just touching would not work)
dtb:
	dtc -I dts -O dtb -i $(CHS_SW_DIR)/boot $(CHS_SW_DIR)/boot/cheshire_$(BOARD).dts -o $(CHS_SW_DIR)/boot/cheshire_$(BOARD).dtb 


############
## Vivado ##
############

# Board in      {vcu128, genesys2}
BOARD        ?= vcu128
XILINX_HOST  ?= bordcomputer
# IIS bordcomputer has a fixed vivado version for the hw_server 
VIVADO_BORDCOMPUTER ?= vitis-2020.2 vivado
VCU128 ?= 2
# GDB ?= riscv64-unknown-elf-gdb 
GDB ?= /usr/scratch/fenga3/vmaisto/cva6-sdk_fork_backup/buildroot/output/host/bin/riscv64-buildroot-linux-gnu-gdb

# Select board specific variables
ifeq ($(BOARD),vcu128)
	VIVADO       ?= vitis-2020.2 vivado
	XILINX_PART  ?= xcvu37p-fsvh2892-2L-e
	XILINX_BOARD ?= xilinx.com:vcu128:part0:1.0
# 	VCU128-01 (broken flash)
	ifeq ($(VCU128),1)
		XILINX_PORT	 ?= 3231 
		FPGA_PATH	 ?= xilinx_tcf/Xilinx/091847100576A 
		GDB_LOCAL_PORT  ?= 3337
		GDB_REMOTE_PORT ?= 3337
	endif
# 	VCU128-02
	ifeq ($(VCU128),2)
		XILINX_PORT	 ?= 3232
		FPGA_PATH	 ?= xilinx_tcf/Xilinx/091847100638A 
		GDB_LOCAL_PORT  ?= 3333
		GDB_REMOTE_PORT ?= 3334
	endif
	FPGA_DEVICE	 ?= xcvu37p_0
	IPS_NAMES    := xlnx_vio xlnx_mig_ddr4 xlnx_clk_wiz 
# Choose whether to use BSCANE2 or external scanchain for the debug module 
	ifeq ($(EXT_JTAG),0)
		xilinx_targs += -t bscane
	endif
endif

DEBUG_RUN ?= 1
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
              LTX="$(LTX)"          	       


# Redirect to xilinx.mk targets
chs-xil-top: 
	$(MAKE) chs-xil-ips -j; make chs-xil-all 

chs-xil-ips: $(ips)

# Add to xilinx.mk targets
chs-xil-clean: chs-xil-util-clean

chs-xil-all: chs-xil-report

# Local targets
chs-xil-report: $(bit) $(PROJECT)
	cd $(CHS_XIL_DIR)/$(PROJECT); $(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) $(PROJECT).xpr -source $(TCL_DIR)/get_run_info.tcl | grep " \[REPORT]" > $(CHS_XIL_DIR)/$(PROJECT)/reports/report.tmp
	grep " cheshire_top_xilinx " $(CHS_XIL_DIR)/$(PROJECT)/reports/$(PROJECT).utilization.rpt | sed -E "s/.+top\) //g" >>  $(CHS_XIL_DIR)/$(PROJECT)/reports/report.tmp

chs-xil-tcl:
	@echo "Starting $(VIVADO) TCL"
	cd $(CHS_XIL_DIR)/$(PROJECT); $(VIVADOENV) $(VIVADO) -nojournal -mode tcl $(PROJECT).xpr

util-debug-gui: chs-xil-debug-gui
chs-xil-debug-gui:
	@echo "Starting $(VIVADO) GUI for debug"
	$(VIVADOENV) $(VIVADO) -nojournal -mode gui -source $(TCL_DIR)/debug_gui.tcl

util-launch-gdb:
	-ssh -L $(GDB_LOCAL_PORT):localhost:$(GDB_REMOTE_PORT) -C -N -f -l $$USER $(XILINX_HOST)
	$(GDB) -ex "target extended-remote :$(GDB_LOCAL_PORT)"

# Spare IPS from clean
chs-xil-util-clean:
# 	Vivado products in target/
	rm -rf $(CHS_XIL_DIR)/$(PROJECT) $(out) 
# 	Viviado files from top directory
	rm -rf *.mcs *.prm .Xil/ 
# 	NOTE: Keep Vivado logs

chs-xil-clean-ips:
	rm -rf $(CHS_XIL_DIR)*.xci
	cd  $(CHS_XIL_DIR)/xilinx; $(foreach ip, $(ips-names), make -C $(ip) clean;)

# Call all the clean targets
chs-xil-clean-all: chs-xil-util-clean chs-xil-clean-ips

#####################
# Script generation #
#####################

CVA6_SDK := ../cva6-sdk_fork_backup
# CVA6_SDK := ../../../cva6-sdk_fork_update_kernel
INPUT_LOAD_ELF=$(CVA6_SDK)/install64/in_memory_fw_payload.elf
INPUT_DUMP_ELF=$(CVA6_SDK)/install64/vmlinux.dump
# From OpenSBI configuration
FW_PAYLOAD_OFFSET=0x200000
util-gdb-script: $(CHS_XIL_DIR)/scripts/gdb/in_memory_boot.gdb
$(CHS_XIL_DIR)/scripts/gdb/in_memory_boot.gdb: $(CHS_XIL_DIR)/scripts/gen_gdb_script.sh
	bash $< $(INPUT_LOAD_ELF) $(INPUT_DUMP_ELF) $@ $(FW_PAYLOAD_OFFSET)

