program ClockWise;

uses
  SvcMgr,
  ServMain in 'ServMain.pas' {XCleaner: TService};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := '自动关机';
  Application.CreateForm(TXCleaner, XCleaner);
  Application.Run;
end.
