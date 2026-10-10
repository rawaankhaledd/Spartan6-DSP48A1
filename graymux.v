module graymux (clk, rst, clk_en, in, out); 
parameter WIDTH = 18;
parameter SEL   = 1;
parameter RSTTYPE    = "SYNC";    // OR ASYNC
input      clk, rst, clk_en;
input      [WIDTH-1 :0] in;
output     [WIDTH-1 :0] out;
reg        [WIDTH-1 :0] in_reg;

generate
    if (RSTTYPE == "SYNC") begin
        always @(posedge clk) begin
            if (rst)
            in_reg <= 0;
            else if (clk_en)
            in_reg <= in;  
            else
            in_reg <= 0;
        end
    end

    else begin
        always @(posedge clk or posedge rst) begin
            if (rst)
            in_reg <= 0;
            else if (clk_en)
            in_reg <= in;  
            else
            in_reg <= 0;
        end
    end
endgenerate

assign out = (SEL == 1)? in_reg : in;

endmodule
