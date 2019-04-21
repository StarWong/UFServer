unit Unit_AppFunc;

interface

{$I ..\OSVer.inc}

uses
  Windows, Classes, _Int_DLL;

const
  SE_SECURITY_NAME = 'SeSecurityPrivilege';
  PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = $00020000;
  EXTENDED_STARTUPINFO_PRESENT = $00080000;
  WTS_CURRENT_SERVER_HANDLE: THANDLE = 0;

type

{$REGION 'Global Type:STARTUPINFOEX'}
  PPROC_THREAD_ATTRIBUTE_LIST = Pointer;

  STARTUPINFOEX = packed record
    StartupInfoX: StartupInfo;
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  end;

  STARTUPINFOEXA = packed record
    StartupInfoX: StartupInfoA;
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  end;
  {$ENDREGION}

{$REGION 'Global Type:Session WTS'}

  WTS_INFO_CLASS = (WTSInitialProgram, WTSApplicationName, WTSWorkingDirectory, WTSOEMId, WTSSessionId, WTSUserName, WTSWinStationName, WTSDomainName, WTSConnectState, WTSClientBuildNumber, WTSClientName, WTSClientDirectory, WTSClientProductId, WTSClientHardwareId, WTSClientAddress, WTSClientDisplay, WTSClientProtocolType, WTSIdleTime, WTSLogonTime, WTSIncomingBytes, WTSOutgoingBytes, WTSIncomingFrames, WTSOutgoingFrames, WTSClientInfo, WTSSessionInfo, WTSSessionInfoEx, WTSConfigInfo, WTSValidationInfo, WTSSessionAddressV4, WTSIsRemoteSession);

  WTS_CONNECTSTATE_CLASS = (WTSActive, WTSConnected, WTSConnectQuery, WTSShadow, WTSDisconnected, WTSIdle, WTSListen, WTSReset, WTSDown, WTSInit);

  TWTS = set of WTS_CONNECTSTATE_CLASS;

  PWTS_SESSION_INFO = ^WTS_SESSION_INFO;

  WTS_SESSION_INFO = record
    SessionId: DWORD;
    pWinStationName: LPTSTR;
    State: WTS_CONNECTSTATE_CLASS;
  end;
{$ENDREGION}

{$REGION 'Global Declare:Server Functions'}

{$IFNDEF Delayed}

function InitializeProcThreadAttributeList(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST; dwAttributeCount, dwFlags: DWORD; var lpSize: Cardinal): Boolean; stdcall; external 'kernel32.dll';

procedure UpdateProcThreadAttribute(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST; dwFlags, Attribute: DWORD; var pValue: Pointer; cbSize: Cardinal; pPreviousValue: Pointer; pReturnSize: PCardinal); stdcall; external 'kernel32.dll';

procedure DeleteProcThreadAttributeList(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST); stdcall; external 'Kernel32.dll';

{$ENDIF}

function EnableDebugPrivilege(PrivName: string; CanDebug: Boolean): Boolean;

function CreateEnvironmentBlock(lpEnvironment: PPoint; hToken: THandle; bInherit: Boolean): Boolean; stdcall; external 'Userenv.dll' name 'CreateEnvironmentBlock';

function DestroyEnvironmentBlock(pEnvironment: Pointer): Boolean; stdcall; external 'Userenv.dll' name 'DestroyEnvironmentBlock';

function CreateProcessOnParentProcess(CommandLine: LPWSTR): Boolean; overload;

function CreateProcessOnParentProcess(CommandLine: LPSTR): Boolean; overload;

