module DSP48A1_tb ();
parameter A1REG = 1, B1REG = 1, CREG = 1, DREG = 1, MREG = 1, PREG = 1, CARRYINREG = 1, CARRYOUTREG = 1, OPMODEREG = 1;
parameter A0REG = 0, B0REG = 0;
parameter CARRYINSEL = "OPMODE5"; // OR CARRYIN
parameter B_INPUT    = "DIRECT";  // OR CASCADE
parameter RSTTYPE    = "SYNC";    // OR ASYNC

reg        CLK, CARRYIN, RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE, CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE;
reg [17:0] A, B, D, BCIN;
reg [47:0] C, PCIN;
reg [7:0]  OPMODE;

wire        CARRYOUT, CARRYOUTF;
wire [17:0] BCOUT;
wire [47:0] PCOUT, P;
wire [35:0] M;

reg        CARRYOUT_exp, CARRYOUTF_exp;
reg [17:0] BCOUT_exp;
reg [47:0] PCOUT_exp, P_exp;   
reg [35:0] M_exp;        

//Instantiation
DSP48A1 #(.A0REG(A0REG),.A1REG(A1REG),.B0REG(B0REG),.B1REG(B1REG),.CREG(CREG),.DREG(DREG),
.MREG(MREG),.PREG(PREG),.CARRYINREG(CARRYINREG),.CARRYOUTREG(CARRYOUTREG),
.OPMODEREG(OPMODEREG),.CARRYINSEL(CARRYINSEL) ,.B_INPUT(B_INPUT),.RSTTYPE(RSTTYPE)) 
 DUT (A, B, D, C, CLK, CARRYIN, OPMODE, BCIN, PCIN,
 RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE,
 CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE, 
 BCOUT, PCOUT, P, M, CARRYOUT, CARRYOUTF);

//Clock Generation
initial begin
    CLK = 0;
    forever
    #1 CLK = ~CLK;
end


initial begin    
//Verify Reset Operation
    RSTA       = 1;
    RSTB       = 1;
    RSTM       = 1;
    RSTP       = 1;
    RSTC       = 1;
    RSTD       = 1;
    RSTCARRYIN = 1;
    RSTOPMODE  = 1;
    A          = $random;          
    B          = $random;
    D          = $random;
    C          = $random; 
    CARRYIN    = $random;          
    OPMODE     = $random;      
    BCIN       = $random;   
    PCIN       = $random;   
    BCOUT_exp     = 0; 
    M_exp         = 0;
    P_exp         = 0;
    PCOUT_exp     = 0;
    CARRYOUT_exp  = 0;
    CARRYOUTF_exp = 0;
    if (BCOUT != BCOUT_exp || M != M_exp || P != P_exp || PCOUT != PCOUT_exp || CARRYOUT != CARRYOUT_exp || CARRYOUTF != CARRYOUTF_exp) begin
        $display ("Error - Incorrect Reset Functionalilty");
        $stop;
    end
    RSTA       = 0;
    RSTB       = 0;
    RSTM       = 0;
    RSTP       = 0;
    RSTC       = 0;
    RSTD       = 0;
    RSTCARRYIN = 0;
    RSTOPMODE  = 0;
    CEA        = 1;
    CEB        = 1;
    CEM        = 1;
    CEP        = 1;
    CEC        = 1;
    CED        = 1;
    CECARRYIN  = 1;
    CEOPMODE   = 1;
//Verify DSP Path 1
    OPMODE = 8'b11011101;
    A = 20;
    B = 10;
    C = 350;
    D = 25;
    BCIN    = $random;
    PCIN    = $random;
    CARRYIN = $random;
    repeat(4) @(negedge CLK); 
    BCOUT_exp     ='hf; 
    M_exp         ='h12c;
    P_exp         ='h32;
    PCOUT_exp     ='h32; 
    CARRYOUT_exp  = 0;
    CARRYOUTF_exp = 0;
    if (BCOUT != BCOUT_exp || M != M_exp || P != P_exp || PCOUT != PCOUT_exp || CARRYOUT != CARRYOUT_exp || CARRYOUTF != CARRYOUTF_exp) begin
        $display ("Error - Path 1 Failed");
        $stop;
    end
//Verify DSP Path 2
    OPMODE = 8'b00010000;
    A = 20;
    B = 10;
    C = 350;
    D = 25;
    BCIN    = $random;
    PCIN    = $random;
    CARRYIN = $random;
    repeat(3) @(negedge CLK); 
    BCOUT_exp     ='h23; 
    M_exp         ='h2bc;
    P_exp         = 0;
    PCOUT_exp     = 0; 
    CARRYOUT_exp  = 0;
    CARRYOUTF_exp = 0;
    if (BCOUT != BCOUT_exp || M != M_exp || P != P_exp || PCOUT != PCOUT_exp || CARRYOUT != CARRYOUT_exp || CARRYOUTF != CARRYOUTF_exp) begin
        $display ("Error - Path 2 Failed");
        $stop;
    end
//Verify DSP Path 3
    OPMODE = 8'b00001010;
    A = 20;
    B = 10;
    C = 350;
    D = 25;
    BCIN    = $random;
    PCIN    = $random;
    CARRYIN = $random;
    repeat(3) @(negedge CLK); 
    BCOUT_exp     ='ha; 
    M_exp         ='hc8;
    P_exp         = P;
    PCOUT_exp     = P; 
    CARRYOUT_exp  = CARRYOUT;
    CARRYOUTF_exp = CARRYOUT;
    if (BCOUT != BCOUT_exp || M != M_exp || P != P_exp || PCOUT != PCOUT_exp || CARRYOUT != CARRYOUT_exp || CARRYOUTF != CARRYOUTF_exp) begin
        $display ("Error - Path 3 Failed");
        $stop;
    end
//Verify DSP Path 4
    OPMODE = 8'b10100111;
    A = 5;
    B = 6;
    C = 350;
    D = 25;
    BCIN    = $random;
    PCIN    = 3000;
    CARRYIN = $random;
    repeat(3) @(negedge CLK); 
    BCOUT_exp     ='h6; 
    M_exp         ='h1e;
    P_exp         ='hfe6fffec0bb1;
    PCOUT_exp     ='hfe6fffec0bb1; 
    CARRYOUT_exp  = 1;
    CARRYOUTF_exp = 1;
    if (BCOUT != BCOUT_exp || M != M_exp || P != P_exp || PCOUT != PCOUT_exp || CARRYOUT != CARRYOUT_exp || CARRYOUTF != CARRYOUTF_exp) begin
        $display ("Error - Path 4 Failed");
        $stop;
    end
$stop;
end

initial begin
$monitor("BCOUT=%h, M=%h, PCOUT=%h,  P=%h, CARYYOUT=%h, CARRYOUTF=%h, BCOUT_exp=%h, M_exp=%h, PCOUT_exp=%h, P_exp=%h, CARYYOUT_exp=%h, CARRYOUTF_exp=%h", 
          BCOUT, M, PCOUT, P, CARRYOUT, CARRYOUTF, BCOUT_exp, M_exp, PCOUT_exp, P_exp, CARRYOUT_exp, CARRYOUTF_exp);
end

endmodule