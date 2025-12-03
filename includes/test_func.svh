//--------------------------
// Useful functions for testing
//--------------------------
function automatic void gemm_golden(
  input  logic [SizeAddrWidth-1:0] Mi,
  input  logic [SizeAddrWidth-1:0] Ki,
  input  logic [SizeAddrWidth-1:0] Ni,
  input  logic signed [ InDataWidthA-1:0] A_i [DataDepth],
  input  logic signed [ InDataWidthB-1:0] B_i [DataDepth],
  output logic signed [ OutDataWidth-1:0] Y_o [DataDepth]
);
  // Iterate over the output matrix dimensions (Row-Major C)
  // Truncate dimensions to multiples of M, K, N to match hardware behavior
  int Mi_trunc = (Mi / M) * M;
  int Ki_trunc = (Ki / K) * K;
  int Ni_trunc = (Ni / N) * N;

  for (int m = 0; m < Mi_trunc; m++) begin
    for (int c = 0; c < Ni_trunc; c++) begin
      logic signed [OutDataWidth-1:0] acc = 0;
      for (int k_idx = 0; k_idx < Ki_trunc; k_idx++) begin
        int unsigned m_tile, k_tile_a, local_r_a, local_c_a, tile_idx_a, bit_offset_a;
        logic signed [InDataWidth-1:0] val_a;
        int unsigned k_tile_b, n_tile, local_r_b, local_c_b, tile_idx_b, bit_offset_b;
        logic signed [InDataWidth-1:0] val_b;

        // -------------------------------------------------------
        // Extract A[m][k_idx] from tiled memory A_i
        // -------------------------------------------------------
        // Tile coordinates
        m_tile = m / M;
        k_tile_a = k_idx / K;
        // Local coordinates within the tile
        local_r_a = m % M;
        local_c_a = k_idx % K;
        
        // Index of the tile in A_i
        tile_idx_a = m_tile * (Ki/K) + k_tile_a;
        // Bit offset within the tile (Row-Major: row * Width + col)
        bit_offset_a = (local_r_a * K + local_c_a) * InDataWidth;
        
        val_a = A_i[tile_idx_a][bit_offset_a +: InDataWidth];

        // -------------------------------------------------------
        // Extract B[k_idx][c] from tiled memory B_i
        // -------------------------------------------------------
        // Tile coordinates
        k_tile_b = k_idx / K;
        n_tile = c / N;
        // Local coordinates within the tile
        local_r_b = k_idx % K;
        local_c_b = c % N;
        
        // Index of the tile in B_i
        tile_idx_b = k_tile_b * (Ni/N) + n_tile;
        // Bit offset within the tile (Row-Major: row * Width + col)
        bit_offset_b = (local_r_b * N + local_c_b) * InDataWidth;
        
        val_b = B_i[tile_idx_b][bit_offset_b +: InDataWidth];

        // Accumulate
        acc += $signed(val_a) * $signed(val_b);
      end
      Y_o[m * Ni_trunc + c] = acc;
    end
  end
endfunction