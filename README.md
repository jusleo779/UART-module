# UART Transceiver — Verilog

A UART transmitter and receiver implemented from scratch in Verilog, with full loopback verification in simulation. No starter code, no lab manual — built and debugged independently.

## Overview

This project implements the UART serial communication protocol as a set of modular RTL blocks:

- **Baud Rate Generator** — divides the system clock down to the target baud rate, with a reconfigurable first-pulse target to support phase-locked receiver sampling
- **Transmitter (State Machine + Shift Register)** — serializes an 8-bit byte into a standard UART frame (start bit, 8 data bits LSB-first, stop bit)
- **Receiver** — detects an incoming start bit, phase-aligns to the middle of each bit period, and deserializes the incoming line into an 8-bit byte
- **Top Level** — wires transmitter and receiver together in loopback for end-to-end verification

## Architecture

```
                ┌─────────────────┐
   clk ────────▶│ BaudRateGen(TX) │──tick──┐
                └─────────────────┘        │
                                            ▼
              ┌──────────────┐          ┌──────────────┐
data[7:0] ──▶│ Shift Register│◀──────▶│ State Machine │──── TX ───┐
              └──────────────┘  shift/  └──────────────┘            │
                                load                                │
                                                                    │ (loopback)
                ┌─────────────────┐                                 │
   clk ────────▶│ BaudRateGen(RX) │◀── reset on start-bit detect   │
                └─────────────────┘        │                        │
                        │ tick             ▼                        │
                        └────────▶┌──────────────┐                  │
                                   │   Receiver    │◀─── RX ────────┘
                                   └──────────────┘
                                          │
                                    out[7:0], valid
```

## Modules

| Module | Description |
|---|---|
| `BaudRateGen` | Counts clock cycles to generate a periodic `tick` at the target baud rate. Parameterized with `FIRST_TARGET` and `TARGET` to support an initial half-period pulse (used by the receiver to align to the start bit) followed by full-period pulses. |
| `State_Machine` | Four-state FSM (`IDLE`, `START`, `DATA`, `STOP`) that owns the `tx` line, controls the shift register via `load`/`shift`, and tracks bit count. |
| `Shift_reg` | 8-bit shift register. Loads parallel data, shifts LSB-first on each `shift` pulse, exposes the current output bit combinationally. |
| `reciever` | Detects the falling edge of the RX line (start bit), phase-locks a dedicated baud generator to that edge, samples each subsequent bit at the mid-bit point, and asserts `valid` for one clock cycle when a complete byte has been received. |
| `Top` | Instantiates and wires the transmitter and receiver together. TX is looped back directly to RX for self-contained verification. |

## Key Design Decisions

**No runtime division.** The baud rate divisor is computed once (`clk_freq / baud_rate`) and hardcoded as a parameter, rather than synthesizing a hardware divider.

**Mid-bit sampling.** The receiver does not sample immediately on detecting the start bit — it waits half a bit period first, then samples every full bit period after that, landing in the most stable part of each bit.

**Phase-locked receiver clock.** An early version used two independent free-running baud generators (one for the half-period alignment pulse, one for full-period ticks). This caused a bug: the two counters weren't phase-aligned to the actual arrival time of the start bit, since they were both counting from a global reset instead of from the moment transmission began. Fixed by using a single reconfigurable generator whose reset is triggered by the receiver's own start-bit detection, so it always counts from the correct reference point.

**Strobe-style handshaking.** `valid` pulses high for exactly one clock cycle when a new byte is ready, rather than staying high indefinitely — a standard pattern for signaling "new data available" without occupying a persistent state.

## Simulation

Verified in Icarus Verilog via a self-checking testbench (`tb`) that:
1. Applies reset
2. Loads a known byte into the transmitter
3. Asserts `EN` to begin transmission
4. Monitors `out` and `valid` on the receiver side to confirm the received byte matches the transmitted byte

Run with:
```
iverilog -o sim tb.v BaudRateGen.v State_Machine.v Shift_reg.v reciever.v Top.v
vvp sim
```

Waveforms are dumped to `dump.vcd` and can be viewed in GTKWave.

## Status

- [x] Transmitter — verified in simulation
- [x] Receiver — verified in simulation
- [x] TX→RX loopback — verified in simulation
- [X] Synthesis and timing closure in Vivado Note: synthesis clean, implementation run, timing met with +5.701ns margin, 0 failing endpoints.
- [ ] Hardware bring-up on Arty A7-100T
- [ ] Configurable baud rate at synthesis time

## Target Hardware

Arty A7-100T (Xilinx Artix-7). Not yet synthesized or tested on physical hardware — simulation only at this stage.
