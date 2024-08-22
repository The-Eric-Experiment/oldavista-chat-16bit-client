unit Frm;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, FatThing, IrcTags, StdCtrls, ExtCtrls, Spin, Menus;

type
  TForm1 = class(TForm)
{*  GroupBox1: TGroupBox;
    Image1: TImage;
    Label1: TLabel;
    MircMemo: TMemo;
    Memo1: TMemo;
    ImgBug: TImage;
    ImgDollar: TImage;
    ImgSmile: TImage;
    ImgBeer: TImage;
    ImgMail: TImage;
    PopupMenu1: TPopupMenu;
    RemLink: TMenuItem;
    Visible1: TMenuItem;
    MenuText: TMenuItem;
    MenuLink: TMenuItem;
    N1: TMenuItem;
    PopupMenu2: TPopupMenu;
    Copytoclipboard1: TMenuItem;
    Label2: TLabel;
    LHeight: TSpinEdit;
    DAlign: TRadioGroup;
    SImages: TCheckBox;
    WWrap: TCheckBox; }
    FatMemo1: TFatMemo;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Label1: TLabel;
    MircMemo: TMemo;
    ImgDollar: TImage;
    ImgSmile: TImage;
    ImgBeer: TImage;
    ImgMail: TImage;
    PopupMenu1: TPopupMenu;
    RemLink: TMenuItem;
    Visible1: TMenuItem;
    MenuText: TMenuItem;
    MenuLink: TMenuItem;
    N1: TMenuItem;
    PopupMenu2: TPopupMenu;
    Copytoclipboard1: TMenuItem;
    Label2: TLabel;
    LHeight: TSpinEdit;
    DAlign: TRadioGroup;
    SImages: TCheckBox;
    WWrap: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FatMemo1LinkClick(Sender: TObject; Link: String);
    procedure MircMemoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MircMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
    procedure FatMemo1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RemLinkClick(Sender: TObject);
    procedure Visible1Click(Sender: TObject);
    procedure Copytoclipboard1Click(Sender: TObject);
    procedure LHeightChange(Sender: TObject);
    procedure DAlignClick(Sender: TObject);
    procedure SImagesClick(Sender: TObject);
    procedure WWrapClick(Sender: TObject);
    procedure MenuLinkClick(Sender: TObject);
    procedure MenuTextClick(Sender: TObject);
    procedure FatMemo1ScrollVert(Sender: TObject);
  private
    { Private declarations }
    RightClicked: TFatPart;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
var L: TFatLine;
  P: TFatPart;
