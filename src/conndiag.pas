unit Conndiag;

interface

uses SysUtils,WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls, RxCombos, DBCtrls;
{    , WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls;}

type
  TConnectionDialog = class(TForm)
    BtnConnect: TBitBtn;
    Label1: TLabel;
    NicknameEdit: TEdit;
    RoomSelector: TComboBox;
    Label2: TLabel;
    BtnExit: TBitBtn;
    Image1: TImage;
    ColorSelector: TComboBox;
    Label3: TLabel;
    procedure ColorSelectorDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ConnectionDialog: TConnectionDialog;

implementation

uses Main, ProtocolMessages;

{$R *.DFM}

procedure TConnectionDialog.ColorSelectorDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  ColorWidth = 22;
  FDisplayNames = True;
var
  ARect: TRect;
  Text: array[0..255] of Char;
  Safer: TColor;
begin
  ARect := Rect;
  Inc(ARect.Top, 2);
  Inc(ARect.Left, 2);
  Dec(ARect.Bottom, 2);
  if FDisplayNames then ARect.Right := ARect.Left + ColorWidth
  else Dec(ARect.Right, 3);
  with (Control as TComboBox).Canvas do begin
    FillRect(Rect);
    Safer := Brush.Color;
    Pen.Color := clWindowText;
    Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    Brush.Color := StringToColor((Control as TComboBox).Items[Index]);
    try
      InflateRect(ARect, -1, -1);
      FillRect(ARect);
    finally
      Brush.Color := Safer;
    end;
    if FDisplayNames then begin
      StrPCopy(Text, (Control as TComboBox).Items[Index]);
      Rect.Left := Rect.Left + ColorWidth + 6;
      DrawText(Handle, Text, StrLen(Text), Rect,
        DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
    end;
end;
end;

end.
