program Client;

uses
  Forms,
  Main in 'MAIN.PAS' {MainForm},
  Conndiag in 'CONNDIAG.PAS' {ConnectionDialog},
  ProtocolMessages in 'MSGS.PAS';

{$R *.RES}

begin
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TConnectionDialog, ConnectionDialog);
  Application.Run;
end.
