// Module: execute
// Description: EX Stage - ALU
//   - Performs arithmetic/logic operations
//   - ALU inputs selected via forwarding muxes
//   - alu_op:
//       00 = ADD  (lw, sw address calculation)
//       01 = SUB  (sub instruction, funct=100010)
//       10 = XOR  (xori instruction)
//
// Forwarding MUX select (ForwardA / ForwardB):
//       00 = use register file output (no forwarding)
//       01 = forward from MEM/WB stage (write_back data)
//       10 = forward from EX/MEM stage (ALU result)
// ============================================================
module execute (
    input  wire [31:0] read_data1,      // Rs value from register file
    input  wire [31:0] read_data2,      // Rt value from register file
    input  wire [31:0] sign_ext_imm,    // Sign-extended immediate
    input  wire [1:0]  alu_op,          // ALU operation selector
    input  wire        alu_src,         // 0=reg, 1=immediate
    input  wire [5:0]  funct,           // Function code (for R-type)

    // Forwarding inputs
    input  wire [1:0]  forward_a,       // Forwarding select for Rs
    input  wire [1:0]  forward_b,       // Forwarding select for Rt
    input  wire [31:0] ex_mem_alu_result,  // ALU result from EX/MEM
    input  wire [31:0] mem_wb_write_data,  // Write data from MEM/WB

    output reg  [31:0] alu_result,      // ALU output
    output reg  [31:0] forward_data2    // Forwarded Rt value (for sw store data)
);

    // Internal: actual ALU operands after forwarding mux
    reg [31:0] alu_input_a;
    reg [31:0] alu_input_b_reg; // After forward mux (before alu_src mux)
    reg [31:0] alu_input_b;     // Final ALU input B

    always @(*) begin
        // ------------------------------------------------
        // Forwarding MUX for ALU input A (Rs)
        // ------------------------------------------------
        case (forward_a)
            2'b00: alu_input_a = read_data1;            // No forwarding
            2'b01: alu_input_a = mem_wb_write_data;     // Forward from MEM/WB
            2'b10: alu_input_a = ex_mem_alu_result;     // Forward from EX/MEM
            default: alu_input_a = read_data1;
        endcase

        // ------------------------------------------------
        // Forwarding MUX for ALU input B (Rt)
        // ------------------------------------------------
        case (forward_b)
            2'b00: alu_input_b_reg = read_data2;           // No forwarding
            2'b01: alu_input_b_reg = mem_wb_write_data;    // Forward from MEM/WB
            2'b10: alu_input_b_reg = ex_mem_alu_result;    // Forward from EX/MEM
            default: alu_input_b_reg = read_data2;
        endcase

        // Save forwarded Rt for sw (store data)
        forward_data2 = alu_input_b_reg;


        // ALU Source MUX: register or immediate
        if (alu_src)        //Difference between alu_input_b_reg and just alu_input_b
            alu_input_b = sign_ext_imm;
        else
            alu_input_b = alu_input_b_reg;

        // ------------------------------------------------
        // ALU Operation
        // ------------------------------------------------
        case (alu_op)
            2'b00: alu_result = alu_input_a + alu_input_b;  // ADD
            2'b01: alu_result = alu_input_a - alu_input_b;  // SUB
            2'b10: alu_result = alu_input_a ^ alu_input_b;  // XOR
            default: alu_result = 32'b0;
        endcase
    end

endmodule