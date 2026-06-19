module emulador_sensor #(
    parameter REG_NUM = 16,
    parameter REG_SIZE = 8,
    parameter REG_ID
)(
    input  logic clk,
    input  logic rst,

    input  logic se,
    output logic miso,
    input  logic mosi,
    output logic sclk,


    // lista de registradores, virou saída para ser conferido no TB
    output logic[REG_SIZE-1:0] regs [0:REG_NUM-1]
);

// temp register
logic[REG_SIZE-1:0] temp_reg;

logic [$clog2(REG_NUM)-1:0] addr_received; // Endereço do registrador para coletar, recebido pelo MOSI 
logic [5:0] bit_cnt_mosi; // Bit counter para o MOSI
logic [5:0] bit_cnt_miso; // Bit counter para o MISO


// state machine - SPI
typedef enum logic [1:0] {
    IDLE, RECEIVE, SEND
} state_t;

state_t EA;  // estado atual
state_t PE;  // próximo estado

// clk de saída do sensor,
// para sincronizar com o coletor
assign sclk = (EA == IDLE) ? 1'b0 : clk;

// Lógica para decidir próximo estado
always_comb begin
    case (EA)
        IDLE:       PE = (se && !rst) ? RECEIVE : IDLE;

        RECEIVE:    PE = (bit_cnt_mosi == $clog2(REG_NUM)) ? SEND : RECEIVE;

        SEND:       PE = (bit_cnt_miso == REG_SIZE - 1) ? IDLE : SEND;
        default:    PE = IDLE;
    endcase
end


// FSM Sequencial
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        EA <= IDLE;
    else 
        EA <= PE;
end   

// lê/escreve dos registradores internos 
// de acordo com o estado atual
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        bit_cnt_mosi   <= '0;
        bit_cnt_miso   <= '0;
        addr_received <= '0;
        temp_reg  <= '0;
        miso <= 1'b0;
    end
    else begin
    case (EA)
        IDLE: begin
            bit_cnt_mosi   <= '0;
            bit_cnt_miso   <= '0;
            addr_received <= '0;
            temp_reg  <= '0;
        end
 
        RECEIVE: begin
            bit_cnt_miso <= '0;
            addr_received <= {addr_received[$clog2(REG_NUM)-2:0], mosi};
            bit_cnt_mosi <= bit_cnt_mosi + 1;
            temp_reg <= regs[addr_received];
        end
 
        SEND: begin
            miso <= temp_reg[REG_SIZE-1];
            temp_reg <= {temp_reg[REG_SIZE-2:0], 1'b0}; // temp_reg << 1
            bit_cnt_miso  <= bit_cnt_miso + 1;
        end
 
    endcase
    end
end


// atualiza a leitura do sensor periodicamente
genvar i;
generate
    for (i = 0; i < REG_NUM; i++) begin
        always_ff @(posedge clk or posedge rst) begin
            if(rst) regs[i] = 0;
            else regs[i] = i*$random(REG_ID); // qualquer coisa no sensor
        end
    end
endgenerate

endmodule 