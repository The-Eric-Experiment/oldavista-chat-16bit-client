unit Splitter;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs;

type
  TSplitter = class;

  ESplitterError = class(Exception);
  TSplitterKind = (skHorizontal, skVertical);
  TSplitterStyle = (ssStandard, ssOwnerDraw);
  TDrawSplitterEvent = procedure(Sender: TSplitter; Canvas: TCanvas;
    Rect: TRect) of object;
  TSplitterResizingEvent = procedure(Sender: TSplitter;
    var SplitPos: Integer) of object;
  TSplitterResizedEvent = procedure(Sender: TSplitter; SplitPos: Integer) of object;
  TSplitter = class(TWinControl)
  private
    { Private declarations }
    DC: HDC;
    OldPen: HPen;
    OldFocus: HWnd;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
  protected
    { Protected declarations }
    Dragging: boolean;
    DragPos: Integer;
    DragOffset: Integer;
    Split: Boolean;
    Ratio: Real;
    OldSplitterPos: Integer;
    FAllowSplit: Boolean;
    FFullDrag: Boolean;
    FKeepRatio: Boolean;
    FKind: TSplitterKind;
    FLeftControl: TControl;
    FRightControl: TControl;
    FStyle: TSplitterStyle;
    FSplitterPos: Integer;
    FSplitterWidth: Integer;
    FOnDrawSplitter: TDrawSplitterEvent;
    FOnResizing: TSplitterResizingEvent;
    FOnResized: TSplitterResizedEvent;
    procedure SetFullDrag(Value: Boolean);
    procedure SetKind(Value: TSplitterKind);
    procedure SetLeftControl(Value: TControl);
    procedure SetRightControl(Value: TControl);
    procedure SetStyle(Value: TSplitterStyle);
    procedure SetSplitterPos(Value: Integer);
    procedure SetSplitterWidth(Value: Integer);
    function  MaxSplitPos: Integer;
    function  GetSplitterRect: TRect;
    procedure DrawSplitter;
    procedure DrawSizingLine(Pos: Integer);
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    { Public declarations }
    SplitCursor: array [TSplitterKind] of TCursor;
    constructor Create(AOwner: TComponent); override;
  published
    { Published declarations }
    property Align;
    property AllowSplit: Boolean read FAllowSplit write FAllowSplit default True;
    property Color;
    property Enabled;
    property FullDrag: Boolean read FFullDrag write SetFullDrag default false;
    property KeepRatio: Boolean read FKeepRatio write FKeepRatio default true;
    property Kind: TSplitterKind read FKind write SetKind default skVertical;
    property LeftControl: TControl read FLeftControl write SetLeftControl;
    property RightControl: TControl read FRightControl write SetRightControl;
    property Style: TSplitterStyle read FStyle write SetStyle default ssStandard;
    property SplitterPos: Integer read FSplitterPos write SetSplitterPos;
    property SplitterWidth: Integer read FSplitterWidth write SetSplitterWidth
      default 7;
    property Visible;
    property OnDrawSplitter: TDrawSplitterEvent read FOnDrawSplitter
      write FOnDrawSplitter;
    property OnResizing: TSplitterResizingEvent read FOnResizing
      write FOnResizing;
    property OnResized: TSplitterResizedEvent read FOnResized write FOnResized;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MyControls', [TSplitter]);
end;  { Register }

constructor TSplitter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents, csOpaque];
  Width := 200;
  Height := 120;
  SplitCursor[skVertical] := crHSplit;
  SplitCursor[skHorizontal] := crVSplit;
  FAllowSplit := True;
  FFullDrag := false;
  FKeepRatio := true;
  FKind := skVertical;
  FStyle := ssStandard;
  FSplitterPos := Width div 2;
  Ratio := 2.0;
  FSplitterWidth := 7;
end;  { TSplitter.Create }

procedure TSplitter.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;  { TSplitter.CreateParams }

procedure TSplitter.AlignControls(AControl: TControl; var Rect: TRect);
begin
  if (FKind = skVertical) then begin
    if (FLeftControl <> nil) then with FLeftControl do begin
      Left := 0; Top := 0;
      Width := FSplitterPos; Height := Self.ClientHeight;
    end;
    if (FRightControl <> nil) then with FRightControl do begin
      Left := FSplitterPos + FSplitterWidth; Top := 0;
      Width := Self.ClientWidth - Left; Height := Self.ClientHeight;
    end;
  end else begin
    if (FLeftControl <> nil) then with FLeftControl do begin
      Left := 0; Top := 0;
      Width := Self.ClientWidth; Height := SplitterPos;
    end;
    if (FRightControl <> nil) then with FRightControl do begin
      Left := 0; Top := FSplitterPos + FSplitterWidth;
      Width := Self.ClientWidth; Height := Self.ClientHeight - Top;
    end;
  end;
