program compiler;
uses scanner, identifiers, generator, interpreter;

procedure error(s: symbols; st: string);
begin
	writeln;
	writeln ('error: ',s,' ',st);
	halt
end;

procedure expect(s: symbols);
begin
	if symbol <> s then error(s,'expected');
	getSymbol
end;

procedure block;
var L0: cardinal;
	k: ObjType;
	l,a: cardinal;
	vc: cardinal;

	procedure constantDeclaration;
	var name: string; value: cardinal;
	begin
		getSymbol;
		name := str; expect(s_ident);
		expect(s_eql);
		value := val; expect(s_number);
		addConst(name,value);
//		write(' *** constant ',name, ' assigned to ',value,' *** ')
	end;
	
	procedure varDeclaration;
	var name: string;
	begin
		getSymbol;
		name := str; expect(s_ident);
		addVar(name);
//		write(' *** var ',name, ' declared *** ')
	end;
	
	procedure procedureDeclaration;
	var name: string;
	begin
		getSymbol;
		name := str; expect(s_ident);
		addProc(name, getLabel);
		//write(' *** procedure ',name,' declared *** ');	
		expect(s_semi);
		block;
		expect(s_semi)
	end;
	
	procedure statement;
	var L0, L1: cardinal;
	
	
	  procedure expression;
	  var oper: cardinal;
	  	  negate : boolean;
	
		procedure term;
		var oper: cardinal;

		
			procedure factor;
			begin
				case symbol of
				s_ident: begin 
							//write(' *** identifier ',str,' *** ');
							If not (checkConst(str) or checkVar(str)) then error(s_ident,' identifier '+str+' not declared');
							find(str,k,l,a);
							if k = constant then gen(LIT,0,a) else gen(LOD,l,a); // can be done shorter
							getSymbol 
						 end;
				s_number: begin gen(LIT,0,val); getSymbol end;
				s_lparen: begin
							getSymbol;
							expression;
							expect(s_rparen)
						  end;
				else error(symbol,'should be one of s_ident,s_number or s_lparen ')
				end
			end;
		
		begin // term
				factor;
				while symbol in [s_times,s_div] do
					begin
						if symbol = s_times then oper := 4  //write(' *** mult *** ')
										    else oper := 5; //write(' *** div *** ');
						getSymbol;
						factor;
						gen(OPR,0,oper)
				end
		end;
		
	  begin //expression
		//write(' *** enter expression *** ');
		negate := false;
		if symbol in [s_plus,s_minus] then 
			begin
				if symbol = s_minus then negate := true;
				getSymbol;
			end;
		term;
		if negate then gen(OPR,0,1);
		while symbol in [s_plus,s_minus] do
			begin
				if symbol = s_plus then oper := 2 //write(' *** plus *** ')
								   else oper := 3; //write(' *** minus *** ');
				getSymbol;
				term;
				gen(OPR,0,oper)
			end;
		//write(' *** exit expression *** ')
	  end;
	
	procedure assignment;
	var name: string; 
	begin
		name := str; getSymbol; expect(s_becomes);
		If not checkVar(name) then error(symbol,' '+name+' is not declared as a variable'); 
		//write(' *** var ',name,' assigned *** ');
		expression;
		find(name,k,l,a);
		gen(STO,l,a)		
	end;
	
	procedure condition;
	var oper: cardinal;
	begin
		if symbol = s_odd then begin 
									getSymbol; 
									expression;
									gen(OPR,0,6) 
							   end
						  else 
							begin
								expression;
								case symbol of
									s_eql: oper := 8; //write(symbol);
									s_neq: oper := 9; //write(symbol);
									s_lss: oper := 10; //write(symbol);
									s_leq: oper := 11; //write(symbol);
									s_gtr: oper := 12; //write(symbol);
									s_geq: oper := 13; //write(symbol);
									else error(symbol,' condition expected ' )
								end;
								getSymbol;
								expression;
								gen(OPR,0,oper)
							end
	end;
	
	begin // statement
		//write(' *** enter statement *** ');
		case symbol of
		s_ident: assignment;
		s_call: begin 
					getSymbol;
//					debug;
					if not checkProc(str) then error(symbol, ' '+str+' is not a declared as a procedure ');
					//write(' *** call ',str,' *** ');
					find(str,k,l,a);
					expect(s_ident) ;
					gen(CAL,l,a);
				end;
		s_read: begin
					getSymbol;
					if symbol=s_ident then
						begin
							if not checkVar(str) then error(symbol,'variable expected');
							find(str,k,l,a);
							gen(OPR,0,14);
							gen(STO,l,a);
							//write(' *** read identifier ',str,' *** ');
							getSymbol
						end
				end;
		s_write: begin
					getSymbol;
					//write(' *** write *** ');
					expression;
					gen(OPR,0,15);
				 end;
		s_begin: begin
					//write (' *** begin *** ');
					getSymbol; statement;
					while symbol = s_semi do begin getSymbol; statement end;
					expect(s_end);
					//write(' *** end *** ')
				 end;
		s_if: begin
					// write(' *** if *** ');
					getSymbol; condition;
					L0 := getLabel;
					gen(JPC,0,0);
					expect(s_then);
					statement;
					fixUp(L0)
			  end;
		s_while: begin
					// write(' *** while ***');
					L0 := getLabel;
					getSymbol;
					condition;
					L1 := getLabel;
					gen(JPC,0,0);
					expect(s_do);
					statement;
					gen(JMP,0,L0);
					fixUp(L1)
				 end;
		else error(symbol,' statement expected ')
		end;
		//write(' *** exit statement *** ')
	end;
	
begin // block
	//writeln (' *** enter block *** ');
	enterBlock;
	
	L0 := getLabel;
	gen(JMP,0,0); // jump to begin of statement (in case there is procedure code inbetween)

	if symbol = s_const then begin
								constantDeclaration;
								while symbol = s_comma do constantDeclaration;
								expect(s_semi)
							 end;	
	if symbol = s_var then begin
								varDeclaration;
								while symbol = s_comma do varDeclaration;
								expect(s_semi)
							 end;
							 vc := varCount;
	while symbol = s_proc do procedureDeclaration;
	
	fixup(L0);
	gen(ISP,0,vc);
	statement;
	gen(OPR,0,0); //RETURN. if return is called at the end of the main routine (= without a CAL)
					// the RET restores PC to 0 (default old PC at startup) and provokes the end.
	//writeln(' *** exit block *** ');

	exitBlock;

end;

begin // compiler
	writeln('-----------------------------------');
	writeln('pl/0 compiler by ir. Marc Dendooven');
	writeln('-----------------------------------');
	
	//use paramCount to check nr of parameters
	assign (f,paramStr(1));
	reset(f);
	
	getChar;
	getSymbol;
	
	block;
	if symbol <> s_period then error(symbol, 'period expected');
//	gen(JMP,0,0); //exit no longer necessery because of return in block

	writeln; 
	writeln('-----------------------------------');
	writeln('program compiled without errors');
	writeln('-----------------------------------');
	
	close(f);
	
	report;
	
	writeln('-----------------------------------');	
	writeln('executing program');
	writeln('-----------------------------------');
	
	interpret

end.
