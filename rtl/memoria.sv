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
        if (we)
            //$display("escrevendo %b em %h", data_i, addr);
            mem[addr] <= data_i;
    end

    // Leitura
    always_ff @(negedge clk) begin
        data_o <= mem[addr];
    end

endmodule
