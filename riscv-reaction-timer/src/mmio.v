module mmio(
    input cpu_clk,
    input disp_clk,
    input rst,

    input [31:0] cpu_addr,
    input [31:0] cpu_wdata,
    input cpu_we,
    output reg [31:0] cpu_rdata,

    input btnC,
    input btnD,

    output [7:0] led,
    output reg [6:0] seg,
    output reg [3:0] an,
    output reg dp
);

    // =====================
    // Memory-mapped I/O address
    // =====================
    localparam BUTTON_REG  = 32'd4;
    localparam LED_REG     = 32'd8;
    localparam TIMER_REG   = 32'd16;
    localparam TIMER_CTRL  = 32'd20;
    localparam DISPLAY_REG = 32'd24;
    localparam WAIT_CTRL   = 32'd28;
    localparam WAIT_STATUS = 32'd32;
    localparam ROUND_REG   = 32'd36;
    localparam HOLD_CTRL   = 32'd40;
    localparam HOLD_STATUS = 32'd44;

    // =====================
    // Time setting
    // =====================
    // Basys 3 clock = 100MHz
    // 1ms = 100,000 cycles
    localparam TICKS_PER_1MS = 32'd100_000;

    // Round 1 / Round 2 顯示 10 秒
    localparam HOLD_TIME_10S = 32'd1_000_000_000;

    // Round 3 顯示 5 秒
    localparam HOLD_TIME_5S  = 32'd500_000_000;

    // 提早按錯誤提示 0.5 秒
    localparam ERROR_TIME = 32'd50_000_000;

    // =====================
    // Registers
    // =====================
    reg [7:0] led_reg = 8'b0000_0000;

    // Timer
    reg timer_run = 1'b0;
    reg [31:0] tick_count = 32'd0;
    reg [31:0] timer_ms = 32'd0;
    reg [31:0] display_ms = 32'd0;

    // Random wait
    reg [15:0] lfsr = 16'hACE1;
    reg wait_run = 1'b0;
    reg wait_ready = 1'b0;
    reg prompt_led = 1'b0;
    reg [31:0] wait_count = 32'd0;
    reg [31:0] wait_target = 32'd100_000_000;

    // Hold display
    reg hold_run = 1'b0;
    reg hold_ready = 1'b0;
    reg [31:0] hold_count = 32'd0;
    reg [31:0] hold_target = HOLD_TIME_10S;

    // Early press error
    reg error_active = 1'b0;
    reg [31:0] error_count = 32'd0;

    // Current round
    reg [1:0] round_reg = 2'd0;

    // =====================
    // CPU read
    // =====================
    always @(*) begin
        case (cpu_addr)
            BUTTON_REG:  cpu_rdata = {30'b0, btnD, btnC};
            LED_REG:     cpu_rdata = {24'b0, led_reg};
            TIMER_REG:   cpu_rdata = timer_ms;
            DISPLAY_REG: cpu_rdata = display_ms;
            WAIT_STATUS: cpu_rdata = {31'b0, wait_ready};
            ROUND_REG:   cpu_rdata = {30'b0, round_reg};
            HOLD_STATUS: cpu_rdata = {31'b0, hold_ready};
            default:     cpu_rdata = 32'b0;
        endcase
    end

    // =====================
    // Main control
    // =====================
    always @(posedge disp_clk) begin
        if (rst) begin
            lfsr <= 16'hACE1;

            led_reg <= 8'b0000_0000;

            timer_run <= 1'b0;
            tick_count <= 32'd0;
            timer_ms <= 32'd0;
            display_ms <= 32'd0;

            wait_run <= 1'b0;
            wait_ready <= 1'b0;
            prompt_led <= 1'b0;
            wait_count <= 32'd0;
            wait_target <= 32'd100_000_000;

            hold_run <= 1'b0;
            hold_ready <= 1'b0;
            hold_count <= 32'd0;
            hold_target <= HOLD_TIME_10S;

            error_active <= 1'b0;
            error_count <= 32'd0;

            round_reg <= 2'd0;
        end
        else begin
            // LFSR 持續跑，讓隨機等待時間有變化
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            // =====================
            // CPU write
            // =====================
            if (cpu_we) begin
                case (cpu_addr)

                    LED_REG: begin
                        led_reg <= cpu_wdata[7:0];
                    end

                    DISPLAY_REG: begin
                        display_ms <= cpu_wdata;
                    end

                    ROUND_REG: begin
                        round_reg <= cpu_wdata[1:0];
                    end

                    TIMER_CTRL: begin
                        if (cpu_wdata == 32'd0) begin
                            // Stop timer
                            timer_run <= 1'b0;
                            prompt_led <= 1'b0;
                        end
                        else if (cpu_wdata == 32'd1) begin
                            // Start timer
                            timer_run <= 1'b1;
                        end
                        else if (cpu_wdata == 32'd2) begin
                            // Clear timer
                            timer_run <= 1'b0;
                            tick_count <= 32'd0;
                            timer_ms <= 32'd0;
                        end
                    end

                    WAIT_CTRL: begin
                        if (cpu_wdata == 32'd1) begin
                            // 開始隨機等待
                            wait_run <= 1'b1;
                            wait_ready <= 1'b0;
                            prompt_led <= 1'b0;
                            wait_count <= 32'd0;

                            hold_run <= 1'b0;
                            hold_ready <= 1'b0;
                            hold_count <= 32'd0;

                            error_active <= 1'b0;
                            error_count <= 32'd0;

                            timer_run <= 1'b0;
                            tick_count <= 32'd0;
                            timer_ms <= 32'd0;

                            // 隨機等待約 1.0 ~ 2.75 秒
                            case (lfsr[2:0])
                                3'd0: wait_target <= 32'd100_000_000;
                                3'd1: wait_target <= 32'd125_000_000;
                                3'd2: wait_target <= 32'd150_000_000;
                                3'd3: wait_target <= 32'd175_000_000;
                                3'd4: wait_target <= 32'd200_000_000;
                                3'd5: wait_target <= 32'd225_000_000;
                                3'd6: wait_target <= 32'd250_000_000;
                                3'd7: wait_target <= 32'd275_000_000;
                            endcase
                        end
                    end

                    HOLD_CTRL: begin
                        if (cpu_wdata == 32'd1) begin
                            // Round 1 / Round 2：顯示本回合結果 10 秒
                            hold_run <= 1'b1;
                            hold_ready <= 1'b0;
                            hold_count <= 32'd0;
                            hold_target <= HOLD_TIME_10S;

                            wait_run <= 1'b0;
                            wait_ready <= 1'b0;
                            prompt_led <= 1'b0;
                            timer_run <= 1'b0;
                        end
                        else if (cpu_wdata == 32'd2) begin
                            // Round 3：顯示第三回合結果 5 秒
                            hold_run <= 1'b1;
                            hold_ready <= 1'b0;
                            hold_count <= 32'd0;
                            hold_target <= HOLD_TIME_5S;

                            wait_run <= 1'b0;
                            wait_ready <= 1'b0;
                            prompt_led <= 1'b0;
                            timer_run <= 1'b0;
                        end
                    end

                endcase
            end

            // =====================
            // Error state
            // 太早按 BTND
            // =====================
            if (error_active) begin
                if (error_count >= ERROR_TIME) begin
                    error_active <= 1'b0;
                    error_count <= 32'd0;

                    wait_run <= 1'b1;
                    wait_ready <= 1'b0;
                    prompt_led <= 1'b0;
                    wait_count <= 32'd0;

                    timer_run <= 1'b0;
                    tick_count <= 32'd0;
                    timer_ms <= 32'd0;

                    case (lfsr[2:0])
                        3'd0: wait_target <= 32'd100_000_000;
                        3'd1: wait_target <= 32'd125_000_000;
                        3'd2: wait_target <= 32'd150_000_000;
                        3'd3: wait_target <= 32'd175_000_000;
                        3'd4: wait_target <= 32'd200_000_000;
                        3'd5: wait_target <= 32'd225_000_000;
                        3'd6: wait_target <= 32'd250_000_000;
                        3'd7: wait_target <= 32'd275_000_000;
                    endcase
                end
                else begin
                    error_count <= error_count + 1'b1;
                end
            end

            // =====================
            // Hold display
            // 顯示每回合結果
            // =====================
            else if (hold_run) begin
                if (hold_count >= hold_target) begin
                    hold_run <= 1'b0;
                    hold_ready <= 1'b1;
                    hold_count <= 32'd0;
                end
                else begin
                    hold_count <= hold_count + 1'b1;
                end
            end

            // =====================
            // Random wait
            // =====================
            else if (wait_run) begin
                if (btnD) begin
                    // LED[0] 還沒亮就按 BTND，算提早按
                    wait_run <= 1'b0;
                    wait_ready <= 1'b0;
                    prompt_led <= 1'b0;

                    timer_run <= 1'b0;
                    tick_count <= 32'd0;
                    timer_ms <= 32'd0;

                    error_active <= 1'b1;
                    error_count <= 32'd0;
                end
                else if (wait_count >= wait_target) begin
                    wait_run <= 1'b0;
                    wait_ready <= 1'b1;
                    prompt_led <= 1'b1;

                    // LED[0] 亮起瞬間開始計時
                    timer_ms <= 32'd0;
                    tick_count <= 32'd0;
                    timer_run <= 1'b1;
                end
                else begin
                    wait_count <= wait_count + 1'b1;
                end
            end

            // =====================
            // Timer count
            // 每 1ms 加一次
            // =====================
            if (timer_run) begin
                if (tick_count >= TICKS_PER_1MS - 1) begin
                    tick_count <= 32'd0;

                    if (timer_ms >= 32'd9999) begin
                        timer_ms <= 32'd0;
                    end
                    else begin
                        timer_ms <= timer_ms + 1'b1;
                    end
                end
                else begin
                    tick_count <= tick_count + 1'b1;
                end
            end
        end
    end

    // =====================
    // LED output
    // LED[0] = 提示燈
    // LED[2:1] = 目前回合
    // LED[7] = 太早按錯誤
    // =====================
    assign led = {error_active, 4'b0000, round_reg, prompt_led};

    // =====================
    // Seven-segment display value
    // error_active → 顯示 9.999
    // timer_run → 顯示目前反應時間
    // hold_run → 顯示當回合結果
    // done → 顯示總時間
    // =====================
    wire [31:0] display_raw;
    assign display_raw = error_active ? 32'd9999 :
                         timer_run    ? timer_ms :
                                        display_ms;

    wire [13:0] display_mod;
    assign display_mod = display_raw % 32'd10000;

    wire [3:0] d0;
    wire [3:0] d1;
    wire [3:0] d2;
    wire [3:0] d3;

    assign d0 = display_mod % 10;
    assign d1 = (display_mod / 10) % 10;
    assign d2 = (display_mod / 100) % 10;
    assign d3 = (display_mod / 1000) % 10;

    // =====================
    // Seven-segment refresh
    // =====================
    reg [19:0] refresh_count = 20'd0;
    reg [3:0] current_digit;

    always @(posedge disp_clk) begin
        refresh_count <= refresh_count + 1'b1;
    end

    always @(*) begin
        case (refresh_count[19:18])
            2'b00: begin
                an = 4'b1110;
                current_digit = d0;
                dp = 1'b1;
            end

            2'b01: begin
                an = 4'b1101;
                current_digit = d1;
                dp = 1'b1;
            end

            2'b10: begin
                an = 4'b1011;
                current_digit = d2;
                dp = 1'b1;
            end

            2'b11: begin
                an = 4'b0111;
                current_digit = d3;
                dp = 1'b0;   // 顯示 S.mmm
            end
        endcase
    end

    // =====================
    // Seven-segment decoder
    // Basys 3 active low
    // =====================
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule