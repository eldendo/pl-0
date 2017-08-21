//******************************
// identifier package
// (c)2013 ir. Marc Dendooven
//******************************
unit identifiers;

interface

type objType = (constant,variable,proc,null);

procedure enterBlock;
procedure exitBlock;

procedure addConst(name: string; val: integer);
procedure addVar(name: string);
procedure addProc(name: string; val: integer);

function checkConst(name: string): boolean;
function checkVar(name: string): boolean;
function checkProc(name: string): boolean;

function varCount: cardinal;

procedure find(name: string; var k: objType; var l: cardinal; var a: cardinal);

procedure debug; // print identifierstack

implementation

type objNodePtr = ^objNode;
	 objNode = record
					next: objNodePtr;
					name: string;
					kind: objType;
					level: cardinal;
					val: integer;
	           end;	


var currentLevel: cardinal = 0; //level of static scope
	varCounter: cardinal; //number of variable in a level !!! should stored somewhere for each level or in proc obj
	top: objNodePtr = nil;

procedure error(s: string);
begin
	writeln;writeln(s);
	halt
end;

procedure checkLevel(name: string);
var ptr: objNodePtr; 
begin
	ptr := top;
	while (ptr <> nil) and (ptr^.level = currentLevel) do
	begin
		if name = ptr^.name then error('error: ' + name + ' has already been defined');
		ptr := ptr^.next
	end
		
end;

function checkObj(kind: ObjType; name: string): boolean;
var ptr: objNodePtr; 
begin
	ptr := top;
	checkObj := false;
	while (ptr <> nil) and (name <> ptr^.name) do ptr := ptr^.next;
	if (ptr <> nil) and (ptr^.kind = kind) then checkObj := true
end;

procedure find(name: string; var k: objType; var l: cardinal; var a: cardinal);
var ptr: ObjNodePtr;
begin
	ptr := top;
	k := null;
	while (ptr <> nil) and (ptr^.name <> name) do ptr := ptr^.next;
	if ptr <> nil then 
		begin
			k := ptr^.kind;
			l := currentLevel-ptr^.level;
			a := ptr^.val
		end
end;

function checkConst(name: string): boolean;
begin
	checkConst := checkObj(constant, name);
end;

function checkVar(name: string): boolean;
begin
	checkVar := checkObj(variable, name);
end;

function checkProc(name: string): boolean;
begin
	checkProc := checkObj(proc, name);
end;

procedure addObj(kind: objType; name: string; val: integer);
var newObj : objNodePtr;
begin
		checklevel(name);
		newObj := new(objNodePtr);

		newObj^.next := top;
		newObj^.name := name;
		newObj^.kind := kind;
		newObj^.level := currentLevel;
		newObj^.val := val;
		
		top := newObj	
end;

procedure addConst(name: string; val: integer);
begin
	addObj(constant, name, val)
end;

procedure addVar(name: string);
begin
	addObj(variable,name,varCounter);
	varCounter := varCounter+1
end;

procedure addProc(name: string; val: integer);
begin
	addObj(proc,name,val)
end;

procedure cleanLevel;
begin
	while (top <> nil) and (top^.level = currentLevel) do top := top^.next	
end;

procedure enterblock;
begin
	currentLevel := currentLevel+1;
	varCounter := 3 //var 0,1,2 zijn SL, DL en old PC
end;

procedure exitBlock;
begin
	cleanLevel;
	currentLevel := currentLevel-1
end;

function varCount: cardinal;
begin
	varCount := varCounter
end;

procedure debug;
var ptr: ObjNodePtr;
begin
	ptr := top;
	writeln;
	while ptr <> nil do
	  begin
		writeln(ptr^.name,' ',ptr^.kind,' ',Ptr^.level);
		ptr := ptr^.next
	  end	
end;

end.
