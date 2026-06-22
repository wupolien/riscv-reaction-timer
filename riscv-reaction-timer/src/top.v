module top(
    input clk,
    input btnC,
    input btnD,
    input btnU,

    output [7:0] led,
    output [6:0] seg,
    output [3:0] an,
    output dp
);

    // Basys 3 clk = 100MHz¡ACPU ¥ý­°ºC
    reg [25:0] clk_div = 26'd0;

    always @(posedge clk) begin
        clk_div <= clk_div + 1'b1;
    end

    wire cpu_clk;
    assign cpu_clk = clk_div[18];

    // btnU «ö¤U®É reset
    wire start;
    assign start = ~btnU;

    wire [31:0] io_addr;
    wire [31:0] io_wdata;
    wire io_we;
    wire [31:0] io_rdata;

    SingleCycleCPU u_cpu(
        .clk(cpu_clk),
        .start(start),

        .io_addr(io_addr),
        .io_wdata(io_wdata),
        .io_we(io_we),
        .io_rdata(io_rdata)
    );

    mmio u_mmio(
        .cpu_clk(cpu_clk),
        .disp_clk(clk),
        .rst(btnU),

        .cpu_addr(io_addr),
        .cpu_wdata(io_wdata),
        .cpu_we(io_we),
        .cpu_rdata(io_rdata),

        .btnC(btnC),
        .btnD(btnD),

        .led(led),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

endmodule