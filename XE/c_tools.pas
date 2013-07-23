unit c_tools;

interface

uses
  windows;

function FFTtoNum(value : single): smallint;
function FileExists (fname : string) : bool;
function IntToStr(i:integer):string;
function GetConsoleWindow: HWND; stdcall; external 'Kernel32.dll';
function AnsiCompareStr(const S1, S2: string): Integer;
function RegWriteStr(RootKey: HKEY; Key, Name, Value: string): Boolean;
function StrToInt(s:string):integer;
//function Ansi2OEM(const S : string) : string;
function TrimSpaceLeft(text : string) : string;
procedure CreateNewFile (fname : string);	
procedure CopyStrToStr(var dest : string; source : string; num : integer);

implementation

procedure CopyStrToStr(var dest : string; source : string; num : integer);
var i, endOf : integer;
begin

 endOf := num;
 if endOf > Length(source) then endOf := Length(source);

 for i := 1 to endOf do dest := dest + source[i];

end;

function FFTtoNum(value : single): smallint;
begin
 result := Trunc((Abs(value)) * 200);
end;

function FileExists (fname : string) : bool;
var
file_exist : THandle;
wfd        : WIN32_FIND_DATA;
begin
    file_exist := FindFirstFile(PChar(fname), wfd);
    if (INVALID_HANDLE_VALUE <> file_exist) then begin
        FindClose(file_exist);
        result := true;
        exit;
    end;

    result := false;
end;

procedure CreateNewFile (fname : string);
var
file_new : THandle;
begin

   file_new:= CreateFile(PChar(fname),GENERIC_READ or
      GENERIC_WRITE, FILE_SHARE_WRITE or FILE_SHARE_READ, nil, CREATE_NEW,
      FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0);

   CloseHandle(file_new);
end;

function IntToStr(i:integer):string;
var
  s : string;
begin
  Str(i, s);
  Result := s;
end;

function StrToInt(s:string):integer;
var
  t:integer;
  c:integer;
begin
  val(s,t,c);
  if c=0 then
    Result:=t
  else
    Result:=0;
end;

//function Ansi2OEM(const S : string) : string;
//begin
//  SetLength(Result,Length(S));
 /// if  Length(S) <> 0  then
 //   CharToOem(pChar(S),pChar(Result));
//end;

function TrimSpaceLeft(text : string) : string;
var i : integer;
begin

 result := '';

 for i := 1 to Length(text) do
    if text[i] = ' ' then continue
    else begin
            result := copy(text,i, Length(text)-i+1);
            exit;
         end;

end;
	
function RegWriteStr(RootKey: HKEY; Key, Name, Value: string): Boolean;
var
  Handle: HKEY;
  Res: LongInt;
begin
  Result := False;
  Res := RegCreateKeyEx(RootKey, PChar(Key), 0, nil, REG_OPTION_NON_VOLATILE,
    KEY_ALL_ACCESS, nil, Handle, nil);
  if Res <> ERROR_SUCCESS then
    Exit;
  Res := RegSetValueEx(Handle, PChar(Name), 0, REG_SZ, PChar(Value),
    Length(Value) + 1);
  Result := Res = ERROR_SUCCESS;
  RegCloseKey(Handle);
end;

function AnsiCompareStr(const S1, S2: string): Integer;
begin
{$IFDEF MSWINDOWS}
  Result := CompareString(LOCALE_USER_DEFAULT, 0, PChar(S1), Length(S1),
    PChar(S2), Length(S2)) - 2;
{$ENDIF}
{$IFDEF LINUX}
  // glibc 2.1.2 / 2.1.3 implementations of strcoll() and strxfrm()
  // have severe capacity limits.  Comparing two 100k strings may
  // exhaust the stack and kill the process.
  // Fixed in glibc 2.1.91 and later.
  Result := strcoll(PChar(S1), PChar(S2));
{$ENDIF}
end;   

end. 