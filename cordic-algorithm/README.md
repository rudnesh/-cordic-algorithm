# CORDIC Sine and Cosine Calculator in Verilog

An educational RTL design that computes sine and cosine using the **CORDIC (COordinate Rotation DIgital Computer) algorithm**. This project demonstrates how mathematical functions can be implemented efficiently in digital hardware using iterative shift-and-add operations.

## Overview

Sine and cosine are widely used in digital signal processing, wireless communications, navigation systems, robotics, and coordinate transformations.

A direct hardware implementation may require multipliers, complex arithmetic, or large lookup tables. CORDIC provides an alternative approach by approximating trigonometric functions through a sequence of small rotations using:

- Addition and subtraction
- Arithmetic right shifts
- A lookup table of precomputed arctangent values

This makes CORDIC a useful algorithm to study when designing area-conscious mathematical accelerators for FPGAs and ASICs.

## Features

- Synthesizable, sequential Verilog RTL
- Sine and cosine calculation using CORDIC rotation
- Signed 32-bit fixed-point arithmetic in Q16.16 format
- 16 iterative rotation stages
- Arctangent lookup table
- Start, busy, and done control signals
- Testbench with expected-value comparisons
- Simulation support using Icarus Verilog
- Waveform inspection using GTKWave

## Project Structure

```text
cordic-algorithm/
├── README.md
├── cordic.v
├── tb_cordic.v
└── Makefile
```

| File | Description |
|---|---|
| `cordic.v` | CORDIC hardware implementation |
| `tb_cordic.v` | Testbench for functional verification |
| `Makefile` | Commands for simulation and cleanup |
| `README.md` | Project documentation |

## How Does CORDIC Work?

CORDIC calculates trigonometric functions by rotating a vector through a sequence of smaller angles.

The algorithm starts with a vector whose initial coordinates are chosen to compensate for the gain introduced by the rotations. Each iteration rotates the vector in a direction determined by the remaining angle.

After enough iterations:

- The final X coordinate approximates the cosine of the input angle.
- The final Y coordinate approximates the sine of the input angle.

### 1. Initialization

The initial coordinates are:

\[
x_0 = K,\qquad y_0 = 0,\qquad z_0 = \theta
\]

Where:

- \(x_0\) is the initial X coordinate.
- \(y_0\) is the initial Y coordinate.
- \(z_0\) is the residual angle.
- \(\theta\) is the input angle in radians.

The CORDIC gain compensation constant is:

\[
K \approx 0.607252935
\]

For Q16.16 representation:

\[
K_{\text{fixed}} \approx 0.607252935 \times 65536 = 39797
\]

### 2. Iterative Rotation

At each iteration \(i\), the hardware selects a rotation direction based on the sign of the residual angle.

If \(z_i \geq 0\):

\[
\begin{aligned}
x_{i+1} &= x_i-(y_i \ggg i)\\
y_{i+1} &= y_i+(x_i \ggg i)\\
z_{i+1} &= z_i-\arctan(2^{-i})
\end{aligned}
\]

Otherwise:

\[
\begin{aligned}
x_{i+1} &= x_i+(y_i \ggg i)\\
y_{i+1} &= y_i-(x_i \ggg i)\\
z_{i+1} &= z_i+\arctan(2^{-i})
\end{aligned}
\]

Here, `>>>` in Verilog represents an arithmetic right shift, which preserves the sign of signed values.

The arctangent values are stored in a lookup table (LUT). After 16 iterations, the resulting coordinates approximate the required trigonometric values.

### 3. Why Use Shifts Instead of Multipliers?

Dividing a binary number by \(2^i\) can be implemented using a right shift. This allows CORDIC to perform its repeated rotations without requiring a general-purpose multiplier for each iteration.

The iterative architecture reuses the same coordinate-update datapath over multiple clock cycles, helping reduce hardware usage.

## Fixed-Point Representation: Q16.16

This design uses a signed 32-bit Q16.16 representation.

- 16 fractional bits
- Scale factor: \(2^{16}=65536\)
- Real value = stored integer / 65536

| Real value | Q16.16 integer |
|---|---:|
| 0 | 0 |
| 0.5 | 32768 |
| 1.0 | 65536 |
| \(\pi/6\) radians | Approximately 34315 |
| \(\pi/4\) radians | Approximately 51472 |
| \(\pi/2\) radians | Approximately 102944 |

**Important:** The angle input is expressed in radians, not degrees. The sine and cosine outputs are also in Q16.16 format.

For example, a sine output of `32768` represents approximately `0.5`.

