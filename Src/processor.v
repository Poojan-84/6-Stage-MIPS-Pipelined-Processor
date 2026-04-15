// Module: processor (Top-Level)
// Description: 6-Stage Pipelined MIPS Processor
// Stages:  IF → ID → RR → EX → MEM → WB
// Registers: IF/ID, ID/RR, RR/EX, EX/MEM, MEM/WB
module processor (
    input wire clk,
    input wire reset
    output wire [31:0] debug_pc,
    output wire [31:0] debug_alu_result,
    output wire [31:0] debug_wb_data
);
    // WIRE / REG DECLARATIONS
    // ---- IF Stage ----
    wire [31:0] if_instruction;
    wire [31:0] if_pc;
    // ---- IF/ID Pipeline Register ----
    reg  [31:0] if_id_instruction;
    reg  [31:0] if_id_pc_plus4;
    // ---- ID Stage outputs ----
    wire [5:0]  id_opcode;
    wire [4:0]  id_rs, id_rt, id_rd;
    wire [15:0] id_imm16;
    wire [31:0] id_sign_ext_imm;
    wire [4:0]  id_shamt;
    wire [5:0]  id_funct;
    wire  id_reg_dst, id_alu_src, id_mem_to_reg;
    wire  id_reg_write, id_mem_read, id_mem_write;
    wire [1:0]  id_alu_op;
    wire        id_jump;
    wire [31:0] id_jump_target;
    wire        id_flush_if;
    // ---- ID/RR Pipeline Register ----
    reg  [4:0]  id_rr_rs, id_rr_rt, id_rr_rd;
    reg  [31:0] id_rr_sign_ext_imm;
    reg  [5:0]  id_rr_funct;
    reg id_rr_reg_dst, id_rr_alu_src, id_rr_mem_to_reg;
    reg id_rr_reg_write, id_rr_mem_read, id_rr_mem_write;
    reg  [1:0]  id_rr_alu_op;
    // ---- RR Stage (Register Read) ----
    wire [31:0] rr_read_data1, rr_read_data2;
    // ---- RR/EX Pipeline Register ----
    reg  [4:0]  rr_ex_rs, rr_ex_rt, rr_ex_rd;
    reg  [31:0] rr_ex_read_data1, rr_ex_read_data2;
    reg  [31:0] rr_ex_sign_ext_imm;
    reg  [5:0]  rr_ex_funct;
    reg rr_ex_reg_dst, rr_ex_alu_src, rr_ex_mem_to_reg;
    reg rr_ex_reg_write, rr_ex_mem_read, rr_ex_mem_write;
    reg  [1:0]  rr_ex_alu_op;
    // ---- EX Stage outputs ----
    wire [31:0] ex_alu_result;
    wire [31:0] ex_forward_data2;  
    wire [1:0]  ex_forward_a, ex_forward_b;
    // ---- EX/MEM Pipeline Register ----
    reg  [4:0]  ex_mem_rd;
    reg  [31:0] ex_mem_alu_result;
    reg  [31:0] ex_mem_write_data;  
    reg         ex_mem_mem_to_reg, ex_mem_reg_write;
    reg         ex_mem_mem_read, ex_mem_mem_write;
    // ---- MEM Stage outputs ----
    wire [31:0] mem_read_data;
    // ---- MEM/WB Pipeline Register ----
    reg  [4:0]  mem_wb_rd;
    reg  [31:0] mem_wb_alu_result;
    reg  [31:0] mem_wb_read_data;
    reg         mem_wb_mem_to_reg, mem_wb_reg_write;
    // ---- WB Stage ----
    wire [31:0] wb_write_data;
    wire [4:0]  wb_write_reg;
    wire        wb_reg_write;
    // ---- Hazard Detection ----
    reg         stall;        // 1 = load-use stall active
// HAZARD DETECTION (Load-Use Hazard)
// Detect when instruction in ID/RR is lw AND its destination
// (rt) matches rs or rt of instruction currently in ID stage
    always @(*) begin
  // Load-use hazard: lw in RR stage, next instr needs result
        if (id_rr_mem_read &&
          ((id_rr_rt == id_rs) || (id_rr_rt == id_rt))) begin
            stall = 1'b1;
        end else begin
            stall = 1'b0;
        end
    end
    // STAGE 1: INSTRUCTION FETCH (IF)
    instruction_fetch IF_STAGE (
        .clk            (clk),
        .reset          (reset),
        .stall          (stall),
        .jump           (id_jump),
        .jump_target    (id_jump_target),
        .pc_out         (if_pc),
        .instruction_out(if_instruction)
    );
