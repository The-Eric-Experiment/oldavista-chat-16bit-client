unit Main;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, WSocket, IrcTags, FatThing, ExtCtrls, ProtocolMessages,
  Wait;

type
  PUser = ^RUser;

type
  TMainForm = class(TForm)
    CommSocket: TWSocket;
    MessagePanel: TPanel;
    ChatMemo: TFatMemo;
    EditMessage: TEdit;
    BtnSend: TButton;
    Panel2: TPanel;
    StatusPanel: TPanel;
    Panel4: TPanel;
    Separator: TPanel;
    UsersList: TListBox;
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
    procedure ProcessColorList(Msg: String);
    procedure ProcessRoomListStart;
    procedure ProcessRoomListEnd;
    procedure ProcessRoomListItem(Msg: String);
    procedure ProcessUserRegistrationSuccess(Msg: String);
    procedure ProcessUserListAdd(Msg: String);
    procedure ProcessUserListRemove(Msg: String);
    procedure ProcessMessageSent(Msg: String);
    procedure ProcessMessage(Msg: String);
    procedure Login;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure EditMessageKeyPress(Sender: TObject; var Key: Char);
    procedure SendMessage(Sender: TObject);
    procedure AddFormattedLine(Sender: TObject; ChatMemo: TFatMemo; const S: string);
  private
    RoomNames    : TStringList;
    RoomIds      : TStringList;
    FRcvBuf      : array [0..2047] of char;
    FRcvCnt      : Integer;
    ChatUsers    : TList;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Shown: Boolean;
  CurrentUser: RUser;
  CurrentRoom: String;

implementation

uses ConnDiag;

{$R *.DFM}

procedure TMainForm.AddFormattedLine(Sender: TObject; ChatMemo: TFatMemo; const S: string);
var
  L: TFatLine;
  P: TFatPart;
  I, Start: Integer;
  TextPart, Tag, Param: string;
  InTag: Boolean;

  procedure AddTextPiece(const AText: string);
  begin
    if AText <> '' then
    begin
      P := L.Add;
      P.Text := AText;
    end;
  end;