end;  { TSplitter.AlignControl }

procedure TSplitter.WMPaint(var Msg: TWMPaint);
begin
  inherited;
  DrawSplitter;
end;  { TSplitter.WMPaint }

function  TSplitter.MaxSplitPos: Integer;
begin
  if (FKind = skVertical) then
    Result := ClientWidth
  else
    Result := ClientHeight;
end;  { TSplitter.MaxSplitPos }

procedure TSplitter.WMSize(var Msg: TWMSize);
var
  SaveRatio: Real;
begin
  inherited;
  if FKeepRatio and (Ratio <> 0.0) then begin
    { The Ratio might be changed by SetSplitterPos and we don't want this to happen }
    SaveRatio := Ratio;
    SetSplitterPos(Round(MaxSplitPos/Ratio));
    Ratio := SaveRatio;
  end;
end;  { TSplitter.WMSize }

procedure TSplitter.SetFullDrag(Value: Boolean);
begin
  if not Dragging then
    FFullDrag := Value;
end;  { TSplitter.SetFullDrag }

procedure TSplitter.SetKind(Value: TSplitterKind);
begin
  if (Value <> FKind) then begin
    FKind := Value;
    if (Ratio <> 0.0) then
      SetSplitterPos(Round(MaxSplitPos/Ratio))
    else
      SetSplitterPos(FSplitterPos);
  end;
end;  { TSplitter.SetKind }

procedure TSplitter.SetLeftControl(Value: TControl);
begin
  if (Value <> nil) and (Value.Parent <> Self) then
    raise ESplitterError.Create('Invalid Control');
  FLeftControl := Value;
  SetSplitterPos(FSplitterPos);
end;  { TSplitter.SetLeftControl }

procedure TSplitter.SetRightControl(Value: TControl);
begin
  if (Value <> nil) and (Value.Parent <> Self) then
    raise ESplitterError.Create('Invalid Control');
  FRightControl := Value;
  SetSplitterPos(FSplitterPos);
end;  { TSplitter.SetRightControl }

procedure TSplitter.SetStyle(Value: TSplitterStyle);
begin
  if (Value <> FStyle) then begin
    FStyle := Value;
    DrawSplitter;
  end;
end;  { TSplitter.SetStyle }

procedure TSplitter.SetSplitterPos(Value: Integer);
var
  MaxValue: Integer;
  Update: Boolean;
begin
  if (FKind = skVertical) then MaxValue := Width else MaxValue := Height;
  if (Value < 0) or (Value > MaxSplitPos) then
    raise ESplitterError.Create('Are you crazy? Where do you want me to go?');

  Update := Value <> FSplitterPos;
  FSplitterPos := Value;
  if (FSplitterPos = 0) then
    Ratio := 0.0
  else
    Ratio := MaxSplitPos / FSplitterPos;
  ReAlign;
  if Update then InvalidateRect(Handle, nil, true);
  if Assigned(FOnResized) then FOnResized(Self, FSplitterPos);
end;  { TSplitter.SetSplitterPos }

procedure TSplitter.SetSplitterWidth(Value: Integer);
begin
  if (Value < 2) then
    raise ESplitterError.Create('Invalid Splitter Width!');
  if (Value <> FSplitterWidth) then begin
    FSplitterWidth := Value;
    SetSplitterPos(FSplitterPos);
  end;
end;  { TSplitter.SetSplitterWidth }

function  TSplitter.GetSplitterRect: TRect;
begin
  if (FKind = skVertical) then
    Result := Bounds(FSplitterPos, 0, FSplitterWidth, ClientHeight)
  else
    Result := Bounds(0, FSplitterPos, ClientWidth, FSplitterWidth);
end;  { TSplitter.GetSplitterRect }

procedure TSplitter.DrawSplitter;
var
  Canvas: TCanvas;
  Rect: TRect;
begin
  Canvas := TCanvas.Create;
  Canvas.Handle := GetDCEx(Handle, 0, DCX_CACHE or DCX_CLIPSIBLINGS or
    DCX_CLIPCHILDREN);
  try
    Rect := GetSplitterRect;
    Canvas.Brush.Color := Color;
    if (Style = ssStandard) then with Canvas do begin
      if (FKind = skVertical) then begin
        Pen.Color := clBtnFace;
        MoveTo(FSplitterPos, 0); LineTo(FSplitterPos, ClientHeight);
        Pen.Color := clWhite;
        MoveTo(FSplitterPos + 1, 0); LineTo(FSplitterPos + 1, ClientHeight);
        Pen.Color := clBtnShadow;
        MoveTo(FSplitterPos + FSplitterWidth - 2, 0);
        LineTo(FSplitterPos + FSplitterWidth - 2, ClientHeight);
        Pen.Color := clBlack;
        MoveTo(FSplitterPos + FSplitterWidth - 1, 0);
        LineTo(FSplitterPos + FSplitterWidth - 1, ClientHeight);
        InflateRect(Rect, -2, 0);
      end else begin
        Pen.Color := clBtnFace;
        MoveTo(0, FSplitterPos); LineTo(ClientWidth, FSplitterPos);
        Pen.Color := clWhite;
        MoveTo(0, FSplitterPos + 1); LineTo(ClientWidth, FSplitterPos + 1);
        Pen.Color := clBtnShadow;
        MoveTo(0, FSplitterPos + FSplitterWidth - 2);
        LineTo(ClientWidth, FSplitterPos + FSplitterWidth - 2);
        Pen.Color := clBlack;
        MoveTo(0, FSplitterPos + FSplitterWidth - 1);
        LineTo(ClientWidth, FSplitterPos + FSplitterWidth - 1);
        InflateRect(Rect, 0, -2);
      end;
      Canvas.FillRect(Rect);
    end else if Assigned(FOnDrawSplitter) then
      FOnDrawSplitter(Self, Canvas, Rect);
  finally
    ReleaseDC(Handle, Canvas.Handle);
    Canvas.Free;
  end;
end;  { TSplitter.DrawSplitter }

procedure TSplitter.DrawSizingLine(Pos: Integer);
begin
  Inc(Pos, FSplitterWidth div 2);
  if (FKind = skVertical) then begin
    MoveToEx(DC, Pos, 0, nil);
    LineTo(DC, Pos, ClientHeight);
  end else begin
    MoveToEx(DC, 0, Pos, nil);
    LineTo(DC, ClientWidth, Pos);
  end;
end;  { TSplitter.DrawSizingLine }

procedure TSplitter.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Split then begin
    Dragging := true;
    OldFocus := WinProcs.SetFocus(Handle);
    OldSplitterPos := FSplitterPos;
    DragPos := FSplitterPos;
    if (FKind = skVertical) then
      DragOffset := X - FSplitterPos
    else
      DragOffset := Y - FSplitterPos;
    if not FFullDrag then begin
      DC := GetDCEx(Handle, 0, DCX_CACHE or DCX_CLIPSIBLINGS);
      if (FSplitterWidth < 4) then
        OldPen := SelectObject(DC, CreatePen(PS_SOLID,FSplitterWidth,0))
      else
        OldPen := SelectObject(DC, CreatePen(PS_SOLID,FSplitterWidth - 2,0));
      SetROP2(DC, R2_NOT);
      DrawSizingLine(DragPos);
    end;
  end;
end;  { TSplitter.MouseDown }

procedure TSplitter.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if Dragging then begin
    DrawSizingLine(DragPos);
    if (FKind = skVertical) then
      DragPos := X - DragOffset
    else
      DragPos := Y - DragOffset;
    if (DragPos < 0) then DragPos := 0;
    if (DragPos > MaxSplitPos - FSplitterWidth) then
      DragPos := MaxSplitPos - FSplitterWidth;
    if Assigned(FOnResizing) then FOnResizing(Self, DragPos);
    if FFullDrag then
      SetSplitterPos(DragPos)
    else
      DrawSizingLine(DragPos);
  end else if not (csDesigning in ComponentState) and FAllowSplit then begin
    if (FKind = skVertical) then
      Split := (X >= FSplitterPos) and (X <= FSplitterPos + FSplitterWidth)
    else
      Split := (Y >= FSplitterPos) and (Y <= FSplitterPos + FSplitterWidth);
    if Split then
      Cursor := SplitCursor[FKind]
    else
      Cursor := crDefault;
  end;
end;  { TSplitter.MouseMove }

procedure TSplitter.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if Dragging then begin
    Dragging := false;
    if not FFullDrag then begin
      DrawSizingLine(DragPos);
      DeleteObject(SelectObject(DC,OldPen));
      ReleaseDC(Handle, DC);
    end;
    SplitterPos := DragPos;
    WinProcs.SetFocus(OldFocus);
    if Assigned(FOnResized) then
      FOnResized(Self, DragPos);
  end;
end;  { TSplitter.MouseUp }

procedure TSplitter.WMChar(var Msg: TWMChar);
begin
  if (Msg.CharCode = VK_ESCAPE) and Dragging then begin
    Dragging := false;
    ReleaseCapture;
    if FFullDrag then
      SetSplitterPos(OldSplitterPos)
    else begin
      DrawSizingLine(DragPos);
      DeleteObject(SelectObject(DC,OldPen));
      ReleaseDC(Handle, DC);
    end;
    WinProcs.SetFocus(OldFocus);
  end;
end;  { TSplitter.WMChar }

end.
