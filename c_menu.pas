unit c_menu;

interface

uses   windows; //messages

type

  {Класс для низкоуровневого вывода в консоле}

  TConsoleOutput = Class
    private
     coord         : TCoord;
     WhiteOnBlue,
     WhiteOnGreen,
     Green,
     RedOnWhite,
     YellowOnBlue,
     BlackOnWhite,
     WhiteOnBlack : smallint;
     tmp           : cardinal;
     console_x,
     console_y     : smallint;

    public
	 console, c_input : THandle;
         procedure BlankScreen;
         procedure ConsoleInit;
	 procedure ConsoleLine(x , y : shortint; str : string; len : shortint; color_type : shortint = 1);
         procedure ConsoleOut(x , y : shortint; str : string; selected : boolean = false);
         procedure ConsoleMessage(x , y : shortint; infostr : shortstring);
         function  ReadInput(x , y : shortint): string;
         procedure Cursor(state : boolean);
         procedure CursorPos(x , y : shortint);
         procedure ConsoleLongMessage(x , y , str_len : shortint; infostr : shortstring);
         property  x : smallint read console_x;
         property  y : smallint read console_y;
	 Constructor Create;
    end;

  menuItem = record
     title   : string;
     info    : string;
     selected: boolean;
    end;

  { Меню - наследует класс вывода в консоли, добавляя функции вывода меню }

  TMenu = Class(TConsoleOutPut)

    private
     header   : string;
     items    : array of menuItem;
     position : integer;
     len,max_l: shortint;
     x,y      : shortint;
     id       : shortint;
     vertical : boolean;
     procedure SelectItem(Value : integer; select : boolean);

    public
     Constructor Create(createx, createy, newid : shortint; head : string; min_len : shortint = -1);
     procedure Draw;
     procedure NewItem(title,info : string; selected : boolean = false);
     procedure SetHeader(Value : string);
     procedure SetPosition(Value : integer);
     function GetItemTitle(Value : integer) : string;
     function GetItemInfo(Value : integer) : string;
     function IsItemSelected(Value : integer) : boolean;
    { procedure Clear;  }
     procedure TurnItemSelect(Value : integer);
     procedure MoveUp(skip : integer = 1);
     procedure MoveDown(skip : integer = 1);
     function getItemsNum : integer;

     property  MenuName : string read header write setHeader;
     property  Pos : integer read position write setPosition;
     property  MenuID   : shortint read id;
     property  ItemsNum : integer read getItemsNum;
    end;

implementation

{
procedure EmptyKeyQueue;
 var
   Msg: TMsg;
 begin
   while PeekMessage(Msg, 0, $0100, $0108,
     PM_REMOVE or PM_NOYIELD) do;
 end;


procedure EmptyMouseQueue;
 var
   Msg: TMsg;
 begin
   while PeekMessage(Msg, 0, WM_MOUSEFIRST, WM_MOUSELAST,
     PM_REMOVE or PM_NOYIELD) do;
 end;
}

Constructor TConsoleOutput.Create;
begin
   Inherited;

{системные постоянные}

   console := GetStdHandle(STD_OUTPUT_HANDLE);
   c_input := GetStdHandle(STD_INPUT_HANDLE);

   { for windows vista or hight its optimal frame size }

   console_x := 80;
   console_y := 25;

   WhiteOnBlue := FOREGROUND_BLUE or FOREGROUND_GREEN or
		  FOREGROUND_RED or FOREGROUND_INTENSITY or
		  BACKGROUND_BLUE;

   WhiteOnGreen := FOREGROUND_BLUE or FOREGROUND_GREEN or
		  FOREGROUND_RED or FOREGROUND_INTENSITY or
		  BACKGROUND_GREEN;

   Green := FOREGROUND_GREEN;

   YellowOnBlue := 14 or BACKGROUND_BLUE;

   BlackOnWhite := 0 or
		  BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE
		  or BACKGROUND_INTENSITY;
   WhiteOnBlack := FOREGROUND_INTENSITY or FOREGROUND_RED or FOREGROUND_GREEN
                  or FOREGROUND_BLUE;
   {
    Foreground and background color constants of original CRT unit
    Black = 0;
    Blue = 1;
    Cyan = 3;
    Red = 4;
    Magenta = 5;
    Brown  6;
    LightGray = 7;
                   
    Foreground color constants of original CRT unit
    DarkGray = 8;
    LightBlue = 9;
    LightGreen = 10;
    LightCyan = 11;
    LightRed = 12;
    LightMagenta = 13;
    Yellow = 14;
    White = 15;
    }

   RedOnWhite := FOREGROUND_RED or FOREGROUND_INTENSITY or
		  BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE
		  or BACKGROUND_INTENSITY;
end;

procedure TConsoleOutput.Cursor(state : boolean);
var CCI: _CONSOLE_CURSOR_INFO;
begin
    GetConsoleCursorInfo(console,CCI);
    CCI.bVisible := state;
    SetConsoleCursorInfo(console, CCI);
end;

procedure TConsoleOutput.CursorPos(x , y : shortint);
begin
   Coord.X := x; Coord.Y := y;
   SetConsoleCursorPosition(console, Coord);