// IF/ID PIPELINE REGISTER
//On reset: cleared to 0 (NOP)
//On stall: holds current values (PC frozen)
//On jump flush:insert NOP(Clear instrct)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_instruction <= 32'h00000000;
            if_id_pc_plus4    <= 32'h00000000;
        end else if (id_flush_if) begin
   // Jump detected: squash instruction in IF → NOP
            if_id_instruction <= 32'h00000000;
            if_id_pc_plus4    <= 32'h00000000;
        end else if (!stall) begin
            if_id_instruction <= if_instruction;
            if_id_pc_plus4    <= if_pc + 32'd4;
        end
// If stall: IF/ID holds current values (no update)
    end
    // STAGE 2: INSTRUCTION DECODE (ID)
    instruction_decode ID_STAGE (
        .clk            (clk),
        .reset          (reset),
        .instruction    (if_id_instruction),
        .pc_plus4       (if_id_pc_plus4),
        .stall          (stall),
        .opcode         (id_opcode),
        .rs             (id_rs),
        .rt             (id_rt),
        .rd             (id_rd),
        .imm16          (id_imm16),
        .sign_ext_imm   (id_sign_ext_imm),
        .shamt          (id_shamt),
        .funct          (id_funct),
        .reg_dst        (id_reg_dst),
        .alu_src        (id_alu_src),
        .mem_to_reg     (id_mem_to_reg),
        .reg_write      (id_reg_write),
        .mem_read       (id_mem_read),
        .mem_write      (id_mem_write),
        .alu_op         (id_alu_op),
        .jump           (id_jump),
        .jump_target    (id_jump_target),
        .flush_if       (id_flush_if)
    );
// ID/RR PIPELINE REGISTER
// - On reset or stall: insert NOP (Clear)
    always @(posedge clk or posedge reset) begin
        if (reset || stall) begin
            // Insert NOP bubble when stalling
            id_rr_rs           <= 5'b0;
            id_rr_rt           <= 5'b0;
            id_rr_rd           <= 5'b0;
            id_rr_sign_ext_imm <= 32'b0;
            id_rr_funct        <= 6'b0;
            id_rr_reg_dst      <= 1'b0;
            id_rr_alu_src      <= 1'b0;
            id_rr_mem_to_reg   <= 1'b0;
            id_rr_reg_write    <= 1'b0;
            id_rr_mem_read     <= 1'b0;
            id_rr_mem_write    <= 1'b0;
            id_rr_alu_op       <= 2'b0;
        end else begin
            id_rr_rs           <= id_rs;
            id_rr_rt           <= id_rt;
            id_rr_rd           <= id_rd;
            id_rr_sign_ext_imm <= id_sign_ext_imm;
            id_rr_funct        <= id_funct;
            id_rr_reg_dst      <= id_reg_dst;
            id_rr_alu_src      <= id_alu_src;
            id_rr_mem_to_reg   <= id_mem_to_reg;
            id_rr_reg_write    <= id_reg_write;
            id_rr_mem_read     <= id_mem_read;
            id_rr_mem_write    <= id_mem_write;
            id_rr_alu_op       <= id_alu_op;
        end
    end
    // STAGE 3: REGISTER READ (RR)
