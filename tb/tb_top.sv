`timescale 1ns/1ps

module tb_top;

localparam REG_SIZE = 8;
localparam REG_NUM = 8;

logic clk_100 = 0;  
logic clk_50 = 0;
logic clk_40 = 0;  
logic clk_25 = 0;
logic clk_15 = 0;

always #5 clk_100 = ~clk_100;  // 100 MHz
always #10 clk_50 = ~clk_50;   // 50 MHz
always #25 clk_40 = ~clk_40;   // 40 MHz
always #20 clk_25 = ~clk_25;   // 25 MHz
always #33.333 clk_15 = ~clk_15;   // 15 MHz (aproximadamente)

logic rst;
logic start_i;
logic [1:0] reg_id_i;
logic ready_o;
logic [7:0] mem_data_o;
logic [7:0] mem_addr_tb;
logic [REG_SIZE-1:0] es1_regs [0:REG_NUM-1];    // 
logic [REG_SIZE-1:0] es2_regs [0:REG_NUM-1];    //  Regitradores dos sensores para amostragem
logic [REG_SIZE-1:0] es3_regs [0:REG_NUM-1];    //
logic [REG_SIZE-1:0] es4_regs [0:REG_NUM-1];    //

top #(
    .REG_NUM  (REG_NUM),
    .REG_SIZE (REG_SIZE)
) dut (
    .clk_15 (clk_15),
    .clk_40 (clk_40),
    .clk_50 (clk_50),
    .clk_25 (clk_25),
    .clk_100 (clk_100),
    .rst(rst),
    .start_i (start_i),
    .reg_id_i (reg_id_i),
    .ready_o (ready_o),
    .mem_data_o (mem_data_o),
    .mem_addr_tb (mem_addr_tb),
    .es1_regs (es1_regs),
    .es2_regs (es2_regs),
    .es3_regs (es3_regs),
    .es4_regs (es4_regs)
);

function automatic logic [7:0] valor_esperado(input logic [1:0] sensor_id, input logic [7:0] reg_idx);
    case(sensor_id)
        2'b00: return es1_regs[reg_idx];
        2'b01: return es2_regs[reg_idx];
        2'b10: return es3_regs[reg_idx];
        2'b11: return es4_regs[reg_idx];
    endcase
endfunction

task coleta_sensor(input logic [1:0] sensor_id);
    start_i = 1'b0;
    // Esperando o CD dar "ready"
    @(posedge clk_100);
    while(!ready_o) @(posedge clk_100);

    // Sinaliza começo para o CD
    @(posedge clk_100);
    reg_id_i = sensor_id;
    start_i = 1'b1;
    @(posedge clk_100);
    @(posedge clk_100);
    start_i = 1'b0;

    @(posedge clk_100);
    while(!ready_o) begin
        @(posedge clk_100);
    end
    
    repeat(5) @(posedge clk_100);
endtask

int pass_count;
int fail_count;
logic[7:0] mem_base_addr; // Endereço de memória do primeiro registrador desse sensor
logic[7:0] exp_val, got_val; // Valor esperado e valor encontrado

task verifica_coleta(input logic [1:0] sensor_id);
    mem_base_addr = sensor_id * REG_NUM;
    for (int r = 0; r < REG_NUM; r++) begin
        exp_val = valor_esperado(sensor_id, r);

        mem_addr_tb = mem_base_addr + r;    
        repeat(3) @(posedge clk_100);
        got_val = mem_data_o;

        if (got_val == exp_val) begin
            $display("[TB] PASS! Sensor %d reg[%0d]: Esperado=0x%02h Encontrado=0x%02h", sensor_id, r, exp_val, got_val);
            pass_count++;
        end else begin
            $display("[TB] PASS! Sensor %d reg[%0d]: Esperado=0x%02h Encontrado=0x%02h", sensor_id, r, exp_val, got_val);
            fail_count++;
        end
    end
endtask

initial begin
        pass_count = 0;
        fail_count = 0;

        $display("TRABALHO 3 - SISTEMAS DIGITAIS - 2026/1");
        $display("Estudantes: Alexandre Utzig do Amaral Padilha, Giovanni Camargo Gardenal Morandi, Henrique Skolaude Staubus, Solano Schmidt Battisti");

        rst = 1'b1;
        start_i = 1'b0; 
        reg_id_i = '0; 
        mem_addr_tb = '0;
        repeat(100) @(posedge clk_100);
        rst = 1'b0;
        repeat(10) @(posedge clk_100);

        $display("\n[TB] Teste 1.a: Coleta Sensor 1");
        coleta_sensor(2'b00);
        $display("\n[TB] Teste 1.b: Verifica Coleta 1");
        verifica_coleta(2'b00);

        $display("\n[TB] Teste 2.a: Coleta Sensor 2");
        coleta_sensor(2'b01);
        $display("\n[TB] Teste 2.b: Verifica Coleta 2");
        verifica_coleta(2'b01);

        $display("\n[TB] Teste 3.a: Coleta Sensor 3");
        coleta_sensor(2'b10);
        $display("\n[TB] Teste 3.b: Verifica Coleta 3");
        verifica_coleta(2'b10);

        $display("\n[TB] Teste 4.a: Coleta Sensor 4");
        coleta_sensor(2'b11);
        $display("\n[TB] Teste 4.b: Verifica Coleta 4");
        verifica_coleta(2'b11);

        $display(" ");
        $display("RESULTADOS: %0d PASS, %0d FAIL", pass_count, fail_count);

end


endmodule
