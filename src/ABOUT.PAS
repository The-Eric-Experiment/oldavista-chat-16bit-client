
Unit About;

Interface

Uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
Buttons, ExtCtrls, AppMeta;

Type 
  TAboutBox = Class(TForm)
    Panel1: TPanel;
    OKButton: TBitBtn;
    ProgramIcon: TImage;
    LblProductName: TLabel;
    LblVersion: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    Label1: TLabel;
    AboutHeaderImage: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Procedure FormActivate(Sender: TObject);
    Private 
    { Private declarations }
    Public 
    { Public declarations }
  End;

Var 
  AboutBox: TAboutBox;

Implementation

{$R *.DFM}

Procedure TAboutBox.FormActivate(Sender: TObject);
Begin
  LblProductName.Caption := AppName;
  LblVersion.Caption := 'Version ' + AppVersion + ' (' + AppEnvironment + ')';
End;

End.
