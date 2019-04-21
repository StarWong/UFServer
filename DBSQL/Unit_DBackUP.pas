unit Unit_DBackUP;

interface


{$I ..\DacVer.inc}

uses
  SysUtils, _Int_DLL ,Classes {$IFDEF AnyDAC},
  uADStanIntf, uADStanOption, uADStanError, uADGUIxIntf,
  uADPhysIntf, uADStanDef, uADStanPool, uADStanAsync, uADPhysManager,
  uADStanParam, uADDatSManager, uADDAptIntf, uADDAptManager, DB, uADCompDataSet,
  uADCompClient, uADGUIxFormsWait, uADCompGUIx, uADPhysODBCBase, uADPhysMSSQL
  {$ENDIF}

  {$IFDEF  UniDAC},
  UniProvider, SQLServerUniProvider, MemDS, DBAccess, Uni
  {$ENDIF}

  {$IFDEF  AdoDac},
  ADODB
  {$ENDIF};
{$REGION 'Declare Global Type'}
const
  AccFields: array [0 .. 6] OF string = ('6', 'iSysid', 'cAcc_Id', 'cAcc_Name',
    'cAcc_Path', 'cUnitName', 'iyear');
  Tables_Ex: array [0 .. 10] of string = ('10', 'UA_Account_Ex', 'UA_Period_Ex',
    'UA_User_Ex', 'UA_HoldAuth_Ex', 'UA_Account_sub_Ex', 'UA_Log_Ex',
    'UA_Account_sub_Plugin_Ex', 'UA_HoldAuth_Plugin_Ex', 'UA_Log_Plugin_Ex' ,
    'UU_Setup_Ex');
  //Dir_PerlRegEx: UTF8String ='^[a-zA-Z]:(\\((([^ \f\n\r\t\v\\\?\/\*\|<>:"]){1,2})|([^ \f\n\r\t\v\\\?\/\*\|<>:"][^\f\n\r\t\v\\\?\/\*\|<>:"]*[^ \f\n\r\t\v\\\?\/\*\|<>:"])))*$';
  YYMMDD_PerlRegEx: UTF8String = '^((((([1|2])[0-9]{1})(0[48]|[2468]' + '[048]|[13579][26])|((0[48]|[2468][048]|[13579][26])00))0229)|' + '([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9]' + '[0-9]{3})(((0[13578]|1[02])(0[1-9]|[12][0-9]|3[01]))|((0[469]|11)' + '(0[1-9]|[12][0-9]|30))|(02(0[1-9]|[1][0-9]|2[0-8]))))$';
   //Dir_PerlRegEx: d:,c:\1
  Demo_Acct_SysID_998: string = '40864.8103240741';
  Demo_Acct_SysID_999: string = '40983.6623263889';
  SQLVersion_Check: string = ' SELECT CAST(SERVERPROPERTY(' + #39 + 'ProductVersion' + #39 + ') AS SYSNAME) AS ProductVersion';
{$REGION 'SQLSTR_Head'}
  SQLSTR_Head: string = 'if Exists(select 1 from tempdb..sysobjects ' +
  'where id = object_id(N' + #39 + 'Tempdb..#DBSize' + #39 + ') and type=' +
  #39 + 'U' + #39 + ')' + #13#10 + 'Drop table #DBSize' + #13#10 +
  'CREATE TABLE #DBSize' + #13#10 +
  '(' + #13#10 +
  '[Ext Used space] decimal(38,0),' + #13#10 +
  '[Used space] decimal(38,0)' + #13#10 +
  ')' +
  #13#10 + 'INSERT INTO #DBSize' + #13#10 + 'EXEC sp_msforeachdb' + #13#10 + #39 + 'USE [?];';
{$ENDREGION}
{$REGION '*do not use*Method1:SQL2K+ Only,U Can Use Method2 instead,It Supports 2K AND 2K+'}
{$REGION 'SQLSTR_FullSTR_2K_UP'}
  SQLSTR_FullSTR_2K_UP: string = #13#10 + 'select sum(a.total_pages*8*1024) AS UsedSpace' + #13#10 + 'from sys.allocation_units a';
{$ENDREGION}
{$ENDREGION}
{$REGION 'SQLSTR_Body'}
SQLSTR_Body: string = #13#10 + 'Where DB_NAME() In' + #13#10 + '(select (' + #39 + #39 + 'UFDATA_' + #39 + #39 + ' + T2.cAcc_ID + ' + #39 + #39 + '_' + #39 + #39 + ' + Convert(varchar(4),T2.iYear)) as UFDBName' + #13#10 + 'from ufsystem..ua_account t1 left join' + #13#10 + '(SELECT cAcc_ID,iyear FROM UFSystem..UA_Period where (' + 'bIsDelete=0 or bisdelete is null) GROUP BY cAcc_ID,iyear) T2' + #13#10 + 'ON T1.cAcc_ID = T2.cAcc_ID' + #13#10 + 'where t1.iSysID Not in(40864.8103240741,40983.6623263889)' + #13#10 + ')' + #39 +
//#13#10 + 'GO' +
    #13#10 +
    'SELECT Max(isnull([Used space],0))/1.5+(Sum(isnull([Ext Used space],0)) ' +
    '+' +
    ' Sum(isnull([Used space],0))/3) as Used' +
    #13#10 +
    'FROM #DBSize' +
    #13#10 + 'DROP TABLE #DBSize';
{$ENDREGION}
{$REGION '*do not use*Method2,Use SQLSTR_PARTSTR_Base + Choose_2K_UP For SQL2K+'}
{$REGION 'SQLSTR_PARTSTR_Base'}
  SQLSTR_PARTSTR_Base: string = #13#10 + 'SELECT  CAST(SUM(FILEPROPERTY(name, ' + #39 + #39 + 'SpaceUsed' + #39 + #39 + '))*8192 AS BigInt) AS [Used space(Bytes)]';
{$ENDREGION}
{$REGION 'Choose_2K_UP'}
  Choose_2K_UP: string = #13#10 + 'FROM sys.database_files';
{$ENDREGION}
{$REGION 'Choose_2K'}
  Choose_2K: string = #13#10 + 'FROM sysfiles';
{$ENDREGION}
{$ENDREGION}
{$REGION '*do not use*Method3:Return Mini Space Required For DBS'}
  SQLSTR_MINIRequire: string = #13#10 + 'SELECT Sum(Convert(decimal(38,2), ' + '((db.size*8)*1024 * db.growth /100))) as MiniReqSpace' + #13#10 + 'FROM sys.database_files db';
{$ENDREGION}
{$REGION 'Method4:Full detect(retention + 1.5*UsedSpace + Numbers of DB * 100m)'}
SQLSTR_FULL_Detect_2K_UP: string = #13#10 +
  'select (Convert(decimal(38,2),' +
  '(sum(size*8*1024 * growth /100))) + 104857600) as ExtSpace,' +
  #13#10 + '(CAST(SUM(FILEPROPERTY(name, ' + #39 + #39 +
  'SpaceUsed' +
  #39 + #39 + '))*12288 AS decimal(38,2))) as UsedSpace' + #13#10 +
  'FROM sys.database_files';
  SQLSTR_FULL_Detect_2K: string = #13#10 +
  'select (Convert(decimal(38,2),' +
  '(sum(size*8*1024 * growth /100))) + 104857600) as ExtSpace,' +
  #13#10 + '(CAST(SUM(FILEPROPERTY(name, ' + #39 + #39 +
  'SpaceUsed' +
  #39 + #39 + '))*12288 AS decimal(38,2))) as UsedSpace' + #13#10 +
  'FROM sysfiles';
{$ENDREGION}
type

  Tmybackuptask = class(TInterfacedObject,IDB)
  private
   {$REGION 'Conn&Query'}
    FConnect: {$IFDEF AdoDac}TAdoConnection
    {$Else} {$IFDEF UniDac}TUniConnection{$ENDIF}{$ENDIF};
    FQuery: {$IFDEF AdoDac}TAdoquery
    {$Else} {$IFDEF UniDac}TUniquery{$ENDIF}{$ENDIF};
    {$ENDREGION}
    FUF2KAct_Lst:TStrings;
    FConStr: string;
    FSaPsw: string;
    FBakDir: string;
    procedure initialize_Lst;
    function TStringsToFile(List: TStrings; mFileName: TFileName): Boolean;
  public
  {$REGION 'Public'}
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
    constructor Create;
    destructor Destroy; override;
  {$ENDREGION}
  end;
 {$ENDREGION}

