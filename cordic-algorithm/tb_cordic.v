
`timescale 1ns/1ps

module tb_cordic;

    reg clk;
    reg rst;
    reg start;
    reg signed [31:0] angle;

    wire signed [31:0] sine;
    wire signed [31:0] cosine;
    wire busy;
    wire done;

    // Device under test
    cordic uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .angle(angle),
        .sine(sine),
        .cosine(cosine),
        .busy(busy),
        .done(done)
    );

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    // Apply one angle and wait for the result
    task run_test;
        input signed [31:0] test_angle;
        input [127:0] test_name;
        begin
            @(negedge clk);
            angle = test_angle;
            start = 1;

            @(negedge clk);
            start = 0;

            wait (done == 1'b1);

            $display("--------------------------------");
            $display("Test       : %0s", test_name);
            $display("Angle raw  : %0d", angle);
            $display("Sine raw   : %0d", sine);
            $display("Cosine raw : %0d", cosine);
            $display("Sine       : %f",
                     $itor(sine) / 65536.0);
            $display("Cosine     : %f",
                     $itor(cosine) / 65536.0);
        end
    endtask

    initial begin
        $dumpfile("cordic.vcd");
        $dumpvars(0, tb_cordic);

        clk   = 0;
        rst   = 1;
        start = 0;
        angle = 0;

        // Reset
        repeat (3) @(negedge clk);
        rst = 0;

        // Q16.16 angle inputs in radians
        run_test(32'sd0,     "0 degrees");
        run_test(32'sd34315, "30 degrees");
        run_test(32'sd51472, "45 degrees");
        run_test(32'sd68629, "60 degrees");
        run_test(32'sd102944,"90 degrees");

        $display("--------------------------------");
        $display("All tests completed.");

        #20;
        $finish;
    end

endmodule

