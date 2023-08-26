# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Vincenzo Maisto <vincenzo.maisto2@unina.it>

CHS_XIL_DIR  ?= $(CHS_ROOT)/target/xilinx
VIVADO       ?= vitis-2020.2 vivado

PROJECT      ?= cheshire
ip-dir       := $(CHS_XIL_DIR)/xilinx

# Select board specific variables
ifeq ($(BOARD),vcu128)
	XILINX_PART  ?= xcvu37p-fsvh2892-2L-e
	XILINX_BOARD ?= xilinx.com:vcu128:part0:1.0
	XILINX_PORT  ?= 3232
	FPGA_PATH    ?= xilinx_tcf/Xilinx/091847100638A
	XILINX_HOST  ?= bordcomputer
	ips-names    := xlnx_mig_ddr4 xlnx_clk_wiz xlnx_vio
	ifeq ($(INT_JTAG),1)
		xilinx_targs += -t bscane
	endif
endif
ifeq ($(BOARD),genesys2)
	XILINX_PART  ?= xc7k325tffg900-2
	XILINX_BOARD ?= digilentinc.com:genesys2:part0:1.1
	XILINX_PORT  ?= 3332
	XILINX_HOST  ?= bordcomputer
	FPGA_PATH    ?= xilinx_tcf/Digilent/200300A8C60DB
	ips-names    := xlnx_mig_7_ddr3 xlnx_clk_wiz xlnx_vio
endif
ifeq ($(BOARD),zcu102)
	XILINX_PART    ?= xczu9eg-ffvb1156-2-e
	XILINX_BOARD   ?= xilinx.com:zcu102:part0:3.4
	ips-names      := xlnx_mig_ddr4 xlnx_clk_wiz xlnx_vio
endif

ifeq ($(ARA),1)
	PROJECT := $(PROJECT)_ara_$(ARA_NR_LANES)_lanes
else
	PROJECT := $(PROJECT)_no_ara
endif
ifeq ($(INT_JTAG),1)
	PROJECT := $(PROJECT)_INT_JTAG
endif

# Location of ip outputs
ips := $(addprefix $(CHS_XIL_DIR)/,$(addsuffix .xci ,$(basename $(ips-names))))
# Derive bender args from enabled ips
xilinx_targs += -t fpga -t cva6
xilinx_targs += $(foreach ip-name,$(ips-names),$(addprefix -t ,$(ip-name)))
xilinx_targs += $(addprefix -t ,$(BOARD))

# Outputs
out ?= $(CHS_XIL_DIR)/out
BIT ?= $(out)/$(PROJECT).bit
LTX ?= $(out)/$(PROJECT).ltx
mcs ?= $(out)/$(PROJECT).mcs
ROUTED_DCP := $(out)/$(PROJECT)_routed.dcp

# Vivado variables
VIVADOENV ?=  PROJECT=$(PROJECT)            \
              BOARD=$(BOARD)                \
              XILINX_PART=$(XILINX_PART)    \
              XILINX_BOARD=$(XILINX_BOARD)  \
              PORT=$(XILINX_PORT)           \
              HOST=$(XILINX_HOST)           \
              FPGA_PATH=$(FPGA_PATH)        \
              BIT=$(BIT)                    \
              IP_PATHS="$(foreach ip-name,$(ips-names),../xilinx/$(ip-name)/$(ip-name).srcs/sources_1/ip/$(ip-name)/$(ip-name).xci)" \
              ROUTED_DCP=$(ROUTED_DCP)      \
              CHECK_TIMING=$(CHECK_TIMING)

MODE        ?= batch
VIVADOFLAGS ?= -nojournal -mode $(MODE)

chs-xil-all: $(BIT)

$(PROJECT):
	mkdir -p $(CHS_XIL_DIR)/$(PROJECT)

# Generate mcs from bitstream
$(mcs): $(BIT)
	cd $(CHS_XIL_DIR)/$(PROJECT) ; $(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source ./scripts/write_cfgmem.tcl -tclargs $@ $^

# Compile bitstream
$(BIT): $(ips) $(CHS_XIL_DIR)/scripts/add_sources.tcl $(PROJECT)
	@mkdir -p $(out)
# cd $(CHS_XIL_DIR)/$(PROJECT) ; $(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source ../scripts/prologue.tcl -source ../scripts/run.tcl
	cp $(CHS_XIL_DIR)/$(PROJECT)/$(PROJECT).runs/impl_1/cheshire_top_xilinx.bit $(BIT)
	cp $(CHS_XIL_DIR)/$(PROJECT)/$(PROJECT).runs/impl_1/cheshire_top_xilinx.ltx $(LTX)
	cp $(CHS_XIL_DIR)/$(PROJECT)/$(PROJECT).runs/impl_1/*_routed.dcp $(ROUTED_DCP)

# Generate ips
%.xci:
	@echo $@
	@echo $(CHS_XIL_DIR)
	@echo "Generating IP $(basename $@)"
	IP_NAME=$(basename $(notdir $@)) ; cd $(ip-dir)/$$IP_NAME ; $(MAKE) clean ; $(VIVADOENV) VIVADO="$(VIVADO)" $(MAKE)
	IP_NAME=$(basename $(notdir $@)) ; cp $(ip-dir)/$$IP_NAME/$$IP_NAME.srcs/sources_1/ip/$$IP_NAME/$$IP_NAME.xci $@

chs-xil-gui:
	@echo "Starting $(vivado) GUI"
	cd $(CHS_XIL_DIR)/$(PROJECT) ; $(VIVADOENV) $(VIVADO) -nojournal -mode gui $(PROJECT).xpr &

chs-xil-program: #$(BIT)
	@echo "Programming board $(BOARD) ($(XILINX_PART))"
	$(VIVADOENV) $(VIVADO) $(VIVADOFLAGS) -source $(CHS_XIL_DIR)/scripts/program.tcl

chs-xil-flash: $(CHS_SW_DIR)/boot/linux-${BOARD}.gpt.bin
	$(VIVADOENV) FILE=$< OFFSET=0 $(VIVADO) $(VIVADOFLAGS) -source $(CHS_XIL_DIR)/scripts/flash_spi.tcl

chs-xil-clean:
	cd $(CHS_XIL_DIR) && rm -rf scripts/add_sources.tcl* *.log *.jou *.str *.mif *.xci *.xpr .Xil/ $(out) $(PROJECT).srcs $(PROJECT).cache $(PROJECT).hw $(PROJECT).ioplanning $(PROJECT).ip_user_files $(PROJECT).runs $(PROJECT).sim

# Re-compile only top and not ips
chs-xil-rebuild-top:
	${MAKE} chs-xil-clean
	find $(CHS_XIL_DIR)/xilinx -wholename "**/*.srcs/**/*.xci" | xargs -n 1 -I {} cp {} $(CHS_XIL_DIR)
	${MAKE} $(BIT)

# Bender script
$(CHS_XIL_DIR)/scripts/add_sources.tcl: Bender.yml
	$(BENDER) script vivado $(xilinx_targs) $(BENDER_DEFS) > $@

.PHONY: chs-xil-gui chs-xil-program chs-xil-flash chs-xil-clean chs-xil-rebuild-top chs-xil-all
