module register_file (
    input  wire        clk,
    input  wire        reset,
    // Read port
    input  wire [4:0]  read_reg1,   // Rs
    input  wire [4:0]  read_reg2,   // Rt
    output reg  [31:0] read_data1,  // Data from Rs
    output reg  [31:0] read_data2,  // Data from Rt
    // Write port
    input  wire [4:0]  write_reg,   // Destination register
    input  wire [31:0] write_data,  // Data to write
    input  wire        reg_write    // Write enable signal
);
    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];
    integer i;
    
    // WRITE: Positive clock edge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all registers to 0 on reset
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
                
                //Iniitial Values of Registers
            registers[1]  <= 32'd10;
            registers[2]  <= 32'd20;
            registers[3]  <= 32'd30;
            registers[4]  <= 32'd40;
            registers[5]  <= 32'd5;
            registers[7]  <= 32'd2;
            registers[8]  <= 32'd10;
            registers[11] <= 32'd0;
            
        end else begin
            // Write only if RegWrite is asserted and dest is not R0
            if (reg_write && write_reg != 5'b00000)
                registers[write_reg] <= write_data;
        end
    end

    // READ: Negative clock edge
    // R0 always returns 0
    // Internal forwarding: if write and read same register same cycle,
    // return the write data directly (write-before-read within cycle)
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            read_data1 <= 32'b0;
            read_data2 <= 32'b0;
        end else begin
            // Port 1
            if (read_reg1 == 5'b00000)
                read_data1 <= 32'b0;
            else if (reg_write && (write_reg == read_reg1))
                read_data1 <= write_data; // Forward: written this cycle instead of waiting
            else
                read_data1 <= registers[read_reg1];
                
            // Port 2
            if (read_reg2 == 5'b00000)
                read_data2 <= 32'b0;
            else if (reg_write && (write_reg == read_reg2))
                read_data2 <= write_data; // Forward: written this cycle instead of waiting
            else
                read_data2 <= registers[read_reg2];
        end
    end
endmodule