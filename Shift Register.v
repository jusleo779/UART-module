module Shift_reg(
    input clk,
    input shift,
    input load,
    input [7:0] data,
    output out
);

reg [7:0] dataLoaded;

always@(posedge clk)begin
    if(load)
        dataLoaded <= data;
    else if(shift)begin
        dataLoaded <= {1'b0,dataLoaded[7:1]};
    end
end
assign out = dataLoaded[0];

endmodule