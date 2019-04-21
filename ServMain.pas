unit ServMain;

interface

{$I OSVer.inc}

uses
  SvcMgr, Classes;
{$REGION 'Declare Global Type'}

type
  TUFBackUp = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceBeforeInstall(Sender: TService);
  private
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

  TFirsThread = class(TThread)
  private
    function DBBackUPTask: Boolean;
  protected
    procedure Execute; override;
  public
  end;

  TSecThread = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;

  ThirdThread = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;

    TFouthThread = class(TThread)
  private
  protected
    procedure Execute; override;
  public
  end;
{$ENDREGION}

var
  UFBackUp: TUFBackUp;

implementation

uses
  DateUtils, SysUtils, Windows, _Int_DLL;

function TMyBDBackUP_Create: IDB; stdcall; external 'DBSQL.dll';

function TAPPFunc_Create: IAPPFunc; stdcall; external 'AppFunc.dll';
{$R *.DFM}

var
  First: TFirsThread;
  Sec: TSecThread;
  Third: ThirdThread;
  Four:TFouthThread;
  ini: Pini;
  IsDBWorking:Boolean;

{$REGION 'Imp:The FirstThread,Task:DBBackUP,SysAutoRSDown'}

function TFirsThread.DBBackUPTask;

  function ReturnRootPath(const Path: string): string;
  var
    I: Cardinal;
  begin
    I := Pos('\', Path);
    if I > 0 then
      Result := Copy(Path, 1, I)
    else
      Result := Path + '\';
  end;

var
  BK: IDB;
  accounts: TAccounts;
  cSysID, ID, cAcc_Path, IYear,Msg: string;
  I: Integer;
  FreeCanBeUsed, TotalSpace, TotalFree, SafeSpace, SqlDynSpaceReq: Int64;
  app: IAPPFunc;
begin
  Result := False;
  IsDBWorking:=True;
  try
    try
      BK := TMyBDBackUP_Create;
      app := TAPPFunc_Create;
      BK.SetSaPsw(ini.DBBackUP.Sa_PSW);
      if not BK.ConnectServer then
        app.SaveLogEx('连接数据库失败', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);

      if not GetDiskFreeSpaceEx(PWideChar(ReturnRootPath(ini.DBBackUP.Bak_Dir)), FreeCanBeUsed, TotalSpace, @TotalFree) then
      begin
        app.SaveLogEx('备份路径错误', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        Exit;
      end;
      if FreeCanBeUsed < 1073741824 then
      begin
        app.SaveLogEx('磁盘可用空间不足10G,备份任务即将退出,请联系系统管理员', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        Exit;
      end
      else if FreeCanBeUsed < 21474836480 then
      begin
        app.SaveLogEx('磁盘可用空间不足20G,您的系统进入警告状态，请联系系统管理员', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
      end;

      SqlDynSpaceReq := BK.SafeSpaceRequired;
      app.SaveLogEx('磁盘可用空间:' + IntToStr(FreeCanBeUsed) + '字节,数据库正常运行所需空间:' + IntToStr(SqlDynSpaceReq) + '字节');
      SafeSpace := FreeCanBeUsed - SqlDynSpaceReq;
      if SafeSpace < 0 then
        app.SaveLogEx('分区保留空间不够系统正常使用，本次备份可能会失败！', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST)
      else if SafeSpace < 1073741824 then  //10G
      begin
        app.SaveLogEx('除去数据库动态安全容量大小，磁盘保留容量小于10G,请注意！', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
      end;

      if FileExists(ini.DBBackUP.Bak_Dir) then
      begin
        if not BK.ReNameFile_Dir(ini.DBBackUP.Bak_Dir, False) then
          app.SaveLogEx('存在路径同命名文件，而且无法重命名，创建备份目录失败', False, '发生错误,MB_OK + MB_ICONSTOP + MB_TOPMOST');
        Exit;
      end;
      if not DirectoryExists(ini.DBBackUP.Bak_Dir) then
      begin
        if not CreateDir(ini.DBBackUP.Bak_Dir) then
        begin
          app.SaveLogEx('创建备份目录' + ini.DBBackUP.Bak_Dir + '失败', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
          Exit;
        end;
      end;
      if BK._MakeDir(ini.DBBackUP.Bak_Dir, cAcc_Path) then
        BK.SetBakDir(cAcc_Path) // do not contain '/'
      else
      begin
        app.SaveLogEx('创建目录' + cAcc_Path + '失败', false, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        Exit;
      end;
      BK.GetAccounts(accounts);
      for I := 1 to StrToInt(accounts[0, 0]) do
      begin
        cSysID := accounts[I, 0];
        ID := accounts[I, 1];
        cAcc_Path := accounts[I, 3];
        IYear := accounts[I, 5];
        if cAcc_Path[Length(cAcc_Path)] <> '\' then
          cAcc_Path := cAcc_Path + '\';
        BK.BakPerAcc(ID, cSysID, cAcc_Path, IYear);
      end;
      BK.PlanToCleanDirs(ini.DBBackUP.Bak_Dir,Msg,INI.DBBackUP.AcctKeepDays);
      if Msg <>'' then
      begin
      Delete(Msg,length(Msg),1);
         app.SaveLogEx('已经清理文件夹:' + Msg);
         end;
      Result := True;
    finally
      BK := nil;
      IsDBWorking:=False;
    end;
  except
    app.SaveLogEx('DBBackUP初始化失败', False, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
  end;
end;

procedure TFirsThread.Execute;

  function StrToTimeEX(T: THHMMSS): TDateTime;
  begin
    Result := EncodeTime(StrToInt(T[0]), StrToInt(T[1]), StrToInt(T[2]), 0);
  end;

var
  mode: Byte;
  Year, Month, Day, Hour, Min, Sec: Word;
  TiggerTime: THHMMSS;
  _Time, _Now: TDateTime;
  app: IAPPFunc;
  I:Cardinal;
begin
  mode := (ord(ini.DBBackUP.enable) shl 1) + ord(ini.SysAutoRSDown.enable);
  app := TAPPFunc_Create;
  case mode of
    0:
      begin
        Exit;
      end;
    1:
      begin
        TiggerTime := ini.SysAutoRSDown.ShutupTime;
      end;
    2:
      begin
        TiggerTime := ini.DBBackUP.BacKUpTime;
      end;
    3:
      begin
        _Time := StrToTimeEX(ini.DBBackUP.BacKUpTime);
        _Now := StrToTimeEX(ini.SysAutoRSDown.ShutupTime);
        if _Time >= _Now then
          TiggerTime := ini.DBBackUP.BacKUpTime
        else
          TiggerTime := ini.SysAutoRSDown.ShutupTime;
      end;
  end;
  Hour := StrToInt(TiggerTime[0]);
  Min := StrToInt(TiggerTime[1]);
  Sec := StrToInt(TiggerTime[2]);
  for I := 1 to 2*60 do
  begin
  FreeOnTerminate := True;
    SleepEx(100,False);
  if Terminated then Exit;
  end;
  while not Terminated do
  begin
    SleepEx(100, false);
    DecodeDate(now, Year, Month, Day);
    _Time := EncodeDateTime(Year, Month, Day, Hour, Min, Sec, 0);
    _Now := Now;
    if (MilliSecondsBetween(_Now, _Time) < 1000) and (MilliSecondsBetween(_Now, _Time) > -1000) then
    begin
      case mode of
        3:
          begin

            if not DBBackUPTask then
              app.SaveLogEx('备份失败！', False, '发出错误', MB_OK + MB_ICONSTOP + MB_TOPMOST)
            else
            begin
              app.SaveLogEx('备份成功');
              app.RS_execute(ini.DBBackUP.IsReboot, ini.DBBackUP.UserWaitTime);
            end;
          end;
        2:
          begin
            if not DBBackUPTask then
              app.SaveLogEx('备份失败', False, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST)
            else
              app.SaveLogEx('备份成功');
          end;
        1:
          begin
            app.RS_execute(ini.DBBackUP.IsReboot, ini.DBBackUP.UserWaitTime);
          end;
      end;

    end
  end;

end;

{$ENDREGION}

{$REGION 'Imp:The SecondThread,Task:AutomaticRun'}
// 二号线程  =================================================================//

procedure TSecThread.Execute;
var
I,Clock:Cardinal;
Year,Month,day,hour,min,sec:Word;
_Time,_Now:TDateTime;
APP:IAPPFunc;
begin

     if Not ini.AutomaticRun.enable then
      Exit;



    FreeOnTerminate:=True;
    APP:=TAPPFunc_Create;
    if ini.AutomaticRun.OnStartup then
    begin
    Clock:=Round((ini.AutomaticRun.ClsTime)/100);
    for I := 0 to Clock do
      begin
        SleepEx(100,False);
        if Terminated then  Exit;
      end;
      APP.RunExe(Ini.AutomaticRun.ProgramPath);
    end
    else
    begin
        hour := StrToInt(ini.AutomaticRun.RunatTime[0]);
        min := StrToInt(ini.AutomaticRun.RunatTime[1]);
        sec := StrToInt(ini.AutomaticRun.RunatTime[2]);
      while not Terminated do
      begin
        SleepEx(100,False);
        DecodeDate(now, Year, Month, day);
          _Time := EncodeDateTime(Year, Month, day, hour, min, sec, 0);
          _Now := Now;
          if (MilliSecondsBetween(_Now, _Time) < 1000) and (MilliSecondsBetween(_Now, _Time) > -1000) then
          begin
             APP.RunExe(Ini.AutomaticRun.ProgramPath);
          end;
      end;
    end;


end;
{$ENDREGION}

{$REGION 'Imp:The ThirdThread,Task:SystimeAutomatic'}
// 三号线程 ==================================================================//

procedure ThirdThread.Execute;
var
  Year, Month, day, hour, min, sec: Word;
  _Now, _Time: TDateTime;
  TimesToTry: Cardinal;
  App: IAPPFunc;
  P:Cardinal;
begin
  App := TAPPFunc_Create;
  if not ini.SystimeAutomatic.enable then
    Exit;
  TimesToTry := ini.SystimeAutomatic.TimesToExitWhileFailed;
  FreeOnTerminate := True;
      for P:= 1 to 30 do
     begin 
     SleepEx(100,False);
     end;
  case ord(ini.SysAutoRSDown.enable) of

    0:
      begin
        hour := StrToInt(ini.SystimeAutomatic.NoRSonCheckTime[0]);
        min := StrToInt(ini.SystimeAutomatic.NoRSonCheckTime[1]);
        sec := StrToInt(ini.SystimeAutomatic.NoRSonCheckTime[2]);
        while not Terminated do
        begin
          SleepEx(100, false);
          DecodeDate(now, Year, Month, day);
          _Time := EncodeDateTime(Year, Month, day, hour, min, sec, 0);
          _Now := Now;
          if (MilliSecondsBetween(_Now, _Time) < 1000) and (MilliSecondsBetween(_Now, _Time) > -1000) then
          begin
            App.Syn(TimesToTry);
          end;
        end;
      end;

    1:
      begin
        App.Syn(TimesToTry);
      end;

  end;
end;

{$ENDREGION}

{$REGION 'Imp:The FouthThread,Task:DiskSpaceDetection'}

procedure TFouthThread.Execute;
var
P,I:Word;
ATMSpace,TiggerVol:Int64;
APP:IAPPFunc;
OnTigger:Cardinal;
Root,nMessage:string;
function AlterUser(out Frees:int64):Boolean;
var
Total,TotalFrees:Int64;
begin
 Result:=GetDiskFreeSpaceEx(PWideChar(Root),FreeS,total,@TotalFrees);
end;
function  _RootPath(const Path:string):string;
begin
  if Path[Length(Path)] = '\' then
  Result:=Path
  else
  Result:=Copy(Path,1,(Pos('\',Path)));
end;
begin
   if not ini.DiskSpaceDetection.enable then
    Exit;

     FreeOnTerminate:=True;
         for P:= 1 to 60 do
     begin 
     SleepEx(100,False);
     if Terminated then Exit;
     
     end;

    Root:=_RootPath(Ini.DBBackUP.Bak_Dir);
    I:=0;
    OnTigger:=(Ini.DiskSpaceDetection.interval)*600;
    TiggerVol:=(Ini.DiskSpaceDetection.TiggerVol)*1024*1024;
    APP:=TAPPFunc_Create;
     while not Terminated do
      begin
          SleepEx(100,False);
         if  IsDBWorking then Continue;
          Inc(I);
          if I>= OnTigger then
            begin
              I:=0;
              if AlterUser(ATMSpace) then
              begin

              if ATMSpace < TiggerVol then
              begin

//                APP.WTS_Execute('系统警告','磁盘剩余:' +
//                FloatToStr(RoundFloat((ATMSpace/1024/1024),2)) +
//                'mb,不足' +
//                FloatToStr(RoundFloat((TiggerVol/1024/1024),2)) + 'mb',
//                10,MB_OK xor MB_ICONWARNING xor MB_SYSTEMMODAL xor MB_TOPMOST);

              APP.LowVolWarnning(ATMSpace,TiggerVol);
              end;
              end;

            end;
      end;
end;

{$ENDREGION}
procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  UFBackUp.Controller(CtrlCode);
end;

{$REGION 'Imp:TUFBackUP'}

function TUFBackUp.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TUFBackUp.ServiceBeforeInstall(Sender: TService);
begin
{$IFDEF Delayed}
 Interactive:=True;
 {$ELSE}
 Interactive:=False;
 {$ENDIF}
end;

procedure TUFBackUp.ServiceStart(Sender: TService; var Started: Boolean);
var
  app: IAPPFunc;
  IsVistaOrAbove:Boolean;
begin
  app := TAPPFunc_Create;
  if not app.IniFileToVar(ini) then
  begin
    app.SaveLogEx('读取Ini失败!', False, '发生错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    Abort;
  end;
  IsDBWorking:=False;
  Third := ThirdThread.Create(True);
  Third.Resume;
  First := TFirsThread.Create(True);
  First.Resume;
  Sec := TSecThread.Create(True);
  Sec.Resume;
  Four:=TFouthThread.Create(True);
  Four.Resume;
  Started := True;
end;

procedure TUFBackUp.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  First.Terminate;
  Sec.Terminate;
  Third.Terminate;
  Four.Terminate;
  Stopped := True;
  
end;

{$ENDREGION}

end.

