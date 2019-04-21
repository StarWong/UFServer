unit CTPasuser;

interface
uses
SysUtils,Classes,Windows;

const
WTS_CURRENT_SERVER_HANDLE: THANDLE = 0;

type
{$REGION 'WTS_INFO_CLASS'}
 WTS_INFO_CLASS = (
    WTSInitialProgram,
    WTSApplicationName,
    WTSWorkingDirectory,
    WTSOEMId,
    WTSSessionId,
    WTSUserName,
    WTSWinStationName,
    WTSDomainName,
    WTSConnectState,
    WTSClientBuildNumber,
    WTSClientName,
    WTSClientDirectory,
    WTSClientProductId,
    WTSClientHardwareId,
    WTSClientAddress,
    WTSClientDisplay,
    WTSClientProtocolType,
    WTSIdleTime,
    WTSLogonTime,
    WTSIncomingBytes,
    WTSOutgoingBytes,
    WTSIncomingFrames,
    WTSOutgoingFrames,
    WTSClientInfo,
    WTSSessionInfo,
    WTSSessionInfoEx,
    WTSConfigInfo,
    WTSValidationInfo,
    WTSSessionAddressV4,
    WTSIsRemoteSession
  );
{$ENDREGION}

{$REGION 'WTS_CONNECTSTATE_CLASS'}
   WTS_CONNECTSTATE_CLASS = (
    WTSActive,
    WTSConnected,
    WTSConnectQuery,
    WTSShadow,
    WTSDisconnected,
    WTSIdle,
    WTSListen,
    WTSReset,
    WTSDown,
    WTSInit
  );
  {$ENDREGION}

{$REGION 'PWTS_SESSION_INFO'}
PWTS_SESSION_INFO = ^WTS_SESSION_INFO;
 WTS_SESSION_INFO = record
    SessionId: DWORD;
    pWinStationName: LPTSTR;
    State: WTS_CONNECTSTATE_CLASS;
  end;
  {$ENDREGION}

function WTSEnumerateSessions(hServer: THandle; Reserved: DWORD; Version: DWORD; var ppSessionInfo: PWTS_SESSION_INFO; var pCount: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name {$IFDEF UNICODE}'WTSEnumerateSessionsW'{$ELSE}'WTSEnumerateSessionsA'{$ENDIF};
function WTSQuerySessionInformation(hServer: THandle; SessionId: DWORD; WTSInfoClass: WTS_INFO_CLASS; var ppBuffer: LPTSTR; var pBytesReturned: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name {$IFDEF UNICODE}'WTSQuerySessionInformationW'{$ELSE}'WTSQuerySessionInformationA'{$ENDIF};
procedure WTSFreeMemory(pMemory: Pointer); stdcall; external 'Wtsapi32.dll';
function WTSGetActiveConsoleSessionId: DWORD; stdcall;
external kernel32 name 'WTSGetActiveConsoleSessionId';
procedure SaveLog(Str: string);
procedure AppendTxt(filePath: string; Str: string);
procedure NewTxt(filePath: string);
function  EnableDebugPrivilege(PrivName: string; CanDebug: Boolean): Boolean;
function WTSSendMessage(Server: HWND; SessionId: DWORD; Title: PChar;
  TitleLength: DWORD; AMessage: PChar; MessageLength: DWORD; Style: DWORD;
  Timeout: DWORD; var Response: DWORD; Wait: Boolean): Boolean; stdcall;
  external 'wtsapi32.dll' name 'WTSSendMessageW';

function GetLoggedInUser(Out ASessions:TStringList;
AState:WTS_CONNECTSTATE_CLASS = WTSActive):Boolean;

implementation
 uses
 TypInfo;
procedure SaveLog(Str: string); //记录日志文件,主进程函数
var
    DirectoryPath, logFileName: string;
begin
    DirectoryPath := ExtractFilePath(paramstr(0));
    logFileName := 'T3BackUp.log';
    if not fileExists(DirectoryPath + logFileName) then
    begin
        NewTxt(DirectoryPath + logFileName);
        AppendTxt(DirectoryPath + logFileName, Str);
    end
    else
        AppendTxt(DirectoryPath + logFileName, Str)
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

{ 提升进程权限 }

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
     {获取活动的Session}
function GetLoggedInUser(Out ASessions:TStringList;
AState:WTS_CONNECTSTATE_CLASS = WTSActive):Boolean;
var
  Sessions, Session: PWTS_SESSION_INFO;
  NumSessions, I, NumBytes: DWORD;
  UserName: LPTSTR;
  SessionLine,WTS_Name:string;
begin
Result:=True;
try
  if not WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, Sessions,
   NumSessions) then
    //RaiseLastOSError;
    begin
      Result:=False;
      Exit;
    end;
  try
    if NumSessions > 0 then
    begin
      Session := Sessions;
      WTS_Name:=GetEnumName(TypeInfo(WTS_CONNECTSTATE_CLASS),ord(AState));
      for I := 0 to NumSessions-1 do
      begin
        if Session.State = AState then
        begin
          if WTSQuerySessionInformation(WTS_CURRENT_SERVER_HANDLE,
           Session.SessionId, WTSUserName, UserName, NumBytes) then
          begin
            try
              SessionLine := 'SessionID:= ' + IntToStr(SESSION.SessionId) +
              ', WinStationName:= ' + Session.pWinStationName +
              ', UserName:= ' + UserName;
              ASessions.Add(IntToStr(Session.SessionId) + '=' +
              WTS_Name);
            finally
              WTSFreeMemory(UserName);
            end;
          end;
        end;
        Inc(Session);
      end;
    end;
  finally
    WTSFreeMemory(Sessions);
  end;
  except
  Result:=False;
end;

end;


end.

