CORDIC Sine and Cosine Calculator (Verilog)
A small educational RTL project that computes sine and cosine using the
CORDIC (COordinate Rotation DIgital Computer) algorithm.
Why use CORDIC in digital hardware?
Directly implementing sine/cosine with general-purpose arithmetic or a large
lookup table can cost hardware resources. CORDIC approximates these functions
through repeated micro-rotations using:
- addition and subtraction,
- arithmetic shifts,
- a small table of arctangent constants.
This makes it a useful example of an area-conscious math accelerator for FPGA
and ASIC designs. It is used in signal processing, communications, navigation,
coordinate transforms, and numerical hardware.
What this project demonstrates
- Sequential RTL: one iteration per clock cycle.
- Signed fixed-point arithmetic (Q16.16).
- An arctangent lookup table.
- A simple start/busy/done handshake.
- Simulation with Icarus Verilog and waveform inspection with GTKWave.
Files
- cordic.v — synthesizable CORDIC RTL.
- tb_cordic.v — testbench with expected-value checks.
- Makefile — convenient simulation targets.
Number representation: Q16.16
A signed 32-bit Q16.16 value stores a real number scaled by 65536.
fixed_point_value = real_value * 65536
Examples:
- 0 radians: 0
- 0.5 radians: 32768
- 1 radian: 65536
- 90 degrees = pi/2 radians: approximately 102944
The module's angle input is in radians, not degrees. Outputs are also Q16.16.
To interpret an output, divide its signed integer value by 65536.
Algorithm overview
The algorithm begins with:
x0 = K = 0.607252935 * 65536 ≈ 39797
y0 = 0
z0 = input_angle
At iteration i, choose the direction based on the sign of the residual angle:
if z >= 0:
    x_next = x - (y >>> i)
    y_next = y + (x >>> i)
    z_next = z - atan(2^-i)
else:
    x_next = x + (y >>> i)
    y_next = y - (x >>> i)
    z_next = z + atan(2^-i)
The >>> operator is an arithmetic right shift. After 16 iterations,
x approximates cosine and y approximates sine.
The starting constant compensates for the gain introduced by the sequence of
micro-rotations. The LUT constants are stored in Q16.16 radians.
Interface
Signal	Direction	Meaning
clk	input	Clock
rst	input	Active-high asynchronous reset
start	input	Start a calculation when busy is low
angle	input	Signed Q16.16 angle in radians
sine	output	Signed Q16.16 sine result
cosine	output	Signed Q16.16 cosine result
busy	output	High while iterating
done	output	One-clock pulse when result is ready


Keep angle stable when start is asserted. The basic design accepts angles
approximately from -pi/2 to +pi/2 for the clearest results. Wider convergence
range is possible, but full-circle support needs quadrant/range reduction.
Run the simulation
Install Icarus Verilog and GTKWave if needed. From this directory:
iverilog -g2012 -Wall -s tb_cordic -o cordic_sim cordic.v tb_cordic.v
vvp cordic_sim
gtkwave cordic.vcd
Or, if make is installed:
make
make wave
make clean
Expected sine/cosine values for the test angles are close to:
Angle	Sine	Cosine
0 rad	0.0000	1.0000
0.5 rad	0.4794	0.8776
pi/6 rad (approx.)	0.5000	0.8660
pi/4 rad (approx.)	0.7071	0.7071
pi/3 rad (approx.)	0.8660	0.5000
pi/2 rad (approx.)	1.0000	0.0000


The testbench uses a small tolerance because fixed-point rounding and finite
iterations cause approximation error. It also prints PASS/FAIL for each case.
What to inspect in GTKWave
Useful signals:
- angle, sine, cosine
- busy, done, start
- internal signals uut.x, uut.y, uut.z, uut.iter
You should see iter advance from 0 to 15, busy remain high during
calculation, and done pulse when the outputs are captured.
Important implementation notes
1. This is an educational fixed-point implementation, not a certified
   high-precision math IP.
2. The code uses 16 iterations; increasing iterations requires updating the
   counter condition and adding more LUT constants.
3. >>> is used for signed arithmetic right shifts.
4. This iterative architecture reuses one coordinate-update datapath over
   multiple cycles. A fully pipelined CORDIC can produce higher throughput but
   uses more hardware resources.
5. Synthesis results depend on FPGA family, tool settings, and timing targets.
Next improvements
- Add angle normalization for full 360-degree operation.
- Parameterize the number of iterations and fixed-point width.
- Add randomized tests and assertions in SystemVerilog.
- Synthesize in Vivado and compare LUT/FF usage and maximum clock frequency.
- Try a pipelined architecture and compare area, latency, and throughput.
Learning takeaway
CORDIC is a good example of algorithm-to-hardware thinking: a mathematical
operation is reorganized into simple repetitive operations that map well to
digital logic.
