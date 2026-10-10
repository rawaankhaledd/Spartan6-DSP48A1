# Spartan-6 DSP48A1 Slice in Verilog

A parameterizable RTL model of the Xilinx **Spartan-6 DSP48A1** DSP slice, written in Verilog and taken through the complete digital design flow: simulation, elaboration, synthesis, implementation, and linting.

> Digital IC Design project, 2025 – Rawan Khaled

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Module Details](#module-details)
- [OPMODE Reference](#opmode-reference)
- [Verification](#verification)
- [How to Run the Simulation](#how-to-run-the-simulation)
- [Synthesis & Implementation Results](#synthesis--implementation-results)
- [Linting](#linting)
- [Tools Used](#tools-used)
- [Author](#author)

---

## Overview

The DSP48A1 is the arithmetic building block of the Spartan-6 family. It combines an input pre-adder/subtractor, an 18x18 multiplier, and a 48-bit post-adder/subtractor, with optional pipeline registers at every stage and flexible data routing controlled by an 8-bit `OPMODE`.

This project implements the slice following the datasheet (UG389) and includes:

- Fully parameterized pipeline registers and input/carry selection
- Synchronous or asynchronous reset, selectable by parameter
- Cascade support through `BCIN`/`BCOUT` and `PCIN`/`PCOUT`
- A self-checking testbench covering reset behavior and four DSP datapaths
- A Questasim run script (`.do` file)
- Vivado elaboration, synthesis, and implementation with timing and utilization reports
- Questa Lint analysis

## Architecture

```
          D ──► [DREG] ──┐
                         ├──► Pre-Adder/Sub ──► [B1REG] ──┐
 B / BCIN ► [B0REG] ─────┘     (OPMODE[6])                ├──► Multiplier ──► [MREG] ──► M
                                                          │      (36-bit)         │
          A ──► [A0REG] ──► [A1REG] ──────────────────────┘                       │
                                                                                  ▼
 C ──► [CREG] ─────────────────────┐                                    ┌──── X MUX (OPMODE[1:0])
 PCIN ─────────────────────────────┼──► Z MUX (OPMODE[3:2]) ──┐         │
 P (feedback) ─────────────────────┘                          ▼         ▼
                                                        Post-Adder/Sub (OPMODE[7]) ◄── CIN
                                                                 │
                                                       [PREG] ──► P / PCOUT
                                                       [CARRYOUTREG] ──► CARRYOUT / CARRYOUTF
```

Every register stage is built from a reusable `graymux` module (a register plus a bypass mux), so each stage can be enabled or bypassed with a parameter.

## Repository Structure

```
.
├── DSP48A1.v               # Top-level DSP48A1 slice
├── graymux.v               # Parameterized register + bypass mux
├── DSP48A1_tb.v            # Self-checking testbench
├── run_DSP48A1_tb.do       # Questasim run script
├── Constraints_DSP48A1.xdc # Clock constraint
└── README.md
```

## Module Details

### `graymux`

A register with a bypass mux, used for every pipeline stage in the slice.

| Parameter | Default  | Description                                              |
|-----------|----------|----------------------------------------------------------|
| `WIDTH`   | `18`     | Data width                                               |
| `SEL`     | `1`      | `1` = registered output, `0` = combinational bypass      |
| `RSTTYPE` | `"SYNC"` | `"SYNC"` or `"ASYNC"` reset                              |

Ports: `clk`, `rst`, `clk_en`, `in`, `out`. When `rst` is asserted the register clears; otherwise it loads `in` when `clk_en` is high.

### `DSP48A1`

**Parameters**

| Parameter                                                                  | Default    | Description                                                  |
|----------------------------------------------------------------------------|------------|--------------------------------------------------------------|
| `A0REG`, `B0REG`                                                           | `0`        | First-stage input registers for A and B                      |
| `A1REG`, `B1REG`                                                           | `1`        | Second-stage input registers for A and B                     |
| `CREG`, `DREG`, `MREG`, `PREG`, `CARRYINREG`, `CARRYOUTREG`, `OPMODEREG`   | `1`        | Enable the corresponding pipeline register (`0` = bypass)    |
| `CARRYINSEL`                                                               | `"OPMODE5"`| Carry-in source: `"OPMODE5"` or `"CARRYIN"`                  |
| `B_INPUT`                                                                  | `"DIRECT"` | B source: `"DIRECT"` (`B` port) or `"CASCADE"` (`BCIN`)      |
| `RSTTYPE`                                                                  | `"SYNC"`   | `"SYNC"` or `"ASYNC"` reset                                  |

**Ports**

| Group            | Signals                                                                                  |
|------------------|------------------------------------------------------------------------------------------|
| Data inputs      | `A[17:0]`, `B[17:0]`, `D[17:0]`, `C[47:0]`, `BCIN[17:0]`, `PCIN[47:0]`, `CARRYIN`        |
| Control          | `CLK`, `OPMODE[7:0]`                                                                     |
| Resets           | `RSTA`, `RSTB`, `RSTC`, `RSTD`, `RSTM`, `RSTP`, `RSTCARRYIN`, `RSTOPMODE`                |
| Clock enables    | `CEA`, `CEB`, `CEC`, `CED`, `CEM`, `CEP`, `CECARRYIN`, `CEOPMODE`                        |
| Outputs          | `P[47:0]`, `M[35:0]`, `PCOUT[47:0]`, `BCOUT[17:0]`, `CARRYOUT`, `CARRYOUTF`              |

## OPMODE Reference

| Bits          | Function            | Encoding                                                                              |
|---------------|---------------------|---------------------------------------------------------------------------------------|
| `OPMODE[1:0]` | X multiplexer       | `00`: 0, `01`: M (multiplier), `10`: P (feedback), `11`: D:A:B concatenated           |
| `OPMODE[3:2]` | Z multiplexer       | `00`: 0, `01`: PCIN, `10`: P (feedback), `11`: C                                      |
| `OPMODE[4]`   | Pre-adder select    | `0`: bypass pre-adder (use B0), `1`: use pre-adder result                             |
| `OPMODE[5]`   | Carry-in            | Used as carry-in when `CARRYINSEL = "OPMODE5"`                                        |
| `OPMODE[6]`   | Pre-adder operation | `0`: D + B, `1`: D - B                                                                |
| `OPMODE[7]`   | Post-adder operation| `0`: Z + X + CIN, `1`: Z - (X + CIN)                                                  |

## Verification

The testbench (`DSP48A1_tb.v`) instantiates the DUT with the default parameters, generates a clock (2 ns period), and compares all outputs against expected values after each test. On any mismatch it prints an error message and halts with `$stop`.

| Test               | OPMODE       | Inputs                                          | Expected                                                                      |
|--------------------|--------------|-------------------------------------------------|-------------------------------------------------------------------------------|
| **Reset**          | random       | All resets asserted, random inputs              | All outputs = 0                                                               |
| **Path 1**         | `8'b11011101`| A=20, B=10, C=350, D=25                         | BCOUT=`0xF`, M=`0x12C`, P=PCOUT=`0x32`, CARRYOUT=0                            |
| **Path 2**         | `8'b00010000`| A=20, B=10, C=350, D=25                         | BCOUT=`0x23`, M=`0x2BC`, P=PCOUT=0, CARRYOUT=0                                |
| **Path 3**         | `8'b00001010`| A=20, B=10, C=350, D=25                         | BCOUT=`0xA`, M=`0xC8`, P/PCOUT/CARRYOUT unchanged                             |
| **Path 4**         | `8'b10100111`| A=5, B=6, C=350, D=25, PCIN=3000                | BCOUT=`0x6`, M=`0x1E`, P=PCOUT=`0xFE6FFFEC0BB1`, CARRYOUT=CARRYOUTF=1         |

A `$monitor` statement prints actual and expected values to the transcript throughout the run.

## How to Run the Simulation

Requires Questasim (or ModelSim).

```bash
vsim -do run_DSP48A1_tb.do
```

The script compiles the design, runs the testbench, and adds all signals to the waveform:

```tcl
vlib work
vlog DSP48A1.v DSP48A1_tb.v
vsim -voptargs=+acc work.DSP48A1_tb
add wave *
run -all
#quit -sim
```

The simulation ends at 26 ns with a `$stop` once all paths have been checked.

## Synthesis & Implementation Results

Flow run in **Xilinx Vivado** targeting `xc7a200tffg1156-3`, with a 10 ns (100 MHz) clock constraint (see `Constraints_DSP48A1.xdc`).

### Utilization

| Stage          | Slice LUTs | Slice Registers | DSPs | Bonded IOB | BUFGCTRL |
|----------------|-----------:|----------------:|-----:|-----------:|---------:|
| Synthesis      | 348        | 152             | 1    | 325        | 1        |
| Implementation | 347        | 171             | 1    | 325        | 1        |

Implementation also reports 116 occupied slices.

### Timing (10 ns clock)

| Stage          | Worst Setup Slack (WNS) | Worst Hold Slack (WHS) | Worst Pulse Width Slack (WPWS) | Failing Endpoints |
|----------------|------------------------:|-----------------------:|-------------------------------:|------------------:|
| Synthesis      | 5.224 ns                | 0.414 ns               | 4.500 ns                       | 0                 |
| Implementation | 3.646 ns                | 0.522 ns               | 4.500 ns                       | 0                 |

All user-specified timing constraints are met.

> The implementation DRC reports one warning (`CFGBVS-7`) about the configuration voltage setting for the board's configuration bank. It does not affect functionality.

## Linting

Linting was run with **Questa Lint 2021.1**. The run reports no errors; the 8 findings are all informational style items:

- Constant condition expressions (from parameter-driven `generate`/mux logic)
- Duplicate parameter names across modules
- Lines exceeding the character limit
- Multiple ports declared on a single line

## Tools Used

- **Verilog HDL** for RTL design
- **Questasim** for simulation
- **Xilinx Vivado** for elaboration, synthesis, and implementation
- **Questa Lint 2021.1** for static linting
- **VS Code** for editing

## Author

**Rawan Khaled**
Communication and Electronics Engineering, Helwan University
Digital IC Design
