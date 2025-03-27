
Unit Conndiag;

Interface

Uses SysUtils,WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
StdCtrls, ExtCtrls;

Type 
  TConnectionDialog = Class(TForm)
    BtnConnect: TBitBtn;
    Label1: TLabel;
    NicknameEdit: TEdit;
    RoomSelector: TComboBox;
    Label2: TLabel;
    BtnExit: TBitBtn;
    Image1: TImage;
    ColorSelector: TComboBox;
    Label3: TLabel;
    Procedure ColorSelectorDrawItem(Control: TWinControl; Index: Integer;
                                    Rect: TRect; State: TOwnerDrawState);
    Private 
    { Private declarations }
    Public 
    { Public declarations }
      NicknameColors: TStringList;
    {constructor Create(AOwner: TComponent); override;}
      destructor Destroy;
      override;
  End;

Var 
  ConnectionDialog: TConnectionDialog;

Implementation

Uses Main, ProtocolMessages;

{$R *.DFM}

destructor TConnectionDialog.Destroy;
Begin
  NicknameColors.Free;
  inherited Destroy;
End;

Procedure TConnectionDialog.ColorSelectorDrawItem(Control: TWinControl;
                                                  Index: Integer; Rect: TRect;
                                                  State: TOwnerDrawState);

Const 
  ColorWidth = 22;
  FDisplayNames = True;

Var 
  ARect: TRect;
  Text: array[0..255] Of Char;
  Safer: TColor;
  BrushHandle: HBRUSH;
  DC: HDC;
  LogPalette: PLogPalette;
  Palette: HPALETTE;
  OldPalette: HPALETTE;
  ColorRef: TColorRef;
Begin
  ARect := Rect;
  Inc(ARect.Top, 2);
  Inc(ARect.Left, 2);
  Dec(ARect.Bottom, 2);
  If FDisplayNames Then
    ARect.Right := ARect.Left + ColorWidth
  Else
    Dec(ARect.Right, 3);

  With (Control as TComboBox).Canvas Do
    Begin
      FillRect(Rect);
      Safer := Brush.Color;
      Pen.Color := clWindowText;
      Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);

    { Convert color }
      ColorRef := ColorToRGB(HtmlToDelphiColor(NicknameColors[Index]));

    { Allocate memory for a logical palette (1 color entry) }
      GetMem(LogPalette, SizeOf(TLogPalette) + SizeOf(TPaletteEntry));
      Try
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
        Try
          InflateRect(ARect, -1, -1);
          WinProcs.FillRect(DC, ARect, BrushHandle);
        Finally
          DeleteObject(BrushHandle);
    End;

      { Restore previous palette }
  SelectPalette(DC, OldPalette, False);
  DeleteObject(Palette);
Finally
  FreeMem(LogPalette, SizeOf(TLogPalette) + SizeOf(TPaletteEntry));
End;

If FDisplayNames Then
  Begin
    StrPCopy(Text, (Control as TComboBox).Items[Index]);
    Rect.Left := Rect.Left + ColorWidth + 6;
    DrawText(Handle, Text, StrLen(Text), Rect,
    DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
  End;
End;
End;

End.
