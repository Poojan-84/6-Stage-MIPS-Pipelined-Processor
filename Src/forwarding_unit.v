// Forwarding paths
//   EX/MEM → EX  (ForwardA/B = 10): instruction 1 cycle ahead
//   MEM/WB → EX  (ForwardA/B = 01): instruction 2 cycles ahead
//
// ForwardA (for Rs / ALU input A):
//   10: EX/MEM.RegisterRd == ID/EX.RegisterRs AND
//       EX/MEM.RegWrite == 1 AND
//       EX/MEM.RegisterRd != 0
//   01: MEM/WB.RegisterRd == ID/EX.RegisterRs AND
//       MEM/WB.RegWrite == 1 AND
//       MEM/WB.RegisterRd != 0 AND
//       NOT (EX/MEM forward condition already covers it)
//   00: No forwarding needed
//
// ForwardB (for Rt / ALU input B):
//   Same conditions but using ID/EX.RegisterRt
// EX/MEM forwarding takes priority over MEM/WB

module forwarding_unit (
    // Source registers of instruction currently in EX stage
    input  wire [4:0]  id_ex_rs,            // Rs of EX-stage instruction
    input  wire [4:0]  id_ex_rt,            // Rt of EX-stage instruction

    // Destination register of instruction in EX/MEM stage
    input  wire [4:0]  ex_mem_register_rd,  // Dest reg of MEM-stage instr
    input  wire        ex_mem_reg_write,    // MEM-stage writes to reg

    // Destination register of instruction in MEM/WB stage
    input  wire [4:0]  mem_wb_register_rd,  // Dest reg of WB-stage instr
    input  wire        mem_wb_reg_write,    // WB-stage writes to reg?

    // Forwarding select outputs
    output reg  [1:0]  forward_a,           // Mux select for ALU input A
    output reg  [1:0]  forward_b            // Mux select for ALU input B
);

    always @(*) begin
    
        // ForwardA: Forwarding for Rs (ALU input A)
        // Default: no forwarding
        forward_a = 2'b00;

        // EX/MEM hazard (higher priority)
        if (ex_mem_reg_write &&
            (ex_mem_register_rd != 5'b00000) &&
            (ex_mem_register_rd == id_ex_rs)) begin
            forward_a = 2'b10; // Forward from EX/MEM ALU result
        end
        // MEM/WB hazard 
        else if (mem_wb_reg_write &&
                 (mem_wb_register_rd != 5'b00000) &&
                 (mem_wb_register_rd == id_ex_rs)) begin
            forward_a = 2'b01; // Forward from MEM/WB write data
        end

        // ForwardB: Forwarding for Rt (ALU input B)
        forward_b = 2'b00;

        // EX/MEM hazard (higher priority)
        if (ex_mem_reg_write &&
            (ex_mem_register_rd != 5'b00000) &&
            (ex_mem_register_rd == id_ex_rt)) begin
            forward_b = 2'b10; // Forward from EX/MEM ALU result
        end
        // MEM/WB hazard (lower priority)
        else if (mem_wb_reg_write &&
                 (mem_wb_register_rd != 5'b00000) &&
                 (mem_wb_register_rd == id_ex_rt)) begin
            forward_b = 2'b01; // Forward from MEM/WB write data
        end
    end

endmodule