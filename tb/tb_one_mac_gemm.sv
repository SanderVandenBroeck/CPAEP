module tb_one_mac_gemm;
  //---------------------------
  // Design Time Parameters
  //---------------------------

  //---------------------------
  // DESIGN NOTE:
  // Parameters are a way to customize your design at
  // compile time. Here we define the data width,
  // memory depth, and number of ports for the
  // multi-port memory instances used in the DUT.
  //
  // In other test benches, you can also have test parameters,
  // such as the number of tests to run, or the sizes of
  // matrices to be used in the tests.
  //
  // You can customize these parameters as needed.
  // Or you can also add your own parameters.
  //---------------------------

  // General Parameters
  parameter int unsigned InDataWidth    = 8;
  parameter int unsigned goldenTempSize = 1024;
  parameter int unsigned DataDepth      = 64;
  parameter int unsigned AddrWidth      = (DataDepth <= 1) ? 1 : $clog2(DataDepth);
  parameter int unsigned SizeAddrWidth  = 8;

  // added ourselves
  parameter int unsigned M = 8;
  parameter int unsigned K = 4;
  parameter int unsigned N = 2;

  // Input Data Width Parameters
  parameter int unsigned InDataWidthA = 8 * M * K; // Matrix A
  parameter int unsigned InDataWidthB = 8 * K * N; // Matrix B

  // Output Data Width Parameters
  parameter int unsigned OutDataWidth = 32; // Matrix C
  
  // Test Parameters
  parameter int unsigned MaxNum   = 64;
  parameter int unsigned ThreeCases = 0; //1;
  

  parameter int unsigned SingleM = 32;
  parameter int unsigned SingleK = 32;
  parameter int unsigned SingleN = 32;
  // parameter int unsigned SingleM = 4;
  // parameter int unsigned SingleK = 8;
  // parameter int unsigned SingleN = 4;

  int unsigned tempAddr, floorN, floorM, floorC, floorExtraC;
  int signed acc;

  //---------------------------
  // Wiresq
  //---------------------------
  // Size control
  // logic [SizeAddrWidth-1:0] M_i, K_i, N_i;
  logic [SizeAddrWidth-1:0] M_i, K_i, N_i;

  // Removed illegal variable-sized arrays and parameters
  // logic signed [InDataWidth-1:0] orderedA [0:M_i*K_i-1];
  // logic signed [InDataWidth-1:0] orderedB, orderedBT [0:K_i*N_i-1];
  // parameter int signed tempAddrA, floorKA, floorMA, tempAddrB, floorKB, floorNB;

  // Clock, reset, and other signals
  logic clk_i;
  logic rst_ni;
  logic start;
  logic done;
  logic unsigned [AddrWidth*M*N:0] test_depth;
  logic unsigned [1:0] NumTests;



  logic signed [InDataWidth-1:0] tempA     [0:goldenTempSize-1]; // goldenTempSize should be Ki*Mi in reality, but this is always lower than or equal to goldenTempSize
  logic signed [InDataWidth-1:0] tempB     [0:goldenTempSize-1];
  logic signed [OutDataWidth-1:0] tempC    [0:goldenTempSize-1];
  logic signed [InDataWidth-1:0] orderedA  [0:goldenTempSize-1];
  logic signed [InDataWidth-1:0] orderedB  [0:goldenTempSize-1];
  logic signed [InDataWidth-1:0] orderedBT [0:goldenTempSize-1];

  //---------------------------
  // Memory
  //---------------------------
  // Golden data dump
  logic signed [OutDataWidth-1:0] G_memory [0:goldenTempSize-1]; 
  logic signed [OutDataWidth-1:0] reorderedOut [0:goldenTempSize-1];

  // Memory control
  logic [AddrWidth-1:0] sram_a_addr;
  logic [AddrWidth-1:0] sram_b_addr;
  logic [AddrWidth-1:0] sram_c_addr;

  // Memory access
  logic signed [ InDataWidthA-1:0] sram_a_rdata;
  logic signed [ InDataWidthB-1:0] sram_b_rdata;
  logic signed [ OutDataWidth*M*N-1:0] sram_c_wdata;
  logic                           sram_c_we;
  

  //---------------------------
  // Declaration of input and output memories
  //---------------------------

  //---------------------------
  // DESIGN NOTE:
  // These are where the memories are instantiated for the DUT.
  // You can modify the data width and data depth parameters.
  //
  // This can be useful for increasing your memory bandwidth.
  // However, you need to think about and take care of how to,
  // initialize the memories accordingly.
  // That includes knowing how to pack the data accordingly.
  //
  // Make sure that the connection for the address, data, and wen
  // signals are consistent with the number of ports.
  //
  // Refer to the single_port_memory.sv and 
  // tb_single_port_memory.sv file for more details.
  //---------------------------

  // Input memory A
  // Note: this is read only
  single_port_memory #(
    .DataWidth     ( InDataWidthA ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_a (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_a_addr  ),
    .mem_we_i      ( '0           ),
    .mem_wr_data_i ( '0           ),
    .mem_rd_data_o ( sram_a_rdata )
  );

  // Input memory B
  // Note: this is read only
  single_port_memory #(
    .DataWidth     ( InDataWidthB ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_b (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_b_addr  ),
    .mem_we_i      ( '0           ),
    .mem_wr_data_i ( '0           ),
    .mem_rd_data_o ( sram_b_rdata )
  );

  // Output memory C
  // Note: this is write only
  single_port_memory #(
    .DataWidth     ( OutDataWidth*M*N ),
    .DataDepth     ( DataDepth    ),
    .AddrWidth     ( AddrWidth    )
  ) i_sram_c (
    .clk_i         ( clk_i        ),
    .rst_ni        ( rst_ni       ),
    .mem_addr_i    ( sram_c_addr  ),
    .mem_we_i      ( sram_c_we    ),
    .mem_wr_data_i ( sram_c_wdata ),
    .mem_rd_data_o ( /* unused */ )
  );

  //---------------------------
  // DUT instantiation
  //---------------------------
  gemm_accelerator_top #(
    .InDataWidth   ( InDataWidth   ),
    .OutDataWidth  ( OutDataWidth  ),
    .AddrWidth     ( AddrWidth     ),
    .SizeAddrWidth ( SizeAddrWidth ),
    .M             ( M             ),
    .N             ( N             ),
    .K             ( K             )
  ) i_dut (
    .clk_i          ( clk_i        ),
    .rst_ni         ( rst_ni       ),
    .start_i        ( start        ),
    .N_size_i       ( N_i          ),
    .M_size_i       ( M_i          ),
    .K_size_i       ( K_i          ),
    .sram_a_addr_o  ( sram_a_addr  ),
    .sram_b_addr_o  ( sram_b_addr  ),
    .sram_c_addr_o  ( sram_c_addr  ),
    .sram_a_rdata_i ( sram_a_rdata ),
    .sram_b_rdata_i ( sram_b_rdata ),
    .sram_c_wdata_o ( sram_c_wdata ),
    .sram_c_we_o    ( sram_c_we    ),
    .done_o         ( done         )
  );

  //---------------------------
  // Tasks and functions
  //---------------------------
  `include "includes/common_tasks.svh"
  `include "includes/test_tasks.svh"
  `include "includes/test_func.svh"

  //---------------------------
  // Test control
  //---------------------------

  // Clock generation
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;  // 100MHz clock
  end

  //---------------------------
  // DESIGN NOTE:
  //
  // The sequence driver is usually the main stimulus
  // generator for the test bench. Here is where
  // you define the sequence of operations to be
  // performed during the simulation.
  //
  // It often starts with an initial reset sequence,
  // by loading default values and asserting the reset.
  //
  // We also do for-loops to run multiple tests
  // with different input parameters. In this case,
  // we randomize the matrix sizes for each test.
  //
  // You can also customize in here the way
  // the memories are initialized, how the golden
  // results are generated, and how the results
  // are verified.
  //
  // Refer to the tasks and functions included above
  // for more details.
  //---------------------------

  // Sequence driver
  initial begin

    // Initial reset
    start  = 1'b0;
    rst_ni = 1'b0;
    NumTests = ThreeCases ? 3 : 1;
    #50;
    rst_ni = 1'b1;

    $display("---------------------------------------------------");

    for (integer num_test = 0; num_test < NumTests; num_test++) begin
      $display("Test number: %0d", num_test);

      if (ThreeCases) begin
        if(num_test == 0) begin
          M_i = 4;
          K_i = 64;
          N_i = 16;
        end else if(num_test == 1) begin
          M_i = 16;
          K_i = 64;
          N_i = 4;
        end else if(num_test == 2) begin
          M_i = 32;
          K_i = 32;
          N_i = 32;
        end
      end else begin
        M_i = SingleM;
        K_i = SingleK;
        N_i = SingleN;
      end

      $display("M: %0d, K: %0d, N: %0d", M_i, K_i, N_i);

      //---------------------------
      // DESIGN NOTE:
      // You will most likely modify this part
      // to initialize the input memories
      // according to your design requirements.
      //
      // In here, we simply fill the memories
      // with random data for testing.
      //
      // We assume a row-major storage for both matrices A and B.
      // Row major means that the elements of each row
      // are stored in contiguous memory locations.
      //
      // We also make the assumption that the matrix output C
      // will be stored in row-major format as well.
      //
      // Take note that you WILL change this part according to your design.
      // Just make sure that the way you initialize the memories
      // is consistent with the way you generate the golden results
      // and the way your DUT reads/writes the data.
      //
      // The tricky part here is that since the data accesses are
      // shared within a single long bit-width (suppose you use longer)
      // memory word. For example, if your memory word is 32 bits wide
      // and your data width is 8 bits, then you can pack
      // 4 data elements in a single memory word.
      // So when you initialize the memory, you need to
      // make sure that the data elements are packed
      // correctly within each memory word.
      //---------------------------

      // Initialize memories with random data
      for (integer m = 0; m < M_i/M; m++) begin
        for (integer k = 0; k < K_i/K; k++) begin
          i_sram_a.memory[m*K_i/K+k] = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()} ;//% (2 ** (InDataWidth*M*K));
          // i_sram_a.memory[0] = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 8'd11, 8'd12, 8'd13, 8'd14, 8'd15};
          // i_sram_a.memory[1] = {8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd21, 8'd22, 8'd23, 8'd24, 8'd25, 8'd26, 8'd27, 8'd28, 8'd29, 8'd30, 8'd31};

        end
      end

      for (integer k = 0; k < K_i/K; k++) begin
        for (integer n = 0; n < N_i/N; n++) begin
          i_sram_b.memory[k*N_i/N+n] = {$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()} ;//% (2 ** InDataWidth*K*N);
          // i_sram_b.memory[0] = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 8'd11, 8'd12, 8'd13, 8'd14, 8'd15};
          // i_sram_b.memory[1] = {8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd21, 8'd22, 8'd23, 8'd24, 8'd25, 8'd26, 8'd27, 8'd28, 8'd29, 8'd30, 8'd31};
        end
      end

      // Generate golden result
      gemm_golden(M_i, K_i, N_i, i_sram_a.memory, i_sram_b.memory, G_memory);

      // Just delay 1 cycle
      clk_delay(1);

      // Execute the GeMM
      start_and_wait_gemm();

      // Reorder output memory layout
      // for (int unsigned m = 0; m < M_i; m++) begin
      //   for (int unsigned n = 0; n < N_i; n++) begin
      //     floorN = n/N;
      //     floorM = m/M;
      //     tempAddr = floorN*M*K + floorM*M*K_i + n%N + (m%M)*N; // floor(n,N)*M*K + floor(m,M)*M*Ni + mod(n,N) + mod(m,M)*N
      //     reorderedOut[tempAddr] = i_sram_c.memory[N_i*m + n];
      //   end
      // end
      // Place concatenated words of A_i into array tempA with only 8 bit words
      for (int unsigned t = 0; t < (N_i/N) * (M_i/M); t++) begin
        for (int unsigned u = 0; u < M*N; u++) begin
          tempC[t*N*M + u] = i_sram_c.memory[t][u*OutDataWidth+:OutDataWidth];
        end
      end

      for (int unsigned t = 0; t < N_i*M_i; t+=N) begin
        floorC = t/(M*N);
        floorExtraC = t/(M*N_i);
        reorderedOut[(t%(M*N)) * (N_i/N) + floorC*N + floorExtraC*(M-1)*N_i +:N] = tempC[t+:N];
      end


      // Verify the result
      test_depth = (M_i) * (N_i);
      verify_result_c(G_memory, reorderedOut, test_depth,
                      0 // Set this to 1 to make mismatches fatal
      );

      // Just some trailing cycles
      // For easier monitoring in waveform
      clk_delay(10);
      $display("---------------------------------------------------");
    end

    $display("All test tasks completed!");
    $finish;
  end

endmodule
