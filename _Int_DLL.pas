unit _Int_DLL;

interface
type
  TAccounts = array of array of string;
  TYears = array of string;
  THHMMSS = array[0..3] of string;
  TRS = procedure(nResponse:Cardinal) of object;
  PDBBackUP = ^TDBBackUP;

  TDBBackUP = record
    enable: Boolean;
    Sa_PSW: string;
    Bak_Dir: string;
    AcctKeepDays:Word;
    BacKUpTime: THHMMSS;
    IsReboot: Boolean;
    UserWaitTime: Cardinal;
  end;

  PSysAutoRSDown = ^TSysAutoRSDown;

  TSysAutoRSDown = record
    enable: Boolean;
    RS_Option: Boolean;
    UserWaitTime: Cardinal;
    ShutupTime: THHMMSS;
  end;

  PSystimeAutomatic = ^TSystimeAutomatic;

  TSystimeAutomatic = record
    enable: Boolean;
    TimesToExitWhileFailed: Cardinal;
    NoRSonCheckTime: THHMMSS;
  end;

  PAutomaticRun = ^TAutomaticRun;

  TAutomaticRun = record
    enable: Boolean;
    ProgramPath: string;
    OnStartup:Boolean;
    RunatTime: THHMMSS;
    ClsTime: Cardinal;
  end;

  PDiskSpaceDetection = ^TDiskSpaceDetection;

  TDiskSpaceDetection = record
    enable:Boolean;
    interval:Word;
    TiggerVol:Int64;
  end;


  Pini = ^Tini;

  Tini = record
    DBBackUP:PDBBackUP;
    SysAutoRSDown:PSysAutoRSDown;
    SystimeAutomatic:PSystimeAutomatic;
    AutomaticRun:PAutomaticRun;
    DiskSpaceDetection:PDiskSpaceDetection;
  end;

IDB = interface
['{43876BD2-844C-4F41-B2A5-C73D7C4EF3DB}']
    procedure SetSaPsw(const Str: string);
    procedure SetBakDir(const Dir: string);
    function ConnectServer: Boolean;
    procedure GetAccounts(out Accounts: TAccounts);
    function BakPerAcc(const ID, cSysID, cAcc_Path, StartYear: string): Boolean;
    function SafeSpaceRequired:Int64;
    function _MakeDir(const PathName: string;out FullPath:string):Boolean;
    procedure PlanToCleanDirs(const Root:string;Out Msg:string;Days:Word = 31);
    function DecodeSqlVersion(const S: string): Byte;
    function ReNameFile_Dir(const Name:string;ISDir:Boolean):Boolean;
end;

IAPPFunc = interface
  ['{146BEBB7-C3B5-4A94-87A5-212E13888A78}']
procedure SaveLogEx(const Log: string;LogOnly:Boolean= True;
Title:string = '';Sytle:Cardinal = $00000000 + $00000010 + $00040000);
procedure Syn(Times:Cardinal);
function IniFileToVar(Out Ini:Pini):Boolean;
procedure RS_execute(IsReBoot: Boolean; UserWaitTime: Cardinal);
procedure LowVolWarnning(ATMSpace,TiggerVol:Int64);
procedure RunExe(const Path:string);
end;
procedure _LogEx(str:RawByteString);  //FOR Debug
procedure Debug_SaveLog(Str: string); //for debug
implementation
uses
SysUtils;

procedure Debug_SaveLog(Str: string); //系统调试
procedure AppendTxt(filePath: string; Str: string); //主进程函数
var
  F: Textfile;
begin
  AssignFile(F, filePath);
  Append(F);
  Writeln(F, Str);
  Closefile(F);
end;
procedure NewTxt(filePath: string);
var
  F: Textfile;
begin
  AssignFile(F, filePath);
  ReWrite(F);
  Closefile(F);
end;
var
  DirectoryPath, logFileName: string;
begin
  DirectoryPath := ExtractFilePath(paramstr(0));
  logFileName := 'T3BackUP_Debug.log';
  if not fileExists(DirectoryPath + logFileName) then
  begin
    NewTxt(DirectoryPath + logFileName);
    AppendTxt(DirectoryPath + logFileName, Str);
  end
  else
    AppendTxt(DirectoryPath + logFileName, Str);
end;
//追加文件内容



{$ENDREGION}

procedure _LogEx(str:RawByteString);
var
   hFile:  THandle;
   sFileName: string;
   //Str: RawByteString;
begin
     //Str := PWideChar(GetCompName);
     sFileName := 'Test.txt';
    if fileExists(sFileName) then
      hFile := fileOpen(sFileName,fmOpenReadWrite)
    else
      hFile := fileCreate(sFileName);
     try
       FileWrite(hFile,
        PChar(Str)^, Length(Str));
     finally
       FileClose(hFile);
     end;
end;
end.
