unit Main;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, WSocket, FatThing, ExtCtrls, ProtocolMessages;

type
  TMainForm = class(TForm)
    CommSocket: TWSocket;
    Panel1: TPanel;
    ChatMemo: TFatMemo;
    EditMessage: TEdit;
    BtnConnect: TButton;
    BtnSend: TButton;
    Panel2: TPanel;
    StatusPanel: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    UsersList: TListBox;
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
    procedure CommSocketDataAvailable(Sender: TObject; ErrCode: Word);
    procedure CommSocketSessionConnected(Sender: TObject; ErrCode: Word);
    procedure CommSocketSessionClosed(Sender: TObject; ErrCode: Word);
    procedure CommSocketSocksConnected(Sender: TObject; ErrCode: Word);
    procedure CommSocketSendData(Sender: TObject; BytesSent: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure UsersListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ProcessMessage(Msg: String);
    procedure Login;
private
    RoomNames    : TStringList;
    RoomIds      : TStringList;
    FRcvBuf      : array [0..2047] of char;
    FRcvCnt      : Integer;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Shown: Boolean;

implementation

uses ConnDiag;

{$R *.DFM}

procedure TMainForm.BtnConnectClick(Sender: TObject);
begin
    CommSocket.SocksLevel := '5';
    ChatMemo.Lines.Add('Connecting using Socks' + CommSocket.SocksLevel);

    CommSocket.SocksServer         := '';
    CommSocket.SocksPort           := '1080';
    CommSocket.Proto               := 'tcp';
    CommSocket.Addr                := '192.168.1.60';
    CommSocket.Port                := '8886';
    CommSocket.Connect;
end;

procedure TMainForm.BtnSendClick(Sender: TObject);
begin
{     CommSocket.SendStr(EditMessage.Text);}
      ConnectionDialog.RoomSelector.Items := GetMessageAsList('10 Potato "Salad Stuff"');
end;

procedure TMainForm.ProcessMessage(Msg: String);
var
   Result: TModalResult;
   MessageType: String;
   ColorList: RColorList;
   ListItem: RRoomListItem;
begin
     MessageType := GetMessageType(Msg);

     if MessageType = SERVER_COLOR_LIST then
     begin
         ColorList := ParseColorListMessage(Msg);
         ConnectionDialog.ColorSelector.Items := ColorList.Colors;
         ConnectionDialog.ColorSelector.ItemIndex := 0;
     end
     else if MessageType = SERVER_ROOM_LIST_START then
     begin
          if Assigned(RoomNames) then
             RoomNames.Free;
          if Assigned(RoomIds) then
             RoomIds.Free;

          RoomNames := TStringList.Create;
          RoomIds := TStringList.Create;
     end
     else if MessageType = SERVER_ROOM_LIST_END then
     begin
          ConnectionDialog.RoomSelector.Items := RoomNames;
          ConnectionDialog.RoomSelector.ItemIndex := 0;
          Result := ConnectionDialog.ShowModal;
          if Result = mrOk then
             CommSocket.SendStr(
                           CreateRegisterUserMessage(
                           RoomIds[ConnectionDialog.RoomSelector.ItemIndex],
                           ConnectionDialog.NicknameEdit.Text,
                           ConnectionDialog.ColorSelector.Items[ConnectionDialog.ColorSelector.ItemIndex]))
          else
             Application.Terminate;
          Shown := True;
     end
     else if MessageType = SERVER_ROOM_LIST_ITEM then
     begin
          ListItem := ParseRoomListItemMessage(Msg);
          RoomNames.Add(ListItem.Name);
          RoomIds.Add(ListItem.RoomId);
     end
     else
         ShowMessage('Unknown Message');
end;

procedure TMainForm.CommSocketDataAvailable(Sender: TObject;
  ErrCode: Word);
var
    Len : Integer;
    I   : Integer;
    p   : PChar;
begin
    Len := TWSocket(Sender).Receive(@FRcvBuf[FRcvCnt], Sizeof(FRcvBuf) - FRcvCnt - 1);
    if Len < 0 then
        Exit;
    FRcvCnt := FRcvCnt + Len;
    FRcvBuf[FRcvCnt] := #0;

    while FRcvCnt > 0 do begin
        p := StrScan(FRcvBuf, #10);
        if p = nil then
            Exit;
        I := p - FRcvBuf;

        FRcvBuf[I] := #0;
        if (I > 0) and (FRcvBuf[I - 1] = #13) then
            FRcvBuf[I - 1] := #0;

        Self.ProcessMessage(StrPas(FRcvBuf));
        Move(FRcvBuf[I + 1], FRcvBuf[0], FRcvCnt - I);
        FRcvCnt := FRcvCnt - I - 1;
    end;
end;

procedure TMainForm.Login;
begin
     {Ask for colors}
     CommSocket.SendStr(CLIENT_COLOR_LIST_REQUEST);
     CommSocket.SendStr(CLIENT_ROOM_LIST_REQUEST);
end;

procedure TMainForm.CommSocketSessionConnected(Sender: TObject;
  ErrCode: Word);
begin
     if Shown = False then
     begin
        Self.Login;
     end;
     StatusPanel.Caption := 'Connected...';
end;

procedure TMainForm.CommSocketSessionClosed(Sender: TObject;
  ErrCode: Word);
begin
     StatusPanel.Caption := 'Disonnected...';
end;

procedure TMainForm.CommSocketSocksConnected(Sender: TObject;
  ErrCode: Word);
begin
     StatusPanel.Caption := 'Connected1...';
end;

procedure TMainForm.CommSocketSendData(Sender: TObject;
  BytesSent: Integer);
begin
  StatusPanel.Caption := 'Sending Stuff...';
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
   ChatMemo.Lines.Clear;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
     if CommSocket.State = wsClosed then
     begin
          CommSocket.SocksLevel := '5';
          ChatMemo.Lines.Add('Connecting using Socks' + CommSocket.SocksLevel);

          CommSocket.SocksServer         := '';
          CommSocket.SocksPort           := '1080';
          CommSocket.Proto               := 'tcp';
          CommSocket.Addr                := '192.168.1.60';
          CommSocket.Port                := '8886';
          CommSocket.Connect;
     end;
end;

procedure TMainForm.UsersListDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
     with (Control as TListBox).Canvas do
     begin
          if odSelected in State then
             Brush.Color := $00FFD2A6;

          FillRect(Rect);
          TextOut(Rect.Left, Rect.Top, (Control as TListBox).Items[Index]);
          if odFocused In State then begin
             Brush.Color := UsersList.Color;
             DrawFocusRect(Rect);
          end;
     end;
end;

end.
