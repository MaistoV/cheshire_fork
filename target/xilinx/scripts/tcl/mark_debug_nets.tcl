# Copyright 2018 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Author: Vincenzo Maisto <vincenzo.maisto2@unina.it>

# Mark target debug nets
# NOTE: these nets must have been preserved during synthesis
set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/axi_req_o*                ]
set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/axi_resp_i*               ]
# set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/fetch_entry_if_id*        ]
set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/pc_commit*                ]
set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/commit_stage_i/exception_o*]
set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/commit_stage_i/commit_instr_i*]
set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/csr_regfile_i/mepc_q*/Q   ]]
set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/csr_regfile_i/mcause_q*/Q ]]
set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/csr_regfile_i/mtval_q*/Q  ]]
set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/csr_regfile_i/cycle_q*/Q  ]]

if { $::env(ARA) eq "1" } {
  # TODO?: unpack these to probe only the necessary signals
  set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_ara/acc_req_i* ]
  set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_ara/acc_resp_o*]
  set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_ara/axi_req_o* ]
  set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_ara/axi_resp_i*]

  # MMU-related ports
  # this is still under developement
  catch {
      set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_ara/mmu* ]
      set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_ara/en_ld_st_translation_i ]
  } errmsg;

  # Internal ports
  # this is still under developement
  catch {
    # ara_dispatcher
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/ara_req_o         ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/ara_req_valid_o   ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/ara_req_ready_i   ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/ara_resp_i        ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/ara_resp_valid_i  ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/ara_idle_i        ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/core_st_pending_o ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/load_complete_i   ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/store_complete_i  ]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/store_pending_i   ]]
    # addrgen
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/i_vlsu/i_addrgen/state_q_reg*/Q]]
    set_property MARK_DEBUG 1 [get_nets -of [get_pins i_cheshire_soc/gen_cva6_cores[0].i_ara/i_vlsu/i_addrgen/axi_addrgen_state_q_reg*/Q]]
  } errmsg;
}

# MMU, same as CVA6 mmu.sv for now
# set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/ex_stage_i/lsu_i/gen_mmu_sv39.i_cva6_mmu/req_port_i*           ]
# set_property MARK_DEBUG 1 [get_nets i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/ex_stage_i/lsu_i/gen_mmu_sv39.i_cva6_mmu/req_port_o*           ]
# set_property MARK_DEBUG 1 [get_pets -of get_nets [i_cheshire_soc/gen_cva6_cores[0].i_core_cva6/ex_stage_i/lsu_i/gen_mmu_sv39.i_cva6_mmu/i_ptw ]   ]
