//   - CLK: period = 10ns (100 MHz)
//   - RESET held HIGH for 2 cycles, then released
`timescale 1ns/1ps
module testbench;
    reg clk;
    reg reset;
    processor DUT (
        .clk   (clk),
        .reset (reset)
    );
    // ---- Clock generation: period = 10ns ----
    initial begin
        clk = 0;
    end
    always #5 clk = ~clk; 
    initial begin
        // Assert reset at time 0
        reset = 1;
        // Hold reset for 2 full clock cycles
        @(posedge clk); #1;
        @(posedge clk); #1;
        // Release reset
        reset = 0;
        // Run for 30 cycles
        repeat (30) @(posedge clk);
        $finish;
    end

    // Waveform dump (for GTKWave / ModelSim)
    initial begin
        $dumpfile("processor_sim.vcd");
        $dumpvars(0, testbench);
    end
    //Cycle-by-cycle monitor 
    integer cycle_count;
    initial cycle_count = 0;
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            $display("--- Cycle %0d ---", cycle_count);
            $display("  PC         = %0d", DUT.IF_STAGE.pc_out);
            $display("  IF/ID instr= %h",  DUT.if_id_instruction);
            $display("  Stall      = %b",  DUT.stall);
            $display("  R1=%0d R2=%0d R3=%0d R4=%0d",
                DUT.REG_FILE.registers[1],
                DUT.REG_FILE.registers[2],
                DUT.REG_FILE.registers[3],
                DUT.REG_FILE.registers[4]);
        end
    end
endmodule
