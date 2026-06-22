module InstructionMemory(
    input [31:0] readAddr,
    output reg [31:0] inst
);

    always @(*) begin
        case (readAddr)

            32'd0:   inst = 32'h00400293; // addi x5,x0,4    BUTTON_REG
            32'd4:   inst = 32'h01400413; // addi x8,x0,20   TIMER_CTRL
            32'd8:   inst = 32'h01000493; // addi x9,x0,16   TIMER_REG
            32'd12:  inst = 32'h01800513; // addi x10,x0,24  DISPLAY_REG
            32'd16:  inst = 32'h01C00713; // addi x14,x0,28  WAIT_CTRL
            32'd20:  inst = 32'h02000793; // addi x15,x0,32  WAIT_STATUS
            32'd24:  inst = 32'h02400813; // addi x16,x0,36  ROUND_REG
            32'd28:  inst = 32'h02800893; // addi x17,x0,40  HOLD_CTRL
            32'd32:  inst = 32'h02C00913; // addi x18,x0,44  HOLD_STATUS
            32'd36:  inst = 32'h00000593; // addi x11,x0,0   total = 0
            32'd40:  inst = 32'h00B52023; // sw x11,0(x10)   display = 0

            // Round 1
            32'd44:  inst = 32'h00100393; // addi x7,x0,1
            32'd48:  inst = 32'h00782023; // sw x7,0(x16)    ROUND_REG = 1
            32'd52:  inst = 32'h00772023; // sw x7,0(x14)    WAIT_CTRL = 1

            // 等隨機時間結束
            32'd56:  inst = 32'h0007A603; // lw x12,0(x15)   WAIT_STATUS
            32'd60:  inst = 32'hFE060EE3; // beq x12,x0,56

            // 等 BTND
            32'd64:  inst = 32'h0002A383; // lw x7,0(x5)
            32'd68:  inst = 32'h0023F613; // andi x12,x7,2
            32'd72:  inst = 32'hFE060CE3; // beq x12,x0,64

            // 停止、讀取單回合時間、加總
            32'd76:  inst = 32'h00000393; // addi x7,x0,0
            32'd80:  inst = 32'h00742023; // sw x7,0(x8)     stop timer
            32'd84:  inst = 32'h0004A683; // lw x13,0(x9)    read timer
            32'd88:  inst = 32'h00D585B3; // add x11,x11,x13 total += time
            32'd92:  inst = 32'h00D52023; // sw x13,0(x10)   顯示 Round 1 結果

            // 顯示 Round 1 結果 10 秒
            32'd96:  inst = 32'h00100393; // addi x7,x0,1
            32'd100: inst = 32'h0078A023; // sw x7,0(x17)    HOLD_CTRL = 1
            32'd104: inst = 32'h00092603; // lw x12,0(x18)   HOLD_STATUS
            32'd108: inst = 32'hFE060EE3; // beq x12,x0,104

            // Round 2
            32'd112: inst = 32'h00200393; // addi x7,x0,2
            32'd116: inst = 32'h00782023; // sw x7,0(x16)    ROUND_REG = 2
            32'd120: inst = 32'h00100393; // addi x7,x0,1
            32'd124: inst = 32'h00772023; // sw x7,0(x14)    WAIT_CTRL = 1

            // 等隨機時間結束
            32'd128: inst = 32'h0007A603; // lw x12,0(x15)
            32'd132: inst = 32'hFE060EE3; // beq x12,x0,128

            // 等 BTND
            32'd136: inst = 32'h0002A383; // lw x7,0(x5)
            32'd140: inst = 32'h0023F613; // andi x12,x7,2
            32'd144: inst = 32'hFE060CE3; // beq x12,x0,136

            // 停止、讀取單回合時間、加總
            32'd148: inst = 32'h00000393; // addi x7,x0,0
            32'd152: inst = 32'h00742023; // sw x7,0(x8)
            32'd156: inst = 32'h0004A683; // lw x13,0(x9)
            32'd160: inst = 32'h00D585B3; // add x11,x11,x13
            32'd164: inst = 32'h00D52023; // sw x13,0(x10)   顯示 Round 2 結果

            // 顯示 Round 2 結果 10 秒
            32'd168: inst = 32'h00100393; // addi x7,x0,1
            32'd172: inst = 32'h0078A023; // sw x7,0(x17)
            32'd176: inst = 32'h00092603; // lw x12,0(x18)
            32'd180: inst = 32'hFE060EE3; // beq x12,x0,176

            // Round 3
            32'd184: inst = 32'h00300393; // addi x7,x0,3
            32'd188: inst = 32'h00782023; // sw x7,0(x16)    ROUND_REG = 3
            32'd192: inst = 32'h00100393; // addi x7,x0,1
            32'd196: inst = 32'h00772023; // sw x7,0(x14)    WAIT_CTRL = 1

            // 等隨機時間結束
            32'd200: inst = 32'h0007A603; // lw x12,0(x15)
            32'd204: inst = 32'hFE060EE3; // beq x12,x0,200

            // 等 BTND
            32'd208: inst = 32'h0002A383; // lw x7,0(x5)
            32'd212: inst = 32'h0023F613; // andi x12,x7,2
            32'd216: inst = 32'hFE060CE3; // beq x12,x0,208

           // Round 3：停止、讀取第三回合時間、加總
            32'd220: inst = 32'h00000393; // addi x7,x0,0
            32'd224: inst = 32'h00742023; // sw x7,0(x8)     stop timer
            32'd228: inst = 32'h0004A683; // lw x13,0(x9)    read Round 3 time
            32'd232: inst = 32'h00D585B3; // add x11,x11,x13 total += Round 3 time
            
            // 先顯示 Round 3 結果
            32'd236: inst = 32'h00D52023; // sw x13,0(x10)   顯示 Round 3 秒數
            
            // 顯示 Round 3 結果 5 秒
            32'd240: inst = 32'h00200393; // addi x7,x0,2    x7 = 2，代表 hold 5 秒
            32'd244: inst = 32'h0078A023; // sw x7,0(x17)    HOLD_CTRL = 2
            32'd248: inst = 32'h00092603; // lw x12,0(x18)   HOLD_STATUS
            32'd252: inst = 32'hFE060EE3; // beq x12,x0,248  還沒到 5 秒就繼續等
            
            // 5 秒後顯示三回合總時間
            32'd256: inst = 32'h00B52023; // sw x11,0(x10)   顯示三回合總時間

            // done
            32'd260: inst = 32'h0000006F; // jal x0,done

            default: inst = 32'h00000013; // nop

        endcase
    end

endmodule
