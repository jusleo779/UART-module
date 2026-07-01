module Top(
    input[7:0] data,
    input EN,
    input clk,
    input reset,
    output[7:0] out,
    output valid
    //output tx_debug - used for debugging
);

wire shiftO, loadO;
wire tx_out;
wire[3:0] count;
wire tx;
wire rate, rx_tick;
wire detect; //reset clock to the right timing at half a wave

BaudRateGen m1( //baudrate transmittor
    .clk(clk),
    .rst(reset),
    .rate(rate)
);

BaudRateGen #(.FIRST_TARGET(2604)) rx_brg(
    .clk(clk), 
    .rst(reset | detect), 
    .rate(rx_tick)
);

State_Machine m2(
    .clk(clk),
    .tick(rate),
    .EN(EN),
    .reset(reset),
    .shift_out(tx_out),
    .count(count),
    .tx(tx),
    .shift(shiftO),
    .load(loadO)
);

Shift_reg m3(
    .clk(clk),
    .shift(shiftO),
    .load(loadO),
    .data(data),
    .out(tx_out)
);

reciever  m4(
    .d(tx),
    .tick(rx_tick),
    .clk(clk),
    .rst(reset),
    .valid(valid),
    .out(out),
    .start_detected(detect)
);

assign tx_debug = tx;

endmodule