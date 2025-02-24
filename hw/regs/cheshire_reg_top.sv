// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Top module auto-generated by `reggen`


`include "common_cells/assertions.svh"

module cheshire_reg_top #(
  parameter type reg_req_t = logic,
  parameter type reg_rsp_t = logic,
  parameter int AW = 7
) (
  input logic clk_i,
  input logic rst_ni,
  input  reg_req_t reg_req_i,
  output reg_rsp_t reg_rsp_o,
  // To HW
  input  cheshire_reg_pkg::cheshire_hw2reg_t hw2reg, // Read


  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);

  import cheshire_reg_pkg::* ;

  localparam int DW = 32;
  localparam int DBW = DW/8;                    // Byte Width

  // register signals
  logic           reg_we;
  logic           reg_re;
  logic [BlockAw-1:0]  reg_addr;
  logic [DW-1:0]  reg_wdata;
  logic [DBW-1:0] reg_be;
  logic [DW-1:0]  reg_rdata;
  logic           reg_error;

  logic          addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  // Below register interface can be changed
  reg_req_t  reg_intf_req;
  reg_rsp_t  reg_intf_rsp;


  assign reg_intf_req = reg_req_i;
  assign reg_rsp_o = reg_intf_rsp;


  assign reg_we = reg_intf_req.valid & reg_intf_req.write;
  assign reg_re = reg_intf_req.valid & ~reg_intf_req.write;
  assign reg_addr = reg_intf_req.addr[BlockAw-1:0];
  assign reg_wdata = reg_intf_req.wdata;
  assign reg_be = reg_intf_req.wstrb;
  assign reg_intf_rsp.rdata = reg_rdata;
  assign reg_intf_rsp.error = reg_error;
  assign reg_intf_rsp.ready = 1'b1;

  assign reg_rdata = reg_rdata_next ;
  assign reg_error = (devmode_i & addrmiss) | wr_err;


  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic [31:0] scratch_0_qs;
  logic [31:0] scratch_0_wd;
  logic scratch_0_we;
  logic [31:0] scratch_1_qs;
  logic [31:0] scratch_1_wd;
  logic scratch_1_we;
  logic [31:0] scratch_2_qs;
  logic [31:0] scratch_2_wd;
  logic scratch_2_we;
  logic [31:0] scratch_3_qs;
  logic [31:0] scratch_3_wd;
  logic scratch_3_we;
  logic [31:0] scratch_4_qs;
  logic [31:0] scratch_4_wd;
  logic scratch_4_we;
  logic [31:0] scratch_5_qs;
  logic [31:0] scratch_5_wd;
  logic scratch_5_we;
  logic [31:0] scratch_6_qs;
  logic [31:0] scratch_6_wd;
  logic scratch_6_we;
  logic [31:0] scratch_7_qs;
  logic [31:0] scratch_7_wd;
  logic scratch_7_we;
  logic [31:0] scratch_8_qs;
  logic [31:0] scratch_8_wd;
  logic scratch_8_we;
  logic [31:0] scratch_9_qs;
  logic [31:0] scratch_9_wd;
  logic scratch_9_we;
  logic [31:0] scratch_10_qs;
  logic [31:0] scratch_10_wd;
  logic scratch_10_we;
  logic [31:0] scratch_11_qs;
  logic [31:0] scratch_11_wd;
  logic scratch_11_we;
  logic [31:0] scratch_12_qs;
  logic [31:0] scratch_12_wd;
  logic scratch_12_we;
  logic [31:0] scratch_13_qs;
  logic [31:0] scratch_13_wd;
  logic scratch_13_we;
  logic [31:0] scratch_14_qs;
  logic [31:0] scratch_14_wd;
  logic scratch_14_we;
  logic [31:0] scratch_15_qs;
  logic [31:0] scratch_15_wd;
  logic scratch_15_we;
  logic [1:0] boot_mode_qs;
  logic boot_mode_re;
  logic [31:0] rtc_freq_qs;
  logic rtc_freq_re;
  logic [31:0] platform_rom_qs;
  logic platform_rom_re;
  logic hw_features_bootrom_qs;
  logic hw_features_bootrom_re;
  logic hw_features_llc_qs;
  logic hw_features_llc_re;
  logic hw_features_uart_qs;
  logic hw_features_uart_re;
  logic hw_features_spi_host_qs;
  logic hw_features_spi_host_re;
  logic hw_features_i2c_qs;
  logic hw_features_i2c_re;
  logic hw_features_gpio_qs;
  logic hw_features_gpio_re;
  logic hw_features_dma_qs;
  logic hw_features_dma_re;
  logic hw_features_serial_link_qs;
  logic hw_features_serial_link_re;
  logic hw_features_vga_qs;
  logic hw_features_vga_re;
  logic hw_features_axirt_qs;
  logic hw_features_axirt_re;
  logic hw_features_clic_qs;
  logic hw_features_clic_re;
  logic hw_features_irq_router_qs;
  logic hw_features_irq_router_re;
  logic [31:0] llc_size_qs;
  logic llc_size_re;
  logic [7:0] vga_params_red_width_qs;
  logic vga_params_red_width_re;
  logic [7:0] vga_params_green_width_qs;
  logic vga_params_green_width_re;
  logic [7:0] vga_params_blue_width_qs;
  logic vga_params_blue_width_re;
  logic [31:0] num_harts_qs;
  logic num_harts_re;

  // Register instances

  // Subregister 0 of Multireg scratch
  // R[scratch_0]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_0 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_0_we),
    .wd     (scratch_0_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_0_qs)
  );

  // Subregister 1 of Multireg scratch
  // R[scratch_1]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_1 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_1_we),
    .wd     (scratch_1_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_1_qs)
  );

  // Subregister 2 of Multireg scratch
  // R[scratch_2]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_2 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_2_we),
    .wd     (scratch_2_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_2_qs)
  );

  // Subregister 3 of Multireg scratch
  // R[scratch_3]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_3 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_3_we),
    .wd     (scratch_3_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_3_qs)
  );

  // Subregister 4 of Multireg scratch
  // R[scratch_4]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_4 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_4_we),
    .wd     (scratch_4_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_4_qs)
  );

  // Subregister 5 of Multireg scratch
  // R[scratch_5]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_5 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_5_we),
    .wd     (scratch_5_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_5_qs)
  );

  // Subregister 6 of Multireg scratch
  // R[scratch_6]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_6 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_6_we),
    .wd     (scratch_6_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_6_qs)
  );

  // Subregister 7 of Multireg scratch
  // R[scratch_7]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_7 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_7_we),
    .wd     (scratch_7_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_7_qs)
  );

  // Subregister 8 of Multireg scratch
  // R[scratch_8]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_8 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_8_we),
    .wd     (scratch_8_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_8_qs)
  );

  // Subregister 9 of Multireg scratch
  // R[scratch_9]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_9 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_9_we),
    .wd     (scratch_9_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_9_qs)
  );

  // Subregister 10 of Multireg scratch
  // R[scratch_10]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_10 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_10_we),
    .wd     (scratch_10_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_10_qs)
  );

  // Subregister 11 of Multireg scratch
  // R[scratch_11]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_11 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_11_we),
    .wd     (scratch_11_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_11_qs)
  );

  // Subregister 12 of Multireg scratch
  // R[scratch_12]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_12 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_12_we),
    .wd     (scratch_12_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_12_qs)
  );

  // Subregister 13 of Multireg scratch
  // R[scratch_13]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_13 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_13_we),
    .wd     (scratch_13_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_13_qs)
  );

  // Subregister 14 of Multireg scratch
  // R[scratch_14]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_14 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_14_we),
    .wd     (scratch_14_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_14_qs)
  );

  // Subregister 15 of Multireg scratch
  // R[scratch_15]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_scratch_15 (
    .clk_i   (clk_i    ),
    .rst_ni  (rst_ni  ),

    // from register interface
    .we     (scratch_15_we),
    .wd     (scratch_15_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0  ),

    // to internal hardware
    .qe     (),
    .q      (),

    // to register interface (read)
    .qs     (scratch_15_qs)
  );


  // R[boot_mode]: V(True)

  prim_subreg_ext #(
    .DW    (2)
  ) u_boot_mode (
    .re     (boot_mode_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.boot_mode.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (boot_mode_qs)
  );


  // R[rtc_freq]: V(True)

  prim_subreg_ext #(
    .DW    (32)
  ) u_rtc_freq (
    .re     (rtc_freq_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.rtc_freq.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (rtc_freq_qs)
  );


  // R[platform_rom]: V(True)

  prim_subreg_ext #(
    .DW    (32)
  ) u_platform_rom (
    .re     (platform_rom_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.platform_rom.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (platform_rom_qs)
  );


  // R[hw_features]: V(True)

  //   F[bootrom]: 0:0
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_bootrom (
    .re     (hw_features_bootrom_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.bootrom.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_bootrom_qs)
  );


  //   F[llc]: 1:1
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_llc (
    .re     (hw_features_llc_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.llc.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_llc_qs)
  );


  //   F[uart]: 2:2
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_uart (
    .re     (hw_features_uart_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.uart.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_uart_qs)
  );


  //   F[spi_host]: 3:3
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_spi_host (
    .re     (hw_features_spi_host_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.spi_host.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_spi_host_qs)
  );


  //   F[i2c]: 4:4
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_i2c (
    .re     (hw_features_i2c_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.i2c.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_i2c_qs)
  );


  //   F[gpio]: 5:5
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_gpio (
    .re     (hw_features_gpio_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.gpio.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_gpio_qs)
  );


  //   F[dma]: 6:6
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_dma (
    .re     (hw_features_dma_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.dma.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_dma_qs)
  );


  //   F[serial_link]: 7:7
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_serial_link (
    .re     (hw_features_serial_link_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.serial_link.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_serial_link_qs)
  );


  //   F[vga]: 8:8
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_vga (
    .re     (hw_features_vga_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.vga.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_vga_qs)
  );


  //   F[axirt]: 9:9
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_axirt (
    .re     (hw_features_axirt_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.axirt.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_axirt_qs)
  );


  //   F[clic]: 10:10
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_clic (
    .re     (hw_features_clic_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.clic.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_clic_qs)
  );


  //   F[irq_router]: 11:11
  prim_subreg_ext #(
    .DW    (1)
  ) u_hw_features_irq_router (
    .re     (hw_features_irq_router_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.hw_features.irq_router.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (hw_features_irq_router_qs)
  );


  // R[llc_size]: V(True)

  prim_subreg_ext #(
    .DW    (32)
  ) u_llc_size (
    .re     (llc_size_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.llc_size.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (llc_size_qs)
  );


  // R[vga_params]: V(True)

  //   F[red_width]: 7:0
  prim_subreg_ext #(
    .DW    (8)
  ) u_vga_params_red_width (
    .re     (vga_params_red_width_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.vga_params.red_width.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (vga_params_red_width_qs)
  );


  //   F[green_width]: 15:8
  prim_subreg_ext #(
    .DW    (8)
  ) u_vga_params_green_width (
    .re     (vga_params_green_width_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.vga_params.green_width.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (vga_params_green_width_qs)
  );


  //   F[blue_width]: 23:16
  prim_subreg_ext #(
    .DW    (8)
  ) u_vga_params_blue_width (
    .re     (vga_params_blue_width_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.vga_params.blue_width.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (vga_params_blue_width_qs)
  );


  // R[num_harts]: V(True)

  prim_subreg_ext #(
    .DW    (32)
  ) u_num_harts (
    .re     (num_harts_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.num_harts.d),
    .qre    (),
    .qe     (),
    .q      (),
    .qs     (num_harts_qs)
  );




  logic [22:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[ 0] = (reg_addr == CHESHIRE_SCRATCH_0_OFFSET);
    addr_hit[ 1] = (reg_addr == CHESHIRE_SCRATCH_1_OFFSET);
    addr_hit[ 2] = (reg_addr == CHESHIRE_SCRATCH_2_OFFSET);
    addr_hit[ 3] = (reg_addr == CHESHIRE_SCRATCH_3_OFFSET);
    addr_hit[ 4] = (reg_addr == CHESHIRE_SCRATCH_4_OFFSET);
    addr_hit[ 5] = (reg_addr == CHESHIRE_SCRATCH_5_OFFSET);
    addr_hit[ 6] = (reg_addr == CHESHIRE_SCRATCH_6_OFFSET);
    addr_hit[ 7] = (reg_addr == CHESHIRE_SCRATCH_7_OFFSET);
    addr_hit[ 8] = (reg_addr == CHESHIRE_SCRATCH_8_OFFSET);
    addr_hit[ 9] = (reg_addr == CHESHIRE_SCRATCH_9_OFFSET);
    addr_hit[10] = (reg_addr == CHESHIRE_SCRATCH_10_OFFSET);
    addr_hit[11] = (reg_addr == CHESHIRE_SCRATCH_11_OFFSET);
    addr_hit[12] = (reg_addr == CHESHIRE_SCRATCH_12_OFFSET);
    addr_hit[13] = (reg_addr == CHESHIRE_SCRATCH_13_OFFSET);
    addr_hit[14] = (reg_addr == CHESHIRE_SCRATCH_14_OFFSET);
    addr_hit[15] = (reg_addr == CHESHIRE_SCRATCH_15_OFFSET);
    addr_hit[16] = (reg_addr == CHESHIRE_BOOT_MODE_OFFSET);
    addr_hit[17] = (reg_addr == CHESHIRE_RTC_FREQ_OFFSET);
    addr_hit[18] = (reg_addr == CHESHIRE_PLATFORM_ROM_OFFSET);
    addr_hit[19] = (reg_addr == CHESHIRE_HW_FEATURES_OFFSET);
    addr_hit[20] = (reg_addr == CHESHIRE_LLC_SIZE_OFFSET);
    addr_hit[21] = (reg_addr == CHESHIRE_VGA_PARAMS_OFFSET);
    addr_hit[22] = (reg_addr == CHESHIRE_NUM_HARTS_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = (reg_we &
              ((addr_hit[ 0] & (|(CHESHIRE_PERMIT[ 0] & ~reg_be))) |
               (addr_hit[ 1] & (|(CHESHIRE_PERMIT[ 1] & ~reg_be))) |
               (addr_hit[ 2] & (|(CHESHIRE_PERMIT[ 2] & ~reg_be))) |
               (addr_hit[ 3] & (|(CHESHIRE_PERMIT[ 3] & ~reg_be))) |
               (addr_hit[ 4] & (|(CHESHIRE_PERMIT[ 4] & ~reg_be))) |
               (addr_hit[ 5] & (|(CHESHIRE_PERMIT[ 5] & ~reg_be))) |
               (addr_hit[ 6] & (|(CHESHIRE_PERMIT[ 6] & ~reg_be))) |
               (addr_hit[ 7] & (|(CHESHIRE_PERMIT[ 7] & ~reg_be))) |
               (addr_hit[ 8] & (|(CHESHIRE_PERMIT[ 8] & ~reg_be))) |
               (addr_hit[ 9] & (|(CHESHIRE_PERMIT[ 9] & ~reg_be))) |
               (addr_hit[10] & (|(CHESHIRE_PERMIT[10] & ~reg_be))) |
               (addr_hit[11] & (|(CHESHIRE_PERMIT[11] & ~reg_be))) |
               (addr_hit[12] & (|(CHESHIRE_PERMIT[12] & ~reg_be))) |
               (addr_hit[13] & (|(CHESHIRE_PERMIT[13] & ~reg_be))) |
               (addr_hit[14] & (|(CHESHIRE_PERMIT[14] & ~reg_be))) |
               (addr_hit[15] & (|(CHESHIRE_PERMIT[15] & ~reg_be))) |
               (addr_hit[16] & (|(CHESHIRE_PERMIT[16] & ~reg_be))) |
               (addr_hit[17] & (|(CHESHIRE_PERMIT[17] & ~reg_be))) |
               (addr_hit[18] & (|(CHESHIRE_PERMIT[18] & ~reg_be))) |
               (addr_hit[19] & (|(CHESHIRE_PERMIT[19] & ~reg_be))) |
               (addr_hit[20] & (|(CHESHIRE_PERMIT[20] & ~reg_be))) |
               (addr_hit[21] & (|(CHESHIRE_PERMIT[21] & ~reg_be))) |
               (addr_hit[22] & (|(CHESHIRE_PERMIT[22] & ~reg_be)))));
  end

  assign scratch_0_we = addr_hit[0] & reg_we & !reg_error;
  assign scratch_0_wd = reg_wdata[31:0];

  assign scratch_1_we = addr_hit[1] & reg_we & !reg_error;
  assign scratch_1_wd = reg_wdata[31:0];

  assign scratch_2_we = addr_hit[2] & reg_we & !reg_error;
  assign scratch_2_wd = reg_wdata[31:0];

  assign scratch_3_we = addr_hit[3] & reg_we & !reg_error;
  assign scratch_3_wd = reg_wdata[31:0];

  assign scratch_4_we = addr_hit[4] & reg_we & !reg_error;
  assign scratch_4_wd = reg_wdata[31:0];

  assign scratch_5_we = addr_hit[5] & reg_we & !reg_error;
  assign scratch_5_wd = reg_wdata[31:0];

  assign scratch_6_we = addr_hit[6] & reg_we & !reg_error;
  assign scratch_6_wd = reg_wdata[31:0];

  assign scratch_7_we = addr_hit[7] & reg_we & !reg_error;
  assign scratch_7_wd = reg_wdata[31:0];

  assign scratch_8_we = addr_hit[8] & reg_we & !reg_error;
  assign scratch_8_wd = reg_wdata[31:0];

  assign scratch_9_we = addr_hit[9] & reg_we & !reg_error;
  assign scratch_9_wd = reg_wdata[31:0];

  assign scratch_10_we = addr_hit[10] & reg_we & !reg_error;
  assign scratch_10_wd = reg_wdata[31:0];

  assign scratch_11_we = addr_hit[11] & reg_we & !reg_error;
  assign scratch_11_wd = reg_wdata[31:0];

  assign scratch_12_we = addr_hit[12] & reg_we & !reg_error;
  assign scratch_12_wd = reg_wdata[31:0];

  assign scratch_13_we = addr_hit[13] & reg_we & !reg_error;
  assign scratch_13_wd = reg_wdata[31:0];

  assign scratch_14_we = addr_hit[14] & reg_we & !reg_error;
  assign scratch_14_wd = reg_wdata[31:0];

  assign scratch_15_we = addr_hit[15] & reg_we & !reg_error;
  assign scratch_15_wd = reg_wdata[31:0];

  assign boot_mode_re = addr_hit[16] & reg_re & !reg_error;

  assign rtc_freq_re = addr_hit[17] & reg_re & !reg_error;

  assign platform_rom_re = addr_hit[18] & reg_re & !reg_error;

  assign hw_features_bootrom_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_llc_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_uart_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_spi_host_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_i2c_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_gpio_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_dma_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_serial_link_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_vga_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_axirt_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_clic_re = addr_hit[19] & reg_re & !reg_error;

  assign hw_features_irq_router_re = addr_hit[19] & reg_re & !reg_error;

  assign llc_size_re = addr_hit[20] & reg_re & !reg_error;

  assign vga_params_red_width_re = addr_hit[21] & reg_re & !reg_error;

  assign vga_params_green_width_re = addr_hit[21] & reg_re & !reg_error;

  assign vga_params_blue_width_re = addr_hit[21] & reg_re & !reg_error;

  assign num_harts_re = addr_hit[22] & reg_re & !reg_error;

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[31:0] = scratch_0_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[31:0] = scratch_1_qs;
      end

      addr_hit[2]: begin
        reg_rdata_next[31:0] = scratch_2_qs;
      end

      addr_hit[3]: begin
        reg_rdata_next[31:0] = scratch_3_qs;
      end

      addr_hit[4]: begin
        reg_rdata_next[31:0] = scratch_4_qs;
      end

      addr_hit[5]: begin
        reg_rdata_next[31:0] = scratch_5_qs;
      end

      addr_hit[6]: begin
        reg_rdata_next[31:0] = scratch_6_qs;
      end

      addr_hit[7]: begin
        reg_rdata_next[31:0] = scratch_7_qs;
      end

      addr_hit[8]: begin
        reg_rdata_next[31:0] = scratch_8_qs;
      end

      addr_hit[9]: begin
        reg_rdata_next[31:0] = scratch_9_qs;
      end

      addr_hit[10]: begin
        reg_rdata_next[31:0] = scratch_10_qs;
      end

      addr_hit[11]: begin
        reg_rdata_next[31:0] = scratch_11_qs;
      end

      addr_hit[12]: begin
        reg_rdata_next[31:0] = scratch_12_qs;
      end

      addr_hit[13]: begin
        reg_rdata_next[31:0] = scratch_13_qs;
      end

      addr_hit[14]: begin
        reg_rdata_next[31:0] = scratch_14_qs;
      end

      addr_hit[15]: begin
        reg_rdata_next[31:0] = scratch_15_qs;
      end

      addr_hit[16]: begin
        reg_rdata_next[1:0] = boot_mode_qs;
      end

      addr_hit[17]: begin
        reg_rdata_next[31:0] = rtc_freq_qs;
      end

      addr_hit[18]: begin
        reg_rdata_next[31:0] = platform_rom_qs;
      end

      addr_hit[19]: begin
        reg_rdata_next[0] = hw_features_bootrom_qs;
        reg_rdata_next[1] = hw_features_llc_qs;
        reg_rdata_next[2] = hw_features_uart_qs;
        reg_rdata_next[3] = hw_features_spi_host_qs;
        reg_rdata_next[4] = hw_features_i2c_qs;
        reg_rdata_next[5] = hw_features_gpio_qs;
        reg_rdata_next[6] = hw_features_dma_qs;
        reg_rdata_next[7] = hw_features_serial_link_qs;
        reg_rdata_next[8] = hw_features_vga_qs;
        reg_rdata_next[9] = hw_features_axirt_qs;
        reg_rdata_next[10] = hw_features_clic_qs;
        reg_rdata_next[11] = hw_features_irq_router_qs;
      end

      addr_hit[20]: begin
        reg_rdata_next[31:0] = llc_size_qs;
      end

      addr_hit[21]: begin
        reg_rdata_next[7:0] = vga_params_red_width_qs;
        reg_rdata_next[15:8] = vga_params_green_width_qs;
        reg_rdata_next[23:16] = vga_params_blue_width_qs;
      end

      addr_hit[22]: begin
        reg_rdata_next[31:0] = num_harts_qs;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be = ^reg_be;

  // Assertions for Register Interface
  `ASSERT(en2addrHit, (reg_we || reg_re) |-> $onehot0(addr_hit))