## RTL Interface

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | Clock signal |
| `rst` | Input | Active-high asynchronous reset |
| `start` | Input | Starts a calculation when the module is idle |
| `angle` | Input | Signed Q16.16 angle in radians |
| `sine` | Output | Signed Q16.16 sine result |
| `cosine` | Output | Signed Q16.16 cosine result |
| `busy` | Output | Indicates that a calculation is in progress |
| `done` | Output | One-clock pulse indicating completion |

### Control Sequence

1. Apply the input angle and assert `start` while `busy` is low.
2. The module initializes the coordinates and begins iterating.
3. The `busy` signal remains high while the calculation is in progress.
4. The coordinate registers are updated over successive clock cycles.
5. When the calculation finishes, the sine and cosine outputs become available and `done` pulses high.

Keep the input angle stable when asserting `start`. Refer to the RTL and testbench for the exact cycle timing and handshake behavior.

## Simulation and Verification

### Prerequisites

Install the following tools:

- [Icarus Verilog](https://github.com/steveicarus/iverilog) — Verilog compiler and simulator
- [GTKWave](https://gtkwave.sourceforge.net/) — waveform viewer
- GNU Make — optional, for using the Makefile

### Run the Simulation

Open a terminal in the project directory:

```bash
cd ~/project/cordic-algorithm
```

Compile the RTL and testbench:

```bash
iverilog -g2012 -Wall -s tb_cordic -o cordic_sim cordic.v tb_cordic.v
```

Run the simulation:

```bash
vvp cordic_sim
```

Open the generated waveform:

```bash
gtkwave cordic.vcd
```

If your Makefile defines the corresponding targets, you can also run:

```bash
make
make wave
make clean
```

### Test Cases

The testbench can exercise representative angles such as:

| Input angle | Expected sine | Expected cosine |
|---|---:|---:|
| 0 radians | 0.0000 | 1.0000 |
| 0.5 radians | 0.4794 | 0.8776 |
| 30° (\(\pi/6\)) | 0.5000 | 0.8660 |
| 45° (\(\pi/4\)) | 0.7071 | 0.7071 |
| 60° (\(\pi/3\)) | 0.8660 | 0.5000 |
| 90° (\(\pi/2\)) | 1.0000 | 0.0000 |

These are mathematical reference values, not guaranteed bit-exact simulation outputs. Fixed-point quantization and the finite iteration count introduce approximation error. The testbench uses a tolerance to determine whether each result passes.

## Waveform Analysis with GTKWave

After opening `cordic.vcd`, inspect the following signals:

- `angle` — input angle
- `sine` — computed sine
- `cosine` — computed cosine
- `start` — calculation request
- `busy` — calculation status
- `done` — completion pulse
- `uut.x`, `uut.y`, `uut.z` — internal coordinate and residual-angle registers, if exposed in the waveform
- `uut.iter` — iteration counter, if exposed in the waveform

The waveform helps demonstrate the relationship between the RTL state transitions and the mathematical CORDIC algorithm.

## Design Limitations

- The implementation uses 16 iterations, so the results have finite precision.
- The basic rotation algorithm has a limited convergence range. The design documentation targets angles approximately within \(-\pi/2\) to \(+\pi/2\); verify the actual RTL behavior near the boundaries.
- Full-circle operation requires appropriate angle normalization or quadrant reduction.
- Fixed-point arithmetic can introduce rounding and truncation errors.
- Actual FPGA or ASIC area, timing, and power depend on the target technology, synthesis settings, and implementation constraints.

This is an educational implementation and is not intended to replace a validated high-precision mathematical IP core.

## Future Improvements

Possible extensions include:

- Add quadrant reduction for full 360-degree operation.
- Parameterize the number of iterations and data width.
- Improve verification with randomized tests and SystemVerilog assertions.
- Synthesize the design in Vivado and measure LUT, flip-flop, and timing utilization.
- Implement a pipelined CORDIC architecture for higher throughput.
- Compare iterative and pipelined architectures in terms of latency, throughput, and hardware resources.

## Learning Outcomes

This project demonstrates how a mathematical algorithm can be translated into sequential RTL and verified through simulation.

By studying the design, you can learn about:

- Algorithm-to-hardware mapping
- Signed fixed-point arithmetic
- Arithmetic shifts and iterative datapaths
- Lookup tables in digital hardware
- RTL control logic and handshaking
- Testbench development and waveform debugging
- FPGA/ASIC implementation trade-offs

## References

- [CORDIC — Wikipedia](https://en.wikipedia.org/wiki/CORDIC)
- [Icarus Verilog](https://github.com/steveicarus/iverilog)
- [GTKWave](https://gtkwave.sourceforge.net/)

---

**Author:** Rudnesh Muthusamy

**Project:** CORDIC Sine and Cosine Calculator using Verilog HDL

**Purpose:** Educational RTL design and digital hardware learning.

