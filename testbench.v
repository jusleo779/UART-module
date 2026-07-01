module tb;
    reg clk, EN, reset;
    reg [7:0] data;
    wire[7:0] out;
    wire valid;
    wire tx_debug;

    Top dut(
        .clk(clk), 
        .EN(EN), 
        .reset(reset), 
        .data(data), 
        .out(out),
        .valid(valid),
        .tx_debug(tx_debug)
    );
    
    // generate clock
    always #5 clk = ~clk; //#5 = toggles every 5 time units = 10 unit period clock
    
    initial begin
        // your sequence here

        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        $monitor("time=%0t data_in=%b out=%b valid=%b tx=%b", $time, data, out, valid, tx_debug);
        
        //intializing
        clk = 0; 
        EN = 0; 
        reset = 0; 
        data = 0;


        #10 reset = 1; // # = delays
        #10 reset = 0;
        #10 data  = 8'b00000001;
        #10 EN = 1;
        #1500000;
        $finish;
    end
endmodule