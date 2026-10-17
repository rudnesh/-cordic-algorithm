
module cordic (
    input  wire               clk,
    input  wire               rst,
    input  wire               start,

    // Signed Q16.16 angle in radians
    input  wire signed [31:0] angle,

    // Signed Q16.16 outputs
    output reg  signed [31:0] sine,
    output reg  signed [31:0] cosine,

    output reg                busy,
    output reg                done
);

    // Q16.16 CORDIC gain compensation:
    // 0.607252935 * 65536 = 39797
    localparam signed [31:0] K = 32'sd39797;

    reg signed [31:0] x, y, z;
    reg signed [31:0] x_next, y_next, z_next;
    reg [4:0] iter;

    // atan(2^-i) in Q16.16 radians
    function signed [31:0] atan_lut;
        input [4:0] i;
        begin
            case (i)
                0:  atan_lut = 32'sd51472;
                1:  atan_lut = 32'sd30386;
                2:  atan_lut = 32'sd16055;
                3:  atan_lut = 32'sd8150;
                4:  atan_lut = 32'sd4091;
                5:  atan_lut = 32'sd2047;
                6:  atan_lut = 32'sd1024;
                7:  atan_lut = 32'sd512;
                8:  atan_lut = 32'sd256;
                9:  atan_lut = 32'sd128;
                10: atan_lut = 32'sd64;
                11: atan_lut = 32'sd32;
                12: atan_lut = 32'sd16;
                13: atan_lut = 32'sd8;
                14: atan_lut = 32'sd4;
                15: atan_lut = 32'sd2;
                default: atan_lut = 32'sd0;
            endcase
        end
    endfunction

    // Combinational next-state calculations
    always @(*) begin
        if (z >= 0) begin
            x_next = x - (y >>> iter);
            y_next = y + (x >>> iter);
            z_next = z - atan_lut(iter);
        end else begin
            x_next = x + (y >>> iter);
            y_next = y - (x >>> iter);
            z_next = z + atan_lut(iter);
        end
    end

    // Sequential controller and datapath
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x      <= 0;
            y      <= 0;
            z      <= 0;
            iter   <= 0;
            sine   <= 0;
            cosine <= 0;
            busy   <= 0;
            done   <= 0;
        end else begin
            // done is a one-clock-cycle pulse
            done <= 0;

            if (start && !busy) begin
                x    <= K;
                y    <= 0;
                z    <= angle;
                iter <= 0;
                busy <= 1;
            end else if (busy) begin
                x <= x_next;
                y <= y_next;
                z <= z_next;

                if (iter == 15) begin
                    // Capture the final calculated values
                    cosine <= x_next;
                    sine   <= y_next;
                    busy   <= 0;
                    done   <= 1;
                end else begin
                    iter <= iter + 1'b1;
                end
            end
        end
    end

endmodule

