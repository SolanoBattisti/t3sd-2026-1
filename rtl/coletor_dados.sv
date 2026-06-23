module coletor_dados #(
    parameter NUM_SLAVES = 4,
    parameter REG_NUM = 16,
    parameter REG_SIZE = 8
)(
    input logic clk,
    input logic rst,

    // Interface SPI
    input logic sclk,
    output logic mosi,
    input logic miso,
    output logic [NUM_SLAVES-1:0] se,

    // Interface de acesso à memória
    output logic [7:0] mem_addr,
    output logic [7:0] mem_data_i,
    output logic mem_we,

    // Interface de comando
    output logic ready_o,
    input logic start_i,
    input logic [1:0] reg_id_i
);

// detectando edge do sclk vindo do sensor
logic sclk_r1, sclk_r2;
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_r1 <= 1'b0;
        sclk_r2 <= 1'b0;
    end else begin
        sclk_r1 <= sclk; 
        sclk_r2 <= sclk_r1;
    end
end

wire sclk_rise = ( sclk_r1 & ~sclk_r2);
wire sclk_fall = (~sclk_r1 &  sclk_r2);


typedef enum logic [2:0] {
    IDLE,
    SELECT_SLAVE,
    READY_TO_RECV,
    RECV_DATA,
    MEM_WRITE,
    NEXT_REG
} state_t;

state_t state;

logic [5:0] clk_cnt_mosi;    
logic [5:0] bit_cnt_miso;   // bit counter do MISO
logic [$clog2(REG_NUM)-1:0] reg_idx;    // index do registrador do sensor atual
logic [REG_SIZE-1:0] recv_shift;  // registrador de shift para o MISO
logic regs_done; // chegou no último registrador de um dado sensor

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        mosi <= 1'b0;
        se <= '0;
        mem_addr <= '0;
        mem_data_i <= '0;
        mem_we <= 1'b0;
        ready_o <= 1'b0;
        clk_cnt_mosi <= '0;
        bit_cnt_miso <= '0;
        reg_idx <= '0;
        recv_shift <= '0;
        regs_done <= 1'b0; 
    end 
    else begin
        case (state)
            IDLE: begin
                if(start_i) begin
                    ready_o <= 1'b0;    // Saindo do IDLE
                    state <= SELECT_SLAVE;
                end else begin
                    ready_o <= 1'b1;    // Esperando
                    mem_we <= 1'b0;
                    se <= '0;
                    regs_done <= 1'b0;
                    reg_idx <= '0;
                end
            end

            SELECT_SLAVE: begin
                clk_cnt_mosi <= '0;
                ready_o <= 1'b0;
                mosi <= 1'b0;
                se[reg_id_i] <= 1'b1;   // ativa o 'se' do sensor selecionado
                state <= READY_TO_RECV;
            end

            READY_TO_RECV: begin
                bit_cnt_miso <= '0;
                if(clk_cnt_mosi < 50) begin // Pequeno delay
                    clk_cnt_mosi <= clk_cnt_mosi + 1;
                end
                else begin
                    if(sclk_fall) begin
                        mosi <= 1'b1;   // Sinal de 'ready' para o sensor
                        state <= RECV_DATA;
                    end
                end
            end

            // Recebe o dado do sensor no MISO (Bit mais significante do dado vindo do sensor, na borda de descida do SCLK)
            RECV_DATA: begin
                clk_cnt_mosi <= '0;
                ready_o <= 1'b0;
                if (sclk_fall) begin
                    // $display("miso recebido: %b", miso); // Print para teste
                    recv_shift <= {recv_shift[REG_SIZE-2:0], miso}; 
                    bit_cnt_miso <= bit_cnt_miso + 1;
                    if (bit_cnt_miso == REG_SIZE - 1) begin
                        mosi <= 1'b0;
                        state <= MEM_WRITE;
                    end
                end
            end

            MEM_WRITE: begin
                ready_o <= 1'b0;
                mem_we <= 1'b1;
                mem_data_i <= recv_shift;
                if(reg_idx == (REG_NUM - 1)) regs_done <= 1'b1;
                state <= NEXT_REG;
            end

            NEXT_REG: begin
                ready_o <= 1'b0;
                mem_we <= 1'b0;
                // Incrementa endereço de memória
                mem_addr <= mem_addr + 1;
                // Avança para o próximo registrador do sensor atual ou termina
                if (regs_done) begin
                    state <= IDLE;
                end else begin
                    reg_idx <= reg_idx + 1;
                    state <= READY_TO_RECV;
                end
            end

            default: state <= IDLE;

        endcase
    end
end


endmodule
