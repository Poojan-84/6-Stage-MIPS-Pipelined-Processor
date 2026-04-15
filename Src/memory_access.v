
// Module: memory_access
// Description: MEM Stage - Data Memory (DMEM)
//   - Byte-addressable, 32-bit word access, BIG-ENDIAN format
//   - 256 bytes of DMEM (byte addresses 0-255)
//   - On reset: DMEM initialized to all zeros EXCEPT:
//       bytes 12-15 = 0x0000001E (decimal 30) in big-endian:
//         dmem[12] = 0x00
//         dmem[13] = 0x00
//         dmem[14] = 0x00
//         dmem[15] = 0x1E
//   - mem_read  = 1: read 32-bit word at address (big-endian)
//   - mem_write = 1: write 32-bit word at address (big-endian)
//   - Write happens on positive clock edge
// ============================================================
module memory_access (
    input  wire        clk,
    input  wire        reset,
    input  wire        mem_read,        // 1 = read from memory
    input  wire        mem_write,       // 1 = write to memory
    input  wire [31:0] address,         // Byte address (from ALU result)
    input  wire [31:0] write_data,      // Data to write (for sw)
    output reg  [31:0] read_data        // Data read from memory (for lw)
);

    // Data memory: 256 bytes
    reg [7:0] dmem [0:255];

    integer i;

    // --------------------------------------------------------
    // RESET: Initialize DMEM
    // --------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear all DMEM to 0
            for (i = 0; i < 256; i = i + 1)
                dmem[i] <= 8'h00;

            // Store 0x0000001E at byte addresses 12-15 (big-endian)
            dmem[12] <= 8'h00;
            dmem[13] <= 8'h00;
            dmem[14] <= 8'h00;
            dmem[15] <= 8'h1E;
        end else begin
            // ------------------------------------------------
            // WRITE: Store 32-bit word in big-endian format
            // ------------------------------------------------
            if (mem_write) begin
                dmem[address]     <= write_data[31:24]; // MSB first
                dmem[address + 1] <= write_data[23:16];
                dmem[address + 2] <= write_data[15:8];
                dmem[address + 3] <= write_data[7:0];   // LSB last
            end
        end
    end

    // --------------------------------------------------------
    // READ: Combinational - read 32-bit word in big-endian
    // --------------------------------------------------------
    always @(*) begin
        if (mem_read) begin
            read_data = {dmem[address],
                         dmem[address + 1],
                         dmem[address + 2],
                         dmem[address + 3]};
        end else begin
            read_data = 32'b0;
        end
    end

endmodule