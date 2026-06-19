module top #(
    parameter int REG_NUM  = 16,
    parameter int REG_SIZE = 8
)(
    // Clocks, gerados externamente
    input logic clk_15,
    input logic clk_40,
    input logic clk_50,
    input logic clk_25,
    input logic clk_100,

    input logic rst,

    // Comunicação TB-CD
    output logic ready_o,
    input logic start_i,
    input logic [1:0] reg_id_i,

    // leitura de memória do TB 
    output logic [7:0] mem_data_o,
    input logic [7:0] mem_addr_tb,  // TB pode acessar qualquer endereço

    output logic [REG_SIZE-1:0] es1_regs [0:REG_NUM-1],
    output logic [REG_SIZE-1:0] es2_regs [0:REG_NUM-1],
    output logic [REG_SIZE-1:0] es3_regs [0:REG_NUM-1],
    output logic [REG_SIZE-1:0] es4_regs [0:REG_NUM-1]
);

logic mosi;
logic [3:0] se;   // se[0]=ES1, se[1]=ES2, se[2]=ES3, se[3]=ES4

// MISO: depende do sensor selecionado no momento (ES não selecionado gera MISO = Z)
logic miso_es1, miso_es2, miso_es3, miso_es4;
logic miso;

assign miso = ((se[0]) ? miso_es1 : 
                (se[1]) ? miso_es2 :
                (se[2]) ? miso_es3 :
                (se[3]) ? miso_es4 : 1'bz);

// sclk também depende do sensor selecionado
logic sclk_es1, sclk_es2, sclk_es3, sclk_es4;
logic sclk;

assign sclk = ((se[0]) ? sclk_es1 : 
                (se[1]) ? sclk_es2 :
                (se[2]) ? sclk_es3 :
                (se[3]) ? sclk_es4 : clk_100);


logic [7:0] mem_addr_cd;
logic [7:0] mem_data_i_cd;
logic mem_we_cd;

// CD e TB tem mem_addr: CD escreve durante a operação, TB lê depois
logic [7:0] mem_addr;
assign mem_addr = (mem_we_cd) ? mem_addr_cd : mem_addr_tb;

memoria ram (
    .clk (clk_100),
    .we (mem_we_cd),
    .addr (mem_addr),
    .data_i (mem_data_i_cd),
    .data_o (mem_data_o)
);

coletor_dados #(
    .NUM_SLAVES (4),
    .REG_NUM (REG_NUM),
    .REG_SIZE (REG_SIZE)
) cd (
    .clk (clk_100),
    .rst (rst),
    .sclk (sclk),
    .mosi (mosi),
    .miso (miso),
    .se (se),
    .mem_addr (mem_addr_cd),
    .mem_data_i (mem_data_i_cd),
    .mem_we (mem_we_cd),
    .ready_o (ready_o),
    .start_i (start_i),
    .reg_id_i (reg_id_i)
);

// Sensor 1 - 15 MHz
emulador_sensor #(
    .REG_NUM (REG_NUM),
    .REG_SIZE (REG_SIZE),
    .REG_ID (2'b00)
) es1 (
    .clk (clk_15),
    .rst (rst),
    .sclk (sclk_es1),
    .mosi (mosi),
    .se (se[0]),
    .miso (miso_es1),
    .regs (es1_regs)
);

// Sensor 2 - 40 MHz
emulador_sensor #(
    .REG_NUM (REG_NUM),
    .REG_SIZE (REG_SIZE),
    .REG_ID (2'b01)
) es2 (
    .clk (clk_40),
    .rst (rst),
    .sclk (sclk_es2),
    .mosi (mosi),
    .se (se[1]),
    .miso (miso_es2),
    .regs (es2_regs)
);

// Sensor 3 - 50 MHz
emulador_sensor #(
    .REG_NUM (REG_NUM),
    .REG_SIZE (REG_SIZE),
    .REG_ID (2'b10)
) es3 (
    .clk (clk_50),
    .rst (rst),
    .sclk (sclk_es3),
    .mosi (mosi),
    .se (se[2]),
    .miso (miso_es3),
    .regs (es3_regs)
);

// Sensor 4 - 25 MHz
emulador_sensor #(
    .REG_NUM (REG_NUM),
    .REG_SIZE (REG_SIZE),
    .REG_ID (2'b11)
) es4 (
    .clk (clk_25),
    .rst (rst),
    .sclk (sclk_es4),
    .mosi (mosi),
    .se (se[3]),
    .miso (miso_es4),
    .regs (es4_regs)
);

endmodule