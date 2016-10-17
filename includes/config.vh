/*
You can defines these macros...
IRQ_EN - Bench only. Gives periodic IRQs.
SIM - Bench only. Be more verbose
 */

`timescale 1ns/1ps

`ifndef IRQ_EN
        `define IRQ_EN
`endif

`ifndef SIM
        `define SIM
`endif

`ifndef VCD_FILE_PATH
        `define VCD_FILE_PATH "/tmp/zap.vcd"
`endif

`ifndef MEMORY_IMAGE
        `define MEMORY_IMAGE "/tmp/prog.v"
`endif

`ifndef MAX_CLOCK_CYCLES
        `define MAX_CLOCK_CYCLES 100000
`endif

`ifndef SEED
        `define SEED 32'h12345678
`endif