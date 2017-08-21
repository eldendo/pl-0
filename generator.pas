unit generator;

interface
uses interpreter;

procedure gen(x: mnemonic ; y: level; z: address);

function getLabel : address;

procedure fixUp(z: address);

procedure report;
//////////////////////////////////////////////////////////
implementation

var lab: address = 0;

procedure gen (x: mnemonic ; y: level; z: address);
begin
	if lab > maxAdr then begin writeln; writeln(' code memory range exceeded '); halt end;
	with code[lab] do begin f:=x; l:=y; a:=z end;
//	writeln; writeln (' $$$ ',x,' ',y,' ',z,' $$$ ');
	lab:=lab+1
end;

function getLabel: address; 
begin	
	getLabel := lab
end;

procedure fixUp(z: address);
begin
	code[z].a := lab;
//	writeln; writeln (' $$$ fixup at ',z ,' $$$ ');	
end;

procedure report;
var i: cardinal;
begin
	writeln(lab, ' p-code instructions generated');
	writeln;
	for i:=0 to lab-1 do begin
		with code[i] do begin 
			write(i,': ',f,' ',l,' ',a,' ');
			if f=OPR then begin
				case a of
					0: writeln('return');
					1: writeln('negate');
					2: writeln('add');
					3: writeln('sub');
					4: writeln('mul');
					5: writeln('div');
					6: writeln('odd');
					7: writeln('unknown instruction');
					8: writeln('=');
					9: writeln('#');
					10: writeln('<');
					11: writeln('<=');
					12: writeln('>');
					13: writeln('>=');
					14: writeln('read');
					15: writeln('write');
				end
			end
			else writeln;
		end
	end 
end;
	
end.