end;

function TConsoleOutput.ReadInput(x , y : shortint): string;
var
  a  : Char;
  IR : INPUT_RECORD;
  Wr : cardinal;
  InputStr : string[10];
begin

//  EmptyKeyQueue;

  Cursor(true);
  CursorPos(x, y);

  ConsoleOut(x,y,StringOfChar(' ', 10),true);

  InputStr := '';

  FlushConsoleInputBuffer(c_input);

repeat

  WaitForSingleObjectEx(c_input,INFINITE,false);
  ReadConsoleInput(c_input,IR,1,Wr);

  case IR.EventType of
    KEY_EVENT:
    begin
      if IR.Event.KeyEvent.bKeyDown then
      begin

        a:=IR.Event.KeyEvent.AsciiChar;
        if a=#8 then begin
          Delete(InputStr,Length(InputStr),1);
          if Length(InputStr)>0 then
	      ConsoleOut(x,y,InputStr,true);
          CursorPos(x+Length(InputStr), y);
          ConsoleOut(x+Length(InputStr),y,'',true);
        end
        else if a>#31 then begin
         InputStr := InputStr+a;
         ConsoleOut(x,y,InputStr,true);
         CursorPos(x+Length(InputStr), y);
        end;

      end;

    end;

  end;

until IR.Event.KeyEvent.wVirtualKeyCode = VK_RETURN;

Cursor(false);

// FlushConsoleInputBuffer(c_input);

result := InputStr;
end;

procedure TConsoleOutput.ConsoleInit;
begin

{ограничиваем буфер вывода}

   Coord.X := console_x; Coord.Y := console_y;
   SetConsoleScreenBufferSize(console, Coord);

{кодировка}

   SetConsoleOutputCP(866); {DOS + rus symbols}
   SetConsoleCP(1251);

{убираем курсор}

    Cursor(false);

end;

procedure TConsoleOutput.BlankScreen;
var outof : string;
begin
 Coord.X := 0; Coord.Y := 0;

 //SetConsoleCursorPosition(console, Coord);

 //SetLength(outof,0);

 outof := StringOfChar(' ', console_x*console_y);

 FillConsoleOutputAttribute (console, WhiteOnBlack, console_x*console_y, coord, tmp);
 WriteConsoleOutputCharacter(console, PChar(outof) , console_x*console_y, coord, tmp);
 //write(outof);
end;

{
  выводит текст + заполняет пробелами пространство длиной len
  если текст оказался меньше + обрамляет все это в два пробела по бокам
  используется для меню конкретной длинны
}

procedure TConsoleOutput.ConsoleLine(x , y : shortint; str : string; len : shortint; color_type : shortint  = 1);
var wideChar : pWideChar;
begin

Coord.X := x; Coord.Y := y;

if len = -1 then len := console_x-2;
if Length(str) < len then str := str + StringOfChar(' ', len-Length(str));

str := ' '+str+' ';

GetMem(wideChar, sizeof(WideChar) * Succ(Length(str)));
StringToWideChar(str, wideChar, Succ(Length(str)));

WriteConsoleOutputCharacterW(console, wideChar , len+3, coord, tmp);

FreeMem(wideChar);

 case color_type of
    1: FillConsoleOutputAttribute (console, WhiteOnBlue, len+2, coord, tmp);
    2: FillConsoleOutputAttribute (console, RedOnWhite, len+2, coord, tmp);
    3: FillConsoleOutputAttribute (console, YellowOnBlue, len+2, coord, tmp);
    4: FillConsoleOutputAttribute (console, BlackOnWhite, len+2, coord, tmp);
 end;

end;

{
 вывод
  белый на синем
  красный на белом
}

procedure TConsoleOutput.ConsoleOut(x , y : shortint; str : string; selected : boolean = false);
var wideChar : pWideChar;
begin
   Coord.X := x;
   Coord.Y := y;

   GetMem(wideChar, sizeof(WideChar) * Succ(Length(str)));
   StringToWideChar(str, wideChar, Succ(Length(str)));

   WriteConsoleOutputCharacterW(console, wideChar , Length(str)+1, coord, tmp);

   FreeMem(wideChar);

   if selected then
        FillConsoleOutputAttribute (console, RedOnWhite, Length(str), coord, tmp)
   else
        FillConsoleOutputAttribute (console, WhiteOnBlue, Length(str), coord, tmp);
end;

{
str_len - максимальная длинна строки
}

procedure TConsoleOutput.ConsoleLongMessage(x , y , str_len : shortint; infostr : shortstring);
var counter,len,lines_found : smallint;
    cur_str : shortstring;
begin

  Coord.X := x; Coord.Y := y;

  len := Length(infostr)+1;

  ConsoleLine(x,y,'',str_len,4);

  counter := 1; lines_found := 0; cur_str := '';
  while counter <> len do
        if infostr[counter] = '|' then begin
        inc(lines_found);

        ConsoleLine(x,y+lines_found, cur_str , str_len ,4);

        cur_str := '';
        inc(counter)
        end
        else begin cur_str := cur_str+infostr[counter]; inc(counter) end;

  if cur_str <> '' then begin
        inc(lines_found);
        ConsoleLine(x,y+lines_found, cur_str , str_len ,4);
        cur_str := '';
  end;

  ConsoleLine(x,y+lines_found+1,'',str_len,4);

