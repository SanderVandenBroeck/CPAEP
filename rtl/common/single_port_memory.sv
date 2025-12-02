//-----------------------------
// Single Port Memory Module
//
// Description: This module implements a single-port memory with
// configurable data width and depth. It supports synchronous write
// operations and combinational read operations.
//
// Parameters:
// - DataWidth: Width of the data bus (default: 8 bits)
// - DataDepth: Depth of the memory (default: 4096 entries)
// - AddrWidth: Width of the address bus (calculated based on DataDepth)
//
// Ports:
// - clk_i: Clock input
// - rst_ni: Active low reset input
// - mem_addr_i: Memory address input
// - mem_we_i: Memory write enable input
// - mem_wr_data_i: Memory write data input
// - mem_rd_data_o: Memory read data output
//-----------------------------

//-----------------------------
// DESIGN NOTE:
// You are allowed to modify the Datadepth and
// DataWidth parameters to suit your design requirements.
//-----------------------------
module single_port_memory #(
    parameter int unsigned DataWidth = 8,
    parameter int unsigned MemoryRows = 32,
    parameter int unsigned MemoryColumns = 32,
    parameter int unsigned DataRows = 4,
    parameter int unsigned DataColumns = 4,
    parameter int unsigned WriteDataRows = 4,
    parameter int unsigned WriteDataColumns = 4,
    parameter int unsigned DataDepth = MemoryRows*MemoryColumns,
    parameter int unsigned AddrWidth = (DataDepth <= 1) ? 1 : $clog2(DataDepth)
) (
    input  logic                        clk_i,
    input  logic                        rst_ni,
    input  logic        [6:0]           MatrixCol,
    input  logic        [AddrWidth-1:0] mem_addr_i,
    input  logic                        mem_we_i,
    input  logic signed [DataWidth-1:0] mem_wr_data_i[0:WriteDataRows*WriteDataColumns-1],
    output logic signed [DataWidth-1:0] mem_rd_data_o[0:DataRows*DataColumns-1]
);

  // Memory array
  logic signed [DataWidth-1:0] memory[DataDepth];
  logic signed [DataWidth-1:0] mem_rd_data_o[DataRows*DataColumns]

  // Memory read access
  genvar i, j; // i is loop variable for rows and j for the columns
  for (i = 0; i < DataRows-1; i++) begin
    for (j = 0; j < DataColumns-1; j++) begin
      assign mem_rd_data_o[i] = memory[mem_addr_i+i*MatrixCol+j];
    end
  end

  // Memory write access
  always_ff @(posedge clk_i) begin
    // Write when write enable is asserted
    if (mem_we_i) begin
      memory[mem_addr_i] <= mem_wr_data_i;
    end
  end

  // Memory write access
  genvar i, j; // i is loop variable for rows and j for the columns
  always_ff @(posedge clk_i) begin
    if( mem_we_i) begin
      for (i = 0; i < WriteDataRows-1; i++) begin
        for (j = 0; j < WriteDataColumns-1; j++) begin
          assign memory[mem_addr_i+i*MatrixCol+j] <= mem_wr_data_i[i];
        end
      end
    end
  end
endmodule