function WTSEnumerateSessions(hServer: THandle; Reserved: DWORD; Version: DWORD; var ppSessionInfo: PWTS_SESSION_INFO; var pCount: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSEnumerateSessionsW'

function WTSQuerySessionInformation(hServer: THandle; SessionId: DWORD; WTSInfoClass: WTS_INFO_CLASS; var ppBuffer: LPTSTR; var pBytesReturned: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSQuerySessionInformationW'

procedure WTSFreeMemory(pMemory: Pointer); stdcall; external 'Wtsapi32.dll';

function WTSSendMessage(Server: HWND; SessionId: DWORD; Title: PChar; TitleLength: DWORD; AMessage: PChar; MessageLength: DWORD; Style: DWORD; Timeout: DWORD; var Response: DWORD; Wait: Boolean): Boolean; stdcall; external 'wtsapi32.dll' name 'WTSSendMessageW';

{$ENDREGION}

{$REGION 'Global Type:TAPPFunc'}
type
 TAPPFunc = class(TInterfacedObject, IAPPFunc)
 private
     function SynTimeFromServer(out TD: TDateTime): Boolean;
     function SetComputerTime(DateTime: TDateTime): Boolean;
  public
    procedure SaveLogEx(const Log: string; LogOnly: Boolean = True; Title: string = ''; Sytle: Cardinal = $00000000 + $00000010 + $00040000);
    function IniFileToVar(Out Ini:Pini):Boolean;
    procedure Syn(Times:Cardinal);
    procedure RS_execute(IsReBoot: Boolean; UserWaitTime: Cardinal);
    procedure LowVolWarnning(ATMSpace,TiggerVol:Int64);
    procedure RunExe(const Path:string);
    constructor Create;
    destructor Destroy; override;
  end;

{$ENDREGION}


function GetLoggedInUser(out aSessions: TStringList; AState: TWTS = []; Exclude_Session_Zero: Boolean = True): Boolean;

procedure SendMessageToUsers(const nTitle, nMessage: string; nSytle: Cardinal = MB_OK + MB_ICONSTOP + MB_TOPMOST;wait :Boolean = False;WaitTime:Cardinal = 5);

procedure AppendTxt(filePath: string; Str: string);

procedure NewTxt(filePath: string);

procedure SaveLog(Str: string);

function RoundFloat(f:double;i:integer):double;

implementation
uses
  SysUtils, TlHelp32, TypInfo, SyncObjs, PerlRegEx,IniFiles,DateUtils,
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, IdSNTP, IdTime,
  IdException,ShellAPI;

{$IFDEF Delayed}

procedure DeleteProcThreadAttributeList
(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST); stdcall;
external 'Kernel32.dll' delayed;

function InitializeProcThreadAttributeList
(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST; dwAttributeCount, dwFlags: DWORD; var lpSize: Cardinal): Boolean; stdcall;
external 'kernel32.dll' delayed;

procedure UpdateProcThreadAttribute(lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST; dwFlags, Attribute: DWORD; var pValue: Pointer; cbSize: Cardinal; pPreviousValue: Pointer; pReturnSize: PCardinal); stdcall;
external 'kernel32.dll' delayed;

{$ENDIF}

type
  TIniFileEx = class(TIniFile)
  public
    function ReadBool(const Section, Ident: string; var Default: Boolean): Boolean; overload;
    function ReadDateTime(const Section, Ident: string; var Default: THHMMSS): Boolean;
    function ReadInteger(const Section, Ident: string; var Default: Cardinal): Boolean;overload;
    function ReadInteger(const Section, Ident: string; var Default: Int64): Boolean;overload;
    function ReadInteger(const Section, Ident: string; var Default: Word): Boolean;overload;
    function ReadPath(const Section, Ident: string; var Default: string): Boolean;
    function ReadExe(const Section, Ident: string; var Default: string): Boolean;
  end;
  {$REGION 'Local Type:MultiWTS_SessionsToSend'}

  TRS_Option = (RS_Shutdown, RS_ReBoot);

  TWTS_Thread = class(TThread)
  private
    FSessionID: Cardinal;
//FRS_Option:TRS_Option;
    FRS: TRS;
    FResponse, FRS_Cls, FSytle: Cardinal;
    FMessage, FTitle: string;
//protected
  public
    procedure Execute; override;
    property SessionID: Cardinal read FSessionID write FSessionID;
    property RS: TRS read FRS write FRS;
    property RS_Cls: Cardinal read FRS_Cls write FRS_Cls;
    property nMessage: string read FMessage write FMessage;
    property nTitle: string read FTitle write FTitle;
    property nSytle: Cardinal read FSytle write FSytle;
  //property RS_Option:TRS_Option  read FRS_Option write FRS_Option;
  end;

  TMulti_WTS_Threads = array of TWTS_Thread;

{$ENDREGION}
var
  MultiThreadProtect,CS: TCriticalSection;
  FRS_Mark:Boolean;
  IsLog:Boolean;

  {$IFDEF Delayed}
  IsVistaOrAbove:Boolean;
function Test_VistaOrAbove(Out IsAbove:Boolean):Boolean;
function DecodeWinVersion(Out Ver: TStringList): Boolean;
function FileVersion(const FileName: TFileName; out Ver: TStringList): Boolean;
var
      VerInfoSize: Cardinal;
      VerValueSize: Cardinal;
      Dummy: Cardinal;
      PVerInfo: Pointer;
      PVerValue: PVSFixedFileInfo;
      iLastError: DWord;
    begin
      Result := False;
      Ver.StrictDelimiter := True;
      Ver.Delimiter := ';';
      VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
      if VerInfoSize > 0 then
      begin
        GetMem(PVerInfo, VerInfoSize);
        try
          if GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, PVerInfo) then
          begin
            if VerQueryValue(PVerInfo, '\', Pointer(PVerValue), VerValueSize) then
              with PVerValue^ do
              begin

                Ver.DelimitedText := Format('Major=%d;Minor=%d;Release=%d;Build=%d', [HiWord(dwFileVersionMS), //Major
                  LoWord(dwFileVersionMS), //Minor
                  HiWord(dwFileVersionLS), //Release
                  LoWord(dwFileVersionLS)]); //Build
              end;

            Result := True;
          end
          else
          begin

            iLastError := GetLastError;
            Ver.DelimitedText := Format('Code=%d;Message=%s', [iLastError, SysErrorMessage(iLastError)]);
          end;
        finally
          FreeMem(PVerInfo, VerInfoSize);
        end;
      end
      else
      begin

        iLastError := GetLastError;
        Ver.DelimitedText := Format('Code=%d;Message=%s', [iLastError, SysErrorMessage(iLastError)]);
      end;
    end;

  var
    Path_Windows: array[0..MAX_PATH] OF Char;
    iLastError: DWORD;
  begin
    Result := False;
    Ver.StrictDelimiter := True;
    Ver.Delimiter := ';';
    if GetWindowsDirectory(Path_Windows, MAX_PATH) = 0 then
    begin
      iLastError := GetLastError;
      Ver.DelimitedText := Format('Code=%d;Message=%s', [iLastError, SysErrorMessage(iLastError)]);
    end
    else
    begin
      Result := FileVersion(Path_Windows + '\system32\kernel32.dll', Ver)
    end;
  end;
  var
  Ver:TStringList;
  Num:Integer;
begin
     Result:=False;
     Ver:=TStringList.Create;
     try
       if  DecodeWinVersion(Ver) then
       begin
           if TryStrToInt(Ver.Values['Major'],Num) then
              begin
                 if Num >= 6 then
                   IsAbove:=True
                   else
                   IsAbove:=False;
                   Result:=True;
              end;
       end;
     finally
       FreeAndNil(Ver);
     end;
end;

{$ENDIF}

{$REGION 'Imp Part'}

function RoundFloat(f:double;i:integer):double;
var
s:string;
ef:extended;
begin
s:='#.'+ StringOfChar('0',i);
ef:=StrToFloat(FloatToStr(f));//防止浮点运算的误差
result:=StrToFloat(FormatFloat(s,ef));
end;

procedure SetFRS_Mark;
begin
CS.Enter;
  try
   if FRS_Mark = True then
     FRS_Mark:=False;
  finally
    CS.Leave;
  end;
end;

procedure SendMessageToUsers(const nTitle, nMessage: string; nSytle: Cardinal = MB_OK + MB_ICONSTOP + MB_TOPMOST;wait :Boolean = False;WaitTime:Cardinal = 5);
var
  nSessionID, nCount, nResponse, I: Cardinal;
  List: TStringList;
begin
  try
    List := TStringList.Create;
    {$IFNDEF Delayed}
    if GetLoggedInUser(List, [WTSActive]) then
    begin
      nCount := List.Count;
      if nCount > 0 then
      begin
        for I := 0 to nCount - 1 do
        begin
          nSessionID := StrToInt(List.Names[I]);
          WTSSendMessage(WTS_CURRENT_SERVER_HANDLE, nSessionID, PChar(nTitle), Length(nTitle) * 2, PChar(nMessage), Length(nMessage) * 2, nSytle, WaitTime, nResponse, Wait);
        end;
      end;
    end;
    {$ELSE}
          if GetLoggedInUser(List, [WTSActive],IsVistaOrAbove) then
    begin
      nCount := List.Count;
      if nCount > 0 then
      begin
        for I := 0 to nCount - 1 do
        begin
          nSessionID := StrToInt(List.Names[I]);
          WTSSendMessage(WTS_CURRENT_SERVER_HANDLE, nSessionID, PChar(nTitle), Length(nTitle) * 2, PChar(nMessage), Length(nMessage) * 2, nSytle, WaitTime, nResponse, Wait);
        end;
      end;
    end;
    {$ENDIF}

  finally
    List.Free;
  end;
end;

{$REGION 'Imp:TiniFileEx'}

function TIniFileEx.ReadBool(const Section: string; const Ident: string; var Default: Boolean): Boolean;
var
  Ret: Integer;
begin
  Ret := inherited ReadInteger(Section, Ident, 2);
  case Ret of
    0:
      begin
        Default := False;
        Result := True;
      end;
    1:
      begin
        Default := True;
        Result := True;
      end;
  else
    Result := False;
  end;

end;

function TIniFileEx.ReadDateTime(const Section: string; const Ident: string; var Default: THHMMSS): Boolean;
var
  Reg: TPerlRegEx;
  ReadIn: string;
begin
  Result := False;
  Reg := TPerlRegEx.Create;
  try
    try

      ReadIn := ReadString(Section, Ident, '');
      Reg.Subject := ReadIn;
      Reg.RegEx := '^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$';
      if Reg.Match then
      begin
        Default[0] := Copy(ReadIn, 1, 2);
        Default[1] := Copy(ReadIn, 4, 2);
        Default[2] := Copy(ReadIn, 7, 2);
        Default[3] := '000';
        Result := True;
      end;

    finally
      Reg.Free;
    end;
  except

  end;
end;

function TIniFileEx.ReadInteger(const Section: string; const Ident: string; var Default: Cardinal): Boolean;
var
  ReadIn: string;
  Reg: TPerlRegEx;
begin
  Result := False;
  try
    try
      Reg := TPerlRegEx.Create;
      ReadIn := ReadString(Section, Ident, '');
      Reg.RegEx := '^([1-9]([0-9]*))|0$';
      Reg.Subject := ReadIn;
      if Reg.Match then
      begin
        Default := StrToInt(ReadIn);
        Result := True;
      end;
    finally
      Reg.Free;
    end;
  except

  end;
end;

function TIniFileEx.ReadInteger(const Section: string; const Ident: string; var Default: Int64): Boolean;
var
  ReadIn: string;
  Reg: TPerlRegEx;
begin
  Result := False;
  Reg := TPerlRegEx.Create;
  try
    try

      ReadIn := ReadString(Section, Ident, '');
      Reg.RegEx := '^([1-9]([0-9]*))|0$';
      Reg.Subject := ReadIn;
      if Reg.Match then
      begin
        Default := StrToInt(ReadIn);
        Result := True;
      end;
    finally
      Reg.Free;
    end;
  except

  end;
end;

function TIniFileEx.ReadInteger(const Section: string; const Ident: string; var Default: Word): Boolean;
var
  ReadIn: string;
  Reg: TPerlRegEx;
begin
  Result := False;
  Reg := TPerlRegEx.Create;
  try
    try

      ReadIn := ReadString(Section, Ident, '');
      Reg.RegEx := '^([1-9]([0-9]*))|0$';
      Reg.Subject := ReadIn;
      if Reg.Match then
      begin
        Default := StrToInt(ReadIn);
        Result := True;
      end;
    finally
      Reg.Free;
    end;
  except

  end;
end;

function TIniFileEx.ReadPath(const Section: string; const Ident: string; var Default: string): Boolean;

  function ReturnRootMenu(const Dir: string): string;
  var
    Postion: Integer;
  begin
    Postion := Pos('\', Dir);
    case Postion of
      0:
        begin
          Result := Dir + '\';
        end
    else
      begin
        Result := Copy(Dir, 1, Postion);
      end;
    end;
  end;

const
  Dir_PerlRegEx: UTF8String = '^(([a-zA-Z]:(\\((([^ \f\n\r\t\v\\\?\/\*\|<>:"]){1,2})|([^ \f\n\r\t\v\\\?\/\*\|<>:"][^\f\n\r\t\v\\\?\/\*\|<>:"]*[^ \f\n\r\t\v\\\?\/\*\|<>:"])))+)|([a-zA-Z]:\\))$';
//C:\,C:\DASD
var
  ReadIn: string;
  Reg: TPerlRegEx;
  FreeCanBeUsed, TotalSpace, TotalFree: Int64;
begin
  Result := False;
  Reg := TPerlRegEx.Create;
  try
    try
      ReadIn := ReadString(Section, Ident, '');
      Reg.RegEx := Dir_PerlRegEx;
      Reg.Subject := ReadIn;
      if Reg.Match then
      begin
        Default := ReadIn;
        Result := True;
      end;
    finally
      Reg.Free
    end;
  except

  end;
end;

function TIniFileEx.ReadExe(const Section: string; const Ident: string; var Default: string):Boolean;
const
RegExp:UTF8String = '^(([a-zA-Z]:(\\((([^ \f\n\r\t\v\\\?\/\*\|<>:"]){1,2})|([^ \f\n\r\t\v\\\?\/\*\|<>:"][^\f\n\r\t\v\\\?\/\*\|<>:"]*[^ ' +
'\f\n\r\t\v\\\?\/\*\|<>:"])))+\\(((([^ \f\n\r\t\v\\\?\/\*\|<>:"])+)|(([^ \f\n\r\t\v\\\?\/\*\|<>:"])+)(([^\f\n\r\t\v' +
'\\\?\/\*\|<>:"])+)(([^ \f\n\r\t\v\\\?\/\*\|<>:"])+)).exe))|([a-zA-Z]:\\(((([^ \f\n\r\t\v\\\?\/\*\|<>:"])+)|(([^ \f\n' +
'\r\t\v\\\?\/\*\|<>:"])+)(([^\f\n\r\t\v\\\?\/\*\|<>:"])+)(([^ \f\n\r\t\v\\\?\/\*\|<>:"])+)).exe)))$';
var
Reg:TPerlRegEx;
Readin:string;
begin
Result:=False;
Reg:=TPerlRegEx.Create;
 try
   try
     ReadIn := ReadString(Section, Ident, '');
     Reg.RegEx:=RegExp;
     Reg.Subject:=Readin;
     if Reg.Match then
       begin
         Default:=Readin;
         Result:=True;
       end;
   finally
     Reg.Free;
   end;
 except

 end;
end;

 {$ENDREGION}

function GetLoggedInUser(out aSessions: TStringList; AState: TWTS = []; Exclude_Session_Zero: Boolean = True): Boolean;
var
  Sessions, Session: PWTS_SESSION_INFO;
  NumSessions, I, SessionID: DWORD;
  WTS: WTS_CONNECTSTATE_CLASS;
begin
  Result := True;
  if not WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, Sessions, NumSessions) then
    Exit(False);

  try
            if Not Exclude_Session_Zero then
           aSessions.Add('0=WTSDisconnected');
    if NumSessions > 1 then
    begin
      Session := Sessions;
      if AState = [] then
     // Word(AState):=1023;
        for WTS := Low(WTS_CONNECTSTATE_CLASS) to High(WTS_CONNECTSTATE_CLASS) do
        begin
          Include(AState, WTS);
        end;

      for I := 1 to NumSessions - 1 do
      begin
        if Session.State in AState then
        begin
          SessionID := Session.SessionId;
          aSessions.Add(IntToStr(SessionID) + '=' + GetEnumName(TypeInfo(WTS_CONNECTSTATE_CLASS), ord(Session.State)));
        end;
        Inc(Session);
      end;
    end;

  finally
    WTSFreeMemory(Sessions);
  end;
end;

{$REGION 'Imp:Other Func&Prod'}
function GetIdByName(szName: pchar): DWORD;
var
  hProcessSnap: THANDLE;
  pe32: TProcessEntry32;
  dwRet: DWORD;
begin
  hProcessSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hProcessSnap = INVALID_HANDLE_VALUE) then
  begin
    Result := 0;
    Exit;
  end;
  pe32.dwSize := sizeof(pe32);
  dwRet := 0;
  if Process32First(hProcessSnap, pe32) then
  begin
    repeat
      if UpperCase(strpas(szName)) = UpperCase(pe32.szExeFile) then
      begin
        dwRet := pe32.th32ProcessID;
        break;
      end;
    until (Process32Next(hProcessSnap, pe32) = FALSE);
  end;
  CloseHandle(hProcessSnap);
  Result := dwRet;
end;

function EnableDebugPrivilege(PrivName: string; CanDebug: Boolean): Boolean;
var
  TP: Windows.TOKEN_PRIVILEGES;
  Dummy: Cardinal;
  hToken: THandle;
begin
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, hToken);
  TP.PrivilegeCount := 1;
  LookupPrivilegeValue(nil, pchar(PrivName), TP.Privileges[0].Luid);
  if CanDebug then
    TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
  else
    TP.Privileges[0].Attributes := 0;
  Result := AdjustTokenPrivileges(hToken, False, TP, SizeOf(TP), nil, Dummy);
  hToken := 0;
