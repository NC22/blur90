unit c_player;

interface

uses
      BASS,
      BassFLAC,
      BASS_AAC,
      BASS_ALAC,
      windows;

type

  PID3 = ^TAG_ID3;

  TOnEnd = procedure of object;

  Tplayer = Class { работа с библиотекой Бас}

    private
     channel  : HSTREAM;
     sync     : HSYNC;
     mus      : string;
     time     : shortstring;

     FOnMusicEnd : TOnEnd;

     function MSClock(time : DWORD) : shortstring;
     function IntToStr(i:integer):string;

    public
     property OnMusicEnd : TOnEnd read FOnMusicEnd write FOnMusicEnd;
     function IsStoped : boolean;
     function IsPlaying : boolean;
     function IsPaused : boolean;
     function GetState : shortint;
     function GetTitle : string;
     function GetTime : string;
     function GetVolume : shortint;
     procedure GetFFT(var FFT : array of Single);
     procedure GetWave(var Wave : array of DWORD);
     procedure SetMelody(wayTo : string);
     procedure TimeMove(seconds : smallint);
     procedure Stop;
     procedure Pause;
     procedure SetVolume(new_volume : shortint);
     procedure LoadAndPlay;
     procedure PauseOff;
     property  Duration : shortstring read time;
     Constructor Create;
     Destructor  Destroy; override;

  end;

implementation

procedure ExecOnMusicEnd(handle: HSYNC; channel, data: DWORD; user: Pointer); stdcall;
var
  player : Tplayer;
begin

 if not Assigned(user) then exit;

 player := Tplayer(user);
 player.Stop;

 if Assigned(player.OnMusicEnd) then player.OnMusicEnd;

end;

Constructor Tplayer.Create; 
begin
   Inherited;

   BASS_Init(-1, 44100, 0, 0, nil);
   mus  := '';
   time := '00:00';

end;

destructor Tplayer.Destroy;
begin

  Stop;
  BASS_Free();

  inherited;
end;

function TPlayer.GetState : shortint;
begin

  result := 0;

  if channel = 0 then exit;

  result := BASS_ChannelIsActive(channel);

end;

function TPlayer.IsStoped : boolean;
begin

 result := false;

 if (channel = 0) or (BASS_ChannelIsActive(channel) = BASS_ACTIVE_STOPPED) then

 result := true

end;

function TPlayer.IsPaused : boolean;
begin
 result := BASS_ChannelIsActive(channel) = BASS_ACTIVE_PAUSED;
end;

function TPlayer.IsPlaying : boolean;
begin

if channel = 0 then result := false;

result := BASS_ChannelIsActive(channel) = BASS_ACTIVE_PLAYING;
end;

function TPlayer.GetVolume : shortint;
begin
 result := Trunc(BASS_GetVolume()/0.01);
end;

function TPlayer.IntToStr(i:integer):string;
var
  s:string;
begin
  Str(i,s);
  Result:=s;
end;

procedure TPlayer.PauseOff;
begin
if isPaused then  BASS_ChannelPlay(channel,false);
end;

procedure TPlayer.Pause;
begin
if not isStoped and not isPaused then BASS_ChannelPause(channel);
end;

procedure TPlayer.GetFFT(var FFT : array of Single);
begin

if not isPlaying then exit;

BASS_ChannelGetData(channel, @FFT, BASS_DATA_FFT1024);

end;

procedure TPlayer.GetWave(var Wave : array of DWORD);
begin

if not isPlaying then exit;

BASS_ChannelGetData(channel, @Wave, 2048);

end;

function TPlayer.GetTitle : string;
var
  position : integer;
  comments : pchar;
  id3      : PID3;
  info     : BASS_CHANNELINFO;
begin

   result := '';
   
   BASS_ChannelGetInfo(channel, info);
	 
{Поиск название композиции}

  if (info.ctype <> BASS_CTYPE_STREAM_OGG) and
     (info.ctype <> BASS_CTYPE_STREAM_FLAC) and
     (info.ctype <> BASS_CTYPE_STREAM_FLAC_OGG) then begin
	 
      id3 := PID3(BASS_ChannelGetTags(channel, BASS_TAG_ID3));
	  
      if (id3 <> nil) and (id3.title <> nil) then begin
	    result := id3.title;
		exit;
	  end;
	              
   end;

  comments := PWideChar(BASS_ChannelGetTags(channel, BASS_TAG_OGG));
  
  if comments = nil then comments := PWideChar(BASS_ChannelGetTags(channel, BASS_TAG_VENDOR));

  if comments = nil then exit; 

   position := pos('TITLE=',comments);
   if position <> 0 then begin
    result := copy(comments,position+6, Length(comments) - position);
    exit;
   end;

   position := pos('ALBUM=',comments);
   
   if position <> 0 then 
    result := copy(comments,position+6, Length(comments) - position);

end;

function TPlayer.MSClock(time : DWORD) : shortstring; {переводит секунды в текстовый вид}
var min,sec : smallint;
begin

//if ( time <= 1 ) then begin Result := '00:01'; exit; end;

min := time div 60;
sec := time mod 60;

if min > 9  then Result := IntToStr(min)
else Result := '0' + IntToStr(min);

Result := Result + ':';

if sec > 9 then Result := Result + IntToStr(sec)
else Result := Result + '0' + IntToStr(sec);
      
end;

procedure TPlayer.SetMelody(wayTo : string);
begin
mus := wayTo;
end;

procedure TPlayer.LoadAndPlay;
begin
if mus = ''  then exit;
if channel <> 0 then Stop;

{пробуем открыть как FLAC}

    channel := BASS_FLAC_StreamCreateFile(FALSE, PChar(mus), 0, 0, 0 {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});

  if channel = 0 then

{пробуем открыть как ALAC}

    channel := BASS_ALAC_StreamCreateFile(FALSE, PChar(mus), 0, 0, 0 {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});

  if channel = 0 then

{пробуем открыть как AAC}

    channel := BASS_AAC_StreamCreateFile(FALSE, PChar(mus), 0, 0, 0 {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});

  if channel = 0 then

{как MPEG, OGG, WAV ,AIFF , MP3}

    channel := BASS_StreamCreateFile(FALSE, PChar(mus), 0, 0, 0 {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
	
  if channel = 0 then exit;

    time := MSClock(Trunc(BASS_ChannelBytes2Seconds(channel,BASS_ChannelGetLength(channel, BASS_POS_BYTE)))-1);

    BASS_ChannelPlay(channel, False);

    //sync := BASS_ChannelSetSync(channel, BASS_SYNC_END, 0, @ExecOnMusicEnd, self);

end;

function TPlayer.GetTime : string;
begin

if IsStoped then exit;

result := MSClock(Trunc(BASS_ChannelBytes2Seconds(channel,BASS_ChannelGetPosition(channel, BASS_POS_BYTE))));

end;

procedure TPlayer.TimeMove(seconds : smallint); {сместиться по треку на количество секунд}
begin

if IsStoped then exit;

BASS_ChannelSetPosition(channel, BASS_ChannelGetPosition(channel, BASS_POS_BYTE)+BASS_ChannelSeconds2Bytes(channel,seconds),BASS_POS_BYTE);

end;

procedure TPlayer.Stop;
begin

if channel = 0 then exit;

//BASS_ChannelRemoveSync(channel, sync);
BASS_StreamFree(channel);

channel := 0;

end;

procedure TPlayer.SetVolume(new_volume : shortint);
begin
if IsStoped then exit;

BASS_SetVolume(new_volume*0.01);
end;

end.