endmodule

module cheshire_reg_top_intf
#(
  parameter int AW = 7,
  localparam int DW = 32
) (
  input logic clk_i,
  input logic rst_ni,
  REG_BUS.in  regbus_slave,
  // To HW
  input  cheshire_reg_pkg::cheshire_hw2reg_t hw2reg, // Read
  // Config
  input devmode_i // If 1, explicit error return for unmapped register access
);
 localparam int unsigned STRB_WIDTH = DW/8;

`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

  // Define structs for reg_bus
  typedef logic [AW-1:0] addr_t;
  typedef logic [DW-1:0] data_t;
  typedef logic [STRB_WIDTH-1:0] strb_t;
  `REG_BUS_TYPEDEF_ALL(reg_bus, addr_t, data_t, strb_t)

  reg_bus_req_t s_reg_req;
  reg_bus_rsp_t s_reg_rsp;
  
  // Assign SV interface to structs
  `REG_BUS_ASSIGN_TO_REQ(s_reg_req, regbus_slave)
  `REG_BUS_ASSIGN_FROM_RSP(regbus_slave, s_reg_rsp)

  

  cheshire_reg_top #(
    .reg_req_t(reg_bus_req_t),
    .reg_rsp_t(reg_bus_rsp_t),
    .AW(AW)
  ) i_regs (
    .clk_i,
    .rst_ni,
    .reg_req_i(s_reg_req),
    .reg_rsp_o(s_reg_rsp),
    .hw2reg, // Read
    .devmode_i
  );
  
endmodule


