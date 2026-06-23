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

assign sclk = clk;


logic [REG_SIZE-1:0] bit_cnt_miso; // Bit counter para o MISO
logic [$clog2(REG_NUM)-1:0] reg_idx;    // index do registrador sendo enviado

// MISO é sempre o bit mais significativo do registrador sendo enviado, se o sensor estiver selecionado
always_comb begin
    if(!se) miso = 1'bz;
    else miso = temp_reg[REG_SIZE-1];
end


// state machine - SPI
typedef enum logic [1:0] {
    IDLE, SETUP, SEND, NEXT_REG
} state_t;
state_t state;



always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        bit_cnt_miso <= '0;
        temp_reg <= '0;
        reg_idx <= '0;
    end
    else begin
        case (state)
            IDLE: begin
                reg_idx <= '0;
                bit_cnt_miso <= '0;
                temp_reg <= '0;
                if(se) state <= SETUP; 
            end

            SETUP: begin
                if(!se) state <= IDLE;
                else begin
                    bit_cnt_miso <= '0;
                    temp_reg <= regs[reg_idx];  // Carrega o temp_reg
                    if(mosi) begin  // MOSI vindo do CD sinaliza para início do envio
                        state <= SEND;
                    end
                end
            end

            SEND: begin
                if(!se) state <= IDLE;
                else begin
                    temp_reg <= {temp_reg[REG_SIZE-2:0], 1'b0}; // temp_reg << 1
                    bit_cnt_miso <= bit_cnt_miso + 1;
                    if(bit_cnt_miso == REG_SIZE - 1) begin
                        state <= NEXT_REG;
                    end
                end
            end

            NEXT_REG: begin
                if(!se) begin
                    state <= IDLE;
                end else begin
                    // Passa para o próximo registrador ou termina
                    if(reg_idx == REG_NUM - 1) state <= IDLE;
                    else begin
                        reg_idx <= reg_idx + 1;
                        state <= SETUP;
                    end
                end
            end

            default: state <= IDLE;
        endcase
    end
end

// Print para teste do MISO
// always_ff @(negedge clk) begin
//     if(state == SEND) begin
//         $display("miso: %b, bit_cnt_miso: %d", miso, bit_cnt_miso);
//     end
// end

// atualiza a leitura do sensor periodicamente
genvar i;
generate
    for (i = 0; i < REG_NUM; i++) begin
        always_comb begin
            if(rst) regs[i] = 0;
            else regs[i] = 60 + REG_ID*29 + i*23; // qualquer coisa no sensor
        end
    end
endgenerate

endmodule 
