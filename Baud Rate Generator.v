module BaudRateGen #(
    parameter FIRST_TARGET = 5208,
    parameter TARGET = 5208
)(
    input clk,
    input rst,
    output reg rate
);

reg[12:0] count;
reg first_pulse;

always@(posedge clk) begin
    if(rst) begin
        count <= 0;
        rate <= 0;
        first_pulse <= 1;
    end
    else if((first_pulse && count == FIRST_TARGET) || (!first_pulse && count == TARGET)) begin
        rate <= 1;
        count <= 0;
        first_pulse <= 0;
    end
    else begin
        rate <= 0;
        count <= count + 1;
    end
end

endmodule