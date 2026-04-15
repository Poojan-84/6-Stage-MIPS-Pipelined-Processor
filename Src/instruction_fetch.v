module instruction_fetch (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,           // 1 = freeze PC (load-use hazard)
    input  wire        jump,            // 1 = take jump
    input  wire [31:0] jump_target,     // Jump target address
    output reg  [31:0] pc_out,          // Current PC (goes into IF/ID)
    output reg  [31:0] instruction_out  // Fetched instruction
);
    // Instruction Memory: 64 words (256 bytes)
    reg [31:0] imem [0:63];
    integer i;
    // Example instruction number 
    // sub R2, R1, R7
    //   op=000000, rs=00001(1), rt=00111(7), rd=00010(2),
    //   shamt=00000, funct=100010(34)
    //     bits: 0000_0000_0010_0111_0001_0000_0010_0010 = 0x00271022
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize PC to 0
            pc_out <= 32'b0;
            for (i = 0; i < 64; i = i + 1)
                imem[i] <= 32'h00000000;
            // Load program instructions
            imem[0] <= 32'h8D61000C; // lw  R1,  R11, #12
            imem[1] <= 32'h39030008; // xori R3, R8,  #8
            imem[2] <= 32'h00271022; // sub R2,  R1,  R7
            imem[3] <= 32'hAC220008; // sw  R2,  R1,  #8
            imem[4] <= 32'h08000006; // j   L1   (addr 24)
            imem[5] <= 32'h00C63022; // sub R6,  R6,  R6  (skipped)
            imem[6] <= 32'h00652022; // sub R4,  R3,  R5  (L1)
            instruction_out <= 32'h00000000;
        end else begin
            if (!stall) begin
                if (jump) begin
                    pc_out <= jump_target;
                end else begin
                    pc_out <= pc_out + 32'd4;
                end
                //Word address(Instruction address = byte adress/4
                instruction_out <= imem[pc_out >> 2];       
            end
        end
    end
endmodule