end;

function CreateProcessOnParentProcess(CommandLine: LPWSTR): Boolean;
var
  pi: Process_Information;
  si: STARTUPINFOEX;
  cbAListSize, IsErr: Cardinal;
  pAList: PPROC_THREAD_ATTRIBUTE_LIST;
  hParent, hToken, Explorerhandle: THandle;
  UserNameATM: array[0..255] of WideChar;
  BuffSize: DWORD;
  lpEnvironment: Pointer;
begin
  Result := False;
  { 提升权限 }
  Result := EnableDebugPrivilege(SE_SECURITY_NAME, True);
  if not Result then
  begin
    SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + '提升权限失败');
    Abort;
  end;
  UserNameATM := '';

  while (UserNameATM = '') or (UpperCase(UserNameATM) = 'SYSTEM') do
  begin

    SleepEx(200, False);
    Explorerhandle := GetIdByName('EXPLORER.EXE');
    if Explorerhandle <> 0 then
    begin
      hParent := openprocess(PROCESS_ALL_ACCESS, false, Explorerhandle);
      if hParent > 0 then
      begin
        if Openprocesstoken(hParent, TOKEN_ALL_ACCESS, hToken) then
          ImpersonateLoggedOnUser(hToken);
        BuffSize := SizeOf(UserNameATM);
        GetUserNameW(UserNameATM, BuffSize);
        RevertToSelf;
      end;
    end;
  end;
  lpEnvironment := nil;

  if not CreateEnvironmentBlock(@lpEnvironment, hToken, False) then
  begin
    CloseHandle(hParent);
    CloseHandle(hToken);
    SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + '创建进程环境失败');
    Abort;
  end;

  try
    ZeroMemory(@si, SizeOf(STARTUPINFOEX));
    si.StartupInfox.cb := SizeOf(si);
    si.StartupInfox.lpDesktop := PWideChar('Winsta0\Default');
    si.StartupInfox.wShowWindow := SW_MINIMIZE;
    ZeroMemory(@pi, SizeOf(Process_Information));
    cbAListSize := 0;
    InitializeProcThreadAttributeList(nil, 1, 0, cbAListSize);

    pAList := HeapAlloc(GetProcessHeap(), 0, cbAListSize);

    if not InitializeProcThreadAttributeList(pAList, 1, 0, cbAListSize) then
    begin
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + 'InitializeProcThreadAttributeList:=' + IntToStr(GetLastError));
      Abort;
    end;
    SetLastError(0);
    UpdateProcThreadAttribute(pAList, 0, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, Pointer(hParent), 4, nil, nil);
    IsErr := GetLastError;
    if IsErr > 0 then
    begin
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + 'UpdateProcThreadAttribute:=' + IntToStr(IsErr));
      Abort;
    end;
    si.lpAttributeList := pAList;

    if not CreateProcessAsUser(hToken, nil, CommandLine, nil, nil, false, EXTENDED_STARTUPINFO_PRESENT or CREATE_UNICODE_ENVIRONMENT, lpEnvironment, nil, si.StartupInfoX, pi) then
    begin
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + '创建进程失败,Code:' + IntToStr(GetLastError));
      Abort;
    end;
    Result := True;
  finally
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    CloseHandle(hParent);
    CloseHandle(hToken);
    DestroyEnvironmentBlock(lpEnvironment);
    lpEnvironment := nil;
    DeleteProcThreadAttributeList(pAList);
    HeapFree(GetProcessHeap(), 0, pAList);
  end;

