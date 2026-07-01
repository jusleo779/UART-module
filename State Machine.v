module State_Machine(
    input clk,
    input tick,
    input EN,
    input shift_out,
    input reset,
    output reg[3:0] count,
    output reg tx,
    output reg shift,
    output reg load
);

reg [1:0] state;

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

always@(posedge clk) begin
    if(reset) begin
        state <= IDLE;
        count <= 0;
        tx <= 1;
        shift <= 0;
        load <= 0;
    end
    else begin
        case(state)
        
            IDLE: begin
                tx <= 1;
                if(EN) 
                    state <= START;
            end

            START: begin
                tx <= 0;
                if(tick) begin
                    state <= DATA;
                    load <= 1;
                end
            end

            DATA: begin
                tx <= shift_out;
                load <= 0;
                if(tick) begin
                    shift <= 1;
                    count <= count + 1;
                    if(count == 8)begin
                        state <= STOP;
                        count <= 0;
                    end
                end
                else
                    shift <= 0;
            end

            STOP: begin
                tx <= 1;
                if(tick) 
                    state <= IDLE;
            end
        endcase
    end
end

endmodule