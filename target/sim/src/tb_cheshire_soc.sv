// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

module tb_cheshire_soc;

  fixture_cheshire_soc fix();

  string      preload_elf;
  string      boot_hex;
  logic [1:0] boot_mode;
  logic [1:0] preload_mode;
  bit [31:0]  exit_code;

  initial begin
    // Fetch plusargs or use safe (fail-fast) defaults
    if (!$value$plusargs("BOOTMODE=%d", boot_mode))     boot_mode     = 0;
    if (!$value$plusargs("PRELMODE=%d", preload_mode))  preload_mode  = 0;
    if (!$value$plusargs("BINARY=%s",   preload_elf))   preload_elf   = "";
    if (!$value$plusargs("IMAGE=%s",    boot_hex))      boot_hex      = "";

    // Set boot mode and preload boot image if there is one
    fix.vip.set_boot_mode(boot_mode);
    fix.vip.i2c_eeprom_preload(boot_hex);
    fix.vip.spih_norflash_preload(boot_hex);

    // Wait for reset
    fix.vip.wait_for_reset();

    // Preload in idle mode or wait for completion in autonomous boot
    if (boot_mode == 0) begin
      // Idle boot: preload with the specified mode
      case (preload_mode)
        0: begin      // JTAG
          fix.vip.jtag_init();
          fix.vip.jtag_elf_run(preload_elf);
          // "fix.vip.jtag_wait_for_eoc(exit_code);" does not work,
          // probably because of a bug in CVA6. Use this trick instead.
          wait(tb_cheshire_soc.fix.dut.i_regs.u_scratch_2.q[0] == 1'b1);
          exit_code = tb_cheshire_soc.fix.dut.i_regs.u_scratch_2.q >> 1;
          if (|exit_code) begin
            $error("[JTAG] FAILED: return code %0d", exit_code);
          end else begin
            $display("[JTAG] SUCCESS");
          end
        end 1: begin  // Serial Link
          fix.vip.slink_elf_run(preload_elf);
          fix.vip.slink_wait_for_eoc(exit_code);
        end 2: begin  // UART
          fix.vip.uart_debug_elf_run_and_wait(preload_elf, exit_code);
        end default: begin
          $fatal(1, "Unsupported preload mode %d (reserved)!", boot_mode);
        end
      endcase
    end else if (boot_mode == 1) begin
      $fatal(1, "Unsupported boot mode %d (SD Card)!", boot_mode);
    end else begin
      // Autonomous boot: Only poll return code
      fix.vip.jtag_init();
      fix.vip.jtag_wait_for_eoc(exit_code);
    end

    $finish;
  end

     // Stop the simulation after a maximum number of cycles where the
   // program counter do not change
   int unsigned count;
   logic [63:0] old_pc;
   logic stop, start;
   localparam AFTER_TIME_PS = 100;
   localparam MAX_CYCLES = 10000;
   initial begin
        stop = 1'b0;
        start = 1'b0;
        count = 0;

        // Wait for the first instruction to commit
        wait ( fix.dut.gen_cva6_cores[0].i_core_cva6.commit_stage_i.commit_ack_o[0] == 1'b1 );
        start = 1'b1;

        while ( stop == 1'b0 )  begin
            // Count the cycles
            while ( count < MAX_CYCLES ) begin
                // Wait for a clock cycle
                @(posedge fix.clk);
                // If the current pc matches the previous one
                if ( old_pc == fix.dut.gen_cva6_cores[0].i_core_cva6.commit_stage_i.pc_o ) begin
                    count++;
                end
                else begin
                    // Reset the counter
                    old_pc = fix.dut.gen_cva6_cores[0].i_core_cva6.commit_stage_i.pc_o;
                    count = 0;
                end
            end

            // Pause the simulation
            $warning("DEBUG: Program Counter hanging for %d cycles at: 0x%h\n", MAX_CYCLES, fix.dut.gen_cva6_cores[0].i_core_cva6.commit_stage_i.pc_o);
            stop = 1'b1;
            // Wait for some time before autonomously stoppig the simulation
            // (e.g. a wrapper tb might want to do some post-execution elaboration)
            # AFTER_TIME_PS;
            $warning("DEBUG: Simulation has not been stopped yet, stopping now\n");
            $finish(0);
    end

   end

endmodule
