# Bifrost 
## Wishbone DMA Core

**Author:** Alpha Science Lab  
**Organization:** Alpha Science Lab, Mymensingh Engineering College

This repository contains the Bifrost Wishbone DMA controller design and a verification environment that exercises it. The project is primarily a DMA implementation, with verification and coverage support included as part of the development workflow.

## Overview

The RTL implements a DMA engine with:

- 8 independent DMA channels
- per-channel source/destination addresses
- transfer length and status tracking
- priority-based arbitration with round-robin behavior
- interrupt generation on completion
- Wishbone slave configuration interface and Wishbone master data path

The verification environment under `fv/` is used to validate the design and collect code/functional coverage with the Vivado simulator.

## Repository layout

- `common/` – shared interface definitions
- `rtl/` – DMA RTL implementation
- `fv/` – verification environment, tests, and coverage hooks
- `sim/` – simulation wrapper top-level modules
- `coverage_report/` – generated coverage output
- `Makefile` – build, simulation, and coverage commands
- `files.f` – Vivado file list

## Prerequisites

This project expects a Vivado installation with the following tools available on `PATH`:

- `xvlog`
- `xelab`
- `xsim`
- `xcrg`

The Verilator-based direct simulation flow also uses:

- `verilator`

## Build and simulation

### Verilator-based direct simulation

```bash
make compile
make run
make sim
```

This builds the binary under `build/` and executes the RTL simulation for quick sanity checking.

### Vivado-based verification flow

```bash
make fv_compile
make fv_elaborate
make fv_run
```

This compiles, elaborates, and runs the top-level verification testbench `tb_top`.

### GUI debug run

```bash
make fv_gui
```

### Coverage-enabled run

```bash
make fv_run COV=1
```

This enables coverage collection and generates the HTML reports in:

- `coverage_report/codeCoverageReport/`
- `coverage_report/functionalCoverageReport/`

### Cleanup

```bash
make clean
```

## Typical usage

To run the DMA verification flow with coverage enabled:

```bash
make fv_run COV=1
```

To inspect the generated reports, open the HTML dashboards in the `coverage_report` directories.

## Verification workflow

- `tb_top.sv` instantiates the DMA DUT and drives the verification sequence.
- The Vivado flow compiles the design and runs the configured tests through `make fv_run`.
- Coverage is collected with `make fv_run COV=1`, and the HTML reports are written under the `coverage_report` directories.