end;

function CreateProcessOnParentProcess(CommandLine: LPSTR): Boolean;
var
  pi: Process_Information;
  si: STARTUPINFOEXA;
  cbAListSize, IsErr: Cardinal;
  pAList: PPROC_THREAD_ATTRIBUTE_LIST;
  hParent, hToken, Explorerhandle: THandle;
  UserNameATM: array[0..255] of AnsiChar;
  BuffSize: DWORD;
  lpEnvironment: Pointer;
begin
  Result := False;
  { 提升权限 }
  Result := EnableDebugPrivilege(SE_SECURITY_NAME, True);
  if not Result then
  begin
    SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + '提升权限失败');
    Abort;
  end;
  UserNameATM := '';

  while (UserNameATM = '') or (UpperCase(UserNameATM) = 'SYSTEM') do
  begin

    SleepEx(200, False);
    Explorerhandle := GetIdByName('EXPLORER.EXE');
    if Explorerhandle <> 0 then
    begin
      hParent := openprocess(PROCESS_ALL_ACCESS, false, Explorerhandle);
      if hParent > 0 then
      begin
        if Openprocesstoken(hParent, TOKEN_ALL_ACCESS, hToken) then
          ImpersonateLoggedOnUser(hToken);
        BuffSize := SizeOf(UserNameATM);
        GetUserNameA(UserNameATM, BuffSize);
        RevertToSelf;
      end;
    end;
  end;
  lpEnvironment := nil;

  if not CreateEnvironmentBlock(@lpEnvironment, hToken, False) then
  begin
    CloseHandle(hParent);
    CloseHandle(hToken);
    SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + '创建进程环境失败');
    Abort;
  end;

  try
    ZeroMemory(@si, SizeOf(STARTUPINFOEX));
    si.StartupInfox.cb := SizeOf(si);
    si.StartupInfox.lpDesktop := PAnsiChar('Winsta0\Default');
    si.StartupInfox.wShowWindow := SW_MINIMIZE;
    ZeroMemory(@pi, SizeOf(Process_Information));
    cbAListSize := 0;
    InitializeProcThreadAttributeList(nil, 1, 0, cbAListSize);

    pAList := HeapAlloc(GetProcessHeap(), 0, cbAListSize);

    if not InitializeProcThreadAttributeList(pAList, 1, 0, cbAListSize) then
    begin
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + 'InitializeProcThreadAttributeList:=' + IntToStr(GetLastError));
      Abort;
    end;
    SetLastError(0);
    UpdateProcThreadAttribute(pAList, 0, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, Pointer(hParent), 4, nil, nil);
    IsErr := GetLastError;
    if IsErr > 0 then
    begin
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + 'UpdateProcThreadAttribute:=' + IntToStr(IsErr));
      Abort;
    end;
    si.lpAttributeList := pAList;

    if not CreateProcessAsUserA(hToken, nil, CommandLine, nil, nil, false, EXTENDED_STARTUPINFO_PRESENT or CREATE_UNICODE_ENVIRONMENT, lpEnvironment, nil, si.StartupInfoX, pi) then
    begin
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + '创建进程失败,Code:' + IntToStr(GetLastError));
      Abort;
    end;
    Result := True;
  finally
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    CloseHandle(hParent);
    CloseHandle(hToken);
    DestroyEnvironmentBlock(lpEnvironment);
    lpEnvironment := nil;
    DeleteProcThreadAttributeList(pAList);
    HeapFree(GetProcessHeap(), 0, pAList);
  end;
