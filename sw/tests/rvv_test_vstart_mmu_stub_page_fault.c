// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Vincenzo Maisto <vincenzo.maisto2@unina.it>

#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"
#include "encoding.h"
#include "rvv_test.h"

int main(void) {

    // Vector configuration parameters and variables
    uint64_t avl = RVV_TEST_AVL(64);
    uint64_t vl, vstart_read;
    vcsr_dump_t vcsr_state = {0};

    // Helper variables and arrays
    uint64_t array_load [VLMAX];
    uint64_t array_store [VLMAX];
    uint64_t* address_load = array_load;
    uint64_t* address_store = array_store;

    // Enalbe RVV
    enable_rvv();
    vcsr_dump ( vcsr_state );

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // START OF TESTS
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////
    // TEST: Exception generation: vector load
    //////////////////////////////////////////////////////////////////
    // RVV_TEST_INIT( vl, avl );

    // asm volatile ("vle64.v	v0   , (%0)" : "+&r"(address_load));
    // RVV_TEST_ASSERT_EXCEPTION_EXTENDED(1, address_load, CAUSE_LOAD_PAGE_FAULT)
    // RVV_TEST_CLEAN_EXCEPTION()
    
    // RVV_TEST_CLEANUP();

    // //////////////////////////////////////////////////////////////////
    // // TEST: Exception generation: vector store
    // //////////////////////////////////////////////////////////////////
    // RVV_TEST_INIT( vl, avl );

    // asm volatile ("vse64.v	v0   , (%0)" : "+&r"(address_store));
    // RVV_TEST_ASSERT_EXCEPTION_EXTENDED(1, address_store, CAUSE_STORE_PAGE_FAULT)
    // RVV_TEST_CLEAN_EXCEPTION()
    
    // RVV_TEST_CLEANUP();
    
    //////////////////////////////////////////////////////////////////
    // TEST: Exception generation and non-zero vstart: vector load
    //////////////////////////////////////////////////////////////////
    // RVV_TEST_INIT( vl, avl );

    // // Loop over vstart values
    // for ( uint64_t vstart_val = 0; vstart_val < vl; vstart_val++ ) {
    //   RVV_TEST_INIT( vl, avl );

    //   asm volatile ("csrs     vstart, %0"   :: "r"(vstart_val) );
    //   asm volatile ("vle64.v	v0   , (%0)" : "+&r"(address_load));
    //   RVV_TEST_ASSERT_EXCEPTION_EXTENDED(1, address_load + vstart_val, CAUSE_LOAD_PAGE_FAULT)
    //   RVV_TEST_CLEAN_EXCEPTION()

    //   vstart_read = -1;
    //   asm volatile ("csrr  %0, vstart"  : "=r"(vstart_read) );
    //   RVV_TEST_ASSERT ( vstart_read == vstart_val )
    
    //   RVV_TEST_CLEANUP();
    // }

    //////////////////////////////////////////////////////////////////
    // TEST: Exception generation and non-zero vstart: vector store
    //////////////////////////////////////////////////////////////////
    RVV_TEST_INIT( vl, avl );

    // Loop over vstart values
    for ( uint64_t vstart_val = 0; vstart_val < vl; vstart_val++ ) {
      RVV_TEST_INIT( vl, avl );

      asm volatile ("csrs     vstart, %0"   :: "r"(vstart_val) );
      asm volatile ("vse64.v	v0   , (%0)" : "+&r"(address_store));
      RVV_TEST_ASSERT_EXCEPTION_EXTENDED(1, address_store + vstart_val, CAUSE_STORE_PAGE_FAULT)
      RVV_TEST_CLEAN_EXCEPTION()

      vstart_read = -1;
      asm volatile ("csrr  %0, vstart"  : "=r"(vstart_read) );
      RVV_TEST_ASSERT ( vstart_read == vstart_val )
    
      RVV_TEST_CLEANUP();
    }

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // END OF TESTS
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

RVV_TEST_pass:
    RVV_TEST_PASSED() 

RVV_TEST_error:
    RVV_TEST_FAILED()
  
  return 0;
}
