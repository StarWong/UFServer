program T3BackUp;

uses
  Forms,
  SvcMgr,
  ServMain in 'ServMain.pas' {UFBackUp: TService},
  _Int_DLL in '_Int_DLL.pas';

{$R *.RES}

begin

  Application.Initialize;
  Application.Title := '����T3�Զ�����';
  Application.CreateForm(TUFBackUp, UFBackUp);
  Application.Run;

end.




