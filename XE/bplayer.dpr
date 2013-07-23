program bplayer;

{APPTYPE CONSOLE}
{$R bplayer.res}

uses
  windows,
  main in 'main.pas',
  c_tools;

const
   WM_DESTROY  = $0002;
   WM_COPYDATA = $004A; 

var
  cmain : Tmain;
  cmainThread : Cardinal;
  helpClass   : TWndClassex;
  helpWnd     : HWND;
  cmainHandle : THandle;
  reciever    : COPYDATASTRUCT;
  mmsg: msg;

procedure ProgramExit;
begin

   if Assigned(cmain) then begin
       cmain.TurnOff;
       cmain.Destroy;
   end;

   if helpWnd <> 0 then begin
       SendMessage(helpWnd, WM_DESTROY, 0,0);
       DestroyWindow(helpWnd);
       helpWnd := 0;
   end;

   if cmainThread <> 0 then begin
       CloseHandle(cmainThread);
       cmainThread := 0;
   end;

   FreeConsole;
end;

function ConProc(CtrlType : DWord) : Boolean; stdcall; far;
begin

  case CtrlType of
    {CTRL_C_EVENT: }
    CTRL_BREAK_EVENT: ProgramExit;
    CTRL_CLOSE_EVENT: ProgramExit;
    CTRL_LOGOFF_EVENT: ProgramExit;
    CTRL_SHUTDOWN_EVENT: ProgramExit;
    else

  end;

  result := true;

end;

Procedure Tproc(param:pointer); stdcall;
begin

    cmain := Tmain.Create(cmainHandle);       

    while cmain.alive do begin
        Sleep(DELAY);
        cmain.Draw;
        cmain.KeyStateCheck;
    end;

    cmain.Destroy;
    cmain := nil;

    ProgramExit;
    ExitThread(0);
end;

procedure NewAssociation(ext : string);
begin
   RegWriteStr(HKEY_CURRENT_USER, 'Software\Classes\.' + ext, '', 'Blur90');
   RegWriteStr(HKEY_CURRENT_USER, 'Software\Classes\Blur90\shell\open\command', '', '"' + ParamStr(0) + '" "%1"');
   RegWriteStr(HKEY_CURRENT_USER, 'Software\Classes\Blur90\DefaultIcon', '', ParamStr(0));
end;

function  CheckDuplicates : boolean ; {выключаем все предыдущие блуры . но по названию все таки закрывать не очень надежно. }
var Wnd : hWnd;
    buff: array [0..127] of Char;
begin

// meWnd := GetConsoleWindow;
Wnd := GetWindow(FindWindow(nil,'Bl90HlpWindow'), gw_HWndFirst);

reciever.dwData := 0; reciever.lpData := nil; reciever.cbData := 0;

if (ParamCount > 0) and (ParamStr(1) <> '-register') then begin

reciever.dwData := 0;
reciever.lpData := pchar(ParamStr(1));
reciever.cbData := Length(ParamStr(1)) + 1;

end;

result := false;

while Wnd <> 0 do begin
    
    if (Wnd <> helpWnd) and
        not IsWindowVisible(Wnd) and
        //(GetWindow(Wnd, gw_Owner) = 0) and
        (GetWindowText(Wnd, buff, sizeof(buff)) <> 0)
    then begin

    GetWindowText(Wnd, buff, sizeof(buff));

        if (buff = 'Bl90HlpWindow') and
           ((ParamCount <= 0) or
           (SendMessage(Wnd, WM_COPYDATA, 0, Longint(@reciever)) = 22)) then begin
	     result := true;
             break;
        end;
    end;

Wnd := GetWindow(Wnd, gw_hWndNext);

end;

end;

//WM_TIMER: if MessageBox(0, 'test', '', MB_YESNO + MB_ICONQUESTION) = IDNO then halt;
function windowproc(wnd: hwnd; msg: integer; wparam: wparam; lparam: lparam):lresult;stdcall;
var mess : ^COPYDATASTRUCT;
begin
  case msg of
  WM_COPYDATA: begin
       mess := Pointer(lparam);
       cmain.PlayMessage(string(PChar(mess.lpData)));
       result := 22;
  end;
  WM_DESTROY:
    begin
      postquitmessage(0);
      result := 0;
      exit;
    end;
  else
    result := defwindowproc(wnd,msg,wparam,lparam);
  end;
end;

begin

    helpWnd := 0;
    cmainHandle := 0;
    cmain := nil;

    if CheckDuplicates then exit;
    
    AllocConsole();
    SetConsoleCtrlHandler(@ConProc, true);

    if (ParamCount = 1) and (ParamStr(1) = '-register') then begin

       NewAssociation('M4A');
       NewAssociation('MP3');
       NewAssociation('MP1');
       NewAssociation('MP2');
       NewAssociation('FLAC');
       NewAssociation('AAC');
       NewAssociation('ALAC');
       NewAssociation('WAV');
       NewAssociation('OGG');
       NewAssociation('M3U');
       NewAssociation('M3U8');

       writeln('Associations registered. Press enter to exit...');
       readln;

       Halt;
       exit;
    end;

  helpClass.cbsize := sizeof (helpClass);
  helpClass.style := 0; //cs_hredraw or cs_vredraw;
  helpClass.lpfnwndproc := @windowproc;
  helpClass.cbclsextra := 0;
  helpClass.cbwndextra := 0;
  helpClass.hinstance := hinstance;
  helpClass.hicon := 0;
  helpClass.hcursor := 0;
 // helpClass.hicon := loadicon(0,idi_application);
 // helpClass.hcursor := loadcursor(0,idc_arrow);
  helpClass.hbrbackground:=1;
  helpClass.lpszmenuname := nil;
  helpClass.lpszclassname := 'Bl90Hlp';

  registerclassex(helpClass);

  helpWnd := createwindowex(0,'Bl90Hlp','Bl90HlpWindow', 0,0,0,0,0,0,0,hinstance,nil);

 // ShowWindow(GetConsoleWindow,SW_HIDE);

  cmainHandle := GetCurrentThreadID;
  cmainThread := CreateThread(nil, 0, @Tproc, nil, 0, cmainThread);

  while (helpWnd <> 0) and (getmessage(mmsg, helpWnd, 0, 0)) do
  begin
    translatemessage(mmsg);
    dispatchmessage(mmsg);
  end;

{
  // Old method without Tread

    cmainHandle := GetCurrentThreadID;
    cmain := Tmain.Create(cmainHandle);
    SetConsoleCtrlHandler(@ConProc, true);

    while true do begin
        Sleep(DELAY);
        cmain.KeyStateCheck;
        cmain.Draw;
    end;
}

end.
