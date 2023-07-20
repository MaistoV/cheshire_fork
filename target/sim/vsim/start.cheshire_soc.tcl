# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Nicole Narr <narrn@student.ethz.ch>
# Christopher Reinwardt <creinwar@student.ethz.ch>
# Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

set TESTBENCH tb_cheshire_soc

#######################
## Boot parameters
#######################
# Passive boot mode
set BOOTMODE 0x00

# JTAG
set PRELMODE 0
# # Serial Link
# set PRELMODE 1
# # UART
# set PRELMODE 2

# Only for PRELMODE JTAG and Serial link
# ELF file to be loaded
set BINARY ../../../sw/tests/rvv_hello_world.spm.elf
# set BINARY ../../../sw/tests/helloworld.dram.elf

# Only for BOOTMODE i2c and spih (not supported?)
# set IMAGE    boot_hex

# Set voptargs only if not already set to make overridable.
# Default on fast simulation flags.
if {![info exists VOPTARGS]} {
    # set VOPTARGS "-O5 +acc=p+tb_cheshire_soc. +noacc=p+cheshire_soc. +acc=r+stream_xbar"
    set VOPTARGS "-O5  +acc=tb_cheshire_soc"
}

# Suppress (vopt-7033) Variable '' driven in a combinational block, may not be driven by any other process. 
# Because of ara/lane/operand_requester.sv
set flags "-permissive -suppress 3009 -suppress 8386 -suppress vopt-7033 -error 7 -dpicpppath /usr/pack/questa-2022.3-bt/questasim/gcc-7.4.0-linux_x86_64/bin/g++"

set pargs ""
if {[info exists BOOTMODE]} { append pargs "+BOOTMODE=${BOOTMODE} " }
if {[info exists PRELMODE]} { append pargs "+PRELMODE=${PRELMODE} " }
if {[info exists BINARY]}   { append pargs "+BINARY=${BINARY} " }
if {[info exists IMAGE]}    { append pargs "+IMAGE=${IMAGE} " }

eval "vsim -c ${TESTBENCH} -t 1ps -vopt -voptargs=\"${VOPTARGS}\"" ${pargs} ${flags}

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