// Register file instantiated here
    register_file REG_FILE (
        .clk        (clk),
        .reset      (reset),
        .read_reg1  (id_rr_rs),
        .read_reg2  (id_rr_rt),
        .read_data1 (rr_read_data1),
        .read_data2 (rr_read_data2),
        .write_reg  (wb_write_reg), 
        .write_data (wb_write_data), 
        .reg_write  (wb_reg_write)  
    );
    // RR/EX PIPELINE REGISTER
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rr_ex_rs           <= 5'b0;
            rr_ex_rt           <= 5'b0;
            rr_ex_rd           <= 5'b0;
            rr_ex_read_data1   <= 32'b0;
            rr_ex_read_data2   <= 32'b0;
            rr_ex_sign_ext_imm <= 32'b0;
            rr_ex_funct        <= 6'b0;
            rr_ex_reg_dst      <= 1'b0;
            rr_ex_alu_src      <= 1'b0;
            rr_ex_mem_to_reg   <= 1'b0;
            rr_ex_reg_write    <= 1'b0;
            rr_ex_mem_read     <= 1'b0;
            rr_ex_mem_write    <= 1'b0;
            rr_ex_alu_op       <= 2'b0;
        end else begin
            rr_ex_rs           <= id_rr_rs;
            rr_ex_rt           <= id_rr_rt;
 // Destination register: rd (R-type) or rt (I-type)
    rr_ex_rd <= id_rr_reg_dst ? id_rr_rd : id_rr_rt;
            rr_ex_read_data1   <= rr_read_data1;
            rr_ex_read_data2   <= rr_read_data2;
            rr_ex_sign_ext_imm <= id_rr_sign_ext_imm;
            rr_ex_funct        <= id_rr_funct;
            rr_ex_reg_dst      <= id_rr_reg_dst;
            rr_ex_alu_src      <= id_rr_alu_src;
            rr_ex_mem_to_reg   <= id_rr_mem_to_reg;
            rr_ex_reg_write    <= id_rr_reg_write;
            rr_ex_mem_read     <= id_rr_mem_read;
            rr_ex_mem_write    <= id_rr_mem_write;
            rr_ex_alu_op       <= id_rr_alu_op;
        end
    end
    // FORWARDING UNIT
    forwarding_unit FWD_UNIT (
        .id_ex_rs           (rr_ex_rs),
        .id_ex_rt           (rr_ex_rt),
        .ex_mem_register_rd (ex_mem_rd),
        .ex_mem_reg_write   (ex_mem_reg_write),
        .mem_wb_register_rd (mem_wb_rd),
        .mem_wb_reg_write   (mem_wb_reg_write),
        .forward_a          (ex_forward_a),
        .forward_b          (ex_forward_b)
    );
    // STAGE 4: EXECUTE (EX)
    execute EX_STAGE (
        .read_data1         (rr_ex_read_data1),
        .read_data2         (rr_ex_read_data2),
        .sign_ext_imm       (rr_ex_sign_ext_imm),
        .alu_op             (rr_ex_alu_op),
        .alu_src            (rr_ex_alu_src),
        .funct              (rr_ex_funct),
        .forward_a          (ex_forward_a),
        .forward_b          (ex_forward_b),
        .ex_mem_alu_result  (ex_mem_alu_result),
        .mem_wb_write_data  (wb_write_data),
        .alu_result         (ex_alu_result),
        .forward_data2      (ex_forward_data2)
    );
    // EX/MEM PIPELINE REGISTER
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_mem_rd          <= 5'b0;
            ex_mem_alu_result  <= 32'b0;
            ex_mem_write_data  <= 32'b0;
            ex_mem_mem_to_reg  <= 1'b0;
            ex_mem_reg_write   <= 1'b0;
            ex_mem_mem_read    <= 1'b0;
            ex_mem_mem_write   <= 1'b0;
        end else begin
            ex_mem_rd          <= rr_ex_rd;
            ex_mem_alu_result  <= ex_alu_result;
            ex_mem_write_data  <= ex_forward_data2;
            ex_mem_mem_to_reg  <= rr_ex_mem_to_reg;
            ex_mem_reg_write   <= rr_ex_reg_write;
            ex_mem_mem_read    <= rr_ex_mem_read;
            ex_mem_mem_write   <= rr_ex_mem_write;
        end
    end

    // STAGE 5: MEMORY ACCESS (MEM)
    memory_access MEM_STAGE (
        .clk        (clk),
        .reset      (reset),
        .mem_read   (ex_mem_mem_read),
        .mem_write  (ex_mem_mem_write),
        .address    (ex_mem_alu_result),
        .write_data (ex_mem_write_data),
        .read_data  (mem_read_data)
    );
    // MEM/WB PIPELINE REGISTER
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_wb_rd          <= 5'b0;
            mem_wb_alu_result  <= 32'b0;
            mem_wb_read_data   <= 32'b0;
            mem_wb_mem_to_reg  <= 1'b0;
            mem_wb_reg_write   <= 1'b0;
        end else begin
            mem_wb_rd          <= ex_mem_rd;
            mem_wb_alu_result  <= ex_mem_alu_result;
            mem_wb_read_data   <= mem_read_data;
            mem_wb_mem_to_reg  <= ex_mem_mem_to_reg;
            mem_wb_reg_write   <= ex_mem_reg_write;
        end
    end

    // STAGE 6: WRITE BACK (WB)
    // MUX: select memory data (lw) or ALU result
    assign wb_write_data = mem_wb_mem_to_reg ? mem_wb_read_data
                                              : mem_wb_alu_result;
    assign wb_write_reg  = mem_wb_rd;
    assign wb_reg_write  = mem_wb_reg_write;
    
    assign debug_pc = if_pc;
    assign debug_alu_result = ex_alu_result;
    assign debug_wb_data = wb_write_data;

endmodule
