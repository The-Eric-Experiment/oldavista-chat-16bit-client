unit Conndiag;

interface

uses SysUtils,WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls;

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
    NicknameColors: TStringList;
    {constructor Create(AOwner: TComponent); override;}
    destructor Destroy; override;
  end;

var
  ConnectionDialog: TConnectionDialog;

implementation

uses Main, ProtocolMessages;

{$R *.DFM}

destructor TConnectionDialog.Destroy;
begin
  NicknameColors.Free;
  inherited Destroy;
end;

procedure TConnectionDialog.ColorSelectorDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  ColorWidth = 22;
  FDisplayNames = True;
var
  ARect: TRect;
  Text: array[0..255] of Char;
  Safer: TColor;
  BrushHandle: HBRUSH;
  DC: HDC;
  LogPalette: PLogPalette;
  Palette: HPALETTE;
  OldPalette: HPALETTE;
  ColorRef: TColorRef;
begin
  ARect := Rect;
  Inc(ARect.Top, 2);
  Inc(ARect.Left, 2);
  Dec(ARect.Bottom, 2);
  if FDisplayNames then
    ARect.Right := ARect.Left + ColorWidth
  else
    Dec(ARect.Right, 3);

  with (Control as TComboBox).Canvas do
  begin
    FillRect(Rect);
    Safer := Brush.Color;
    Pen.Color := clWindowText;
    Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);

    { Convert color }
    ColorRef := ColorToRGB(HtmlToDelphiColor(NicknameColors[Index]));

    { Allocate memory for a logical palette (1 color entry) }
    GetMem(LogPalette, SizeOf(TLogPalette) + SizeOf(TPaletteEntry));
    try
      LogPalette^.palVersion := $300;
      LogPalette^.palNumEntries := 1;
      LogPalette^.palPalEntry[0].peRed := GetRValue(ColorRef);
      LogPalette^.palPalEntry[0].peGreen := GetGValue(ColorRef);
      LogPalette^.palPalEntry[0].peBlue := GetBValue(ColorRef);
      LogPalette^.palPalEntry[0].peFlags := PC_NOCOLLAPSE;

      { Create and select the logical palette }
      Palette := CreatePalette(LogPalette^);
      DC := Handle;
      OldPalette := SelectPalette(DC, Palette, False);
      RealizePalette(DC);

      { Fill the rectangle using a solid brush with the mapped palette color }
      BrushHandle := CreateSolidBrush(PALETTEINDEX(0));
      try
        InflateRect(ARect, -1, -1);
        WinProcs.FillRect(DC, ARect, BrushHandle);
      finally
        DeleteObject(BrushHandle);
      end;

      { Restore previous palette }
      SelectPalette(DC, OldPalette, False);
      DeleteObject(Palette);
    finally
      FreeMem(LogPalette, SizeOf(TLogPalette) + SizeOf(TPaletteEntry));
    end;

    if FDisplayNames then
    begin
      StrPCopy(Text, (Control as TComboBox).Items[Index]);
      Rect.Left := Rect.Left + ColorWidth + 6;
      DrawText(Handle, Text, StrLen(Text), Rect,
        DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
    end;
  end;
end;

end.
