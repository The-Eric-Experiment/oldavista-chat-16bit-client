unit Main;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, WSocket, IrcTags, FatThing, ExtCtrls, ProtocolMessages,
  Readhtml, Htmlview, StrmBldr;

type
  PUser = ^RUser;

type
  TMainForm = class(TForm)
    CommSocket: TWSocket;
    MessagePanel: TPanel;
    EditMessage: TEdit;
    BtnSend: TButton;
    Panel2: TPanel;
    StatusPanel: TPanel;
    Panel4: TPanel;
    Separator: TPanel;
    UsersList: TListBox;
    LblUserTo: TLabel;
    CkPrivately: TCheckBox;
    CmbSpeechMode: TComboBox;
    MsgHtmlViewer: THTMLViewer;
    BtnSaveChat: TButton;
    procedure BtnSendClick(Sender: TObject);
    procedure CommSocketDataAvailable(Sender: TObject; ErrCode: Word);
    procedure CommSocketSessionConnected(Sender: TObject; ErrCode: Word);
    procedure CommSocketSessionClosed(Sender: TObject; ErrCode: Word);
    procedure CommSocketSocksConnected(Sender: TObject; ErrCode: Word);
    procedure FormActivate(Sender: TObject);
    procedure UsersListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ProcessColorList(Msg: PChar);
    procedure ProcessRoomListStart;
    procedure ProcessRoomListEnd;
    procedure ProcessRoomListItem(Msg: PChar);
    procedure ProcessUserRegistrationSuccess(Msg: PChar);
    procedure ProcessUserListAdd(Msg: PChar);
    procedure ProcessUserListRemove(Msg: PChar);
    procedure ProcessMessage(Msg: PChar);
    procedure ProcessMessageSent(Msg: PChar);
    procedure Login;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure EditMessageKeyPress(Sender: TObject; var Key: Char);
    procedure SendMessage(Sender: TObject);
    procedure InitializeStream;
    procedure FinalizeStream;
    procedure AppendMessageToViewer(Msg: RServerChatMessage);
    procedure BtnSaveChatClick(Sender: TObject);
    procedure UsersListDblClick(Sender: TObject);
    procedure CommSocketSocksError(Sender: TObject; Error: Integer;
      Msg: String);
    procedure CommSocketError(Sender: TObject);
    procedure SetStatus(Status: String);
    procedure SetChatEnabled(Val: Boolean);
  private
    RoomNames    : TStringList;
    RoomIds      : TStringList;
    FRcvBuf      : array [0..8191] of char;
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
  ChatMessageStream: TMemoryStream;
  SelectedUserTo: PUser;

 
implementation

uses ConnDiag;

{$R *.DFM}

procedure TMainForm.InitializeStream;
const
  HtmlStart: string = '<html><body marginheight="0" marginwidth="0">';
var
  HtmlStartBuffer: PChar;
begin
  { Initialize the memory stream only once }
  if not Assigned(ChatMessageStream) then
  begin
    ChatMessageStream := TMemoryStream.Create;
    GetMem(HtmlStartBuffer, Length(HtmlStart) + 1);
    try
      StrPCopy(HtmlStartBuffer, HtmlStart);
      ChatMessageStream.Write(HtmlStartBuffer^, Length(HtmlStart));  { Use Length instead of StrLen for accurate byte count }
    finally
      FreeMem(HtmlStartBuffer, Length(HtmlStart) + 1);
    end;
  end;
end;

procedure TMainForm.FinalizeStream;
begin
  { Free the memory stream when done }
  if Assigned(ChatMessageStream) then
  begin
    ChatMessageStream.Free;
    ChatMessageStream := nil;
  end;
end;

procedure TMainForm.SetStatus(Status: String);
begin
  StatusPanel.Caption := Status;
end;

procedure TMainForm.SetChatEnabled(Val: Boolean);
begin
  UsersList.Enabled := Val;
  EditMessage.Enabled := Val;
  BtnSend.Enabled := Val;
  MsgHtmlViewer.Enabled := Val;
  CkPrivately.Enabled := Val;
  CmbSpeechMode.Enabled := Val;
  LblUserTo.Enabled := Val;
end;

procedure TMainForm.AppendMessageToViewer(Msg: RServerChatMessage);
var
  StringBuilder: TStringStreamBuilder;
  Stream: TMemoryStream;
  UserColor, SystemMessageReplacement: string;
  Position: Integer;

  function GetUserByID(UserID: string): PUser;
  var
    I: Integer;
  begin
    Result := nil;
    for I := 0 to ChatUsers.Count - 1 do
      if PUser(ChatUsers[I])^.UserID = UserID then
      begin
        Result := PUser(ChatUsers[I]);
        Exit;
      end;

    { Check if the ID matches the current user }
    if CurrentUser.UserID = UserID then
      Result := @CurrentUser;
  end;

