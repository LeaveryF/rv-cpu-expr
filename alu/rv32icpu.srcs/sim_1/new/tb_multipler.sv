`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2025 11:44:45 AM
// Design Name: 
// Module Name: tb_multipler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_multipler();


logic       [63:0] p;
logic       [31:0] a, b, test_a, test_b;


initial begin
    // 结果测试
    // 小数乘法
    for (test_a = 32'b0; test_a < 32'd20; test_a = test_a + 1) begin
        for (test_b = 32'h0; test_b < 32'd20; test_b = test_b + 1) begin
            a = test_a;
            b = test_b;
            #1 assert(p == test_a * test_b) else $fatal("Result Error: {a, b} is {%x, %x} and {Result} is  {%x}, but expected {%x}.", a, b, p, test_a * test_b);
        end
    end
    
    // 大数乘法
    for (test_a = 32'hFFFFFFFC; test_a < 32'hFFFFFFFF; test_a = test_a + 1) begin
        for (test_b =  32'hEFFF1212; test_b < 32'hEFFF3499; test_b = test_b + 1) begin
            a = test_a;
            b = test_b;
            #1 assert(p == test_a * test_b) else $fatal("Result Error: {a, b} is {%x, %x} and {Result} is  {%x}, but expected {%x}.", a, b, p, test_a * test_b);
        end
    end
    $finish;
end

multipler32 my_mul(
    .a(a),
    .b(b),
    .p(p)
);

endmodule
