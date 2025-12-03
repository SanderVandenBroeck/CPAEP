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

  int unsigned m2, n2, k2;
  int unsigned floorA, floorExtra, tempAddrA;
  int unsigned floorB, floorExtraB, tempAddrB;
  int signed acc;

  // Use constant bounds (DataDepth) instead of variable bounds


  // Place concatenated words of A_i into array tempA with only 8 bit words
  for (int unsigned t = 0; t < (Ki/K) * (Mi/M); t++) begin
    for (int unsigned u = 0; u < M*K; u++) begin
      tempA[t*K*M + u] = A_i[t][u*InDataWidth+:InDataWidth];
    end
  end

  // Reorder A matrix
  // for (int unsigned m = 0; m < Mi; m++) begin
  //   for (int unsigned k = 0; k < Ki; k++) begin
  //     floorKA = k/K;
  //     floorMA = m/M;
  //     tempAddrA = floorKA*M*Ki/K + floorMA*M*Ki + k%K + (m%M)*K; // floor(k,K)*M*K + floor(m,M)*M*Ki + mod(k,K) + mod(m,M)*K
  //     orderedA[tempAddrA] = tempA[Ki*m + k];
  //   end
  // end
  for (int unsigned t = 0; t < Ki*Mi; t+=K) begin
    floorA = t/(M*K);
    floorExtra = t/(M*Ki);
    orderedA[(t%(M*K)) * (Ki/K) + floorA*K + floorExtra*(M-1)*Ki +:K] = tempA[t+:K];
  end

  // Place concatenated words of B_i into array tempB with only 8 bit words
  for (int unsigned t = 0; t < (Ki/K) * (Ni/N); t++) begin
    for (int unsigned u = 0; u < N*K; u++) begin
      tempB[t*K*N + u] = B_i[t][u*InDataWidth+:InDataWidth];
    end
  end

  // Reorder B matrix
  // same as previous:
  // for (int unsigned n = 0; n < Ni; n++) begin
  //   for (int unsigned kB = 0; kB < Ki; kB++) begin
  //     floorKB = kB/K;
  //     floorNB = n/N;
  //     tempAddrB = floorKB*N*K + floorNB*N*Ki + kB%K + (n%N)*K; // floor(k,K)*M*K + floor(m,M)*M*Ki + mod(k,K) + mod(m,M)*K
  //     orderedBT[tempAddrB] = tempB[Ki*n + kB];
  //   end
  // end
  for (int unsigned t = 0; t < Ki*Ni; t+=K) begin
    floorB = t/(N*K);
    floorExtraB = t/(N*Ki);
    orderedBT[(t%(N*K)) * (Ki/K) + floorB*K + floorExtraB*(N-1)*Ki +:K] = tempB[t+:K];
  end


  // Tranpose B
  for (int unsigned k = 0; k < Ki; k++) begin
    for (int unsigned n = 0; n < Ni; n++) begin
      orderedB[ n*Ki + k ] = orderedBT[ k*Ni + n ];
    end
  end
  



  for (m2 = 0; m2 < Mi; m2++) begin
    for (n2 = 0; n2 < Ni; n2++) begin
      acc = 0;
      for (k2 = 0; k2 < Ki; k2++) begin
        acc += $signed(orderedA[m2*Ki + k2]) * $signed(orderedB[k2*Ni + n2]);
      end
      Y_o[m2*Ni + n2] = acc;
    end
  end
endfunction