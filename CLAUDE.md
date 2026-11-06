# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Customer project for Beckhoff: a MIPI CSI-2 (2 lanes, 1.5 Gbps per lane) to UDP over 2.5GbE bridge, with every
frame buffered in an external x16 LPDDR4 (1066 Mbps). Target device LFCPNX-100-9CBG256I; external 2.5GBASE-T PHY
on SERDES lane 0 (2500BASE-X). Only the design proposal exists so far (`docs/design_proposal.md`): no RTL,
constraints or Radiant project yet.

- `../MIPI2Ethernet` is the same bridge without LPDDR4 (Versa Board, LFG672). Its CSI-2, UDP and `eth_2p5g`
  blocks are intended for reuse here.
- **Bank plan (hard constraint, see proposal Section 5):**
  - LPDDR4 is in banks 3 and 4 at VCCIO 1.1 V.
  - MIPI is in bank 5 at VCCIO 1.2 V. LP mode needs 1.2 V, and LPDDR4 (LVSTL) needs 1.1 V, so they must never
    share a bank.
  - VREF3_1 (ball R5) is kept unassigned.
- Pin data comes from `docs/references/FPGA-SC-02022-1-0-CertusPro-NX-100-Pinout.csv` (CBG256 column). The
  Lattice download named "CertusProNX-100-CBG256-DD" actually contains the 50K pinout; do not use it.

## Authoritative guidance

The Lattice working rules in `/mnt/lscc/devel/Claude/config/` take precedence over this file:

- `lscc_wslsetup.md`: tool execution policy, MCP usage and settings, by-hand fallbacks, programming
- `lscc_implementation.md`: reference-design sources, folder layout, Readme, git rules, RTL language
- `lscc_learnings.md`: lessons from earlier projects

## Project layout

- `src/` RTL (SystemVerilog unless told otherwise)
- `constraints/` timing and I/O constraints
- `lscc/` Radiant project (`.rdf`)
- `docs/` technical documents and datasheets used by the design
- `scripts/`, `sim/`, `tb/`, `logs/`
- `Readme.md` in the root: what the project is and how to reproduce the results

Ask the user where any other kind of file should go. Take reference designs only from
`/mnt/lscc/devel/LsccRefDesigns` and `/mnt/lscc/devel/Boards`.

## Build, simulation and programming

All Lattice tools run on the build host `lb` through the `lattice-prompt` MCP server, never in WSL or from
`C:\lscc\`. Paths passed to MCP tools must be under `/mnt/lscc`.

- **Build:** `radiant_build_detached(rdf_path=<abs .rdf>, impl=<impl>)`, then `radiant_build_wait`, then
  `validate_timing(project_path=<folder with the .rdf>)`. A build is not a pass until timing passes. Use the
  Radiant version the project was saved with (`grep radiant= lscc/*.rdf`).
- **Simulation:** `simulate_rtl_detached` with `skip_validate=true`, absolute file paths,
  `sim_dir=<project>/sim/mcp_sim/`, `libdirs` for `cae_library/simulation/verilog/<family>` and `uaplatform`,
  and `clean=true` on every run. A run passes only when the testbench prints a PASS message.
- **Lint or compile only:** `simulate_rtl_detached(..., elaborate_only=true)`.
- **Programming:** use the `lattice-prompt` programming tools. The JTAG cables are on `lb`.

## Git

- The default branch is `main`, and commits are signed through 1Password. Never disable signing.
- Add Radiant build working files to `.gitignore`: `.radiant_builds/`, `*_stages_*.tcl`, `radiantc.log.*`,
  `*_build_*.log`, `sim/mcp_sim/`.
