(**************************************************
* p-code interpreter by N. Wirth
* minor changes by ir. Marc Dendooven
* register names:
* PC, LV, SP, IR in stead of p, b, t, i  
* instruction INT renamed to ISP (increment SP)
* base function renamed to fsl (follow static link)
**************************************************)
unit interpreter;
interface

const 	maxLev = 15; //max difference between static scope levels
		maxAdr = 1023; // top of code memory
		
type 	address = 0..maxAdr;
		level = 0..maxLev;
		mnemonic = (LIT, OPR, LOD, STO, CAL, ISP, JMP, JPC);
		instruction = 	packed record
							f: mnemonic;
							l: level;
							a: address;
						end;
						
var code : array[address] of instruction; 

procedure interpret;		
////////////////////////////////////////////////////////////////////////		
implementation

const 	stackSize = 1024; // stack memory size
type 	sAddress = 0..stackSize-1; 

var PC : Address; //register: Program Counter
	LV, SP : sAddress; //register: Local Variable Frame Pointer, Stack Pointer
	IR: instruction; // Instruction Register
	s: array[sAddress] of integer; // stack. s[0] never used ?
	
function fsl(l: sAddress): sAddress; // follow static link for l levels
begin
	fsl := LV;
	while l > 0 do begin fsl := s[fsl]; l := l - 1 end;	
end; 	

procedure debug;
var i: cardinal;
begin
	writeln(PC,' ',IR.f,' ',IR.l,' ',IR.a, ' SP=',SP,' LV=',LV);
//	for i := 0 to SP do write ('s[',i,']=',s[i],',');
	writeln;
	readln;
end;

procedure interpret;
begin
	SP := 0; LV := 1; PC := 0; 
	s[1] := 0; s[2] := 0; s[3] := 0; //set SL,DL en return adres to 0 for global frame (why ?)
	repeat
		IR := code[PC]; 
//		debug;
		PC := PC+1;
		with IR do
			case f of
			LIT: begin SP := SP+1 ; s[SP] := a end; // put litteral on top of stack
			OPR: case a of
				    0: begin SP := LV - 1; PC := s[SP + 3]; LV := s[SP + 2] end; // return
					1: s[SP] := -s[SP]; //negate
					2: begin SP := SP - 1; s[SP] := s[SP] + s[SP + 1] end; // add
					3: begin SP := SP - 1; s[SP] := s[SP] - s[SP + 1] end; // sub
					4: begin SP := SP - 1; s[SP] := s[SP] * s[SP + 1] end; // mult
					5: begin SP := SP - 1; s[SP] := s[SP] div s[SP + 1] end; // integer div
					6: s[SP] := ord(odd(s[SP])); // odd 			
					// 7 is not used by Wirth. why ?
					8: begin SP := SP - 1; s[SP] := ord(s[SP] = s[SP + 1]) end; // =
					9: begin SP := SP - 1; s[SP] := ord(s[SP] <> s[SP + 1]) end; //#
					10: begin SP := SP - 1; s[SP] := ord(s[SP] < s[SP + 1]) end; // <
					11: begin SP := SP - 1; s[SP] := ord(s[SP] <= s[SP + 1]) end; // <=
					12: begin SP := SP - 1; s[SP] := ord(s[SP] > s[SP + 1]) end; // >
					13: begin SP := SP - 1; s[SP] := ord(s[SP] >= s[SP + 1]) end; // >=
					14: begin SP := SP + 1; write('>');read(s[SP]) end; //read integer
					15: begin writeln(s[SP]); SP := SP - 1 end; //write integer
				end;	
			LOD: begin SP := SP+1; s[SP] := s[fsl(l)+a] end; // load var on top
			STO: begin s[fsl(l)+a] := s[SP]; SP := SP-1 end; // store var from top
			CAL: begin s[SP+1] := fsl(l); s[SP+2] := LV; s[SP+3] := PC; // save static link, dyn link, and return adress 
					   LV := SP+1; PC := a end; 						// set new LV and jump to a
			ISP: SP := SP + a; // increment SP
			JMP: PC := a; // jump to a
			JPC: begin if s[SP] = 0 then PC := a ; SP := SP - 1 end; //conditional jump to a
			end
	until PC = 0 // exit interpreter with a JMP to 0
end;

end.
