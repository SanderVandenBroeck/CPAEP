//--------------------------
// Useful functions for testing
//--------------------------
function automatic void gemm_golden(
  input  logic [AddrWidth-1:0] Mi,
  input  logic [AddrWidth-1:0] Ki,
  input  logic [AddrWidth-1:0] Ni,
  input  logic signed [ InDataWidthA-1:0] A_i [DataDepth],
  input  logic signed [ InDataWidthB-1:0] B_i [DataDepth],
  output logic signed [ OutDataWidth-1:0] Y_o [DataDepth]
);
  // int unsigned m, n, k;
  // int signed acc;

  // for (m = 0; m < M; m++) begin
  //   for (n = 0; n < N; n++) begin
  //     acc = 0;
  //     for (k = 0; k < K; k++) begin
  //       acc += $signed(A_i[m*K + k]) * $signed(B_i[k*N + n]);
  //     end
  //     Y_o[m*N + n] = acc;
  //   end
  // end

  logic [InDataWidthA] orderedA [0:Mi*Ki-1];
  logic [InDataWidthB] orderedB, orderedBT [0:Ki*Ni-1];
  int unsigned tempAddrA, floorKA, floorMA, tempAddrB, floorKB, floorNB;

  // Reorder A matrix
  generate
  for (int unsigned m = 0; m < Mi; m++) begin
    for (int unsigned kA = 0; kA < Ki; kA++) begin
      floorKA = kA/K;
      floorMA = m/M;
      tempAddrA = floorKA*M*K + floorMA*M*Ki + kA%K + (m%M)*K; // floor(k,K)*M*K + floor(m,M)*M*Ki + mod(k,K) + mod(m,M)*K
      assign orderedA[tempAddrA] = A_i[Ki*m + kA];
    end
  end

  // Reorder B matrix
  // same as previous:
  for (int unsigned n = 0; n < Ni; n++) begin
    for (int unsigned kB = 0; kB < Ki; kB++) begin
      floorKB = kB/K;
      floorNB = n/N;
      tempAddrB = floorKB*N*K + floorNB*N*Ki + kB%K + (n%N)*K; // floor(k,K)*M*K + floor(m,M)*M*Ki + mod(k,K) + mod(m,M)*K
      assign orderedBT[tempAddrB] = B_i[Ki*n + kB];
    end
  end
  // Tranpose B
  for (int unsigned k = 0; k < Ki; k++) begin
    for (int unsigned n = 0; n < Ni; n++) begin
      assign orderedB[ n*Ki + k ] = orderedBT[ k*Ni + n ];
    end
  end
  endgenerate

  int unsigned m, n, k;
  int signed acc [0:M*N-1];

  for (m = 0; m < M; m++) begin
    for (n = 0; n < N; n++) begin
      acc = 0;
      for (k = 0; k < K; k++) begin
        acc += $signed(A_i[m*K + k]) * $signed(B_i[k*N + n]);
      end
      Y_o[m*N + n] = acc;
    end
  end
endfunction