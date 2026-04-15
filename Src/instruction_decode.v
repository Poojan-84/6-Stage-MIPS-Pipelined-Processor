module instruction_decode (
    input  wire        clk,
    input  wire        reset,
    // Instruction from IF/ID register
    input  wire [31:0] instruction,
    input  wire [31:0] pc_plus4,        // PC+4 passed from IF/ID
    // Stall signal (from hazard detection)
    input  wire        stall,
    //  Decoded fields output (to ID/RR register)
    output reg  [5:0]  opcode,
    output reg  [4:0]  rs,
    output reg  [4:0]  rt,
    output reg  [4:0]  rd,
    output reg  [15:0] imm16,
    output reg  [31:0] sign_ext_imm,    // Sign-extended immediate
    output reg  [4:0]  shamt,
    output reg  [5:0]  funct,
    // Control signals output
    output reg         reg_dst,
    output reg         alu_src,
    output reg         mem_to_reg,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg  [1:0]  alu_op,
    // Jump handling 
    output reg         jump,
    output reg  [31:0] jump_target,     // Computed jump address
    output reg         flush_if         // 1 = flush IF/ID (insert NOP)
);
    // Opcode constants
    localparam OP_RTYPE = 6'b000000; // sub
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_XORI  = 6'b001110;
    localparam OP_J     = 6'b000010;
    // Internal wire for opcode extraction
    wire [5:0] op = instruction[31:26];
    always @(*) begin
        // Default: NOP / safe values
        opcode      = instruction[31:26];
        rs          = instruction[25:21];
        rt          = instruction[20:16];
        rd          = instruction[15:11];
        shamt       = instruction[10:6];
        funct       = instruction[5:0];
        imm16       = instruction[15:0];
        sign_ext_imm = {{16{instruction[15]}}, instruction[15:0]}; // Sign extend
        // Default control signals (NOP state)
        reg_dst    = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 1'b0;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_op     = 2'b00;
        jump       = 1'b0;
        jump_target = 32'b0;
        flush_if   = 1'b0;

        if (!stall) begin
            case (op)
                OP_RTYPE: begin
                    // sub: R-type
                    reg_dst    = 1'b1;  // destination is rd
                    alu_src    = 1'b0;  // ALU uses register values
                    mem_to_reg = 1'b0;  // write ALU result to reg
                    reg_write  = 1'b1;  // write enabled
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    alu_op     = 2'b01; // SUB operation
                end
                OP_LW: begin
                    // lw: load word
                    reg_dst    = 1'b0;  // destination is rt
                    alu_src    = 1'b1;  // ALU uses immediate (offset)
                    mem_to_reg = 1'b1;  // write memory data to reg
                    reg_write  = 1'b1;  // write enabled
                    mem_read   = 1'b1;  // read memory
                    mem_write  = 1'b0;
                    alu_op     = 2'b00; // ADD (base + offset)
                end
                OP_SW: begin
                    // sw: store word
                    reg_dst    = 1'b0;  // don't care (no reg write)
                    alu_src    = 1'b1;  // ALU uses immediate (offset)
                    mem_to_reg = 1'b0;  // don't care
                    reg_write  = 1'b0;  // no register write
                    mem_read   = 1'b0;
                    mem_write  = 1'b1;  // write to memory
                    alu_op     = 2'b00; // ADD (base + offset)
                end
                OP_XORI: begin
                    // xori: XOR with immediate
                    reg_dst    = 1'b0;  // destination is rt
                    alu_src    = 1'b1;  // ALU uses sign-extended immediate
                    mem_to_reg = 1'b0;  // write ALU result to reg
                    reg_write  = 1'b1;  // write enabled
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    alu_op     = 2'b10; // XOR operation
                end
                OP_J: begin
                    // j: jump - resolved HERE in ID stage
                    // Jump target = {PC+4[31:28], instruction[25:0], 2'b00}
                    reg_dst    = 1'b0;
                    alu_src    = 1'b0;
                    mem_to_reg = 1'b0;
                    reg_write  = 1'b0;  // no register write
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    alu_op     = 2'b00;
                    jump       = 1'b1;
                    // Compute jump target address
                    jump_target = {pc_plus4[31:28], instruction[25:0], 2'b00};
                    flush_if   = 1'b1;  // squash instruction in IF stage
                end
                default: begin
                    // NOP or unknown: all signals 0/inactive
                    reg_dst    = 1'b0;
                    alu_src    = 1'b0;
                    mem_to_reg = 1'b0;
                    reg_write  = 1'b0;
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    alu_op     = 2'b00;
                end
            endcase
        end
    end
endmodule