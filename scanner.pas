unit scanner;

interface

type symbols = (s_null,s_odd,s_times,s_div,s_plus,s_minus,s_eql,s_neq,s_lss,
				s_leq,s_gtr,s_geq,s_comma,s_rparen,s_then,s_do,s_lparen,
				s_becomes,s_number,s_ident,s_semi,s_end,s_call,s_if,s_while,
				s_begin,s_read,s_write,s_const,s_var,s_proc,s_period,s_eof);
				
const symbolStrings : array[s_null..s_eof] of string 
				= ('','ODD','*','/','+','-','=','#','<',
				   '<=','>','>=',',',')','THEN','DO','(',
				   ':=','','',';','END','CALL','IF','WHILE',
				   'BEGIN','?','!','CONST','VAR','PROCEDURE','.','');

var	symbol: symbols;
	val: cardinal;
	str: string;
	f: file of char;
	
procedure getChar;
procedure getSymbol;

implementation

var ch: char;

procedure getChar;
begin
	if not eof(f) 
	  then
		begin
			read(f,ch);
			write(ch);
			ch := upcase(ch) // language is case insensitive
		end
	  else  
		begin
			writeln;
			writeln('error: unexpected end of file encountered. Execution halted');
			halt
		end			
end;

procedure number;
begin
	symbol := s_number;
	val := 0;
	while ch in ['0'..'9'] do
	begin
			val := val*10 + ord(ch) - ord('0');
			getChar
	end;
end;

procedure identifier;
var s: symbols;
begin
	symbol := s_ident;
	str := '';
	while ch in ['A'..'Z','0'..'9'] do
	begin
			str := str + ch;
			getChar
	end;
	for s := s_null to s_eof do //check for reserved words
			if str = symbolStrings[s] then begin symbol := s end;			
end;

procedure other;
var s: symbols;
begin
	symbol := s_null;
	str := ch; getChar;
	if ch in ['=','*'] then begin str := str + ch; getChar end;
	if str = '(*' then begin
							repeat
								while ch <> '*' do getChar;
								getChar
							until ch = ')';
							getchar;
							getSymbol
						end;	
	for s := s_null to s_eof do //check for reserved symbols
				if str = symbolStrings[s] then symbol := s							  
end;

procedure getSymbol;
begin 
	while ch in [#00..#32] do getChar; // skip whitespace
	case ch of
//	#00: symbol := s_eof;
	'0'..'9': number;
	'A'..'Z': identifier;
	else other
	end
end;

end.