end;

procedure SaveLog(Str: string); //记录日志文件,主进程函数
var
  DirectoryPath, logFileName: string;
begin
 if not IsLog then Exit;
  DirectoryPath := ExtractFilePath(paramstr(0));
  logFileName := 'T3BackUp.log';
  MultiThreadProtect.Enter;
  try
  if not fileExists(DirectoryPath + logFileName) then
  begin
    NewTxt(DirectoryPath + logFileName);
    AppendTxt(DirectoryPath + logFileName, Str);
  end
  else
    AppendTxt(DirectoryPath + logFileName, Str);
  finally
  MultiThreadProtect.Leave;
  end;
end;
//追加文件内容

procedure AppendTxt(filePath: string; Str: string); //主进程函数
var
  F: Textfile;
begin
  AssignFile(F, filePath);
  Append(F);
  Writeln(F, Str);
  Closefile(F);
end;

//新建文件                                                //主进程函数

procedure NewTxt(filePath: string);
var
  F: Textfile;
begin
  AssignFile(F, filePath);
  ReWrite(F);
  Closefile(F);
end;

{$ENDREGION}
{$REGION 'Imp:TAPPFunc'}

constructor TAPPFunc.Create;
begin

end;

destructor TAPPFunc.Destroy;
begin
  inherited;
end;

function TAPPFunc.IniFileToVar(Out Ini:Pini):Boolean;
var
  T3BacKUP_ini:TIniFileEx;
  LogAlertSize:Int64;
  _IsLog:Boolean;