implementation

uses
  DateUtils,PerlRegEx,Types,IOUtils,ZLibExGZ{$IFDEF AdoDac},ActiveX{$ENDIF};

{$REGION 'Imp:TMyBackUPTask'}

constructor Tmybackuptask.Create;
begin
  {$IFDEF AdoDac}
  CoInitialize(nil);
  FConnect := TAdoConnection.Create(nil);
  FQuery := TAdoQuery.Create(nil);
  {$ELSE}
  {$IFDEF UniDac}
  FConnect := TUniConnection.Create(nil);
  FQuery := TUniQuery.Create(nil);
  {$ENDIF}
  {$ENDIF}
  //FQuery.OptionsIntf.ResourceOptions.EscapeExpand:=False;
  FQuery.Connection := FConnect;
  FUF2KAct_Lst:=TStringList.Create;

end;

destructor Tmybackuptask.Destroy;
begin
  inherited;
  if Assigned(FConnect) then
    FConnect.Free;
  if Assigned(FQuery) then
    FQuery.Free;
    if Assigned(FUF2KAct_Lst) then
     FreeAndNil(FUF2KAct_Lst);
  {$IFDEF AdoDac}
  CoUninitialize();
  {$ENDIF}

end;

procedure Tmybackuptask.SetSaPsw(const Str: string);
begin
  FSaPsw := Str;
  {$IFDEF AdoDac}
   FConStr:='Provider=SQLOLEDB.1;Password=' +
   FSaPsw +
   ';Persist Security Info=True;User ID=sa;Initial Catalog=master;Data Source=.';
  {$ELSE}
  {$IFDEF UniDac}
  FConStr:='Provider Name=SQL Server;' +
  'Data Source=.;Initial Catalog=master;User ID=sa;Password=' +
  FSaPsw;
  {$ENDIF}
  {$ENDIF}
