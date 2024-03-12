// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
//
// Simple payload to test bootmodes

#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"
#include "encoding.h"

int main(void) {
    // char str[] = "Hello, attempting to run some vector instructions!\r\n";
    // uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
    // uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
    // uart_init(&__base_uart, reset_freq, 115200);
    // uart_write_str(&__base_uart, str, sizeof(str));
    // uart_write_flush(&__base_uart);

    // First set MSTATUS.VS
    asm volatile (" li      t0, %0       " :: "i"(MSTATUS_FS | MSTATUS_XS | MSTATUS_VS));
    asm volatile (" csrs    mstatus, t0" );

    // Run some vector instructions here
    // Vector configuration
    #define AVL 32
    uint64_t vl;
    asm volatile("li        t0 ,  %0" :: "i"(32));
    asm volatile("vsetvli   %0, t0, e64, m8, ta, ma" : "=r"(vl));

    //////////////////////////////////////////////////////////////////
    // TEST: These instructions should WB asap to ROB
    //////////////////////////////////////////////////////////////////
    asm volatile("fence");

    // Vector permutation/arithmetic
    asm volatile("vmv.v.i   v0 ,  1");
    asm volatile("vadd.vv   v16, v0, v0");

    //////////////////////////////////////////////////////////////////
    // TEST: These intructions should WB to CVA6 only after WB from PEs
    //////////////////////////////////////////////////////////////////
    asm volatile("fence");

    // Allocate array in memory
    uint64_t array [AVL];
    uint64_t* address = array;
    // initialize
    for ( uint64_t i = 0; i < AVL; i++ ) {
        array[i] = -i;
    }

    // * OpcodeLoadFp, OpcodeStoreFp

    // Vector load
    asm volatile("vle64.v	v24, (%0)" : "+&r"(address));

    // Vector store
    asm volatile("vse64.v	v16, (%0)" : "+&r"(address));

    // Vector load
    asm volatile("vle64.v	v8 , (%0)" : "+&r"(address));

    // 64-bit return value
    uint64_t rd = 0;
    // 64-bit FP return value
    double fd = 0;

    asm volatile ("vfmv.f.s     %0, v0  " : "=fr"(fd));    // f[rd] = vs2[0] (rs1=0)
    asm volatile ("vmv.x.s      %0, v8  " : "=r"(rd));    //x[rd] = vs2[0] (vs1=0)
    asm volatile ("vpopc.m      %0, v16 " : "=r"(rd));
    asm volatile ("vfirst.m     %0, v24 " : "=r"(rd));

    // * for instructions which could trap, Ara stalls until its backend com
    // These should trap in dispatcher
    asm volatile ("csrs         vstart, 1");
    asm volatile ("vpopc.m      %0, v16 " : "=r"(rd));

    asm volatile ("csrs         vstart, 1");
    asm volatile ("vfirst.m     %0, v24 " : "=r"(rd));

    //////////////////////////////////////////////////////////////////
    // TEST: Chaining
    //////////////////////////////////////////////////////////////////
    asm volatile("fence");
    
    // Re-initialize input
    for ( uint64_t i = 0; i < AVL; i++ ) {
        array[i] = -i;
    }
    // Allocate and init output
    uint64_t array_dst [AVL] = {0};
    uint64_t* address_dst = array_dst;

    // Load, Op, Store
    asm volatile ("vle64.v	v24, (%0)" : "+&r"(address));
    asm volatile ("vadd.vv   v0, v24, v24");
    asm volatile ("vse64.v	v0, (%0)" : "+&r"(address_dst));



    //////////////////////////////////////////////////////////////////
    // TEST: These intructions should WB to CVA6 only after WB from PEs
    //////////////////////////////////////////////////////////////////
    asm volatile("fence");

    uint64_t vstart_read = -1;
    // CSR <-> vector instrucitons
    asm volatile ("csrs         vstart, 1");
    asm volatile ("vadd.vv       v0, v24, v24");
    // vstart_read should be 0
    asm volatile ("csrr         %0, vstart" : "=r"(vstart_read));

    // TODO?: add other tests from MSc thesis

    return 0;
}
