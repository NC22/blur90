unit main;

interface

uses
  windows, Messages, c_menu, c_language, c_player, c_tools, BASS;

const DELAY = 70;

type

    key = packed record
     id: SMALLINT;
     state: SMALLINT;
    end;

    Tkey_holder = record
        ptime_up, ptime_down: smallint;
        delay : smallint;
    end;

    fileInfo = packed record
     dir  : string;
     name : string;
     ext  : shortstring;
    end;

    mControlls = packed record {common buttons for all kind menu's}
	  RIGHT  : key;
	  LEFT   : key;
	  UP     : key;
	  DOWN   : key;
    SELECT : key;
    DELETE : key;
    S_ALL  : key;
    UP_10  : key;
    DOWN_10: key;
    end;

    TFileMan = record
     workdir  : string;
     mask     : shortstring;
    end;

    Tmain = Class

	 private
      MusicList     : array of string;
      OnEndTrigger  : boolean;
      LiveTrg       : boolean;

      SelfWID       : THandle; { идентификатор главного потока}

	    FileMan       : TFileMan;
	    lang          : LANGUAGE;
      Menu          : array[1..2] of TMenu;
	    MenuControlls : mControlls;
	    ActiveMenu    : shortint;

      PLAYB: key; {PAUSE}
	    STOP: key;
	    PREV: key; PREV_A: key;
	    NEXT: key; NEXT_A: key;
	    VOLUMEP: key; VOLUMEP_A: key;
	    VOLUMED: key; VOLUMED_A: key;

      INSERT : key;
	    MODE_CH: key;
	    SAVE   : key;
	    ESC    : key;

      {MENU_A - PLAYLIST | MENU_N - File Manager}
      MENU_A: key; MENU_N: key;

      coord  : TCoord;
      drop   : string;
	    sunny  : boolean; {false if proggram not in focus}
	    slow_delay, slow_delay_cur : smallint; { draw some stuff after that delay in Draw function}
      console: TConsoleOutput;
	    melody : TPlayer;
      select : integer;
      volume : shortint;
	    pname  : pchar;
	    mode   : shortint;
      SongN  : string;


	    key_holder : Tkey_holder;
      drawMode : shortint;

	    function GetFileInfo(f : string) : fileInfo;
	    function NameCut(name : string) : string;
      function IsKeyPressed(var button : key) : boolean ;
	    procedure MusicListAdd(fullPath : string);
	    procedure AddM3UToList(M3U_File_Loc : string);
	    procedure GetSpectr(var outStr : string);
	    procedure GetOsc(var outStr : string);
      procedure GetRand(var outStr : string);
	    procedure Play(selector : smallint = 1);
	    procedure SelectMenu(id : shortint);
	    procedure MusicListDelete(Index: integer);
	    procedure MeInFocus;
	    procedure RestoreOptions;
	    procedure DumpMusicList;
	    procedure DumpOptions;
	    procedure StatusLine;
	    procedure DrawBlank;
	    procedure KillAllMenu;
	    procedure SaveMusicList;
	    procedure KeyStateInit;
	    procedure SongNameCut;
	    procedure VolumePlus;
	    procedure VolumeMinus;
	    procedure Stop_p;
	    procedure OnMusicEnd;
	    procedure MenuSelect;
	    procedure ModeUp;
	    procedure PlayNext;
	    procedure MusicListMenuCreate;
	    procedure SelectAllFiles;
	    procedure DiskSelectCreate;
	    procedure FileManMenuCreate;
	    procedure MenuAccept;
	    procedure Pause;

	public
	    Constructor Create(wID : THandle);
      Destructor  Destroy; override;
      procedure Draw;
      procedure KeyStateCheck;
      procedure TurnOff;
      property  alive : boolean read LiveTrg;
      procedure PlayMessage(newM : string);
	end;

implementation

Constructor Tmain.Create(wID : THandle);
var i:integer;
begin

Inherited Create;

KeyStateInit;

SelfWID := wID;
LiveTrg := true;

//SelfHlpWID := hlpWID;

{Настройка окна консоли}
pname := 'Blur90 v1.31';

console := TConsoleOutput.Create;
console.ConsoleInit;

SetConsoleTitle('Blur90');

slow_delay     := 1000; // 1 sec {для обновление верхнего меню}
slow_delay_cur := slow_delay;

key_holder.delay      := 200; // задержка перемещения по элементам списка меню
key_holder.ptime_up   := 0;
key_holder.ptime_down := 0;

lang := LANGUAGE.Create(GetFileInfo(ParamStr(0)).dir);

drawMode := 2;

SendMessage(GetConsoleWindow,$0080,0,LoadIcon(hInstance,'Picture0'));

{Bass инициализация}

melody := TPlayer.Create;
OnEndTrigger := false;
//melody.OnMusicEnd := OnMusicEnd;  cause some AV errors due to BASS_ChannelSetSync

mode := 1;

ActiveMenu := 0;

select := 0;
setLength(songN,0);

volume := melody.GetVolume;

{Собираем параметры если они есть}

RestoreOptions;
if (mode < 1) or (mode > 3) then mode := 1;
if (drawMode < 1) or (drawMode > 3) then drawMode := 2;

  Finalize(MusicList);
  setlength(MusicList,0);

  if ParamCount>0 then
     for i := 1 to ParamCount do
        begin
          MusicListAdd(ParamStr(i));
        end
  else begin
        SelectMenu(2);
        exit;
  end;

  Play(0);
  DrawBlank;  
   
end;

destructor Tmain.Destroy;
begin

   melody.Destroy;
   inherited;
end;

procedure Tmain.TurnOff;
begin

   Stop_p;
   DumpOptions;
   DumpMusicList;

end;

function Tmain.GetFileInfo(f : string) : fileInfo;
var
  i    : integer;
  extF : boolean;
begin

 extF := false;

 for i := Length(f) downto 1  do  
  begin

    if (extF = false) and (f[i] = '.') then begin

      result.ext := copy(f,i+1, Length(f)-i);
      extF := true
      
    end;

    if (f[i] = '\') or (f[i] = '/') then begin

      result.name := copy(f,i+1, Length(f)-Length(result.ext));
      Break;

    end

  end;

  result.dir := copy(f,1, i-1);

end;

procedure Tmain.MusicListAdd(fullPath : string);
var
  len,i : integer;
begin

  if not FileExists(fullPath) then exit;

  if GetFileInfo(fullPath).ext = 'm3u' then begin
    AddM3UToList(fullPath);
    exit;
  end;

 len := Length(MusicList);

 for i := 0 to len-1 do
   if AnsiCompareStr(MusicList[i], fullPath) = 0 then exit;

 setlength(MusicList,len+1);
 MusicList[len] := fullPath;

 select := len;

end;

procedure Tmain.AddM3UToList(M3U_File_Loc : string);
var M3U_File : TextFile;
    M3U_FInfo: FileInfo;
    buff     : string[255];
begin

     M3U_FInfo := GetFileInfo(M3U_File_Loc);

     AssignFile(M3U_File, M3U_File_Loc);
     reset(M3U_File);

     buff := '';

     while (not EOF(M3U_File)) do begin

       readln(M3U_File, buff);

       buff := TrimSpaceLeft(buff);

       if Length(buff) < 3 then continue;

       if buff[1] = '#' then continue;

       if buff[2] <> ':' then { relative link }
        buff := M3U_FInfo.dir + '\' + buff;

       MusicListAdd(buff);
       buff := '';

     end;

     CloseFile(M3U_File);

end;

procedure Tmain.MusicListDelete(Index: integer);
var
  ALength,sindex: Cardinal;
  TailElements: Cardinal;
begin
  if Index > High(MusicList) then
    Exit;
  if Index < Low(MusicList) then
    Exit;
  if Index = High(MusicList) then
  begin
    SetLength(MusicList, Length(MusicList) - 1);
    select := 0;
    Exit;
  end;

  ALength := Length(MusicList);
  Finalize(MusicList[Index]);
  sindex := index;
  TailElements := ALength - sindex;
  if TailElements > 0 then
    Move(MusicList[Index + 1], MusicList[Index], SizeOf(string) * TailElements);
  Initialize(MusicList[ALength - 1]);
  SetLength(MusicList, ALength - 1);

  select := 0;
end;

procedure Tmain.MeInFocus;   {ид текущего окна неизменен - сохранить и брать из переменной}
begin
  sunny:=SelfWID=GetWindowThreadProcessID(GetForeGroundWindow, nil);
end;

procedure Tmain.RestoreOptions;
var i : integer;
    settings : TextFile;
    buff : string[255];
    param: string[32];
    fileWay : string;

    {восстанавливаемые параметры}

    x,y : smallint;

begin

    fileWay := GetFileInfo(ParamStr(0)).dir+'\opt.cpconf';

    if FileExists(fileWay) = false then exit;

    x := 0;
    y := 0;

    AssignFile(settings, fileWay);

    reset(settings);

    buff := '';

     while (not EOF(settings)) do begin

       readln(settings, buff);

       buff := TrimSpaceLeft(buff); {убирает пробелы только слева т.е. если за параметром будет хотябы один пробел перед = то уже не распознает}

       if Length(buff) < 3 then continue;
       if buff[1] = '#' then continue;

       {ищем параметр в строке}

       param := '';

       for i := 1 to Length(buff) do
         if (buff[i] = '=') then param := copy(buff,1, i-1);

       if (param = '') or (Length(param)+1 = Length(buff)) then continue;

       buff := copy(buff, Length(param)+2, Length(buff) );

       {асоциации с параметрами}

	if param = 'Left' then x := StrToInt(buff)
        else if param = 'Top' then y := StrToInt(buff)
        else if param = 'Mode' then mode := StrToInt(buff)
        else if param = 'DrawMode' then DrawMode := StrToInt(buff);

       buff := '';

     end;

     CloseFile(settings);  

     if (x > 0) or (y > 0) then SetWindowPos(GetConsoleWindow,HWND_TOP,x,y,0,0,SWP_NOSIZE);
end;

procedure Tmain.DumpMusicList;
var musicNewFile: TextFile;
    fileWay : string;
    i : integer;
begin

   if Length(MusicList) = 0 then exit;

   fileWay := GetFileInfo(ParamStr(0)).dir+'\lastCPPlayList.m3u';

   if FileExists(fileWay) = false then CreateNewFile(fileWay);

   if FileExists(fileWay) = false then exit
   else begin

     AssignFile(musicNewFile, fileWay);

     Rewrite(musicNewFile);

   for i := 0 to Length(MusicList)-1 do
      WriteLn(musicNewFile, MusicList[i]);

     reset(musicNewFile);
     CloseFile(musicNewFile);

   end;

end;

procedure Tmain.DumpOptions;
var window  : TRect;
    settings: TextFile;
    fileWay : string;
begin
{OpenThread OpenThread($0002,false,GetCurrentThreadID)}
   fileWay := GetFileInfo(ParamStr(0)).dir+'\opt.cpconf';

   GetWindowRect(GetConsoleWindow,window);

   if FileExists(fileWay) = false then CreateNewFile(fileWay);

   if FileExists(fileWay) = false then exit
   else begin

     AssignFile(settings, fileWay);

     Rewrite(settings);

     WriteLn(settings, 'Left= ' + IntToStr(window.left));
     WriteLn(settings, 'Top= ' + IntToStr(window.top));
     WriteLn(settings, 'Mode= ' + IntToStr(mode));
     WriteLn(settings, 'DrawMode= ' + IntToStr(drawMode));

     reset(settings);
     CloseFile(settings);

   end;
          {сохранять последний список музыки и загружать его при старте если вообще не выбрано}

end;

procedure Tmain.StatusLine;
begin
{отдельно выводится и режим воспроизведения, прописан в Draw Blank}
if not melody.IsStoped then begin

  console.ConsoleLine(0,0,'[ '+lang.Volume+': '+IntToStr(volume)+'%]  '+lang.Time+': '+melody.GetTime+'/'+melody.Duration,39);
  console.ConsoleLine(41,0,'B',1,4);

if mode = 1 then console.ConsoleLine(44,0,lang.Mode+' : '+lang.Mode_Next,34)
else if mode = 2 then console.ConsoleLine(44,0,lang.Mode+' : '+lang.Mode_Loop,34)
else console.ConsoleLine(44,0,lang.Mode+' : '+lang.Mode_Random,34);

end
else console.ConsoleLine(0,0,'[ '+lang.Volume+': '+IntToStr(volume)+'%]  '+pname,-1);

end;

procedure Tmain.DrawBlank;
begin

   console.BlankScreen;

   StatusLine;

   if (ActiveMenu > 0) then exit;

   console.ConsoleLine(0,22,'',-1);
   console.ConsoleLine(0,23,songN,-1);

   if melody.IsPaused then console.ConsoleMessage(60 , 7 , lang.Pause);
   
end;

procedure Tmain.KillAllMenu;
begin

if ActiveMenu = 0 then exit;

menu[ActiveMenu].Free;

ActiveMenu := 0;
DrawBlank;

end;

procedure Tmain.SaveMusicList;
var musicNewFile: TextFile;
    fileWay : string;
    new_Name: string;
    i : integer;
begin

   if Length(MusicList) = 0 then exit;

    console.BlankScreen;
    StatusLine;
    menu[1].Draw;

    console.ConsoleLongMessage(2,17,25,lang.Playlist_save);
    new_Name := console.ReadInput(5,20);

   if Length(new_Name) = 0 then begin
   KillAllMenu;
   exit;
   end;
   // new_Name := 'saveCPPlayList';

   fileWay := GetFileInfo(ParamStr(0)).dir+'\'+new_Name+'.m3u';

   i := 1;

   while FileExists(fileWay) do begin
   fileWay := GetFileInfo(ParamStr(0)).dir+'\'+new_Name+'_'+IntToStr(i)+'.m3u';
   Inc(i);
   end;

   CreateNewFile(fileWay);

   if FileExists(fileWay) = false then exit
   else begin

     AssignFile(musicNewFile, fileWay);

     Rewrite(musicNewFile);

   for i := 0 to Length(MusicList)-1 do
      WriteLn(musicNewFile, MusicList[i]);

     reset(musicNewFile);
     CloseFile(musicNewFile);

     KillAllMenu;
   end;

end;

procedure Tmain.KeyStateInit;
begin

PLAYB.id := 179; PLAYB.state := GetAsyncKeyState(PLAYB.id);
STOP.id := 178; STOP.state := GetAsyncKeyState(STOP.id);
PREV.id := 177; PREV.state := GetAsyncKeyState(PREV.id);
PREV_A.id := 188; PREV_A.state := GetAsyncKeyState(PREV_A.id);
NEXT.id := 176; NEXT.state := GetAsyncKeyState(NEXT.id);
NEXT_A.id := 190; NEXT_A.state := GetAsyncKeyState(NEXT_A.id);
VOLUMEP.id := 175; VOLUMEP.state := GetAsyncKeyState(VOLUMEP.id);
VOLUMEP_A.id := 187; VOLUMEP.state := GetAsyncKeyState(VOLUMEP_A.id);
VOLUMED.id := 174; VOLUMED.state := GetAsyncKeyState(VOLUMED.id);
VOLUMED_A.id := 189; VOLUMED.state := GetAsyncKeyState(VOLUMED_A.id);
MENU_A.id := Ord('M'); MENU_A.state := GetAsyncKeyState(MENU_A.id);
MENU_N.id := Ord('N'); MENU_N.state := GetAsyncKeyState(MENU_N.id);

INSERT.id := VK_INSERT; INSERT.state := GetAsyncKeyState(INSERT.id);
SAVE.id := Ord('S'); SAVE.state := GetAsyncKeyState(SAVE.id);
MODE_CH.id := Ord('B'); MODE_CH.state := GetAsyncKeyState(MODE_CH.id);
ESC.id := VK_ESCAPE; ESC.state := GetAsyncKeyState(ESC.id);

MenuControlls.RIGHT.id := VK_RIGHT;
MenuControlls.LEFT.id := VK_LEFT;
MenuControlls.UP.id := VK_UP;
MenuControlls.DOWN.id := VK_DOWN;
MenuControlls.SELECT.id := VK_RETURN;
MenuControlls.DELETE.id := VK_DELETE;
MenuControlls.S_ALL.id := Ord('P');
MenuControlls.UP_10.id := VK_PRIOR;
MenuControlls.DOWN_10.id := VK_NEXT;

MenuControlls.RIGHT.state := GetAsyncKeyState(MenuControlls.RIGHT.id);
MenuControlls.LEFT.state := GetAsyncKeyState(MenuControlls.LEFT.id);
MenuControlls.UP.state := GetAsyncKeyState(MenuControlls.UP.id);
MenuControlls.DOWN.state := GetAsyncKeyState(MenuControlls.DOWN.id);
MenuControlls.SELECT.state := GetAsyncKeyState(MenuControlls.SELECT.id);
MenuControlls.DELETE.state := GetAsyncKeyState(MenuControlls.DELETE.id);
MenuControlls.S_ALL.state := GetAsyncKeyState(MenuControlls.S_ALL.id);
MenuControlls.UP_10.state := GetAsyncKeyState(MenuControlls.UP_10.id);
MenuControlls.DOWN_10.state := GetAsyncKeyState(MenuControlls.DOWN_10.id);

end;

{Поиск названия композиции в тегах OGG}

function Tmain.NameCut(name : string) : string;
var
 len : smallint;
 max : shortint;
begin
max := console.x-10;

len := Length(name);

if len < max then begin  result:= name; exit; end;

name := '...'+copy(name,len-max+3, len);
SetLength(name,max+1);

result := name;

end;

procedure Tmain.SongNameCut;
var
 len : smallint;
 max : shortint;
begin
max := console.x-10;

len := Length(songN);

if len < max then exit;

songN := '...'+copy(songN,len-max+3, len);
SetLength(songN,max+1);

end;

procedure Tmain.GetRand(var outStr : string);
var i : smallint;
    b : shortint;
begin

  Randomize;

  for i:= 20 downto 0 do
      for b := 0 to 79 do

      if b < 64  then begin
          if Random(100) >= 50 then outStr := outStr + #219
          else outStr := outStr + ' ';
      end
      else outStr := outStr + ' ';
end;

procedure Tmain.GetSpectr(var outStr : string);
var FFTFata : array [0..512] of Single;
    NumericData : array [0..128] of smallint;
    i : smallint;
    b : shortint;
begin

  melody.GetFFT(FFTFata);

  for i := 0 to 128 do
  NumericData[i] := FFTtoNum(FFTFata[i+5]);

  for i:= 20 downto 0 do
      for b := 0 to 79 do

      if b < 64  then begin
          if (NumericData[b*2]+NumericData[b*2+1])/2 > i*2 then begin
            if i = 20 then outStr := outStr + #176
            else if i = 19 then outStr := outStr + #177
            else if i = 18 then outStr := outStr + #178
            else outStr := outStr + #219
          end
          else outStr := outStr + ' ';
      end
      else outStr := outStr + ' ';
end;

procedure Tmain.GetOsc(var outStr : string);
var Wave : array [ 0..2048] of DWORD;
    NumericData : array [0..256] of smallint;
    i : smallint;
    b,num : shortint;
    R, L : SmallInt;
begin

  melody.GetWave(Wave);

  for i := 0 to 256 do begin

  R := SmallInt(LOWORD(Wave[i]));
  L := SmallInt(HIWORD(Wave[i]));

  NumericData[i] := Trunc(((R + L) / (2 * 65535)) * 30);

  end;
  { for b := 0 to 79 do
   outStr := outStr + '| '+IntToStr(Trunc((NumericData[b*3]+NumericData[b*3+1]+NumericData[b*3+2])/3));
    }
  for i:= 20 downto 0 do

    for b := 0 to 79 do begin

     num := Trunc((NumericData[b*3]+NumericData[b*3+1]+NumericData[b*3+2])/3);
     if abs(num) > 10 then begin
         if num < 0 then num := -10
         else num := 10;
     end;

     if (num < 0) and (abs(num+10) = i) then outStr := outStr + #219
     else if (num = 0) and (i = 10) then outStr := outStr + #219
     else if (num > 0) and (num+10 = i) then outStr := outStr + #219
     else outStr := outStr + ' ';

    end;

end;


procedure Tmain.Draw;  { Rename to Process }
var
  mstate : shortint;
begin

  mstate := melody.GetState;

  if (mstate = 0) and (OnEndTrigger) then begin

     OnEndTrigger := false; self.OnMusicEnd;

  end; 

  MeInFocus;
  if not sunny then exit;

  if slow_delay_cur <= 0 then begin
    StatusLine;
    slow_delay_cur := slow_delay
  end
  else Dec(slow_delay_cur,DELAY); {main timer is 0.1 sec per draw}

  if (ActiveMenu > 0) or (mstate <> BASS_ACTIVE_PLAYING) then exit;

  Coord.X := 0; Coord.Y := 1;
  SetConsoleCursorPosition(console.console, Coord);

  SetLength(drop,0);

       if drawMode = 1 then GetSpectr(drop)
  else if drawMode = 2 then GetOsc(drop);
  //GetRand(drop);
  write(drop);

end;


procedure Tmain.VolumePlus; {VOLUMEP}
begin

if melody.IsStoped then exit;
if volume = 100 then exit;

if volume+5 > 100 then volume := 100
else volume := volume + 5;

melody.SetVolume(volume);

StatusLine;

end;

procedure Tmain.VolumeMinus; {VOLUMED}
begin

if melody.IsStoped then exit;
if volume = 0 then exit;

if volume-5 < 0 then volume := 0
else volume := volume - 5;

melody.SetVolume(volume);

StatusLine;

end;

procedure Tmain.Stop_p; {STOP BUTTON}
begin

if melody.IsStoped then exit;

OnEndTrigger := false;
melody.Stop;

SetLength(drop,0);

KillAllMenu;
DrawBlank;
console.ConsoleMessage(50 , 7 , lang.Stop);

end;

procedure Tmain.Play(selector : smallint = 1); {NEXT}
begin

select := select + selector;
if select >= Length(MusicList) then select := 0;
if select < 0 then select := Length(MusicList) - 1;

if Length(MusicList) = 0 then begin
       DrawBlank;
       console.ConsoleLongMessage(2,2,70,lang.ListIsEmpty);
       Sleep(1000);
       exit;
end;

  melody.SetMelody(MusicList[select]);
  melody.LoadAndPlay;

  if melody.IsStoped then begin

    console.ConsoleMessage(2,20,lang.FileError+': '+GetFileInfo(MusicList[select]).name);
    Sleep(1000);

    MusicListDelete(select);

    Play;
    exit;

   end;

   OnEndTrigger := true;
   SetLength(songN,0);

   songN := melody.GetTitle;

    if Length(songN) = 0 then
       songN := PChar(MusicList[select]); {info.filename}

    SongNameCut;

    slow_delay_cur := 0;

   if ActiveMenu = 0 then DrawBlank;

end;

procedure Tmain.OnMusicEnd;
begin

OnEndTrigger := false;
melody.Stop;

slow_delay_cur := slow_delay;

if mode = 1 then Play(1)
else if mode = 2 then Play(0)
else begin
    if Length(MusicList) < 2 then begin Play(0); exit; end;

    Randomize;
    select := Random(Length(MusicList));

    Play(0);
end;
end;

procedure Tmain.PlayNext;
begin

OnEndTrigger := true;
melody.Stop;

if (mode = 1) or (mode = 2) then Play(1)
else begin
    if Length(MusicList) < 2 then begin Play(0); exit; end;

    Randomize;
    select := Random(Length(MusicList));

    Play(0);
end;

end;

procedure Tmain.MusicListMenuCreate;
var
   i : shortint;
   file_name : string;
begin

 if ActiveMenu = 1 then menu[ActiveMenu].Free;

 if Length(MusicList) = 0 then begin

 if ActiveMenu = 0 then exit;
 ActiveMenu := 0;

 if not melody.IsPlaying then begin
         console.BlankScreen;
         console.ConsoleLongMessage(2,2,70,lang.ListIsEmpty);
         StatusLine
 end
 else DrawBlank;

 exit;
 end;
 
 menu[1] := TMenu.Create(2,2,1,lang.MusicList,70);

 ActiveMenu := menu[1].MenuID;

   for i := 0 to Length(MusicList)-1 do begin
    file_name := GetFileInfo(MusicList[i]).name;
    menu[1].NewItem(NameCut(file_name),'');

    if melody.IsPlaying then
                 if select = i then menu[1].SetPosition(i);
   end;

  console.BlankScreen;
  StatusLine;
  console.ConsoleLongMessage(2,17,70,lang.MusicListHelp);
  menu[1].Draw;

end;

procedure Tmain.SelectAllFiles;
var i : integer;
begin
if ActiveMenu <> 2 then exit;

for i := 0 to menu[2].ItemsNum-1 do
     if (not menu[2].IsItemSelected(i)) and (menu[2].GetItemInfo(i) = '') then
     menu[2].TurnItemSelect(i);


end;

procedure Tmain.DiskSelectCreate; {подрежим файлового менеджера - выводит список дисков}
var ld : DWORD; {GetLogicalDrives}
    i  : shortint;
begin
 if ActiveMenu = 2 then menu[ActiveMenu].Free
 else exit;

 menu[2] := TMenu.Create(2,2,2,lang.DiskSelect,70);
 ActiveMenu := menu[2].MenuID;

 console.BlankScreen;

 ld := GetLogicalDrives;

  for i := 0 to 25 do
   if (ld and (1 shl i)) <> 0 then
       menu[2].NewItem(Char(Ord('A') + i) + ':','updir');

  console.ConsoleLongMessage(2,17,70,lang.FileManHelp);     
  menu[2].Draw;

end;

procedure Tmain.FileManMenuCreate;  {Создать \ пересоздать \ обновить список файлов}
var
   file_exist : THandle;
   wfd  : WIN32_FIND_DATA;
   name : string;
   updir: string;

{парсинг маски}
   mask : shortstring;
   count: shortint;
begin

   FileMan.mask := '*.flac|*.wav|*.ogg|*.m3u|*.m3u8|*.mp3|*.mp2|*.mp1|*.aac|*.alac|*.m4a|';  { проверить парсер }

   { LogDrive : set of 0..25;GetLogicalDrives}

  if ActiveMenu = 2 then menu[ActiveMenu].Free
  else begin
         if Length(MusicList) > 0 then
                FileMan.workdir := GetFileInfo(MusicList[select]).dir
        else
                FileMan.workdir := GetFileInfo(ParamStr(0)).dir;
  end;

   menu[2] := TMenu.Create(2,2,2,lang.FileList+' (' + FileMan.workdir + ')',70);
   ActiveMenu := menu[2].MenuID;

   console.BlankScreen;

  {вверх}
  updir := '';

  if Length(FileMan.workdir) > 1 then
  updir := copy(FileMan.workdir,1, 2);

  for count := Length(FileMan.workdir) downto 1  do
    if ((FileMan.workdir[count] = '/') or (FileMan.workdir[count] = '\')) and
       (count <> Length(FileMan.workdir)) then begin

      if (count-1 > 1) and (FileMan.workdir[count-1] <> ':') then
      updir := copy(FileMan.workdir,1, count-1);

      Break;
     end;

  if updir = FileMan.workdir then begin
    menu[2].NewItem(lang.DiskSelect,'select');
    menu[2].TurnItemSelect(0)
  end
  else
  menu[2].NewItem(updir,'updir');
  {Поиск папок}

  file_exist := FindFirstFile(PChar(FileMan.workdir+'\*.*'), wfd);

         if INVALID_HANDLE_VALUE <> file_exist then
         repeat
           if (wfd.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then begin

           name := wfd.cFileName;
              if (name<>'..') and (name<>'.') then  menu[2].NewItem(name,'dir');

           end;
         until FindNextFile(file_exist,wfd) = false;

   FindClose(file_exist);

  {Поиск музыки}

  mask := '';

   for count:=1 to Length(FileMan.mask) do
       if FileMan.mask[count] = '|' then begin

         file_exist := FindFirstFile(PChar(FileMan.workdir+'\'+mask), wfd);

         if INVALID_HANDLE_VALUE <> file_exist then
         repeat

           name := wfd.cFileName;

           if (name<>'..') and (name<>'.') then
                            menu[2].NewItem(name,'');

         until FindNextFile(file_exist,wfd) = false;

          FindClose(file_exist);
          mask := '';
       end
       else mask := mask + FileMan.mask[count];

  {console.ConsoleMessage(2,20,'Total size '+IntToStr(total));  }
  {выделить все . смещяться по списку при выделении}

  StatusLine;
  console.ConsoleLongMessage(2,17,70,lang.FileManHelp);
  menu[2].Draw;
end;

procedure Tmain.MenuAccept;
var len : integer;
    finf: fileInfo;
    fstr: string;
begin

 if ActiveMenu = 1 then begin
   select := menu[1].Pos;
   Play(0);
   KillAllMenu;
 end
 else if ActiveMenu = 2 then begin

    if menu[2].GetItemInfo(menu[2].Pos) = 'updir' then begin

        FileMan.workdir := menu[2].GetItemTitle(menu[2].Pos);
        FileManMenuCreate;

    end
    else if menu[2].GetItemInfo(menu[2].Pos) = 'dir' then begin
        FileMan.workdir := FileMan.workdir+'\'+menu[2].GetItemTitle(menu[2].Pos);
        FileManMenuCreate;
    end
    else if menu[2].GetItemInfo(menu[2].Pos) = 'select' then begin

      DiskSelectCreate;
      
    end
    else begin


    for len := 0 to menu[2].ItemsNum-1 do
        if (menu[2].IsItemSelected(len)) and (menu[2].GetItemInfo(len) = '') then
          MusicListAdd(FileMan.workdir + '\' + menu[2].GetItemTitle(len));

    if not menu[2].IsItemSelected(menu[2].Pos) then
      MusicListAdd(FileMan.workdir + '\' + menu[2].GetItemTitle(menu[2].Pos));

    Play(0);
    KillAllMenu;

    end;
  end;

end;

procedure Tmain.Pause; {PAUSE\PLAY BUTTON}
begin

KillAllMenu;

if melody.IsStoped then begin Play(0); exit; end;

if not melody.IsPaused then begin
melody.Pause;
console.ConsoleMessage(60 , 7 , lang.Pause);
end
else melody.PauseOff;

end;

{
 срабатывает только один раз,
 для повторного срабатывания пользователь должен отпусть клавишу и нажать повторно
 и нужно успеть зафиксировать это функцией
 }

function Tmain.IsKeyPressed(var button : key) : boolean ;
begin

if (GetAsyncKeyState(button.id) <> 0) and (button.state <> 0) then begin result := false;
                                                                         exit;
                                                                end
     else if GetAsyncKeyState(button.id) <> 0 then begin button.state := 1;
                                                        result := true;
                                                        exit;
                                                  end
          else if button.state <> 0 then button.state := 0;

result := false;

end;

procedure Tmain.SelectMenu(id : shortint);
begin

if (ActiveMenu > 0) and (menu[ActiveMenu] = nil) then exit;

if ActiveMenu = id then KillAllMenu
else if ActiveMenu = 0 then
         if id = 1 then MusicListMenuCreate
         else if id = 2 then FileManMenuCreate

else exit;

end;

procedure Tmain.MenuSelect;
begin

if menu[ActiveMenu].GetItemInfo(menu[ActiveMenu].Pos) = 'updir' then exit
else if menu[ActiveMenu].GetItemInfo(menu[ActiveMenu].Pos) = 'select' then exit;

 menu[ActiveMenu].TurnItemSelect(-1);

end;

procedure Tmain.ModeUp;
begin

 if mode + 1 > 3 then mode := 1
 else Inc(mode);

 StatusLine;
end;

procedure Tmain.KeyStateCheck;
begin

          if IsKeyPressed(PLAYB) then Pause
     else if IsKeyPressed(NEXT) then begin

         PlayNext;

         if ActiveMenu = 1 then MusicListMenuCreate
         else if ActiveMenu > 0 then KillAllMenu

         end
     else if IsKeyPressed(PREV) then begin KillAllMenu; Play(-1) end
     else if IsKeyPressed(STOP) then Stop_p
     else if GetAsyncKeyState(VOLUMEP.id) <> 0 then VolumePlus
     else if GetAsyncKeyState(VOLUMED.id) <> 0 then VolumeMinus;

     if sunny then begin {когда окно программы активно}

             if IsKeyPressed(MENU_A) then SelectMenu(1)
        else if IsKeyPressed(MENU_N) then SelectMenu(2)
        else if IsKeyPressed(MODE_CH) then ModeUp;

             if ActiveMenu > 0 then begin {to do move left right for file man}

                if ( key_holder.ptime_up >= key_holder.delay )   then key_holder.ptime_up := 0;
                if ( key_holder.ptime_down >= key_holder.delay ) then key_holder.ptime_down := 0;

                     if GetAsyncKeyState(MenuControlls.UP.id) <> 0 then Inc(key_holder.ptime_up,DELAY)
                else if ( key_holder.ptime_up > 0 ) then key_holder.ptime_up := 0;

                     if GetAsyncKeyState(MenuControlls.DOWN.id) <> 0 then Inc(key_holder.ptime_down,DELAY)
                else if ( key_holder.ptime_down > 0 ) then key_holder.ptime_down := 0;

                     if ( key_holder.ptime_up >= key_holder.delay ) or ( IsKeyPressed(MenuControlls.UP) ) then menu[ActiveMenu].MoveUp
                else if ( key_holder.ptime_down >= key_holder.delay ) or ( IsKeyPressed(MenuControlls.DOWN) ) then menu[ActiveMenu].MoveDown
                else if IsKeyPressed(MenuControlls.UP_10) then menu[ActiveMenu].MoveUp(10)
                else if IsKeyPressed(MenuControlls.DOWN_10) then menu[ActiveMenu].MoveDown(10)
                else if IsKeyPressed(MenuControlls.SELECT) then MenuAccept
                {else if IsKeyPressed(MenuControlls.RIGHT) then MenuMoveRight; }

                else begin

                        if ActiveMenu = 2 then

                          if IsKeyPressed(INSERT) then MenuSelect
                          else if IsKeyPressed(MenuControlls.S_ALL) then SelectAllFiles;

                        if ActiveMenu = 1 then

                           if IsKeyPressed(MenuControlls.DELETE) then begin
                              MusicListDelete(menu[1].Pos); {искать по имени}
                              MusicListMenuCreate;
                           end
                           else if IsKeyPressed(SAVE) then SaveMusicList;
                 end
             end

        else if IsKeyPressed(SAVE) then Stop_p {S - остановить воспроизведение}
        else if IsKeyPressed(MenuControlls.S_ALL) then Pause {P - play\pause}
        else if IsKeyPressed(VOLUMEP_A) then VolumePlus
        else if IsKeyPressed(VOLUMED_A) then VolumeMinus
        else if (IsKeyPressed(NEXT_A)) and (not IsKeyPressed(NEXT)) then PlayNext { = NEXT}
        else if (IsKeyPressed(PREV_A)) and (not IsKeyPressed(PREV)) then begin KillAllMenu; Play(-1) end { = PREV}
        else if IsKeyPressed(ESC) then begin TurnOff; LiveTrg := false; exit; end;

        if melody.IsPlaying then begin

           if GetAsyncKeyState(MenuControlls.RIGHT.id) <> 0 then
               melody.TimeMove(5)
           else if GetAsyncKeyState(MenuControlls.LEFT.id) <> 0 then
               melody.TimeMove(-5);

        end;
        
     end;


end;

procedure Tmain.PlayMessage(newM : string);
begin

TurnOff;

Finalize(MusicList);
setlength(MusicList,0);


MusicListAdd(newM);
Play(0);

end;

end. 