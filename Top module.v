module Top(
    input[3:0] sw,
    input EN,
    input clk,
    input reset,
    output[7:0] out,
    output valid
);

    wire[7:0] data;
    assign data = {4'b0000, sw[3:0]};   // upper nibble hardcoded, lower nibble from switches

    wire shiftO, loadO;
    wire tx_out;
    wire[3:0] count;
    wire tx;
    wire rate, rx_tick;
    wire error;
    wire detect; //reset clock to the right timing at half a wave

    BaudRateGen m1( //baudrate transmittor (sets the amount of bits being transmitted)
        .clk(clk),  // TX baud generator: free-running, ticks once per bit period (5208 clk @ 100 MHz ≈ 19200 baud)
        .rst(reset),
        .rate(rate)
    );

    BaudRateGen #(.FIRST_TARGET(2604)) rx_brg( // RX baud generator: restarted by the receiver's start-bit detect, first tick at half a bit
        .clk(clk),                                          
        .rst(reset | detect), 
        .rate(rx_tick)
    );

    State_Machine m2(                            // Transmitter(Tx) will switch between different states in between ticks.
        .clk(clk),                               // It loads the byte into the register where the shift register and on every
        .tick(rate),                             // tick it will save the last bit and output the last bit that tx copies.
        .EN(EN),                                 // Then it shifts register right so the next bit moves to position 0
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

    reciever  m4(                              // Receiver: a 1->0 edge (falling edge) on the line marks the start bit
        .d(tx),                                // and realigns the RX baud generator.  It then samples 8 bits mid-bit, shifting
        .tick(rx_tick),                        // each into out from the MSB side (so LSB-first data ends up in order),
        .clk(clk),                             // and checks that the stop bit is 1 (otherwise framing_error).
        .rst(reset),                          
        .valid(valid),
        .out(out),
        .framing_error(error),
        .start_detected(detect)
    );



// 
//  
endmodule