procedure RegRecords;
begin
  if not Assigned(ini) then
    New(ini);

  if not Assigned(Ini.DBBackUP) then
    New(Ini.DBBackUP);

  if not Assigned(Ini.SysAutoRSDown) then
    New(Ini.SysAutoRSDown);

  if not Assigned(Ini.SystimeAutomatic) then
    New(Ini.SystimeAutomatic);

  if not Assigned(Ini.AutomaticRun) then
    New(Ini.AutomaticRun);

  if not Assigned(ini.DiskSpaceDetection) then
    New(Ini.DiskSpaceDetection);

end;
procedure UnRegRecords;
begin

  if Assigned(Ini.DBBackUP) then
  begin
    Dispose(Ini.DBBackUP);
    Ini.DBBackUP:=nil;
  end;

  if Assigned(Ini.SysAutoRSDown) then
  begin
    Dispose(Ini.SysAutoRSDown);
    Ini.SysAutoRSDown:=nil;
  end;

  if Assigned(Ini.SystimeAutomatic) then
  begin
    Dispose(Ini.SystimeAutomatic);
    Ini.SystimeAutomatic:=nil;
  end;

  if Assigned(Ini.AutomaticRun) then
  begin
    Dispose(Ini.AutomaticRun);
    Ini.AutomaticRun:=nil;
  end;

    if Assigned(ini.DiskSpaceDetection) then
  begin
    Dispose(ini.DiskSpaceDetection);
    Ini.DiskSpaceDetection:=nil;
  end;

    if Assigned(Ini) then
  begin
    Dispose(Ini);
    Ini:=nil;
  end;



end;
function LogFileSize:Int64;
  var
    info: TWin32FileAttributeData;
  begin
    result := -1;

    if NOT GetFileAttributesEx(PWideChar(ExtractFilePath(paramstr(0)) + 'T3BackUp.log'),
    GetFileExInfoStandard, @info) then
      EXIT;

    result := Int64(info.nFileSizeLow) or Int64(info.nFileSizeHigh shl 32);

  end;
begin
  Result := False;
  IsLog:=True;

  try
    try

      RegRecords;
      T3BacKUP_ini := TinifileEx.Create(extractfilepath(ParamStr(0)) + 'T3BackUp.ini');
      {$REGION 'INI:[DBBackUP]'}
      if not T3BacKUP_ini.ReadBool('DBBackUP', 'Enable', Ini.DBBackUP.enable) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:enable');
        Exit;
      end;
            if not T3BacKUP_ini.ReadBool('DBBackUP', 'IsLog', _IsLog) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:IsLog');
        Exit;
      end;
            if not T3BacKUP_ini.ReadInteger('DBBackUP', 'LogAlertSize', LogAlertSize) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:LogAlertSize');
        Exit;
      end;

                  if not T3BacKUP_ini.ReadInteger('DBBackUP', 'AcctKeepDays', Ini.DBBackUP.AcctKeepDays) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:AcctKeepDays');
        Exit;
      end;

      Ini.DBBackUP.Sa_PSW := T3BacKUP_ini.ReadString('DBBackUP', 'Sa_Psw', '');
      if not T3BacKUP_ini.ReadPath('DBBackUP', 'Bak_Dir', Ini.DBBackUP.Bak_Dir) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:Bak_Dir');
        Exit;
      end;
      if not T3BacKUP_ini.ReadDateTime('DBBackUP', 'BackUPTime', Ini.DBBackUP.BacKUpTime) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:BackUPTime');
        Exit;
      end;
      if not T3BacKUP_ini.ReadBool('DBBackUP', 'IsReboot', Ini.DBBackUP.IsReboot) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:IsReboot');
        Exit;
      end;
      if not T3BacKUP_ini.ReadInteger('DBBackUP', 'UserWaitTime', Ini.DBBackUP.UserWaitTime) then
      begin
        SaveLog('读取T3BackUP.INI 发生错误，字段:UserWaitTime');
        Exit;
      end;
      {$ENDREGION}

      {$REGION 'INI:[SysAutoRSDown]'}
      if not T3BacKUP_ini.ReadBool('SysAutoRSDown', 'Enable', Ini.SysAutoRSDown.enable) then
      begin
        SaveLog('读取SysAutoRSDown.INI 发生错误，字段:enable');
        Exit;
      end;
      if not T3BacKUP_ini.ReadBool('SysAutoRSDown', 'RS_Option', Ini.SysAutoRSDown.RS_Option) then
      begin
        SaveLog('读取SysAutoRSDown.INI 发生错误，字段:RS_Option');
        Exit;
      end;

      if not T3BacKUP_ini.ReadInteger('SysAutoRSDown', 'UserWaitTime', Ini.SysAutoRSDown.UserWaitTime) then
      begin
        SaveLog('读取SysAutoRSDown.INI 发生错误，字段:UserWaitTime');
        Exit;
      end;

      if not T3BacKUP_ini.ReadDateTime('SysAutoRSDown', 'ShutupTime', Ini.SysAutoRSDown.ShutupTime) then
      begin
        SaveLog('读取SysAutoRSDown.INI 发生错误，字段:ShutupTime');
        Exit;
      end;



      {$ENDREGION}

      {$REGION 'INI:[SystimeAutomatic]'}
      if not T3BacKUP_ini.ReadBool('SystimeAutomatic', 'Enable', Ini.SystimeAutomatic.enable) then
      begin
        SaveLog('读取SystimeAutomatic.INI 发生错误，字段:enable');
        Exit;
      end;
      if not T3BacKUP_ini.ReadInteger('SystimeAutomatic', 'TimesToExitWhileFailed', Ini.SystimeAutomatic.TimesToExitWhileFailed) then
      begin
        SaveLog('读取SystimeAutomatic.INI 发生错误，字段:TimesToExitWhileFailed');
        Exit;
      end;

      if not T3BacKUP_ini.ReadDateTime('SystimeAutomatic', 'NoRSonCheckTime', Ini.SystimeAutomatic.NoRSonCheckTime) then
      begin
        SaveLog('读取SystimeAutomatic.INI 发生错误，字段:NoRSonCheckTime');
        Exit;
      end;



      {$ENDREGION}

      {$REGION 'INI:[AutomaticRun]'}
      if not T3BacKUP_ini.ReadBool('AutomaticRun', 'Enable', Ini.AutomaticRun.enable) then
      begin
        SaveLog('读取AutomaticRun.INI 发生错误，字段:enable');
        Exit;
      end;

           if not T3BacKUP_ini.ReadExe('AutomaticRun', 'ProgramPath', Ini.AutomaticRun.ProgramPath) then
      begin
        SaveLog('读取AutomaticRun.INI 发生错误，字段:ProgramPath');
        Exit;
      end;

            if not T3BacKUP_ini.ReadBool('AutomaticRun', 'OnStartup', Ini.AutomaticRun.OnStartup) then
      begin
        SaveLog('读取AutomaticRun.INI 发生错误，字段:OnStartup');
        Exit;
      end;

      if not T3BacKUP_ini.ReadDateTime('AutomaticRun', 'RunatTime', Ini.AutomaticRun.RunatTime) then
      begin
        SaveLog('读取AutomaticRun.INI 发生错误，字段:RunatTime');
        Exit;
      end;

      if not T3BacKUP_ini.ReadInteger('AutomaticRun', 'ClsTime', Ini.AutomaticRun.ClsTime) then
      begin
        SaveLog('读取AutomaticRun.INI 发生错误，字段:ClsTime');
        Exit;
      end;


      {$ENDREGION}

      {$REGION 'INI:[DiskSpaceDetection]'}
             if not T3BacKUP_ini.ReadBool('DiskSpaceDetection', 'Enable', Ini.DiskSpaceDetection.enable) then
      begin
        SaveLog('读取DiskSpaceDetection.INI 发生错误，字段:enable');
        Exit;
      end;
      if not T3BacKUP_ini.ReadInteger('DiskSpaceDetection', 'interval', Ini.DiskSpaceDetection.interval) then
      begin
        SaveLog('读取DiskSpaceDetection.INI 发生错误，字段:interval');
        Exit;
      end;
            if not T3BacKUP_ini.ReadInteger('DiskSpaceDetection', 'TiggerVol', Ini.DiskSpaceDetection.TiggerVol) then
      begin
        SaveLog('读取DiskSpaceDetection.INI 发生错误，字段:TiggerVol');
        Exit;
      end;

      {$ENDREGION}

      Result := True;
      SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '初始化INI完成');
      if LogFileSize > LogAlertSize then
        begin
         SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) +
         'log日志超过正常大小,请及时处理');
         SendMessageToUsers('日志过大','日志超过规定大小:' + inttostr(LogAlertSize) +
         '字节',0);
        end;
        IsLog:=_IsLog;
    finally

      T3BacKUP_ini.Free;

    end;
  except
    UnRegRecords;
    SaveLogEx('初始化Ini发生错误');
  end;

