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

#define ELEM_STRIDE_MAX 3

int main(void) {
    // Vector configuration parameters and variables
    uint64_t avl = RVV_TEST_AVL(64);
    uint64_t vl;
    vcsr_dump_t vcsr_state = {0};

    // Helper variables and arrays
    uint64_t array_load [RVV_TEST_AVL(64) * ELEM_STRIDE_MAX] ;
    uint64_t array_store[RVV_TEST_AVL(64) * ELEM_STRIDE_MAX];
    uint64_t* address_load = array_load;
    uint64_t* address_store = array_store;
    uint64_t store_val, preload_val, byte_stride, elem_stride;

    // Enalbe RVV
    enable_rvv();
    vcsr_dump ( vcsr_state );

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // START OF TESTS
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////
    // TEST: Non-zero stride, zero and non-zero vstart strided load
    //////////////////////////////////////////////////////////////////

    // Loop over stride values
    for ( uint64_t elem_stride = 1; elem_stride <= ELEM_STRIDE_MAX; elem_stride++ ) {
        RVV_TEST_INIT( vl, avl );

        // Loop over vstart values
        for ( uint64_t vstart_val = 0; vstart_val < vl; vstart_val++ ) {
            RVV_TEST_INIT( vl, avl );

            preload_val = -1;
            // Simplification: EEW-aligned strides for simpler memory checking
            byte_stride = sizeof(uint64_t) * elem_stride; // EEW=64

            // Init memory contiguosly
            for ( uint64_t i = 0; i < (vl * elem_stride); i++ ) {
                address_load[i] = preload_val;
            }
            // Init VRF with prestart
            asm volatile ("vle64.v	v24    , (%0)" : "+&r"(address_load));

            // Init strided memory
            for ( uint64_t i = 0; i < vl; i++ ) {
                address_load[ i * elem_stride ] = vstart_val + vl + i;
            }

            // Set vstart
            asm volatile ("csrs     vstart, %0"   :: "r"(vstart_val) );
            // Test target: load vr group body
            asm volatile ("vlse64.v	v24   , (%0), %1" : "+&r"(address_load) : "r"(byte_stride));
            // Store whole vr group back to memory
            asm volatile ("vse64.v	v24   , (%0)" : "+&r"(address_store));

            // Check pre-start
            for ( uint64_t i = 0; i < vstart_val; i++ ) {
                RVV_TEST_ASSERT ( address_store[i] == preload_val );
            }
            // Check body
            for ( uint64_t i = vstart_val; i < vl; i++ ) {
                RVV_TEST_ASSERT ( address_store[i] == address_load[i * elem_stride] );
            }

        RVV_TEST_CLEANUP();
        }

        RVV_TEST_CLEANUP();
    }

    //////////////////////////////////////////////////////////////////
    // TEST: Non-zero stride, zero and non-zero vstart strided stores
    //////////////////////////////////////////////////////////////////

    // Loop over stride values
    for ( uint64_t elem_stride = 1; elem_stride <= ELEM_STRIDE_MAX; elem_stride++ ) {
        RVV_TEST_INIT( vl, avl );

        // Loop over vstart values
        for ( uint64_t vstart_val = 0; vstart_val < vl; vstart_val++ ) {
            RVV_TEST_INIT( vl, avl );

            // Simplify to EEW-aligned strides for untouched memory checking
            byte_stride = sizeof(uint64_t) * elem_stride; // EEW=64
            uint64_t preload_val = vstart_val;

            // Init target memory contiguosly
            for ( uint64_t i = 0; i < (vl * elem_stride); i++ ) {
                address_store[i] = preload_val;
            }

            // Init source memory
            for ( uint64_t i = 0; i < vl; i++ ) {
                address_load[i] = vl + vstart_val + i;
            }

            // Load data
            asm volatile ("vle64.v	v24   , (%0)" : "+&r"(address_load));
            asm volatile ("csrs     vstart, %0"   :: "r"(vstart_val) );
            // Store back stirded
            asm volatile ("vsse64.v	v24   , (%0), %1" : "+&r"(address_store) : "r"(byte_stride));

            // Check pre-start
            for ( uint64_t i = 0; i < vstart_val; i++ ) {
                RVV_TEST_ASSERT ( ( address_store[ i * elem_stride ] == preload_val ) );
            }
            // Check body
            for ( uint64_t i = vstart_val; i < vl; i++ ) {
                RVV_TEST_ASSERT ( ( address_store[ i * elem_stride ] == address_load[i] ) );
            }
            // Check untouched memory
            for ( uint64_t i = 0; i < (vl * elem_stride); i++ ) {
                if ( ( i % elem_stride ) != 0 ) {
                    RVV_TEST_ASSERT( ( address_store[i] == preload_val ) );
                }
            }

            RVV_TEST_CLEANUP();
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
