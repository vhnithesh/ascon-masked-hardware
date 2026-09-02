file mkdir ./synth_out

read_verilog [glob ./src/*.v]

# Synthesize D=0
puts "================================================================"
puts "  SYNTHESIZING UNMASKED ASCON-128 (ORDER D = 0, 1 SHARE)"
puts "================================================================"
synth_design -top ascon128_top -part xc7a100tcsg324-1 -mode out_of_context -generic {ORDER=0 k=128 r=64 a=12 b=6 l=40 y=40}
create_clock -period 10.000 -name clk [get_ports clk]
report_utilization -file ./synth_out/util_d0.rpt
report_timing_summary -file ./synth_out/timing_d0.rpt

# Synthesize D=1
puts "================================================================"
puts "  SYNTHESIZING MASKED ASCON-128 (ORDER D = 1, 3 SHARES)"
puts "================================================================"
synth_design -top ascon128_top -part xc7a100tcsg324-1 -mode out_of_context -generic {ORDER=1 k=128 r=64 a=12 b=6 l=40 y=40}
create_clock -period 10.000 -name clk [get_ports clk]
report_utilization -file ./synth_out/util_d1.rpt
report_timing_summary -file ./synth_out/timing_d1.rpt

# Synthesize D=2
puts "================================================================"
puts "  SYNTHESIZING MASKED ASCON-128 (ORDER D = 2, 4 SHARES)"
puts "================================================================"
synth_design -top ascon128_top -part xc7a100tcsg324-1 -mode out_of_context -generic {ORDER=2 k=128 r=64 a=12 b=6 l=40 y=40}
create_clock -period 10.000 -name clk [get_ports clk]
report_utilization -file ./synth_out/util_d2.rpt
report_timing_summary -file ./synth_out/timing_d2.rpt

puts "================================================================"
puts "  ALL THREE ORDERS (D=0, 1, 2) SYNTHESIZED SUCCESSFULLY!"
puts "================================================================"
exit