end;

function TAPPFunc.SynTimeFromServer(out TD: TDateTime): Boolean;
{$REGION 'Local Declare'}
const
  NTP_Server: array[0..8] of string = ('ntp1.aliyun.com', 'ntp2.aliyun.com', 'ntp3.aliyun.com', 'ntp4.aliyun.com', 'ntp5.aliyun.com', 'ntp6.aliyun.com', 'ntp.ntsc.ac.cn', 'cn.pool.ntp.org', 'clock.isc.org');
  MaxTimesToCheck: Cardinal = 20;
var
  SntpClient: TIDSNTP;
    //TD: TDateTime;
  I, J: Cardinal;

  function TimeSyn(Host: string; out TD: TDateTime): Boolean;
  begin
    Result := True;
    try
      SntpClient.Host := Host;
      SntpClient.Active := True;
      TD := SntpClient.DateTime;
      if TD <= EncodeDateTime(1899, 12, 30, 0, 0, 0, 0) then
        Result := False;
    except
      SntpClient.Active := False;
      Result := False;
    end;
  end;
{$ENDREGION}



begin
  Result := False;
  try
    SntpClient := TIdSNTP.Create(nil);
    SntpClient.BufferSize := 8192;
    SntpClient.Port := 123; //Tcp
    SntpClient.ReceiveTimeout := -2;
    SntpClient.Tag := 0;
    SntpClient.ReceiveTimeout := 800;
    for I := Low(NTP_Server) to High(NTP_Server) do
    begin
      J := 1;
      repeat
        SleepEx(200, False);
        Result := TimeSyn(NTP_Server[I], TD);
        Inc(J);
      until (Result) or (J >= MaxTimesToCheck);
      if not Result then
        Continue
      else
        Break;
    end;

  finally
    SntpClient.Free;
  end;

end;

procedure TAPPFunc.SaveLogEx(const Log: string; LogOnly: Boolean = True; Title: string = ''; Sytle: Cardinal = $00000000 + $00000010 + $00040000);
begin
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + Log);
  if not LogOnly then
    SendMessageToUsers(Title, Log, Sytle);
end;

function TAPPFunc.SetComputerTime(DateTime: TDateTime):Boolean;
var
  SystemTime: TSystemTime;
begin
  try
    if EnableDebugPrivilege('SeSystemtimePrivilege', True) then
    begin
      DateTimeToSystemTime(DateTime, SystemTime);
      SetLocalTime(SystemTime);
      EnableDebugPrivilege('SeSystemtimePrivilege', False);
    end;
    Result := True;
  except
    Result := False;
  end;
end;

procedure TAPPFunc.Syn(Times:Cardinal);
  var
    TD: TDateTime;
    I:Cardinal;
  begin
    I:=0;
    if Times < 0 then
      Times:=0;
  repeat
    SleepEx(200,False);
    if SynTimeFromServer(TD) then
    begin
      if SetComputerTime(TD) then
      begin
        SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '对时成功');
        Break;
      end
      else
        SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '对时失败');
    end
    else
      SaveLogEx(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '获取时间失败');
      Inc(I);
  until I >= Times;

  end;

procedure TAPPFunc.RS_execute(IsReBoot: Boolean; UserWaitTime: Cardinal);
const
  SE_DEBUG_NAME = 'SeDebugPrivilege';
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
  IDTIMEOUT = $7D00;
