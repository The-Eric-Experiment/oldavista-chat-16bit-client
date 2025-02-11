program Client;

uses
  Forms,
  Main in 'MAIN.PAS' {MainForm},
  Conndiag in 'CONNDIAG.PAS' {ConnectionDialog},
  ProtocolMessages in 'MSGS.PAS',
  About in 'ABOUT.PAS' {AboutBox},
  Appmeta in 'APPMETA.PAS';

{$R *.RES}

begin
  Application.Title := 'Old''aVista Chat!';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TConnectionDialog, ConnectionDialog);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
