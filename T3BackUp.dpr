program T3BackUp;

uses
  Forms,
  SvcMgr,
  ServMain in 'ServMain.pas' {UFBackUp: TService},
  _Int_DLL in '_Int_DLL.pas';

{$R *.RES}

begin

  Application.Initialize;
  Application.Title := '用友T3自动备份';
  Application.CreateForm(TUFBackUp, UFBackUp);
  Application.Run;

end.