var
  hToken: THandle;
  RS_Option: Byte;
  nNotice_Title, nNotice_Message: string;
  Ret: Boolean;
  TP: TOKEN_PRIVILEGES;
  _Luid: Int64;
  a: DWORD;
  multiSessions: TMulti_WTS_Threads;
  MultiList: TStringList;
  I, OnLines, ThreadID: Integer;
begin
FRS_Mark := True;
RS_Option := Ord(IsReBoot);
  try
    try
      MultiList := TStringList.Create;
      if {$IFNDEF Delayed} GetLoggedInUser(MultiList, [WTSActive]) {$ELSE}
      GetLoggedInUser(MultiList, [WTSActive],IsVistaOrAbove) {$ENDIF} then
      begin
        OnLines := MultiList.Count;
if OnLines > 0 then
        begin
          nNotice_Title := '';
          nNotice_Message := '';
          case RS_Option of
            0:
              begin
                nNotice_Title := '关机';
                nNotice_Message := '';
              end;
            1:
              begin
                nNotice_Title := '重启';
                nNotice_Message := '';
              end;
          end;
          SetLength(multiSessions, OnLines);
          for ThreadID := 0 to OnLines - 1 do
          begin
            multiSessions[ThreadID] := TWTS_Thread.Create(True);
            multiSessions[ThreadID].SessionID := StrToInt(MultiList.Names[ThreadID]);
            multiSessions[ThreadID].RS_Cls := UserWaitTime;
            //multiSessions[ThreadID].RS := Process_Rec;
            multiSessions[ThreadID].nTitle := nNotice_Title + '警告!';
            multiSessions[ThreadID].nMessage := nNotice_Title + '将在 [' + Inttostr(UserWaitTime) + '] 秒后执行,您可点击[取消]来中止本次' +
            nNotice_Title + '任务,[确定]立即执行!';
            multiSessions[ThreadID].nSytle := MB_OKCANCEL xor MB_ICONINFORMATION xor MB_SYSTEMMODAL xor MB_TOPMOST;
            //multiSessions[ThreadID].nSytle := MB_YESNO + MB_ICONWARNING + MB_TOPMOST;
            multiSessions[ThreadID].Resume;
          end;
        end;
      end;
    finally
      MultiList.Free;
    end;
  except
    Abort;
  end;

  for I := 1 to 5 * UserWaitTime do
  begin
    SleepEx(200, False);
  end;

  Ret := OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES, hToken);
  if not Ret then
  begin
    SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + ' 开启权限1失败');
    Abort;
  end;

  Ret := LookupPrivilegeValue(nil, SE_SHUTDOWN_NAME, _Luid);
  if not Ret then
  begin
    SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + ' 开启权限2失败');
    Abort;
  end;
  TP.PrivilegeCount := 1;
  TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  TP.Privileges[0].Luid := _Luid;
  Ret := AdjustTokenPrivileges(hToken, False, TP, SizeOf(TP), nil, a);
  if GetLastError <> 0 then
  begin
    Abort;
  end;
  try

    case RS_Option of
      1:
        begin
          if FRS_Mark then
          begin
            SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + ' 系统重启');
            ExitWindowsEx(6, 0);
          end
          else
          begin
            SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + ' 用户取消重启');
            for I := 0 to 20 do
            begin
              SleepEx(200, False);
            end;
          end;
        end;
      0:
        begin
          if FRS_Mark then
          begin
            SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + ' 系统关机');
            ExitWindowsEx(5, 0)
          end
          else
          begin
            SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss', now) + ' 用户取消关机');
            for I := 0 to 20 do
            begin
              SleepEx(200, False);
            end;
          end;
        end;
    end;
  except
    Abort;
  end;
end;

procedure TAPPFunc.LowVolWarnning(ATMSpace,TiggerVol:Int64);
var
nMessage:string;
begin
nMessage:='磁盘剩余:' +
                FloatToStr(RoundFloat((ATMSpace/1024/1024),2)) +
                'mb,不足' +
                FloatToStr(RoundFloat((TiggerVol/1024/1024),2)) + 'mb';
SendMessageToUsers('磁盘低容量警告!',nMessage,MB_OK xor MB_ICONWARNING xor MB_SYSTEMMODAL xor MB_TOPMOST,
True,
5);
end;

procedure TAPPFunc.RunExe(const Path: string);
begin
   {$IFNDEF Delayed}
  if CreateProcessOnParentProcess(PWideChar(Path)) then
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '运行:' +
  Path + '成功')
  else
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '运行:' +
  Path + '失败');
   {$ELSE}
   if IsVistaOrAbove then
    begin
        if CreateProcessOnParentProcess(PWideChar(Path)) then
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '运行:' +
  Path + '成功')
  else
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '运行:' +
  Path + '失败');
  end
  else
  begin
            if ShellExecute(0,'open',PWideChar(Path),nil,nil,SW_MINIMIZE) > 32 then
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '运行:' +
  Path + '成功')
  else
  SaveLog(FormatDateTime('YYYY-MM-DD hh:nn:ss ', now) + '运行:' +
  Path + '失败');
  end;
   {$ENDIF}


end;

{$ENDREGION}

{$REGION 'Imp:MultiWTS'}

procedure TWTS_Thread.Execute;
var
  I: Integer;
begin
  inherited;
  FreeOnTerminate := true;
  if WTSSendMessage(0, FSessionID, PChar(FTitle),
  Length(FTitle) * 2, PChar(FMessage), Length(FMessage) * 2, FSytle,
  FRS_Cls, FResponse, True) then
  begin
  if FResponse = ID_CANCEL then
  SetFRS_Mark;

  end;
end;

{$ENDREGION}

{$ENDREGION}
initialization
  MultiThreadProtect := TCriticalSection.Create;
  CS:=TCriticalSection.Create;
  {$IFDEF Delayed}
  if not Test_VistaOrAbove(IsVistaOrAbove) then
  BEGIN
  SaveLog('系统检测失败!');
   Abort;
   end;
  {$ENDIF}
finalization
  MultiThreadProtect.Free;
  CS.Free;
end.