begin
  StringBuilder := TStringStreamBuilder.Create;
  try
    StringBuilder.Append('<br />');
    { If the message is directed to the current user, start the table wrapper }
    if (Msg.ToUser <> nil) and (Msg.ToUser^.UserID = CurrentUser.UserID) then
    begin
      StringBuilder.Append('<table bgcolor="#E0E0E0" border="1" ');
      StringBuilder.Append('bordercolor="#DDDDDD" width="100%" ');
      StringBuilder.Append('cellspacing="0" cellpadding="2"><tr><td>');
    end;

    { Start building the HTML content }
    StringBuilder.Append('<font color="#DDDDDD">');
    StringBuilder.Append('[' + Msg.Time + '] ');
    StringBuilder.Append('</font>');

    if not Msg.IsSystemMessage then
    begin
      { Handle different speech modes }
      if Msg.SpeechMode = 'says-to' then
      begin
        StringBuilder.Append('<strong>');
        if Msg.FromUser = nil then
          StringBuilder.Append('Everyone')
        else
          StringBuilder.Append('<font color="' + Msg.FromUser^.Color + '">' + 
            Msg.FromUser^.Nickname + '</font>');
        StringBuilder.Append('</strong> ');

        if Msg.Privately then
          StringBuilder.Append('privately ');

        StringBuilder.Append('</i>says to</i> ');

        StringBuilder.Append('<strong>');
        if Msg.ToUser = nil then
          StringBuilder.Append('Everyone')
        else
          StringBuilder.Append('<font color="' + Msg.ToUser^.Color + '">' + 
            Msg.ToUser^.Nickname + '</font>');
        StringBuilder.Append('</strong> : ');

        StringBuilder.Append(Msg.Message);
      end
      else if Msg.SpeechMode = 'screams-at' then
      begin
        StringBuilder.Append('<strong>');
        if Msg.FromUser = nil then
          StringBuilder.Append('Everyone')
        else
          StringBuilder.Append('<font color="' + Msg.FromUser^.Color + '">' + 
            Msg.FromUser^.Nickname + '</font>');
        StringBuilder.Append('</strong> ');

        StringBuilder.Append('</i>screams at</i> ');

        StringBuilder.Append('<strong>');
        if Msg.ToUser = nil then
          StringBuilder.Append('Everyone')
        else
          StringBuilder.Append('<font color="' + Msg.ToUser^.Color + '">' + 
            Msg.ToUser^.Nickname + '</font>');
        StringBuilder.Append('</strong> : ');

        StringBuilder.Append('<strong>' + Msg.Message + '</strong>');
      end
      else if Msg.SpeechMode = 'whispers-to' then
      begin
        StringBuilder.Append('<strong>');
        if Msg.FromUser = nil then
          StringBuilder.Append('Everyone')
        else
          StringBuilder.Append('<font color="' + Msg.FromUser^.Color + '">' + 
            Msg.FromUser^.Nickname + '</font>');
        StringBuilder.Append('</strong> ');

        StringBuilder.Append('</i>whispers to</i> ');

        StringBuilder.Append('<strong>');
        if Msg.ToUser = nil then
          StringBuilder.Append('Everyone')
        else
          StringBuilder.Append('<font color="' + Msg.ToUser^.Color + '">' + 
            Msg.ToUser^.Nickname + '</font>');
        StringBuilder.Append('</strong> : ');

        StringBuilder.Append('</i>' + Msg.Message + '</i>');
      end;
    end
    else
    begin
      SystemMessageReplacement := Msg.Message;
      Position := Pos('{nickname}', SystemMessageReplacement);
      while Position > 0 do
        if Msg.SystemMessageSubject <> nil then
        begin
          Delete(SystemMessageReplacement, Position, 10);
          Insert('<font color="' + Msg.SystemMessageSubject^.Color + '">' + 
            Msg.SystemMessageSubject^.Nickname + '</font>', SystemMessageReplacement, Position);
          Position := Pos('{nickname}', SystemMessageReplacement);
        end;
      StringBuilder.Append(SystemMessageReplacement);
    end;

    { If the message is directed to the current user, close the table wrapper }
    if (Msg.ToUser <> nil) and (Msg.ToUser^.UserID = CurrentUser.UserID) then
      StringBuilder.Append('</td></tr></table>');

    Stream := StringBuilder.GetStream;

    { Ensure ChatMessageStream is initialized }
    if not Assigned(ChatMessageStream) then
      ChatMessageStream := TMemoryStream.Create;

    { Move to the end of ChatMessageStream before appending }
    ChatMessageStream.Position := ChatMessageStream.Size;

    { Append the content from StringBuilder's stream }
    ChatMessageStream.CopyFrom(Stream, Stream.Size);

    { Load the final stream into the HTML viewer }
    Self.MsgHtmlViewer.LoadFromStream(ChatMessageStream);

    { Ensure scrollbar is correctly positioned at the end }
    Self.MsgHtmlViewer.VScrollBarPosition := 
      Self.MsgHtmlViewer.VScrollBarRange;
  finally
    StringBuilder.Free;
    FreeServerChatMessage(Msg);
  end;
end;


procedure TMainForm.SendMessage(Sender: TObject);
var Msg: String;
var MessageRec: RMessage;
var SpchMode: String;
begin
  case CmbSpeechMode.ItemIndex of
    0: SpchMode := 'says-to';
    1: SpchMode := 'screams-at';
    2: SpchMode := 'whispers-to';
  else
    SpchMode := 'says-to';
  end;

  with MessageRec do
  begin
    UserID := CurrentUser.UserID;

    if (SelectedUserTo <> nil) then
      UserTo := SelectedUserTo^.UserID
    else
      UserTo := '';

    SpeechMode := SpchMode;
    Message := EditMessage.Text;
    Privately := CkPrivately.Checked;
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

procedure TMainForm.ProcessColorList(Msg: PChar);
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
  if Assigned(ConnectionDialog) and (ConnectionDialog.Visible) then
    Exit;

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

procedure TMainForm.ProcessRoomListItem(Msg: PChar);
var
  ListItem: RRoomListItem;
begin
  ListItem := ParseRoomListItemMessage(Msg);
  RoomNames.Add(ListItem.Name);
  RoomIds.Add(ListItem.RoomId);
end;

procedure TMainForm.ProcessUserRegistrationSuccess(Msg: PChar);
var
  UserItem: PUser;
begin
  New(UserItem);

  CurrentUser := ParseServerUserRegistrationSuccessMessage(Msg);

  with (UserItem^) do
  begin
    UserID := '';
    Nickname := 'Everyone';
    Color := '#000000';
    RoomID := CurrentUser.RoomID;
  end;

  UsersList.Items.Insert(0, UserItem^.Nickname);
  ChatUsers.Insert(0, UserItem);

  SetChatEnabled(True);

  UsersList.ItemIndex := 0;
end;

procedure TMainForm.ProcessUserListAdd(Msg: PChar);
var
  UserItem: PUser;
begin
  New(UserItem);
  UserItem^ := ParseUserAddMessage(Msg);
  ChatUsers.Add(UserItem);
  UsersList.Items.Add(UserItem^.Nickname);
end;

procedure TMainForm.ProcessUserListRemove(Msg: PChar);
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

procedure TMainForm.ProcessMessageSent(Msg: PChar);
var
  ChatMessage: RServerChatMessage;
begin
  ChatMessage := ParseServerChatMessageSentMessage(Msg);
  AppendMessageToViewer(ChatMessage);
end;

procedure TMainForm.ProcessMessage(Msg: PChar);
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

procedure TMainForm.CommSocketDataAvailable(Sender: TObject; ErrCode: Word);
var
  Len, I, J: Integer;
  messageBuffer: PChar;
  bufferSize, oldBufferSize: Integer;
  messageBufferLen: Integer;
begin
  if CommSocket.State = wsClosed then
  begin
    CommSocketSessionClosed(Sender, ErrCode);
    Exit;
  end;

  { Set an initial buffer size }
  bufferSize := 1024;
  GetMem(messageBuffer, bufferSize);
  messageBuffer[0] := #0; { Initialize the buffer to be an empty string }
  messageBufferLen := 0;

  { Receive the data that has arrived, put it after the data already here }
  Len := TWSocket(Sender).Receive(@FRcvBuf[FRcvCnt], SizeOf(FRcvBuf) - FRcvCnt - 1);
  if Len <= 0 then
  begin
    FreeMem(messageBuffer, bufferSize);
    Exit;
  end;

  { Update our counter }
  FRcvCnt := FRcvCnt + Len;
  { Place a null byte at the end of the buffer }
  FRcvBuf[FRcvCnt] := #0;

  I := 0;
  while I < FRcvCnt do
    if FRcvBuf[I] = #13 then
    begin
      { Concatenate characters up to this point into the messageBuffer }
      for J := 0 to I - 1 do
        if FRcvBuf[J] <> #0 then
        begin
          if messageBufferLen + 1 >= bufferSize then
          begin
            { Expand the buffer if necessary }
            oldBufferSize := bufferSize;
            bufferSize := bufferSize * 2;
            ReallocMem(messageBuffer, oldBufferSize, bufferSize);
          end;
          messageBuffer[messageBufferLen] := FRcvBuf[J];
          Inc(messageBufferLen);
        end;

      { Null-terminate the messageBuffer }
      messageBuffer[messageBufferLen] := #0;

      { Process the complete message }
      Self.ProcessMessage(messageBuffer);

      { Move the remaining data in the buffer to the beginning }
      Move(FRcvBuf[I + 2], FRcvBuf[0], FRcvCnt - I - 2);
      FRcvCnt := FRcvCnt - I - 2; { Adjust the count for the remaining data }

      { Null-terminate the remaining buffer again for safety }
      FRcvBuf[FRcvCnt] := #0;

      { Reset the index to start processing from the beginning }
      I := 0;
      messageBufferLen := 0;
    end
    else
      Inc(I);

  { Free the allocated memory for the message buffer }
  FreeMem(messageBuffer, bufferSize);
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
  if (Shown = False) and (CommSocket.State = wsConnected) then
    Self.Login;


  if (CommSocket.State = wsConnected) then
    SetStatus('Connected!');

end;

procedure TMainForm.CommSocketSessionClosed(Sender: TObject;
  ErrCode: Word);
begin
  SetStatus('Disconnected...');
  SetChatEnabled(False);
end;

procedure TMainForm.CommSocketSocksConnected(Sender: TObject;
  ErrCode: Word);
begin
  SetStatus('Connected1...');
end;

procedure TMainForm.FormActivate(Sender: TObject);
var
  L: TFatLine;
  P: TFatPart;
begin
  CmbSpeechMode.ItemIndex := 0;
  SetChatEnabled(False);

  if CommSocket.State = wsClosed then
  begin
    CommSocket.SocksLevel := '5';

    CommSocket.SocksServer         := '';
    CommSocket.SocksPort           := '1080';
    CommSocket.Proto               := 'tcp';
    CommSocket.Addr                := '192.168.1.60';
    CommSocket.Port                := '8081';
    CommSocket.Connect;

    SetStatus('Connecting...');
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
      TextColor := HtmlToDelphiColor(UserItem^.Color)
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

  FinalizeStream;
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

procedure TMainForm.BtnSaveChatClick(Sender: TObject);
const
  HtmlEnd: string = '</body></html>';
var
  HtmlEndBuffer: PChar;
  FileStream: TFileStream;
  CurrentPosition: Integer;
begin
  if Assigned(ChatMessageStream) then
  begin
    { Temporarily add the closing HTML tags for saving }
    GetMem(HtmlEndBuffer, Length(HtmlEnd) + 1);
    try
      StrPCopy(HtmlEndBuffer, HtmlEnd);
      CurrentPosition := ChatMessageStream.Position;
      ChatMessageStream.Position := ChatMessageStream.Size;
      ChatMessageStream.Write(HtmlEndBuffer^, StrLen(HtmlEndBuffer));

      { Save the stream content to a file }
      FileStream := TFileStream.Create('c:\src\chat.html', fmCreate);
      try
        ChatMessageStream.Position := 0; { Reset the stream position to the beginning }
        FileStream.CopyFrom(ChatMessageStream, ChatMessageStream.Size);
      finally
        FileStream.Free;
      end;

      { Remove the temporarily added closing HTML tags }
      ChatMessageStream.SetSize(CurrentPosition);
    finally
      FreeMem(HtmlEndBuffer, Length(HtmlEnd) + 1);
    end;
  end;
end;

procedure TMainForm.UsersListDblClick(Sender: TObject);
begin
  SelectedUserTo := PUser(ChatUsers[UsersList.ItemIndex]);
  LblUserTo.Caption := SelectedUserTo^.Nickname;
  LblUserTo.Font.Color := HtmlToDelphiColor(SelectedUserTo^.Color);
end;

procedure TMainForm.CommSocketSocksError(Sender: TObject; Error: Integer;
  Msg: String);
begin
  ShowMessage('Socks Error man');  
end;

procedure TMainForm.CommSocketError(Sender: TObject);
begin
  ShowMessage('OnError Man..');
end;

end.