end;

function Tmybackuptask.ConnectServer;
begin
  try
    Result := True;
    {$IFDEF AdoDac}
     FConnect.ConnectionString:=FConStr;
    {$ELSE}
    {$IFDEF UniDac}
    FConnect.ConnectString := FConStr;
    {$ENDIF}
    {$ENDIF}
    FConnect.Connected := True;
  except
    Result := False;
  end;
end;

procedure Tmybackuptask.GetAccounts(out Accounts: TAccounts);
var
  ICount, FieldCounts, I, J: Integer;
begin
  with FQuery do
  begin
    Close;
    SQL.Clear;
    SQL.Add('select ');
    FieldCounts := StrToInt(AccFields[0]);
    for I := 1 to FieldCounts do
    begin
      if I = 1 then
        SQL.Add(AccFields[I])
      else
        SQL.Add(' , ' + AccFields[I]);
    end;
    SQL.Add(' From UFSystem..UA_Account');
    Open;
    ICount := RecordCount;
    if ICount = 0 then
      Exit;
    SetLength(Accounts, ICount + 1, FieldCounts);
    Accounts[0, 0] := IntToStr(ICount);
    Accounts[0, 1] := IntToStr(FieldCounts);
    First;

    for I := 1 to ICount do

    begin
      for J := 0 to FieldCounts - 1 do
      BEGIN
        Accounts[I, J] := FieldByName(AccFields[J + 1]).AsString;
      END;

      Next;
    end;

  end;

end;

function Tmybackuptask.BakPerAcc(const ID, cSysID, cAcc_Path, StartYear: string): Boolean;
var
  IYear: TYears;
  ICount, I, J,Bak_Bytes: Integer;
  LInput, LOutput: TFileStream;
  LZip: TGZCompressionStream;
  Lines,StartTime_BackUp,File_size: string;
  {$REGION 'Procedure Generate_Lst'}