begin
  FatMemo1.Lines.Clear;

  L := FatMemo1.Lines.AddNew;
  L.AsIrcText := 'This component is' + TAG_COLOR + '4 free' + TAG_COLOR +
    ', so you don''t have to pay any ';

  
  P := L.Add;
  P.Text := 'money';
  {/ we added text }
  P.Bitmap := ImgDollar.Picture.Bitmap;
{ // which we "overdraw" by setting the bitmap }
  P.Link := 'Ch-ching!';
{ // and a link.
  // in this case, a dollar sign would be drawn, Ch-ching! text would occur as
  // the clicked link and when copying to the clipboard, the word 'money' would be used. }

  P := L.Add;
  P.Text := '.';



  // new line

  L := FatMemo1.Lines.AddNew;
  L.AsIrcText := 'Use it ' + TAG_BOLD + 'any' + TAG_BOLD + ' way you desire ';
  // we added a mirc-formatted text

  P := L.Add;
  P.Text := ':)';
  P.Bitmap := ImgSmile.Picture.Bitmap;

  P := L.Add;
  P.Text := ', just don''t eat it.';

  L := FatMemo1.Lines.AddNew;
  L.AsText := 'If you found a ';

  P := L.Add;
  P.Text := 'bug';
  P.Bitmap := ImgBug.Picture.Bitmap;
  P.Link := 'i''m a little buggy';

  P := L.Add;
  P.Text := ' or you wanna buy me a ';

  P := L.Add;
  P.Text := 'beer';
  P.Bitmap := ImgBeer.Picture.Bitmap;
  P.Link := 'beer :)';
  // The beer picture is now a link  

  P := L.Add;
  P.Text := ' or you have an idea, please ';

  P := L.Add;
  P.FontColor := clBlue;

  P := L.Add;
  P.Style := [fsUnderline];

  P := L.Add;
  P.Text := 'mail me ';
  P.Link := 'mailto:gasper.kozak@email.si';
  // I set the text, now I also set a link on that part
  // When e-mail is set to 'mailto:gasper.kozak@email.si', clicking on it
  // will launch your default mailer.

  P := L.Add;
  P.Bitmap := ImgMail.Picture.Bitmap;
  P.Link := 'mailto:gasper.kozak@email.si';

  P := L.Add;
  P.FontColor := clBlack;

  P := L.Add;
  P.Style := [];

  P := L.Add;
  P.Text := '.';


  L := FatMemo1.Lines.AddNew;
  L.Add.Text := 'See ';
  P := L.Add;
  P.Text := 'FatMemo.Txt';
  P.Link := 'Read this file for detailed description.';
  P := L.Add;
  P.Text := ' for details. Also try left and right clicking in the memo.';

  {}

  LHeight.Value := FatMemo1.LineHeight;

  if dfAlignBottom in FatMemo1.DrawFlags then
    DAlign.ItemIndex := 2 else
  if dfAlignMiddle in FatMemo1.DrawFlags then
    DAlign.ItemIndex := 1 else
    DAlign.ItemIndex := 0;

  SImages.Checked := dfStretchImages in FatMemo1.DrawFlags;

  WWrap.Checked := dfWordWrap in FatMemo1.DrawFlags;
end;

procedure TForm1.FatMemo1LinkClick(Sender: TObject; Link: String);
begin
  ShowMessage(Link);
end;

procedure TForm1.MircMemoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var S: String;
begin
  if Key = VK_RETURN then
    begin
      S := MircMemo.Text;

      while Pos(#10, S) > 0 do
        Delete(S, Pos(#10, S), 1);

      while Pos(#13, S) > 0 do
        Delete(S, Pos(#13, S), 1);

      FatMemo1.Lines.AddLineWithIrcTags(S);
      MircMemo.Text := '';
    end;
end;

procedure TForm1.MircMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var C: Char;
begin
  C := UpCase(Char(Key));
  if (C in ['B', 'U', 'O', 'R', 'L', 'K']) and (ssCtrl in Shift) then
    begin
      case C of
        'B' : MircMemo.SelText := TAG_BOLD;
        'U' : MircMemo.SelText := TAG_UNDERLINE;
        'K' : MircMemo.SelText := TAG_COLOR;
        'O' : MircMemo.SelText := TAG_NORMAL;
        'R' : MircMemo.SelText := TAG_INVERSE;
        'L' :
          begin
            MircMemo.SelText := TAG_BEGINLINK + TAG_ENDLINK;
            MircMemo.SelStart := MircMemo.SelStart - 1;
          end;
      end;

      Key := 0;
    end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  FatMemo1.CopyToClipboard;
end;

procedure TForm1.FatMemo1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var CurPos: TPoint;
begin
  if Button = mbRight then
    begin
      RightClicked := FatMemo1.OverPart;
      if RightClicked <> NIL then
        begin
          Visible1.Checked := RightClicked.Visible;
          MenuText.Caption := 'Text="' + RightClicked.Text + '"';
          MenuLink.Caption := 'Link="' + RightClicked.Link + '"';
          RemLink.Enabled := RightClicked.IsLink;

          GetCursorPos(CurPos);
          PopupMenu1.Popup(CurPos.x, CurPos.y);
        end;

      // remember the part we right-clicked on
      // so it can be used by the popupmenu
    end;
end;

procedure TForm1.RemLinkClick(Sender: TObject);
begin
  if RightClicked <> NIL then
    RightClicked.RemoveLink(RightClicked.Link);
end;

procedure TForm1.Visible1Click(Sender: TObject);
begin
  if RightClicked <> NIL then
    RightClicked.Visible := NOT RightClicked.Visible;
end;

procedure TForm1.Copytoclipboard1Click(Sender: TObject);
begin
  FatMemo1.CopyToClipboard;
end;

procedure TForm1.LHeightChange(Sender: TObject);
begin
  FatMemo1.LineHeight := LHeight.Value;
  LHeight.Value := FatMemo1.LineHeight;
end;

procedure TForm1.DAlignClick(Sender: TObject);
begin
  FatMemo1.DrawFlags := FatMemo1.DrawFlags - [dfAlignMiddle, dfAlignBottom];

  if DAlign.ItemIndex = 1 then
    FatMemo1.DrawFlags := FatMemo1.DrawFlags + [dfAlignMiddle] else
  if DAlign.ItemIndex = 2 then
    FatMemo1.DrawFlags := FatMemo1.DrawFlags + [dfAlignBottom];
end;

procedure TForm1.SImagesClick(Sender: TObject);
begin
  FatMemo1.DrawFlags := FatMemo1.DrawFlags - [dfStretchImages];
  if SImages.Checked then
    FatMemo1.DrawFlags := FatMemo1.DrawFlags + [dfStretchImages];
end;

procedure TForm1.WWrapClick(Sender: TObject);
begin
  FatMemo1.DrawFlags := FatMemo1.DrawFlags - [dfWordWrap];
  if WWrap.Checked then
    FatMemo1.DrawFlags := FatMemo1.DrawFlags + [dfWordWrap];

  FatMemo1.Paint;
end;

procedure TForm1.MenuLinkClick(Sender: TObject);
var L: String;
begin
  if RightClicked <> NIL then
    begin
      L := RightClicked.Link;
      if InputQuery('Edit link', 'Change the link of the part:', L) then
        RightClicked.Link := L;
    end;
end;

procedure TForm1.MenuTextClick(Sender: TObject);
var L: String;
begin
  if RightClicked <> NIL then
    begin
      L := RightClicked.Text;
      if InputQuery('Edit text', 'Change the text of the part:', L) then
        RightClicked.Text := L;
    end;
end;

procedure TForm1.FatMemo1ScrollVert(Sender: TObject);
begin
  if FatMemo1.BarVert.Position = FatMemo1.BarVert.Max then
    FatMemo1.StickText := stBottom else
    FatMemo1.StickText := stNone;
end;

end.

