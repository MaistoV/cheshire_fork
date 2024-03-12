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

#warning "This test does not check for untouched memory"

#define BIT_SHIFT         5
#define INDEXED_MEM_SIZE  ( RVV_TEST_AVL(64) << BIT_SHIFT )

int main(void) {
    // Vector configuration parameters and variables
    // uint64_t avl = RVV_TEST_AVL(64);
    uint64_t avl = 16;
    uint64_t vl;
    vcsr_dump_t vcsr_state = {0};

    // Helper variables and arrays
    uint64_t array_load [INDEXED_MEM_SIZE]; // oversize this
    uint64_t array_store[INDEXED_MEM_SIZE]; // oversize this

    uint64_t* address_load = array_load;
    uint64_t* address_store = array_store;
    uint64_t store_val, preload_val, prestart_val;

    // Simplification: EEW-wide indexes
    uint64_t array_index [RVV_TEST_AVL(64)] ;
    uint64_t* address_index = array_index;

    // Enalbe RVV
    enable_rvv();
    vcsr_dump ( vcsr_state );

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // START OF TESTS
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////
    // TEST: Zero and non-zero vstart indexed load
    //////////////////////////////////////////////////////////////////
    RVV_TEST_INIT( vl, avl );

    // Loop over vstart values
    for ( uint64_t vstart_val = 0; vstart_val < vl; vstart_val++ ) {
      RVV_TEST_INIT( vl, avl );

      preload_val = -1;
      prestart_val = -2;

      // Init source memory
      for ( uint64_t i = 0; i < INDEXED_MEM_SIZE; i++ ) {
          address_load[i] = preload_val;
      }
      // Init index memory
      for ( uint64_t i = 0; i < vl; i++ ) {
          // Constrain the target memory space to +/- (2^BIT_SHIFT)*sizeof(uint64_t) bytes
          // NOTE: to ease testing, indexes should not overlap
          // NOTE: simplification, align offsets to 64-bits words
          // address_index[i] = (((2 << BIT_SHIFT) -1) & ( vstart_val + vl + i )) * sizeof(uint64_t);
          address_index[i] = i * sizeof(uint64_t);
      }
      // Compose a mask for indexed memory:
      //  - 0: the element must to be left untouched
      //  - 1: the element is a target
      uint8_t bit_mask_indexed [INDEXED_MEM_SIZE] = {0};
      for ( uint64_t i = 0; i < vl; i++ ) {
        // Check for overlapping indexes
        if ( bit_mask_indexed[ address_index[ i ] ] == 1 ) {
          RVV_TEST_ASSERT ( 0 );
        }
        bit_mask_indexed[ address_index[ i ] ] = 1;
      }
      // Init indexed memory
      for ( uint64_t i = 0; i < vl; i++ ) {
          *( ((uint8_t*)address_load) + address_index[i] ) = vstart_val + vl + i;
      }

      // Load index array
      asm volatile ("vle64.v	v0   , (%0)" : "+&r"(address_index));

      // Load prestart
      asm volatile ("vmv.v.x	v24   , %0" :: "r"(prestart_val));

      // Set vstart
      asm volatile ("csrs     vstart, %0"   :: "r"(vstart_val) );
      // Test target: load (gather) vr group body from indexed memory
      asm volatile ("vluxei64.v	v24   , (%0), v0" : "+&r"(address_load));

      // Store whole vr group back to memory
      asm volatile ("vse64.v	v24   , (%0)" : "+&r"(address_store));

      // Check pre-start
      for ( uint64_t i = 0; i < vstart_val; i++ ) {
          RVV_TEST_ASSERT ( address_store[i] == prestart_val );
      }
      // Check body
      for ( uint64_t i = vstart_val; i < vl; i++ ) {
          RVV_TEST_ASSERT ( address_store[i] == *( ((uint8_t*)address_load) + address_index[i] ) );
      }

      RVV_TEST_CLEANUP();
    }

    //////////////////////////////////////////////////////////////////
    // TEST: Zero and non-zero vstart indexed stores
    //////////////////////////////////////////////////////////////////
    RVV_TEST_INIT( vl, avl );

    // Loop over vstart values
    for ( uint64_t vstart_val = 0; vstart_val < vl; vstart_val++ ) {
      RVV_TEST_INIT( vl, avl );

      preload_val = 1;

      // Init index memory
      for ( uint64_t i = 0; i < vl; i++ ) {
          // Constrain the target memory space to +/- X*sizeof(uint64_t) bytes
          // NOTE: to ease testing, indexes should not overlap
          // NOTE: simplification, align offsets to 64-bits words
          // address_index[i] = (((2 << BIT_SHIFT) -1) & ( vstart_val + vl + i )) * sizeof(uint64_t);
          address_index[i] = i * sizeof(uint64_t);
      }
      // Compose a mask for indexed memory:
      //  - 0: the element must to be left untouched
      //  - 1: the element is a target
      uint8_t bit_mask_indexed [INDEXED_MEM_SIZE] = {0};
      for ( uint64_t i = 0; i < vl; i++ ) {
        // Check for overlapping indexes
        if ( bit_mask_indexed[ address_index[ i ] ] == 1 ) {
          RVV_TEST_ASSERT ( 0 );
        }
        bit_mask_indexed[ address_index[ i ] ] = 1;
      }
      // Init source memory
      for ( uint64_t i = 0; i < vl; i++ ) {
        address_load[i] = vstart_val + vl + i;
      }
      // Init whole target memory
      for ( uint64_t i = 0; i < INDEXED_MEM_SIZE; i++ ) {
        address_store[i] = preload_val;
      }

      // Load index array
      asm volatile ("vle64.v	v0   , (%0)" : "+&r"(address_index));

      // Load data
      asm volatile ("vle64.v	v24   , (%0)" : "+&r"(address_load));
      // Set vstart
      asm volatile ("csrs       vstart, %0"   :: "r"(vstart_val) );
      // Test target: store (scatter) vr group body to indexed memory
      asm volatile ("vsuxei64.v	v24   , (%0), v0" : "+&r"(address_store));

      // Check pre-start
      for ( uint64_t i = 0; i < vstart_val; i++ ) {
        uint64_t* dest_addr = (uint64_t*)( ((uint8_t*)address_store) + address_index[i] );
        RVV_TEST_ASSERT ( *dest_addr == preload_val );
      }
      // Check body
      for ( uint64_t i = vstart_val; i < vl; i++ ) {
        uint64_t* dest_addr = (uint64_t*)( ((uint8_t*)address_store) + address_index[i] );
        RVV_TEST_ASSERT ( *dest_addr == address_load[i] );
      }
      // Check untouched memory
      for ( uint64_t i = 0; i < INDEXED_MEM_SIZE; i++ ) {
          if ( bit_mask_indexed == 0 ) {
            RVV_TEST_ASSERT ( address_store[i] == preload_val );
          }
      }

      RVV_TEST_CLEANUP();
    }

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // END OF TESTS
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

  return 0;
}
