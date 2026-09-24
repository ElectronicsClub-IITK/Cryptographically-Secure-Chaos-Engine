# crypto_ip — AES-128 / SHA-256 accelerator for Cora Z7 (Zynq-7000)

Custom AXI4-Lite peripheral built with the same flow as
fpgadeveloper.com's "Creating a custom IP block in Vivado" article:
package a black-box AXI4-Lite peripheral, drop in application logic on
top of the generated register interface, repackage, instantiate in the
block design, generate a bitstream, then drive it from the PS over the
same AXI-Lite interconnect used for any other memory-mapped peripheral.
Results come back to the host over UART (the Cora Z7's USB-UART bridge,
already wired to the PS UART).

## Files

```
hdl/
  aes128_core.v                 AES-128 encrypt, iterative, 1 round/clock
  sha256_core.v                 SHA-256 compression, single block, 1 round/clock
  crypto_engine.v               Mode mux between the two cores
  crypto_ip_v1_0_S00_AXI.v      AXI4-Lite slave + register file
  crypto_ip_v1_0.v              Top-level IP wrapper (S00_AXI instance)
sw/
  crypto_ip.h / crypto_ip.c     Baremetal driver (register access, padding, polling)
  main.c                        Test application: mode select over UART, runs a
                                 known-answer test, prints result
docs/
  register_map.md               Full register reference
```

## Packaging the IP in Vivado

1. `Tools -> Create and Package New IP -> Create a new AXI4 peripheral`.
   Name it `crypto_ip`, add one AXI4-Lite slave interface `S00_AXI`,
   32-bit data width. Finish the wizard with "Edit IP" selected — this
   generates the same `<ip>_v1_0.v` / `<ip>_v1_0_S00_AXI.v` skeleton
   that ships in `hdl/`.
2. Replace the generated `crypto_ip_v1_0_S00_AXI.v` and
   `crypto_ip_v1_0.v` with the versions in this repo, and drop
   `aes128_core.v`, `sha256_core.v`, `crypto_engine.v` alongside them
   in the IP's `hdl` directory.
3. In the IP packager GUI: `Merge changes from File Groups Wizard`,
   then `Re-Package IP`.
4. Address range: the IP only needs 128 bytes (32 registers x 4 bytes),
   but Vivado will round up to a 4K/64K boundary depending on the
   interconnect — that's fine, `docs/register_map.md` only uses the
   low 0x68 bytes.

## Block design

1. Create a Zynq block design targeting the Cora Z7 board files, run
   block automation for `ZYNQ7 Processing System` (enables DDR, fixed
   IO, and by default UART1, which is what's routed to the Cora Z7's
   USB-UART bridge — leave it enabled).
2. Add the `crypto_ip` IP to the canvas, run connection automation to
   wire `S00_AXI` to the PS's `M_AXI_GP0` through the AXI interconnect,
   and connect `s00_axi_aclk` / `s00_axi_aresetn` to `FCLK_CLK0` and the
   matching reset.
3. Validate design, generate the block design wrapper, run synthesis,
   implementation, and generate the bitstream.
4. `File -> Export -> Export Hardware` (include bitstream).

## Software

1. In Vitis (or the legacy SDK), create a platform from the exported
   `.xsa`, then a baremetal application project against it.
2. Add `crypto_ip.h`, `crypto_ip.c`, and `main.c` from `sw/` to the
   application's `src` directory.
3. After the platform is generated, confirm the base address macro in
   `xparameters.h` -- for this project it's
   `XPAR_CRYPTO_IP_V1_0_0_BASEADDR` (0x40000000), not the
   `..._S00_AXI_BASEADDR` pattern some Vitis versions use. `main.c`
   falls back to 0x40000000 if the symbol isn't defined, but always
   check your own `xparameters.h` since the exact name depends on your
   IP instance name and Vitis version.
4. Build, program the FPGA + PS, open a serial terminal on the Cora
   Z7's UART (115200 8N1), reset the board, and run the app.

## What the application does

On boot it prints a prompt on the serial console. Typing `0` runs the
FIPS-197 AES-128 known-answer test (fixed key/plaintext, checks the
ciphertext against the published expected value); typing `1` runs the
`SHA-256("abc")` known-answer test and checks the digest. Both are
computed entirely in the PL — the PS only loads operands into the
AXI-Lite registers, pulses `START`, polls `STATUS`, and reads back the
result — and everything is echoed to the terminal.
