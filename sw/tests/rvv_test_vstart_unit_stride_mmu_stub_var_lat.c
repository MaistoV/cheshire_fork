// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Matteo Perotti <mperotti@iis.ee.ethz.ch>

// No exceptions are generated
// Variable response latency from 0 to 10 cycles
#define param_stub_ex          0
#define param_stub_ex_rate     0
#define param_stub_req_rsp_lat 10
#define param_stub_req_rsp_rnd 1

// Test body
#include "rvv_test_vstart_unit_stride.c.body"