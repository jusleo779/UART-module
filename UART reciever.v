module reciever(
    input d,
    input tick,
    input clk,
    input rst,
    output reg valid,
    output reg [7:0] out,
    output reg start_detected
);

reg d_prev;
reg [4:0] count;
reg [1:0] state;
parameter IDLE = 2'b00;
parameter START = 2'b01;
parameter DATA = 2'b10;
parameter STOP = 2'b11;



always@(posedge clk)begin
    if(rst)begin
        state <= IDLE;
        count <= 0;
        valid <= 0;
    end
    else begin
        start_detected <= 0;
        valid <= 0;
        d_prev <= d;
        case(state)
        
        IDLE:begin
            start_detected <= 0;
            if(d_prev == 1 & d == 0)begin //falling edge activate
                state <= START;
                start_detected <= 1;
            end
        end

        START:begin
            if(tick)
                state <= DATA;
        end

        DATA:begin
            if(tick)begin
                out[7:0] <= {d, out[7:1]};
                if(count == 7)begin
                    count <= 0;
                    valid <= 1;
                    state <= STOP;
                end
                else
                    count <= count + 1;
            end     
        end

        STOP:begin
            if(tick)
                state <= IDLE;
        end
        endcase
    end
end


endmodule