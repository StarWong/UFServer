program ClockWise;

uses
  SvcMgr,
  ServMain in 'ServMain.pas' {XCleaner: TService};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '�Զ��ػ�';
  Application.CreateForm(TXCleaner, XCleaner);
  Application.Run;
end.
