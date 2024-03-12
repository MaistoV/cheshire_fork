if { $::env(MMU_STUB) eq "1"} {
    add wave -group mmu_stub sim:/tb_cheshire_soc/fix/dut/gen_cva6_cores[0].i_mmu_stub/*
    add wave -group mmu_req_gen sim:/tb_cheshire_soc/fix/dut/gen_cva6_cores[0].i_mmu_req_gen/*
    add wave -position insertpoint sim:/tb_cheshire_soc/fix/dut/i_regs/u_rvv_debug_reg/*
}
run -a
