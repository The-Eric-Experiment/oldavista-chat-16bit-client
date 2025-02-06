unit About;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, AppMeta;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    OKButton: TBitBtn;
    ProgramIcon: TImage;
    LblProductName: TLabel;
    LblVersion: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    Label1: TLabel;
    AboutHeaderImage: TImage;
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.DFM}

procedure TAboutBox.FormActivate(Sender: TObject);
begin
  LblProductName.Caption := AppName;
  LblVersion.Caption := 'Version ' + AppVersion + ' (' + AppEnvironment + ')';
end;

end.
 
