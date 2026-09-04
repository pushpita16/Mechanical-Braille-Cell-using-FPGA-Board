//=============================================================================
// Module      : braille
// Project     : Mechanical-Braille-Cell-using-FPGA-Board
// Author      : Asmaul Husna Pushpita
//
// Description : Decodes a 7-bit input code into a 6-dot Braille cell pattern
//               and drives six servo channels with a software PWM generator.
//
//               x[0], x[1] gate the whole decoder: every output dot is forced
//               to 0 unless x[0] = 1 and x[1] = 0. The remaining bits
//               x[2]..x[6] select the character.
//
//               B[1] .. B[6] are the six dots of the Braille cell.
//
//               Each PWM channel ramps its pulse width by one count per clock
//               toward PULSE_MAX when its dot is set, or back toward PULSE_MIN
//               when it is cleared. The ramp gives a smooth actuator movement
//               instead of an instantaneous jump.
//
// Timing      : CLOCK_FREQ = 51282 Hz, PWM frame = 50 Hz (20 ms)
//               PULSE_MIN  = 51 counts  (~1.00 ms, dot lowered)
//               PULSE_MAX  = 77 counts  (~1.50 ms, dot raised)
//=============================================================================

module braille (
    input  wire [0:6] x,
    input  wire       clk,
    output reg  [1:6] B,
    output reg  [1:6] pwm_out
);

    //-------------------------------------------------------------------------
    // PWM parameters
    //-------------------------------------------------------------------------
    parameter  CLOCK_FREQ  = 51282;
    parameter  PWM_FREQ    = 50;

    localparam COUNTER_MAX = CLOCK_FREQ / PWM_FREQ;      // 1025 counts per frame
    localparam PULSE_MIN   = CLOCK_FREQ / 1000;          // 51 counts
    localparam PULSE_MAX   = CLOCK_FREQ / 666.6667;      // 77 counts

    //-------------------------------------------------------------------------
    // PWM state
    //-------------------------------------------------------------------------
    reg [31:0] counter = 0;

    reg [31:0] p1 = PULSE_MIN;
    reg [31:0] p2 = PULSE_MIN;
    reg [31:0] p3 = PULSE_MIN;
    reg [31:0] p4 = PULSE_MIN;
    reg [31:0] p5 = PULSE_MIN;
    reg [31:0] p6 = PULSE_MIN;

    always @(posedge clk) begin

        //---------------------------------------------------------------------
        // Free-running frame counter
        //---------------------------------------------------------------------
        if (counter < COUNTER_MAX) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
        end

        //---------------------------------------------------------------------
        // Braille dot decode (sum-of-products)
        //---------------------------------------------------------------------
        B[1] <= ((x[0] & ~x[1]) &
                 ((~x[2] &  x[4]) |
                  (~x[2] &  x[5] &  x[6]) |
                  (~x[3] & ~x[5] &  x[6]) |
                  (~x[3] &  x[5] & ~x[6]) |
                  ( x[2] & ~x[4] & ~x[5]) |
                  ( x[2] & ~x[4] & ~x[6]) |
                  (~x[2] &  x[3] & ~x[5] & ~x[6])));

        B[2] <= ((x[0] & ~x[1]) &
                 ((~x[3] &  x[4] &  x[5]) |
                  (~x[2] &  x[3] & ~x[4] & ~x[5]) |
                  (~x[2] &  x[3] & ~x[5] & ~x[6]) |
                  ( x[2] & ~x[3] & ~x[4]) |
                  ( x[2] & ~x[3] & ~x[6]) |
                  (~x[2] & ~x[4] &  x[5] & ~x[6])));

        B[3] <= ((x[0] & ~x[1]) &
                 ((~x[2] &  x[3] &  x[5] &  x[6]) |
                  (~x[2] &  x[3] &  x[4]) |
                  ( x[2] & ~x[3] & ~x[4]) |
                  ( x[2] & ~x[3] & ~x[5]) |
                  ( x[2] & ~x[3] & ~x[6]) |
                  ( x[2] & ~x[4] & ~x[5]) |
                  ( x[2] & ~x[4] & ~x[6])));

        B[4] <= ((x[0] & ~x[1]) &
                 ((~x[3] &  x[5] &  x[6]) |
                  (~x[2] &  x[3] &  x[5] & ~x[6]) |
                  (~x[2] &  x[3] & ~x[5] &  x[6]) |
                  ( x[2] & ~x[4] & ~x[5]) |
                  (~x[2] & ~x[3] &  x[4] & ~x[6]) |
                  (~x[3] &  x[4] & ~x[5] & ~x[6])));

        B[5] <= ((x[0] & ~x[1]) &
                 ((~x[2] &  x[3] & ~x[4] & ~x[6]) |
                  ( x[2] & ~x[4] & ~x[5] &  x[6]) |
                  ( x[2] & ~x[4] &  x[5] & ~x[6]) |
                  (~x[3] &  x[4] & ~x[5] & ~x[6]) |
                  (~x[3] &  x[4] &  x[5] &  x[6]) |
                  (~x[2] &  x[3] &  x[4] & ~x[5]) |
                  (~x[2] &  x[3] &  x[4] &  x[5])));

        B[6] <= ((x[0] & ~x[1]) &
                 (( x[2] & ~x[3] &  x[4] &  x[6]) |
                  ( x[2] & ~x[3] &  x[4] &  x[5]) |
                  ( x[2] &  x[3] & ~x[4] & ~x[5]) |
                  ( x[2] &  x[3] & ~x[4] & ~x[6])));

        //---------------------------------------------------------------------
        // Per-dot pulse-width ramp and PWM output
        //---------------------------------------------------------------------
        if      (B[1] == 1 && p1 < PULSE_MAX) p1 <= p1 + 1;
        else if (B[1] == 0 && p1 > PULSE_MIN) p1 <= p1 - 1;
        pwm_out[1] <= (counter < p1) ? 1 : 0;

        if      (B[2] == 1 && p2 < PULSE_MAX) p2 <= p2 + 1;
        else if (B[2] == 0 && p2 > PULSE_MIN) p2 <= p2 - 1;
        pwm_out[2] <= (counter < p2) ? 1 : 0;

        if      (B[3] == 1 && p3 < PULSE_MAX) p3 <= p3 + 1;
        else if (B[3] == 0 && p3 > PULSE_MIN) p3 <= p3 - 1;
        pwm_out[3] <= (counter < p3) ? 1 : 0;

        if      (B[4] == 1 && p4 < PULSE_MAX) p4 <= p4 + 1;
        else if (B[4] == 0 && p4 > PULSE_MIN) p4 <= p4 - 1;
        pwm_out[4] <= (counter < p4) ? 1 : 0;

        if      (B[5] == 1 && p5 < PULSE_MAX) p5 <= p5 + 1;
        else if (B[5] == 0 && p5 > PULSE_MIN) p5 <= p5 - 1;
        pwm_out[5] <= (counter < p5) ? 1 : 0;

        if      (B[6] == 1 && p6 < PULSE_MAX) p6 <= p6 + 1;
        else if (B[6] == 0 && p6 > PULSE_MIN) p6 <= p6 - 1;
        pwm_out[6] <= (counter < p6) ? 1 : 0;

    end

endmodule
