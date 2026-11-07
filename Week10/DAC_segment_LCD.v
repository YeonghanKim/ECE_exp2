`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: DAC_segment_LCD
// Project Name: DAC_segment_LCD (Week 10 - Report E)
// Description: 8-bit DAC Controller with 7-Segment and Text-LCD Display
//              - DAC: AD7302 controller with 6 Push Buttons (±1, ±2, ±8)
//              - 7-Segment: 3-digit Decimal Dynamic Scanning (dac_d_temp)
//              - Text-LCD:
//                  Line 1: "DAC VALUE: " + [BCD 3-digit] + "  "
//                  Line 2: "2022440031 YHK  "
//////////////////////////////////////////////////////////////////////////////////

module DAC_segment_LCD(
    input clk,
    input rst,
    input [5:0] btn,
    input add_sel,
    output reg dac_csn,
    output reg dac_ldacn,
    output reg dac_wrn,
    output reg dac_a_b,
    output reg [7:0] dac_d,
    output reg [7:0] led_out,
    output [7:0] seg_data,
    output [7:0] seg_sel,
    output LCD_E,
    output reg LCD_RS,
    output reg LCD_RW,
    output reg [7:0] LCD_DATA
);

    // ===========================================================================
    // 1. DAC Core Registers and Signals (Curriculum Code Preserved)
    // ===========================================================================
    reg [7:0] dac_d_temp;
    reg [7:0] cnt;
    wire [5:0] btn_t;

    reg [1:0] state;

    parameter DELAY   = 2'b00,
              SET_WRN = 2'b01,
              UP_DATA = 2'b10;

    oneshot_universal #(.WIDTH(6)) O1(clk, rst, {btn[5:0]}, {btn_t[5:0]});

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            state <= DELAY;
        end
        else begin
            case(state)
                DELAY   : if(cnt == 200) state <= SET_WRN;
                SET_WRN : if(cnt == 50)  state <= UP_DATA;
                UP_DATA : if(cnt == 30)  state <= DELAY;
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if(!rst)
            cnt <= 8'b0000_0000;
        else begin
            case(state)
                DELAY :
                    if(cnt >= 200) cnt <= 0;
                    else cnt <= cnt + 1;
                SET_WRN :
                    if(cnt >= 50) cnt <= 0;
                    else cnt <= cnt + 1;
                UP_DATA :
                    if(cnt >= 30) cnt <= 0;
                    else cnt <= cnt + 1;
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dac_wrn <= 1;
        end
        else begin
            case(state)
                DELAY :
                    dac_wrn <= 1;
                SET_WRN :
                    dac_wrn <= 0;
                UP_DATA :
                    dac_d <= dac_d_temp;
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dac_d_temp <= 8'b0000_0000;
            led_out <= 8'b0101_0101;
        end
        else begin
            if(btn_t == 6'b100000)      dac_d_temp <= dac_d_temp - 8'b0000_0001;
            else if(btn_t == 6'b010000) dac_d_temp <= dac_d_temp + 8'b0000_0001;
            else if(btn_t == 6'b001000) dac_d_temp <= dac_d_temp - 8'b0000_0010;
            else if(btn_t == 6'b000100) dac_d_temp <= dac_d_temp + 8'b0000_0010;
            else if(btn_t == 6'b000010) dac_d_temp <= dac_d_temp - 8'b0000_1000;
            else if(btn_t == 6'b000001) dac_d_temp <= dac_d_temp + 8'b0000_1000;
            led_out <= dac_d_temp;
        end
    end

    always @(posedge clk) begin
        dac_csn <= 0;
        dac_ldacn <= 0;
        dac_a_b <= add_sel; // 0 : select A, 1 : select B
    end

    // ===========================================================================
    // 2. BCD Conversion and 7-Segment Controller
    // ===========================================================================
    wire [11:0] bcd;

    // Convert dac_d_temp (8-bit binary) to 12-bit BCD for Text-LCD display
    bin2bcd bcd_inst(
        .clk(clk),
        .rst(~rst), // Submodule rst is active-high
        .bin(dac_d_temp),
        .bcd_out(bcd)
    );

    // 7-segment display controller (dynamic scanning for dac_d_temp)
    seg7_controller seg_inst(
        .clk(clk),
        .rst(~rst), // Submodule rst is active-high
        .bin(dac_d_temp),
        .seg_data(seg_data),
        .seg_sel(seg_sel)
    );

    // ===========================================================================
    // 3. Text-LCD FSM Controller (Week 8 Architecture Adapted)
    // ===========================================================================
    reg [2:0] lcd_state;
    parameter LCD_DELAY        = 3'b000,
              LCD_FUNCTION_SET = 3'b001,
              LCD_DISP_ONOFF   = 3'b010,
              LCD_ENTRY_MODE   = 3'b011,
              LCD_LINE1        = 3'b100,
              LCD_LINE2        = 3'b101,
              LCD_DELAY_T      = 3'b110,
              LCD_CLEAR_DISP   = 3'b111;

    integer lcd_cnt;

    // Text-LCD State Transition
    always @(posedge clk or negedge rst) begin
        if(!rst)
            lcd_state <= LCD_DELAY;
        else begin
            case(lcd_state)
                LCD_DELAY        : if(lcd_cnt == 70) lcd_state <= LCD_FUNCTION_SET;
                LCD_FUNCTION_SET : if(lcd_cnt == 30) lcd_state <= LCD_DISP_ONOFF;
                LCD_DISP_ONOFF   : if(lcd_cnt == 30) lcd_state <= LCD_ENTRY_MODE;
                LCD_ENTRY_MODE   : if(lcd_cnt == 30) lcd_state <= LCD_LINE1;
                LCD_LINE1        : if(lcd_cnt == 20) lcd_state <= LCD_LINE2;
                LCD_LINE2        : if(lcd_cnt == 20) lcd_state <= LCD_DELAY_T;
                LCD_DELAY_T      : if(lcd_cnt == 5)  lcd_state <= LCD_CLEAR_DISP;
                LCD_CLEAR_DISP   : if(lcd_cnt == 5)  lcd_state <= LCD_LINE1;
                default          : lcd_state <= LCD_DELAY;
            endcase
        end
    end

    // Text-LCD State Counter
    always @(posedge clk or negedge rst) begin
        if(!rst)
            lcd_cnt <= 0;
        else begin
            case(lcd_state)
                LCD_DELAY        : if(lcd_cnt >= 70) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_FUNCTION_SET : if(lcd_cnt >= 30) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_DISP_ONOFF   : if(lcd_cnt >= 30) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_ENTRY_MODE   : if(lcd_cnt >= 30) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_LINE1        : if(lcd_cnt >= 20) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_LINE2        : if(lcd_cnt >= 20) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_DELAY_T      : if(lcd_cnt >= 95) lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                LCD_CLEAR_DISP   : if(lcd_cnt >= 5)  lcd_cnt <= 0; else lcd_cnt <= lcd_cnt + 1;
                default          : lcd_cnt <= 0;
            endcase
        end
    end

    // Text-LCD Output Signals & ASCII Character Stream
    always @(posedge clk or negedge rst) begin
        if(!rst)
            {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;
        else begin
            case(lcd_state)
                LCD_FUNCTION_SET :
                    {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0011_1000;

                LCD_DISP_ONOFF :
                    {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_1100;

                LCD_ENTRY_MODE :
                    {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0110;

                // Line 1: "DAC VALUE: [BCD 3-digit]  "
                LCD_LINE1 : begin
                    case(lcd_cnt)
                        00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1000_0000; // DDRAM Address 0x00
                        01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0100; // 'D'
                        02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0001; // 'A'
                        03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0011; // 'C'
                        04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0110; // 'V'
                        06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0001; // 'A'
                        07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1100; // 'L'
                        08 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0101; // 'U'
                        09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0101; // 'E'
                        10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_1010; // ':'
                        11 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        12 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, bcd[11:8]}; // Hundreds digit
                        13 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, bcd[7:4]};  // Tens digit
                        14 : {LCD_RS, LCD_RW, LCD_DATA} <= {1'b1, 1'b0, 4'b0011, bcd[3:0]};  // Ones digit
                        15 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        16 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000;
                    endcase
                end

                // Line 2: "2022440031 YHK  "
                LCD_LINE2 : begin
                    case(lcd_cnt)
                        00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1100_0000; // DDRAM Address 0x40
                        01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // '2'
                        02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // '0'
                        03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // '2'
                        04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0010; // '2'
                        05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // '4'
                        06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0100; // '4'
                        07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // '0'
                        08 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // '0'
                        09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0011; // '3'
                        10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // '1'
                        11 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        12 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_1001; // 'Y'
                        13 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1000; // 'H'
                        14 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1011; // 'K'
                        15 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        16 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000; // ' '
                        default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000;
                    endcase
                end

                LCD_DELAY_T :
                    {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0010;

                LCD_CLEAR_DISP :
                    {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0001;

                default :
                    {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;
            endcase
        end
    end

    assign LCD_E = clk;

endmodule
