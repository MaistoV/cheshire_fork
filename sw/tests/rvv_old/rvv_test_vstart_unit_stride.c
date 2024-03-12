// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Vincenzo Maisto <vincenzo.maisto2@unina.it>
// Matteo Perotti  <mperotti@iis.ee.ethz.ch>

// Disable virtual memory
#define param_stub_virt_mem 0

// Fixed req-rsp latency of 1 cycle
#define param_stub_req_rsp_lat_ctrl 0
#define param_stub_req_rsp_lat      1

// Test body
#include "rvv_test_vstart_unit_stride.c.body"
