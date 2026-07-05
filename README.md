# UART Transceiver — Verilog

A UART transmitter and receiver implemented from scratch in Verilog, with full loopback verification in simulation and a clean synthesis/implementation pass in Vivado targeting the Arty A7-100T. No starter code, no lab manual — built and debugged independently.

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
sw[3:0] ──▶{4'b0000,sw}──▶┌──────────────┐          ┌──────────────┐
                           │ Shift Register│◀──────▶│ State Machine │──── TX ───┐
                           └──────────────┘  shift/  └──────────────┘           │
                                             load                               │
                                                                                 │ (loopback)
                ┌─────────────────┐                                            │
   clk ────────▶│ BaudRateGen(RX) │◀── reset on start-bit detect               │
                └─────────────────┘        │                                   │
                        │ tick             ▼                                   │
                        └────────▶┌──────────────┐                             │
                                   │   Receiver    │◀─── RX ───────────────────┘
                                   └──────────────┘
                                          │
                                    out[7:0], valid
```

**Note on hardware input width:** the Arty A7-100T only exposes 4 physical switches, so the top-level `data` port was changed from `input [7:0] data` to `input [3:0] sw`. The upper nibble is hardcoded to `4'b0000` inside `Top` (`data = {4'b0000, sw}`), so only the low nibble is switch-controlled on real hardware. This is a hardware-interface constraint, not a limitation of the UART core itself — the underlying transmitter/receiver still handle a full 8-bit byte.

## Modules

| Module | Description |
|---|---|
| `BaudRateGen` | Counts clock cycles to generate a periodic `tick` at the target baud rate. Parameterized with `FIRST_TARGET` and `TARGET` to support an initial half-period pulse (used by the receiver to align to the start bit) followed by full-period pulses. |
| `State_Machine` | Four-state FSM (`IDLE`, `START`, `DATA`, `STOP`) that owns the `tx` line, controls the shift register via `load`/`shift`, and tracks bit count. |
| `Shift_reg` | 8-bit shift register. Loads parallel data, shifts LSB-first on each `shift` pulse, exposes the current output bit combinationally. |
| `reciever` | Detects the falling edge of the RX line (start bit), phase-locks a dedicated baud generator to that edge, samples each subsequent bit at the mid-bit point, and asserts `valid` for one clock cycle when a complete byte has been received. Also exposes a `framing_error` output (asserted when the expected stop bit is not high) — wired internally in `Top` but not yet routed to a top-level pin. |
| `Top` | Instantiates and wires the transmitter and receiver together. TX is looped back directly to RX for self-contained verification. Top-level ports: `sw[3:0]` (data input), `EN`, `clk`, `reset`, `out[7:0]` (received byte), `valid`. |

## Key Design Decisions

**No runtime division.** The baud rate divisor is computed once (`clk_freq / baud_rate`) and hardcoded as a parameter, rather than synthesizing a hardware divider.

**Mid-bit sampling.** The receiver does not sample immediately on detecting the start bit — it waits half a bit period first, then samples every full bit period after that, landing in the most stable part of each bit.

**Phase-locked receiver clock.** An early version used two independent free-running baud generators (one for the half-period alignment pulse, one for full-period ticks). Both counted from global `reset`, not from the actual arrival time of the start bit — so the receiver's sampling point had no fixed relationship to where the real bit boundaries were. Fixed by using a single reconfigurable generator whose reset is triggered by the receiver's own start-bit detection (`start_detected`), so its count always restarts from the correct reference point for that specific transmission.

**Strobe-style handshaking.** `valid` pulses high for exactly one clock cycle when a new byte is ready, rather than staying high indefinitely — a standard pattern for signaling "new data available" without occupying a persistent state.

## Simulation

Verified in Icarus Verilog via a self-checking testbench (`tb`) that:
1. Applies reset
2. Sets a known 4-bit switch value
3. Asserts `EN` to begin transmission
4. Monitors `out` and `valid` on the receiver side to confirm the received byte matches `{4'b0000, sw}`

Verified against both `sw = 4'b0001` and `sw = 4'b1111` to confirm all four data-bearing bits propagate correctly, not just a single-bit case.

Run with:
```
iverilog -o sim tb.v BaudRateGen.v State_Machine.v Shift_reg.v reciever.v Top.v
vvp sim
```

Waveforms are dumped to `dump.vcd` and can be viewed in GTKWave.

## Vivado / Hardware Bring-Up

- Target part: `xc7a100tcsg324-1` (Arty A7-100T)
- Synthesis: clean, 0 errors, 0 critical warnings, 0 warnings
- Implementation: complete
- Timing: closed, Worst Negative Slack +5.701ns, 0 failing endpoints
- Bitstream: generated (`Top.bit`)
- Constraints (`Top.xdc`): maps `clk` to the onboard 100MHz oscillator, `reset`/`EN` to two push buttons, `sw[3:0]` to the four onboard switches, `out[7:0]` to the four LEDs plus one channel of each RGB LED, `valid` to a second RGB LED channel

Not yet done: loading the bitstream onto physical hardware — this project has not been tested on a physical board yet.

## Status

- [x] Transmitter — verified in simulation
- [x] Receiver — verified in simulation
- [x] TX→RX loopback — verified in simulation
- [x] Synthesis clean in Vivado (0 errors/warnings)
- [x] Implementation and timing closure in Vivado (WNS +5.701ns, 0 failing endpoints)
- [x] Bitstream generated
- [ ] Hardware bring-up on Arty A7-100T (blocked on board arrival)
- [ ] `framing_error` routed to a top-level pin/LED for visibility
- [ ] Configurable baud rate at synthesis time

## Target Hardware

Arty A7-100T (Xilinx Artix-7). Synthesized, implemented, and bitstream-generated for this target. Not yet tested on physical hardware — simulation-verified and Vivado-verified only at this stage.