procedure generate_Lst;
{$REGION 'Func _FormatYears'}
function _FormatYears(const StartYear:string;ICount:Integer):string;
var
I,Year:Integer;
Tmp:string;
begin
      Result:='';
      Year:=StrToInt(StartYear);
     for I := 0 to ICount - 1 do
       begin
           Tmp:=IntToStr(Year + I);
           Delete(Tmp,1,2);
           Result:=Result + Tmp + ',';

       end;
       Delete(Result,Length(Result),1);

end;
{$ENDREGION}
var
I:Integer;
begin
    FUF2KAct_Lst.ValueFromIndex[2]:=ID;
    FUF2KAct_Lst.ValueFromIndex[3]:=cSysID;
    FUF2KAct_Lst.ValueFromIndex[4]:=cAcc_Path + 'ZT' + ID + '\';
    FUF2KAct_Lst.ValueFromIndex[7]:=StartTime_BackUp;
    FUF2KAct_Lst.ValueFromIndex[12]:=File_size;
    FUF2KAct_Lst.ValueFromIndex[15]:=cAcc_Path + 'ZT' + ID + '\UFDATA.BAK';
    FUF2KAct_Lst.ValueFromIndex[17]:='1,,UFDATA.BA_,UFDATA.BAK,' +
    cAcc_Path + 'ZT' + ID + '\' + ',,,' +  StartTime_BackUp + ',' + File_size;
    FUF2KAct_Lst.ValueFromIndex[8]:=IntToStr(ICount);
    FUF2KAct_Lst.ValueFromIndex[9]:=_FormatYears(StartYear,ICount);
    for I := 1 to ICount do
      begin
      FUF2KAct_Lst.Insert(6+I,'VersionCo_' + IntToStr(I) + '=8.21909_用友通10.1');
      end;

