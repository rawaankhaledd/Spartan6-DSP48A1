module DSP48A1 (A, B, D, C, CLK, CARRYIN, OPMODE, BCIN, PCIN,
 RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE,
 CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE, 
 BCOUT, PCOUT, P, M, CARRYOUT, CARRYOUTF);

parameter A1REG = 1, B1REG = 1, CREG = 1, DREG = 1, MREG = 1, PREG = 1, CARRYINREG = 1, CARRYOUTREG = 1, OPMODEREG = 1;
parameter A0REG = 0, B0REG = 0;
parameter CARRYINSEL = "OPMODE5"; // OR CARRYIN
parameter B_INPUT    = "DIRECT";  // OR CASCADE
parameter RSTTYPE    = "SYNC";    // OR ASYNC

input        CLK, CARRYIN, RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE, CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE;
input [17:0] A, B, D, BCIN;
input [47:0] C, PCIN;
input [7:0]  OPMODE;

output        CARRYOUT, CARRYOUTF;
output [17:0] BCOUT;
output [47:0] PCOUT, P;
output [35:0] M;

wire        CIN, CYCMUX_OUT;
wire [17:0] A0MUX_OUT, B0MUX_OUT, A1MUX_OUT, B1MUX_OUT, DMUX_OUT, BMUX_OUT, PREADDER_MUX_OUT;  
wire [47:0] CMUX_OUT; 
wire [35:0] MMUX_OUT, MULTIPLIER_OUT;
wire [7:0]  OPMODEMUX_OUT;
reg         POSTADDER_CYO; 
reg  [47:0] X_OUT, Z_OUT, POSTADDER_OUT; 
reg  [17:0] PREADDER_OUT;

//MULTIPLEXERS
graymux #(.SEL(A0REG)      , .WIDTH(18) , .RSTTYPE("SYNC"))          A0_INST (CLK, RSTA,       CEA,       A,                A0MUX_OUT);
graymux #(.SEL(B0REG)      , .WIDTH(18) , .RSTTYPE("SYNC"))          B0_INST (CLK, RSTB,       CEB,       BMUX_OUT,         B0MUX_OUT); 
graymux #(.SEL(A1REG)      , .WIDTH(18) , .RSTTYPE("SYNC"))          A1_INST (CLK, RSTA,       CEA,       A0MUX_OUT,        A1MUX_OUT);
graymux #(.SEL(B1REG)      , .WIDTH(18) , .RSTTYPE("SYNC"))          B1_INST (CLK, RSTB,       CEB,       PREADDER_MUX_OUT, B1MUX_OUT);
graymux #(.SEL(CREG)       , .WIDTH(48) , .RSTTYPE("SYNC"))           C_INST (CLK, RSTC,       CEC,       C,                CMUX_OUT);
graymux #(.SEL(DREG)       , .WIDTH(18) , .RSTTYPE("SYNC"))           D_INST (CLK, RSTD,       CED,       D,                DMUX_OUT);
graymux #(.SEL(MREG)       , .WIDTH(36) , .RSTTYPE("SYNC"))           M_INST (CLK, RSTM,       CEM,       MULTIPLIER_OUT ,  MMUX_OUT);
graymux #(.SEL(PREG)       , .WIDTH(48) , .RSTTYPE("SYNC"))           P_INST (CLK, RSTP,       CEP,       POSTADDER_OUT,    P);
graymux #(.SEL(CARRYINREG) , .WIDTH(1)  , .RSTTYPE("SYNC"))  CARRYINREG_INST (CLK, RSTCARRYIN, CECARRYIN, CYCMUX_OUT,       CIN);
graymux #(.SEL(CARRYOUTREG), .WIDTH(1)  , .RSTTYPE("SYNC")) CARRYOUTREG_INST (CLK, RSTCARRYIN, CECARRYIN, POSTADDER_CYO,    CARRYOUT);
graymux #(.SEL(OPMODEREG)  , .WIDTH(8)  , .RSTTYPE("SYNC"))   OPMODEREG_INST (CLK, RSTOPMODE,  CEOPMODE,  OPMODE,           OPMODEMUX_OUT);

assign CYCMUX_OUT       = (CARRYINSEL == "OPMODE5")? OPMODE[5] : (CARRYINSEL == "CARRYIN")? CARRYIN : 0;
assign BMUX_OUT         = (B_INPUT    == "DIRECT" )?    B      : (B_INPUT    == "CASCADE")?    BCIN : 0 ;
assign PREADDER_MUX_OUT = (OPMODE[4]  == 0 )?        B0MUX_OUT : PREADDER_OUT;

//MULTIPLIER  M 
assign MULTIPLIER_OUT = B1MUX_OUT * A1MUX_OUT;

//PRE ADDER
always @(*) begin
    case (OPMODE[6])
    0 : PREADDER_OUT = DMUX_OUT + B0MUX_OUT;
    1 : PREADDER_OUT = DMUX_OUT - B0MUX_OUT;
    default : PREADDER_OUT = 0;
    endcase
end

//X MULTIPLEXER
always @(*) begin
    case (OPMODE[1:0])
        2'b00   : X_OUT = 0;
        2'b01   : X_OUT = MMUX_OUT;
        2'b10   : X_OUT = P;
        2'b11   : X_OUT = {DMUX_OUT[11:0], A1MUX_OUT[17:0], B1MUX_OUT[17:0]};
        default : X_OUT = 0;
    endcase
end

//Z MULTIPLEXER
always @(*) begin
    case (OPMODE[3:2])
        2'b00   : Z_OUT = 0;
        2'b01   : Z_OUT = PCIN;
        2'b10   : Z_OUT = P;
        2'b11   : Z_OUT = CMUX_OUT;
        default : Z_OUT = 0;
    endcase
end

//POST ADDER
always @(*) begin
    case (OPMODE[7])
        0 : {POSTADDER_CYO, POSTADDER_OUT} = Z_OUT + X_OUT + CIN;
        1 : {POSTADDER_CYO, POSTADDER_OUT} = Z_OUT - (X_OUT + CIN);
        default : {POSTADDER_CYO, POSTADDER_OUT} = 0;
    endcase
end

//REMAINING OUTPUTS
assign BCOUT     = B1MUX_OUT;
assign PCOUT     = P;
assign CARRYOUTF = CARRYOUT;
assign M         = MMUX_OUT ; 

endmodule