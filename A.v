module testttt();
  reg clk,rst;
  wire [7:0] port_b_out;
  
  hw hw(
  .clk(clk),
  .rst(rst),
  .port_b_out(port_b_out)
  );
  
  initial begin
    rst = 1;
    clk = 0;
    #30
    rst = 0;
  end
always #20 clk = ~clk;  
  
endmodule

