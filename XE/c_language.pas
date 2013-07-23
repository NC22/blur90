unit c_language;

interface

uses windows;

type

  LANGUAGE = Class

    private
      workdir : string;
      function ReadParam(const text : string): string;
      function Trim(const text: string): string;

    public

      Blank_Title,
      Volume,
      Time,
      Pause,
      Stop,
      FileError,
      DiskSelect,
      FileList,
      MusicList,
      Mode,
      Mode_Loop,
      Mode_Random,
      Mode_Next,
      Playlist_save : string[64];

      MusicListHelp,ListIsEmpty,FileManHelp : string[255];

      Constructor Create(local_dir : string = 'none');
      procedure FindLocalization;

  end;

implementation

Constructor LANGUAGE.Create(local_dir : string = 'none'); {set default translation and try to search some localization file}
begin
   Inherited Create;
{
 Delphi не имеет прямых средств работы с ассоциативными массивами
  если добавляете новые поля не забудте прописать их и в FindLocalization

 }

        Blank_Title := 'Unknown Song Name';
	Volume      := 'Volume';
	Time        := 'Time';
	Pause       := 'PAUSE';
	Stop        := 'SONG IS STOPPED';
	ListIsEmpty := 'List of music is empty or all your files have unknown format';
	FileError   := 'Error in file';
	DiskSelect  := 'Disk Select Menu';
        FileList    := 'File List';
        MusicList   := 'Music List';
        Mode        := 'Mode';
        Mode_Loop   := 'Looped';
        Mode_Next   := 'Next';
        Mode_Random := 'Random';
        Playlist_save := 'Enter the filename:';

        MusicListHelp := 'Hot Keys:| Delete - delete selected item from music list|S - save current music list to file|    file will be placed in programm work dirrectory';
        FileManHelp := 'Hot Keys:| Insert - select\deselect current element of list | P - select all elements | N - close file manager';

	workdir := local_dir;

	if local_dir <> 'none' then FindLocalization;

end;

function LANGUAGE.Trim(const text: string): string; {Not from SysUtils}
var i : integer;
    param : boolean;
begin

 result := '';
 param := false;

 for i := 1 to Length(text) do
   if param = false then begin

    if text[i] = ' ' then continue
    else if text[i] = '=' then param := true;

    result := result + text[i]

   end
   else if text[i] <> ' ' then break;

  result := result + copy(text,i, Length(text)-i+1);

end;

function LANGUAGE.ReadParam(const text : string) : string;
var i : integer;
begin

 result := '';

 for i := 1 to Length(text) do
    if (text[i] = '=') then begin

      result := copy(text,1, i-1);
      exit;

    end;

end;

procedure LANGUAGE.FindLocalization;
var Local : TextFile;
    Local_Path, tmp_name : string;
    file_exist : THandle;
    wfd  : WIN32_FIND_DATA;
    buff : string[255];
    param: string[32];
begin

  file_exist := FindFirstFile(PChar(workdir+'\*.cplang'), wfd);

  Local_Path := 'none';

  if INVALID_HANDLE_VALUE <> file_exist then
    repeat

       tmp_name := wfd.cFileName;

              if (tmp_name <> '..') and (tmp_name <> '.') then begin
			    Local_Path := workdir + '\' + tmp_name;
			    break;
			  end;

    until FindNextFile(file_exist,wfd) = false;

   FindClose(file_exist);

   if Local_Path = 'none' then exit;
   
   
   AssignFile(Local, Local_Path);
   
   reset(Local);

   buff := '';

     while (not EOF(Local)) do begin

       readln(Local, buff);

       if Length(buff) < 3 then continue;

       if buff[1] = '#' then continue;   {trim left ?}

           buff := Trim(buff);

	   param := ReadParam(buff);
	   
	   if (param = '') or (Length(param)+1 = Length(buff)) then continue;
	   
	   buff := copy(buff, Length(param)+2, Length(buff) ); 
	   
           {асоциации с параметрами}

		if param = 'Blank_Title' then Blank_Title := buff
                else if param = 'Volume' then Volume := buff
                else if param = 'Time' then Time := buff
                else if param = 'Pause' then Pause := buff
                else if param = 'Stop' then Stop := buff
                else if param = 'ListIsEmpty' then ListIsEmpty := buff
                else if param = 'FileError' then FileError := buff
                else if param = 'DiskSelect' then DiskSelect := buff
                else if param = 'FileManHelp' then FileManHelp := buff
                else if param = 'FileList' then FileList := buff
                else if param = 'MusicList' then MusicList := buff
                else if param = 'MusicListHelp' then MusicListHelp := buff
                else if param = 'Mode_Loop' then Mode_Loop := buff
                else if param = 'Mode_Next' then Mode_Next := buff
                else if param = 'Mode_Random' then Mode_Random := buff
                else if param = 'Mode' then Mode := buff
                else if param = 'Playlist_save' then Playlist_save := buff;

       buff := '';

     end;

     CloseFile(Local);

end;

end.