end;


procedure TConsoleOutput.ConsoleMessage(x , y : shortint; infostr : shortstring);
var
  len  : shortint;
begin

  Coord.X := x;
  Coord.Y := y;

  len := Length(infostr);

  ConsoleOut(x,y,StringOfChar(' ', len+2));

  ConsoleOut(x,y+1,' ' + infostr + ' ');

  ConsoleOut(x,y+2,StringOfChar(' ', len+2));

end;

{TMenu part}

 Constructor TMenu.Create(createx, createy, newid : shortint; head : string; min_len : shortint = -1);
 begin

   inherited Create;

    x        := createx;
    y        := createy;
    header   := head;
    position := -1;
    max_l    := 70;

    vertical := true;

    if min_len = -1 then len := Length(header)
    else begin

        if Length(header) > min_len then len := Length(header)
        else len := min_len;

    end;

    id       := newid;

 end;

 function TMenu.GetItemTitle(Value : integer) : string;
 var items_num : integer;
 begin
 items_num := Length(items);
  if (items_num = 0) or (Value > items_num-1) or (Value < 0) then
  begin
     result := 'Wrong Index';
     exit;
  end;

  result := items[Value].title;

 end;

 function TMenu.GetItemInfo(Value : integer) : string;
 var items_num : integer;
 begin
 items_num := Length(items);
  if (items_num = 0) or (Value > items_num-1) or (Value < 0) then
  begin
     result := 'Wrong Index';
     exit;
  end;

  result := items[Value].info;

 end;

 function TMenu.getItemsNum : integer;
 begin
 result := Length(items);
 end;

 procedure TMenu.SelectItem(Value : integer; select : boolean);
 var items_num : integer;
 begin
 items_num := Length(items);

  if (items_num = 0) or (Value > items_num-1) or (Value < 0) then exit;

  items[Value].selected := select;

 end;

 procedure TMenu.TurnItemSelect(Value : integer);
 begin

  if Value = -1 then Value := position;

  if IsItemSelected(Value) then SelectItem(Value,false)
  else SelectItem(Value,true);

  MoveDown;
  
  Draw;
 end;

 function TMenu.IsItemSelected(Value : integer) : boolean;
 var items_num : integer;
 begin
 items_num := Length(items);

 result := false;

  if (items_num = 0) or (Value > items_num-1) or (Value < 0) then exit;

 if items[Value].selected then result := true;

 end;

 procedure TMenu.Draw;
 var i,max,start,items_num : shortint;
 begin

 max := 10; start := 0; items_num := Length(items);

 if items_num > max then begin

  start := Trunc(position/max)*max;

  items_num := start+max;
  if items_num > Length(items) then
  items_num := Length(items);

  max :=items_num-start

 end
 else max := Length(items);


 ConsoleLine(x,y,'',len);
 ConsoleLine(x,y+1,header,len);

 if start > 0 then ConsoleLine(x,y+2,#24,len)
 else ConsoleLine(x,y+2,'',len);

 if items_num > 0 then
   for i := 0 to max-1 do begin

   if position = start then
     if IsItemSelected(start) then ConsoleLine(x,y+i+3,items[start].title,len,2)
     else ConsoleLine(x,y+i+3,items[start].title,len,4)
   else
     if IsItemSelected(start) then ConsoleLine(x,y+i+3,items[start].title,len,3)
     else ConsoleLine(x,y+i+3,items[start].title,len);

     Inc(start);

   end;

 if max < 10 then
    for i := max to 10 do
          ConsoleLine(x,y+i+3,'',len);

 if Length(items)-items_num > 0 then ConsoleLine(x,y+max+3,#25,len)
 else ConsoleLine(x,y+max+3,'',len);

 end;
 
 procedure TMenu.SetPosition(Value : integer);
 begin
  position := value;
  Draw;
 end;

 procedure TMenu.SetHeader(Value : string);
 begin
  header := value;
  Draw;
 end;
	  
 procedure TMenu.NewItem(title,info : string; selected : boolean = false);
 var items_num : integer; item : ^menuItem;
 begin

 new(item);

 item.title := title;
 item.info  := info;
 item.selected := false;

 if Length(item.title)+Length(item.info) > len then len := Length(item.title)+Length(item.info);
 if len > max_l then len := max_l;

 items_num:=Length(items);

 if items_num = 0 then position := 0;

 setlength(items,items_num+1);

 items[items_num] := item^;

 Dispose(item);

 end;
	  
 procedure TMenu.MoveDown(skip : integer = 1);
 begin

  if Length(items) = 0 then position := 0
  else if position + skip > Length(items)-1 then position := 0
       else Inc(position,skip);

 Draw;
 end;

 procedure TMenu.MoveUp(skip : integer = 1);
 begin

  if Length(items) = 0 then position := 0
  else if position - skip < 0 then position := Length(items)-1
       else Dec(position,skip);

 Draw;
 end;


end.
