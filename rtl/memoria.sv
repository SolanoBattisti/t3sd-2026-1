module memoria (
    input  logic        clk,    // mesmo do CD
    input  logic        we,
    input  logic [7:0]  addr,
    input  logic [7:0]  data_i,
    output logic [7:0]  data_o
);

    // 256 x 8 bits
    logic [7:0] mem [255] = '{default: '0};

    // Write
    always_ff @(negedge clk) begin
        if (we) begin
            $display("[MEM] Escrevendo 0x%02h no endereço %d da memória", data_i, addr); // Print para teste
            mem[addr] <= data_i;
        end
    end

    // Leitura
    always_ff @(negedge clk) begin
        data_o <= mem[addr];
    end

endmodule
