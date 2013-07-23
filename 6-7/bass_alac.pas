Unit BASS_ALAC;

interface

uses windows, bass;

const
  BASS_TAG_MP4        = 7;	// iTunes/MP4 metadata

  // BASS_CHANNELINFO type
  BASS_CTYPE_STREAM_ALAC        = $10e00;


const
  bassalacdll = 'bass_alac.dll';


function BASS_ALAC_StreamCreateFile(mem:BOOL; f:Pointer; offset,length:QWORD; flags:DWORD): HSTREAM; stdcall; external bassalacdll;
function BASS_ALAC_StreamCreateFileUser(system,flags:DWORD; var procs:BASS_FILEPROCS; user:Pointer): HSTREAM; stdcall; external bassalacdll;

implementation

end.