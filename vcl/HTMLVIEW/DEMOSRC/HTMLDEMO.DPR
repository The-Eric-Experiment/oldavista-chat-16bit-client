{$M 24000, 8192}   {Default stack size may be too small}
program HTMLDemo;

uses
  Forms,
  demounit in 'DEMOUNIT.PAS' {Form1},
  Submit in 'SUBMIT.PAS' {SubmitForm},
  Fontdlg in 'FONTDLG.PAS' {FontForm},
  Htmlabt in 'HTMLABT.PAS' {AboutBox},
  ImgForm in 'IMGFORM.PAS' {ImageForm};

{$R *.RES}

begin
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TSubmitForm, SubmitForm);
  Application.Run;
end.