end;
{$ENDREGION}
begin



  try
    Result := True;
    with FQuery do
    begin
      Close;
      SQL.Clear;
{$REGION 'Lines Select Number Of Years'}
      Lines := 'SELECT iyear FROM UFSystem..UA_Period where cAcc_Id=';
      Lines := Lines + #39;
      Lines := Lines + ID;
      Lines := Lines + #39;
      Lines := Lines + ' AND (bIsDelete=0 or bisdelete is null) GROUP BY iyear';
      SQL.Add(Lines);
{$ENDREGION}
      Open;
      ICount := RecordCount;
      if ICount = 0 then
      begin
        Result := False;
        Exit;
      end;
      if Not DirectoryExists(FBakDir + '\ZT' + ID ) then
      begin
        if not CreateDir(FBakDir + '\ZT' + ID) then
        begin
        Result:=False;
        Exit;
        end;
      end;
          if FileExists(FBakDir + '\ZT' + ID + '\UFDATA') then
          begin
         if not  RenameFile(FBakDir + '\ZT' + ID + '\UFDATA',
         FBakDir + '\ZT' + ID + '\UFDATA-' +
          FormatDateTime('yyyy-mm-dd-hh-nn-ss-zzz',Now)) then
          begin
            Result:=False;
            Exit;
          end;
          end;
                   if FileExists(FBakDir + '\ZT' + ID + '\UFDATA.BA_') then
                   begin
         if not  RenameFile(FBakDir + '\ZT' + ID + '\UFDATA.BA_',
         FBakDir + '\ZT' + ID + '\UFDATA-' +
          FormatDateTime('yyyy-mm-dd-hh-nn-ss-zzz',Now) + '.BA_') then
          begin
          Result:=False;
          Exit;
          end;
                   end;
      SetLength(IYear, ICount);
      First;
      for I := 0 to ICount - 1 do
      begin
        IYear[I] := FieldByName('IYear').AsString;
        Next;
      end;
      Close;
      SQL.Clear;
      for I := 0 to ICount - 1 do
      begin

        if I = 0 then
        begin
{$REGION 'First Year'}
{$REGION 'Lines Header'}
          SQL.Add('set quoted_identifier off');
          SQL.Add('SET TEXTSIZE 64512');
          SQL.Add('set implicit_transactions off');
{$ENDREGION}
{$REGION 'Lines 4-12'}
          for J := 1 to StrToInt(Tables_Ex[0]) do
          begin
            Lines := 'IF EXISTS(SELECT NAME FROM UFDATA_' + ID + '_' + IYear[I]
              + '..sysobjects WHERE NAME = ';
            Lines := Lines + #39;
            Lines := Lines + Tables_Ex[J];
            Lines := Lines + #39;
            Lines := Lines + ' AND TYPE = ';
            Lines := Lines + #39;
            Lines := Lines + 'U';
            Lines := Lines + #39;
            Lines := Lines + ') DROP TABLE UFDATA_' + ID + '_' + IYear[I]
              + '..' + Tables_Ex[J];
            SQL.Add(Lines);
          end;
{$ENDREGION}
{$REGION 'Lines 13 :UA_Account_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_Account_Ex FROM UFSystem..UA_Account  WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 14 :UA_Period_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_Period_Ex FROM UFSystem..UA_Period  WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 15 :UA_User_Ex'}
          Lines := 'SELECT U.* INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_User_Ex  FROM UFSystem..UA_User as U ';
          Lines := Lines +
            'WHERE U.iAdmin=0  and U.cUser_Id IN  (SELECT H.cUser_Id  From ';
          Lines := Lines + 'UFSystem..UA_HoldAuth as H  WHERE H.cacc_id = ';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ')';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 16 :UA_HoldAuth_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_HoldAuth_Ex FROM ';
          Lines := Lines + 'UFSystem..UA_HoldAuth ';
          Lines := Lines + 'WHERE (cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and LEFT(cAuth_Id,2) in (select cModuleID from ';
          Lines := Lines +
            'UFSystem..UA_ModuleFacade where bPluginManage=0)) Or (cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and ';
          Lines := Lines + 'LEFT(cAuth_Id,2)=';
          Lines := Lines + #39;
          Lines := Lines + 'AS';
          Lines := Lines + #39;
          Lines := Lines + ') Or (cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and LEFT(cAuth_Id,2)=';
          Lines := Lines + #39;
          Lines := Lines + 'TL';
          Lines := Lines + #39;
          Lines := Lines + ') or ';
          Lines := Lines + '(cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and cAuth_Id=';
          Lines := Lines + #39;
          Lines := Lines + 'Admin';
          Lines := Lines + #39;
          Lines := Lines + ') ';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 17 :UA_Account_sub_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_Account_sub_Ex ';
          Lines := Lines + 'FROM UFSystem..UA_Account_sub WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and cSub_Id in (select cModuleID from  ';
          Lines := Lines + 'UFSystem..UA_ModuleFacade where bPluginManage=0)';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 18 :UA_Log_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I]
            + '..UA_Log_Ex FROM ';
          Lines := Lines + 'UFSystem..UA_Log WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and cSub_Id in (select cModuleID ';
          Lines := Lines +
            'from UFSystem..UA_ModuleFacade where bPluginManage=0)';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 19 :UA_HoldAuth_Plugin_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_HoldAuth_Plugin_Ex ';
          Lines := Lines + 'FROM UFSystem..UA_HoldAuth WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and LEFT(cAuth_Id,2) in (select cModuleID ';
          Lines := Lines +
            'from UFSystem..UA_ModuleFacade where bPluginManage=1)';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 20 :UA_Account_sub_Plugin_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I] +
            '..UA_Account_sub_Plugin_Ex ';
          Lines := Lines + 'FROM UFSystem..UA_Account_sub WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + ' and cSub_Id in (select cModuleID from ';
          Lines := Lines + 'UFSystem..UA_ModuleFacade where bPluginManage=1)';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines 21 :UA_Log_Plugin_Ex'}
          Lines := 'SELECT * INTO UFDATA_' + ID + '_' + IYear[I]
            + '..UA_Log_Plugin_Ex ';
          Lines := Lines + 'FROM UFSystem..UA_Log WHERE cAcc_Id=';
          Lines := Lines + #39;
          Lines := Lines + ID;
          Lines := Lines + #39;
          Lines := Lines + 'and cSub_Id in (select cModuleID ';
          Lines := Lines +
            'from UFSystem..UA_ModuleFacade where bPluginManage=1)';
          SQL.Add(Lines);
{$ENDREGION}
{$REGION 'Lines BackUP'}
          SQL.Add(#13#10);
          Lines := 'BACKUP DATABASE [UFDATA_' + ID + '_' + IYear[I] + '] TO ';
          Lines := Lines + 'DISK = N';
          Lines := Lines + #39;
          Lines := Lines + FBakDir + '\ZT' + ID + '\UFDATA.BAK';
          Lines := Lines + #39;
          Lines := Lines + ' WITH  INIT ,  NOUNLOAD ,  NAME = N';
          Lines := Lines + #39;
          Lines := Lines + 'UFDATA_' + ID + '_' + IYear[I] + ' Backup';
          Lines := Lines + #39;
          Lines := Lines + ',  NOSKIP ,  STATS = 10,  DESCRIPTION = N';
          Lines := Lines + #39;
          Lines := Lines + 'Account';
          SQL.Add(Lines);
          SQL.Add(cSysID);
          SQL.Add('1.00');
          SQL.Add('2.0');
          SQL.Add(ID);
          SQL.Add(IYear[I]);
          Lines:=cAcc_Path + 'ZT' + ID + '\';
          SQL.Add(Lines);
          Lines:=cAcc_Path + 'ZT' + ID + '\' + IYear[I] + '\';
          SQL.Add(Lines);
          Lines := FSaPsw  + #39;
          Lines := Lines + ',  NOFORMAT ';
          SQL.Add(Lines);
          SQL.Add(#13#10);
{$ENDREGION}
{$REGION 'Lines 22-30'}
          for J := 1 to StrToInt(Tables_Ex[0]) do
          begin
            Lines := 'IF EXISTS(SELECT NAME FROM UFDATA_' + ID + '_' + IYear[I]
              + '..sysobjects WHERE NAME = ';
            Lines := Lines + #39;
            Lines := Lines + Tables_Ex[J];
            Lines := Lines + #39;
            Lines := Lines + ' AND TYPE = ';
            Lines := Lines + #39;
            Lines := Lines + 'U';
            Lines := Lines + #39;
            Lines := Lines + ') DROP TABLE UFDATA_' + ID + '_' + IYear[I]
              + '..' + Tables_Ex[J];
            SQL.Add(Lines);
          end;
{$ENDREGION}
{$ENDREGION}
        end
        else
        begin
{$REGION 'Lines BackUP'}
          SQL.Add(#13#10);
          Lines := 'BACKUP DATABASE [UFDATA_' + ID + '_' + IYear[I] + '] TO ';
          Lines := Lines + 'DISK = N';
          Lines := Lines + #39;
          Lines := Lines + FBakDir + '\ZT' + ID + '\UFDATA.BAK';
          Lines := Lines + #39;
          Lines := Lines + ' WITH  NOINIT ,  NOUNLOAD ,  NAME = N';
          Lines := Lines + #39;
          Lines := Lines + 'UFDATA_' + ID + '_' + IYear[I] + ' Backup';
          Lines := Lines + #39;
          Lines := Lines + ',  NOSKIP ,  STATS = 10,  DESCRIPTION = N';
          Lines := Lines + #39;
          Lines := Lines + 'Account';
          SQL.Add(Lines);
          SQL.Add(cSysID);
          SQL.Add('1.00');
          SQL.Add('2.0');
          SQL.Add(ID);
          SQL.Add(IYear[I]);
          Lines:=cAcc_Path + 'ZT' + ID + '\';
          SQL.Add(Lines);
          Lines:=cAcc_Path + 'ZT' + ID + '\' + IYear[I] + '\';
          SQL.Add(Lines);
          Lines := FSaPsw  + #39;
          Lines := Lines + ',  NOFORMAT ';
          SQL.Add(Lines);
{$ENDREGION}
        end;


      end;
      StartTime_BackUp:=FormatDateTime('yyyy-mm-dd hh:nn',Now);
      ExecSQL;
        {$REGION 'GZip DATA'}
        try
          LInput := TFileStream.Create(FBakDir + '\ZT' + ID + '\UFDATA.BAK',
            fmOpenRead);
          LOutput := TFileStream.Create(FBakDir + '\ZT' + ID + '\UFDATA.BA_',
            fmCreate);
          LZip := TGZCompressionStream.Create(LOutput);
          Bak_Bytes:=LInput.Size;
          File_size:=IntToStr(Bak_Bytes);
          LZip.CopyFrom(LInput, Bak_Bytes);
        finally
          LZip.Free;
          LInput.Free;
          LOutput.Free;
        end;
      {$ENDREGION}

      {$REGION 'Create UF2KAct.Lst'}
      if FileExists(FBakDir + '\ZT' + ID + '\UF2KAct.Lst') then
      begin
       if not RenameFile(FBakDir + '\ZT' + ID + '\UF2KAct.Lst',
        FBakDir + '\ZT' + ID + '\UF2KAct-' +
          FormatDateTime('yyyy-mm-dd-hh-nn-ss-zzz',Now) + '.Lst') then
          begin
          Result:=False;
          Exit;
          end;
      end;
      initialize_Lst; //initialize UF2KAct.Lst
      generate_Lst;
      if NOT TStringsToFile(FUF2KAct_Lst,FBakDir + '\ZT' + ID + '\UF2KAct.Lst')
       then
        begin
        Result:=False;
        Exit;
        END



      {$ENDREGION}


    end;
    if FileExists(FBakDir + '\ZT' + ID + '\UFDATA.Bak') then
    SysUtils.DeleteFile(FBakDir + '\ZT' + ID + '\UFDATA.Bak');

  except
    Result := False;
  end;
end;

procedure Tmybackuptask.SetBakDir(const Dir: string);
begin
  FBakDir := Dir;
end;

procedure Tmybackuptask.initialize_Lst;
begin
  FUF2KAct_Lst.Clear;
  FUF2KAct_Lst.Add('[BackRetInfo]');
  FUF2KAct_Lst.Add('Type=Account');
  FUF2KAct_Lst.Add('cAcc_Id=');
  FUF2KAct_Lst.Add('iSysId=');
  FUF2KAct_Lst.Add('cacc_path=');
  FUF2KAct_Lst.Add('Version=1.00');
  FUF2KAct_Lst.Add('VersionEx=2.0');
  //FUF2KAct_Lst.Add('VersionCo_1=8.21909_用友通10.1');
  //FUF2KAct_Lst.Add('VersionCo_2=8.21909_用友通10.1');
  //FUF2KAct_Lst.Add('VersionCo_3=8.21909_用友通10.1');
  //FUF2KAct_Lst.Add('VersionCo_4=8.21909_用友通10.1');
  //FUF2KAct_Lst.Add('VersionCo_5=8.21909_用友通10.1');
  FUF2KAct_Lst.Add('Date=');
  FUF2KAct_Lst.Add('YCount=');
  FUF2KAct_Lst.Add('YYear=');
  FUF2KAct_Lst.Add('Backup=Success');
  FUF2KAct_Lst.Add('Disks=0');
  FUF2KAct_Lst.Add('Bytes=');
  FUF2KAct_Lst.Add('[FileInfo]');
  FUF2KAct_Lst.Add('Count=1');
  FUF2KAct_Lst.Add('File1=');
  FUF2KAct_Lst.Add('[Files]');
  FUF2KAct_Lst.Add('File1=');
end;

function Tmybackuptask.TStringsToFile(List: TStrings; mFileName: TFileName): Boolean;
var
F: Textfile;
I,ListCount: Integer;
begin
Result:=False;
ListCount:=List.Count;
if ListCount > 0 then

begin
{$I-}
//Create File
AssignFile(F, mFileName);
Rewrite(F);
//End Create File
for I := 0 to ListCount - 1 do
begin
Append(F);
Writeln(F, List[I]);
end;
Closefile(F);
{$I+}
Result := (IOResult = 0);
end;
end;

function Tmybackuptask.SafeSpaceRequired;
var
ProductVersion: string;
SqlVersion: Byte;
begin
    with FQuery do
    begin
      Close;
      SQL.Clear;
      SQL.Add(SQLVersion_Check);
      Open;
      ProductVersion := FieldByName('ProductVersion').AsString;
        SqlVersion := DecodeSqlVersion(ProductVersion);
        Close;
        SQL.Clear;
        if SqlVersion > 80 then
          SQL.Add(SQLSTR_Head + SQLSTR_FULL_Detect_2K_UP + SQLSTR_Body)
        else
        SQL.Add(SQLSTR_Head + SQLSTR_FULL_Detect_2K + SQLSTR_Body);
        Open;
        Result := FieldByName('Used').AsLargeInt;
        Close;
    end;
end;

function Tmybackuptask.ReNameFile_Dir(const Name:string;ISDir:Boolean):Boolean;
var
I:Cardinal;
begin
I:=0;
Result:=False;
if ISDir then
begin
     repeat
      Inc(I);
     until ((DirectoryExists(Name + '_' + IntToStr(I)) = False)
     and (FileExists(Name + '_' + IntToStr(I)) = False))
     or (I = 65535);

end
else
begin
      repeat
      Inc(I);
     until ((FileExists(Name + '_' + IntToStr(I)) = False)
     AND (DirectoryExists(Name + '_' + IntToStr(I)) = False))
     or (I = 65535);

end;
if I = 65535 then
 Exit(False);
Result:=RenameFile(Name,Name + '_' + IntToStr(I));
end;

function Tmybackuptask._MakeDir(const PathName: string;out FullPath:string):Boolean;
begin
Result:=True;
try
FullPath:=PathName + '\' + FormatDateTime('YYYYMMDD',Now);
if FileExists(FullPath) then
begin
   Result:=ReNameFile_Dir(FullPath,False);
end
else  if DirectoryExists(FullPath) then
begin
  Result:=ReNameFile_Dir(FullPath,True);
end;
if Result then
Result:=CreateDir(FullPath);
except
    Result:=False;
end;
end;

procedure Tmybackuptask.PlanToCleanDirs(const Root:string;out Msg:string;Days:Word =31);
function _Del(const FolderPath:string):Boolean;
begin
Result:=True;
   try
     TDirectory.Delete(FolderPath,True);
   except
      Result:=False;
   end;
end;
var
  FolderList: TStringDynArray;
  Reg: TPerlRegEx;
  FolderPath: string;
  FolderName:UTF8String;
  CurrDT, FolderDT: TDateTime;
  LenOfRoot: Integer;
  YYYY, MM, DD, HH, NN, SS, ZZZ: WORD;
begin
  //Root := C:\,D:\ss
  if Days = 0 then
  Exit;
  LenOfRoot := Length(Root);
   if Root[LenOfRoot] <> '\' then
   Inc(LenOfRoot);
  FolderList := TDirectory.GetDirectories(Root);
  CurrDT := Now;
  DecodeDateTime(CurrDT, YYYY, MM, DD, HH, NN, SS, ZZZ);
  Msg:='';
  try
    Reg := TPerlRegEx.Create;
    Reg.RegEx := YYMMDD_PerlRegEx;
    for FolderPath in FolderList do
    begin
      FolderName := Copy(FolderPath, LenOfRoot + 1, length(FolderPath) - LenOfRoot);
      Reg.Subject := FolderName;
      if Reg.Match then
      begin
        FolderDT := EncodeDateTime(StrToInt(copy(FolderName, 1, 4)), StrToInt(Copy(FolderName, 5, 2)), StrToInt(Copy(FolderName, 7, 2)), HH, NN, SS, ZZZ);
        if DaysBetween(CurrDT, FolderDT) > Days then
        begin
         if  _Del(FolderPath) then
          Msg:=Msg + FolderName + '删除成功;'
          else
          Msg:=Msg + FolderName + '删除失败;';
        end;
      end;
    end;
  finally
    Reg.Free;
  end;
 end;

function Tmybackuptask.DecodeSqlVersion(const S: string): Byte;
  var
    list: TStringList;
  begin
    Result := 0;
    try
      try
        list := TStringList.Create;
        list.Delimiter := '.';
        list.DelimitedText := S;
        list.StrictDelimiter := True;
        if list[0] = '10' then
        begin

          if list[1] = '50' then
          begin
            Result := 150; //Sql2008R2
            Exit;
          end;

        end;

        Result := StrToInt(list[0]) * 10;
      except
      end;
    finally
      list.Free;
    end;
  end;

{$ENDREGION}

end.
