module Multiplier # (parameter N = 4) (
    input wire clk,
    input wire rst_n,

    input wire start,
    output reg ready,

    input wire   [N-1:0] multiplier,
    input wire   [N-1:0] multiplicand,
    output reg [2*N-1:0] product
);

    // Definição dos estados
    localparam [1:0] 
        IDLE      = 2'b00,  // Aguardando início
        COMPUTING = 2'b01,  // Realizando cálculos
        DONE      = 2'b10;  // Operação concluída

    // Registradores
    reg [N-1:0]   multiplier_reg;    // Registro do multiplicador
    reg [2*N-1:0] multiplicand_reg;  // Registro do multiplicando
    reg [2*N-1:0] product_reg;       // Registro acumulador do produto
    reg [N-1:0]   counter;           // Contador de ciclos
    reg [1:0]     current_state;     // Estado atual

    // Estado atual
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state     <= IDLE;
            multiplier_reg    <= 0;
            multiplicand_reg  <= 0;
            product_reg       <= 0;
            counter           <= 0;
            ready             <= 0;
        end 
        else begin
            current_state    <= next_state;
            multiplier_reg   <= next_multiplier;
            multiplicand_reg <= next_multiplicand;
            product_reg      <= next_product;
            counter          <= next_counter;
            ready            <= next_ready;
        end
    end

    // Sinais para o próximo estado
    reg [1:0]     next_state;
    reg [N-1:0]   next_multiplier;
    reg [2*N-1:0] next_multiplicand;
    reg [2*N-1:0] next_product;
    reg [N-1:0]   next_counter;
    reg           next_ready;

    // Próximo estado
    always @(*) begin
        next_state      = current_state;
        next_multiplier = multiplier_reg;
        next_multiplicand = multiplicand_reg;
        next_product    = product_reg;
        next_counter    = counter;
        next_ready     = 0;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_multiplier   = multiplier;
                    next_multiplicand = {{N{1'b0}}, multiplicand}; 
                    next_product      = 0;
                    next_counter      = 0;
                    next_state        = COMPUTING;
                end
            end

            COMPUTING: begin
                if (multiplier_reg == 0) begin
                    // Multiplicador zerado, operação concluída
                    next_state = DONE;
                end else begin
                    // Verifica bit menos significativo do multiplicador
                    if (multiplier_reg[0]) begin
                        next_product = product_reg + multiplicand_reg;
                    end

                    // Deslocamentos
                    next_multiplicand = multiplicand_reg << 1;
                    next_multiplier   = multiplier_reg >> 1;
                    
                    // Incrementa contador
                    next_counter = counter + 1;

                    // Verifica se já foram processados todos os bits
                    if (next_counter == N) begin
                        next_state = DONE;
                    end
                end
            end

            DONE: begin
                // Sinaliza pronto por um ciclo
                next_ready = 1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Saídas
    always @(*) begin
        product = product_reg;
    end

endmodule