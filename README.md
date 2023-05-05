# Cheshire

This repository hosts the Cheshire SoC platform. Cheshire is a minimal Linux-capable SoC built around the RISC-V CVA6 core. It is developed as part of the PULP project, a joint effort between ETH Zurich and the University of Bologna.

## Disclaimer

This project is still considered to be in early development; some parts may not yet be functional, and existing interfaces and conventions may be broken without prior notice. We target a formal release in the very near future.

## Build

To build different parts of the project, run `make` followed by these targets:

* `hw-all`: generated hardware, including IPs and boot ROM
* `sw-all`: software running on our hardware
* `sim-all`(†): scripts and external models for simulation
* `xilinx-all`: scripts for Xilinx FPGA implementation

† *`sim-all` will download externally provided peripheral simulation models, some proprietary and with non-free license terms, from their publically accessible sources; see `Makefile` for details. By running `sim-all` or the default target `all`, you accept this.*

Running `hw-all` is *required* at least once to correctly configure IPs we depend on. On reconfiguring any generated hardware or changing IP versions, `hw-all` should be rerun.

To run all build targets above (†):

```
make all
```

If you have access to our internal servers, you can run `make nonfree-init` to fetch additional resources we cannot make publically accessible. Note that these are *not required* to use anything provided in this repository.

## Linux image

To build the Linux image for FPGA:
```bash
# Clone and build GCC, OpenSBI, U-Boot and Linux
git clone git@github.com:pulp-platform/cva6-sdk.git --branch fix/cheshire
cd cva6-sdk
git submodule update --init --recursive
make images
# Link the output in the sw dir
ln -s cva6-sdk/install64 sw/boot/install64
# Build the image at sw/boot/linux-[genesys2,vcu128].gpt.bin
make BOARD=[genesys2,vcu128] chs-linux-img

```

On Genesys2, you can now flash this image to your sd card (require sudo).

```bash
# Replace sdX by your SD card device
dd if=sw/boot/cheshire-linux-genesys2.gpt.bin of=/dev/sdX
```

On VCU128, you can now flash this image to the SPI using Vivado:

```bash
# Define XILINX_PORT, XILINX_HOST, FPGA_PATH to let Vivado find your FPGA
# See defaults in xilinx.mk
make chs-xil-flash BOARD=vcu128 MODE=batch
```

## FPGA

To build the bitstream for FPGA, initialize the repository with `make all` then run `make chs-xil-all` followed by desired arguments:

* `BOARD=[genesys2,vcu128]`: select supported evaluation board (note `zcu102` is also supported but do not boot Linux as it does not provide access to an SPI flash or an SD card).
* `INT-JTAG=[1,0]`: (only on vcu128) connect the debugger to the intenal JTAG chain (see BSCANE2 primitive) or to an external JTAG dongle (if 0).
* `MODE=[batch,gui]`: open Vivado GUI or execute in shell.

You can flash the bitstream from the GUI with `make chs-xil-gui` or directly in shell using `make chs-xil-program MODE=batch BOARD=[genesys2,vcu128]`. Here again you will need to define `XILINX_PORT`, `XILINX_HOST`, `FPGA_PATH` for your setup. At IIS, find default values in `carfield.mk`.

## License

Unless specified otherwise in the respective file headers, all code checked into this repository is made available under a permissive license. All hardware sources and tool scripts are licensed under the Solderpad Hardware License 0.51 (see `LICENSE`) with the exception of generated register file code (e.g. `hw/regs/*.sv`), which is generated by a fork of lowRISC's [`regtool`](https://github.com/lowRISC/opentitan/blob/master/util/regtool.py) and licensed under Apache 2.0. All software sources are licensed under Apache 2.0.