begin
  L := ChatMemo.Lines.AddNew;
  I := 1;
  Start := 1;
  InTag := False;

  while I <= Length(S) do
  begin
    if S[I] = '[' then
    begin
      AddTextPiece(Copy(S, Start, I - Start));
      Start := I + 1;
      InTag := True;
    end
    else if S[I] = ']' then
    begin
      Tag := Copy(S, Start, I - Start);
      Param := '';
      if Pos('=', Tag) > 0 then
      begin
        Param := Copy(Tag, Pos('=', Tag) + 1, Length(Tag));
        Tag := Copy(Tag, 1, Pos('=', Tag) - 1);
      end;
      Tag := UpperCase(Tag);

      {// Handle tags}
      if Tag = 'B' then
      begin
        P := L.Add;
        P.Style := [fsBold];
      end
      else if Tag = '/B' then
      begin
        P := L.Add;
        P.Style := [];
      end
      else if Tag = 'I' then
      begin
        P := L.Add;
        P.Style := [fsItalic];
      end
      else if Tag = '/I' then
      begin
        P := L.Add;
        P.Style := [];
      end
      else if Tag = 'U' then
      begin
        P := L.Add;
        P.Style := [fsUnderline];
      end
      else if Tag = '/U' then
      begin
        P := L.Add;
        P.Style := [];
      end
      else if Tag = 'C' then
      begin
        P := L.Add;
        P.FontColor := StringToColor(Param);
      end
      else if Tag = '/C' then
      begin
        P := L.Add;
        P.FontColor := clBlack;
      end
      else if Tag = 'L' then
      begin
        P := L.Add;
        P.Link := Param;
      end
      else if Tag = '/L' then
      begin
        P := L.Add;
        P.Link := '';
      end;

      Start := I + 1;
      InTag := False;
    end;
    Inc(I);
  end;

  AddTextPiece(Copy(S, Start, I - Start));
  ChatMemo.Invalidate;
end;

procedure TMainForm.SendMessage(Sender: TObject);
var Msg: String;
var MessageRec: RMessage;
begin
  with MessageRec do
  begin
    UserID := CurrentUser.UserID;
    UserTo := '';
    SpeechMode := 'says-to';
    Message := EditMessage.Text;
    Privately := False;
    RoomID := CurrentRoom;
  end;

  Msg := CreateSendMessageMessage(MessageRec);

  CommSocket.SendStr(Msg);
  EditMessage.Text := '';
end;

procedure TMainForm.BtnSendClick(Sender: TObject);
begin
  SendMessage(self);
end;

procedure TMainForm.ProcessColorList(Msg: String);
var
  ColorList: RColorList;
begin
  ColorList := ParseColorListMessage(Msg);
  ConnectionDialog.NicknameColors := ColorList.Colors;
  ConnectionDialog.ColorSelector.Items := ColorList.Names;
  ConnectionDialog.ColorSelector.ItemIndex := 0;
end;

procedure TMainForm.ProcessRoomListStart;
begin
  if Assigned(RoomNames) then
    RoomNames.Free;
  if Assigned(RoomIds) then
    RoomIds.Free;

  RoomNames := TStringList.Create;
  RoomIds := TStringList.Create;
end;

procedure TMainForm.ProcessRoomListEnd;
var
  Result: TModalResult;
begin
  ConnectionDialog.RoomSelector.Items := RoomNames;
  ConnectionDialog.RoomSelector.ItemIndex := 0;
  Result := ConnectionDialog.ShowModal;
  if Result = mrOk then
  begin
    CurrentRoom := RoomIds[ConnectionDialog.RoomSelector.ItemIndex];
    CommSocket.SendStr(
      CreateRegisterUserMessage(
      CurrentRoom,
      ConnectionDialog.NicknameEdit.Text,
      ConnectionDialog.NicknameColors[ConnectionDialog.ColorSelector.ItemIndex]));
  end
  else
    Application.Terminate;
  Shown := True;
end;

procedure TMainForm.ProcessRoomListItem(Msg: String);
var
  ListItem: RRoomListItem;
begin
  ListItem := ParseRoomListItemMessage(Msg);
  RoomNames.Add(ListItem.Name);
  RoomIds.Add(ListItem.RoomId);
end;

procedure TMainForm.ProcessUserRegistrationSuccess(Msg: String);
begin
  CurrentUser := ParseServerUserRegistratoinSuccessMessage(Msg);
  UsersList.Enabled := True;
  EditMessage.Enabled := True;
  BtnSend.Enabled := true;
end;

procedure TMainForm.ProcessUserListAdd(Msg: String);
var
  UserItem: PUser;
begin
  New(UserItem);
  UserItem^ := ParseUserAddMessage(Msg);
  ChatUsers.Add(UserItem);
  UsersList.Items.Add(UserItem^.Nickname);
end;

procedure TMainForm.ProcessUserListRemove(Msg: String);
var
  UserItem: RUserRemove;
  I: Integer;
  P: PUser;
begin
  UserItem := ParseUserRemoveMessage(Msg);

  for I := 0 to ChatUsers.Count - 1 do
  begin
    P := PUser(ChatUsers[I]);
    if P^.UserID = UserItem.UserID then
    begin
      Dispose(PUser(ChatUsers[I]));
      ChatUsers.Delete(I);

      UsersList.Items.Delete(I);

      Break;
    end;
  end;
end;

procedure TMainForm.ProcessMessageSent(Msg: String);
var
  ChatMessage: RServerChatMessage;
begin
  ChatMessage := ParseServerChatMessageSentMessage(Msg);
  AddFormattedLine(Self, ChatMemo, ChatMessage.Text);
end;

procedure TMainForm.ProcessMessage(Msg: String);
var
  MessageType: String;
begin
  MessageType := GetMessageType(Msg);

  if MessageType = SERVER_COLOR_LIST then
    ProcessColorList(Msg)
  else if MessageType = SERVER_ROOM_LIST_START then
    ProcessRoomListStart
  else if MessageType = SERVER_ROOM_LIST_END then
    ProcessRoomListEnd
  else if MessageType = SERVER_ROOM_LIST_ITEM then
    ProcessRoomListItem(Msg)
  else if MessageType = SERVER_USER_REGISTRATION_SUCCESS then
    ProcessUserRegistrationSuccess(Msg)
  else if MessageType = SERVER_USER_LIST_ADD then
    ProcessUserListAdd(Msg)
  else if MessageType = SERVER_USER_LIST_REMOVE then
    ProcessUserListRemove(Msg)
  else if MessageType = SERVER_MESSAGE_SENT then
    ProcessMessageSent(Msg)
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

  while FRcvCnt > 0 do
  begin
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
    Self.Login;
  StatusPanel.Caption := 'Session Rested...';
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
var
  L: TFatLine;
  P: TFatPart;
begin
  if CommSocket.State = wsClosed then
  begin
    CommSocket.SocksLevel := '5';
    ChatMemo.Lines.Add('Connecting using Socks Level ' + CommSocket.SocksLevel);


    CommSocket.SocksServer         := '';
    CommSocket.SocksPort           := '1080';
    CommSocket.Proto               := 'tcp';
    CommSocket.Addr                := '192.168.1.60';
    CommSocket.Port                := '8081';
    CommSocket.Connect;
  end;
end;

procedure TMainForm.UsersListDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  TextColor: TColor;
  UserItem: PUser;
begin
  with (Control as TListBox).Canvas do
  begin
    UserItem := PUser(ChatUsers[Index]);

    if Assigned(UserItem) then
      TextColor := StringToColor(UserItem^.Color)
    else
      TextColor := clBlack;

    if odSelected in State then
      Brush.Color := $00FFD2A6
    else
      Brush.Color := UsersList.Color;

    FillRect(Rect);
    Font.Color := TextColor;
    TextOut(Rect.Left, Rect.Top, (Control as TListBox).Items[Index]);


    if odFocused in State then DrawFocusRect(Rect){Brush.Color := UsersList.Color;};
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  if CommSocket.State <> wsClosed then
    try
      CommSocket.Close;
    except
      on E: Exception do
        ShowMessage('Error closing socket: ' + E.Message);
    end;

  for I := 0 to ChatUsers.Count - 1 do
    Dispose(PUser(ChatUsers[I]));
  ChatUsers.Free;
  RoomNames.Free;
  RoomIds.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RoomNames := TStringList.Create;
  RoomIds := TStringList.Create;
  ChatUsers := TList.Create;
end;

procedure TMainForm.FormResize(Sender: TObject);
var
  ButtonSpace: Integer;
begin
  BtnSend.Left := ClientWidth - BtnSend.Width - 3;
  EditMessage.Width := ClientWidth - (EditMessage.Left * 2) - BtnSend.Width - 4;
end;

procedure TMainForm.EditMessageKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    SendMessage(self);
    Key := #0;
  end;
end;

end.
