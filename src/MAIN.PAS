
Unit Main;

Interface

Uses 
SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
Forms, Dialogs, StdCtrls, WSocket, ExtCtrls, ProtocolMessages, MMSystem,
Readhtml, Htmlview, StrmBldr, Buttons, Menus, About, AppMeta, Splitter;

Type 
  PUser = ^RUser;

Type 
  TMainForm = Class(TForm)
    CommSocket: TWSocket;
    MessagePanel: TPanel;
    EditMessage: TEdit;
    BtnSend: TButton;
    PnlStatusBar: TPanel;
    Separator: TPanel;
    LblUserTo: TLabel;
    CkPrivately: TCheckBox;
    CmbSpeechMode: TComboBox;
    MenuMain: TMainMenu;
    MenuGroupChat: TMenuItem;
    MenuGroupHelp: TMenuItem;
    MenuItemConnect: TMenuItem;
    MenuItemDisconnect: TMenuItem;
    N1: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuGroupMessages: TMenuItem;
    MenuItemAutoScroll: TMenuItem;
    MenuItemAbout: TMenuItem;
    SrvTimeCounter: TTimer;
    Splitter1: TSplitter;
    MsgHtmlViewer: THTMLViewer;
    UsersList: TListBox;
    Bevel1: TBevel;
    Panel1: TPanel;
    Bevel2: TBevel;
    LblConnection: TLabel;
    LblServerTime: TLabel;
    Procedure BtnSendClick(Sender: TObject);
    Procedure CommSocketDataAvailable(Sender: TObject; ErrCode: Word);
    Procedure CommSocketSessionConnected(Sender: TObject; ErrCode: Word);
    Procedure CommSocketSessionClosed(Sender: TObject; ErrCode: Word);
    Procedure CommSocketSocksConnected(Sender: TObject; ErrCode: Word);
    Procedure FormActivate(Sender: TObject);
    Procedure UsersListDrawItem(Control: TWinControl; Index: Integer;
                                Rect: TRect; State: TOwnerDrawState);
    Procedure ProcessServerError(Msg: PChar);
    Procedure ProcessColorList(Msg: PChar);
    Procedure ProcessRoomList(Msg: PChar);
    Procedure ProcessUserRegistrationSuccess(Msg: PChar);
    Procedure ProcessUserListAdd(Msg: PChar);
    Procedure ProcessUserListRemove(Msg: PChar);
    Procedure ProcessMessage(MessageType: Word; MessageLength: Word; MessageContent: PChar);
    Procedure ProcessMessageSent(Msg: PChar);
    Procedure ProcessUserKicked(Msg: PChar);
    Procedure ProcessServerTime(Msg: PChar);
    Procedure Login;
    Procedure FormDestroy(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormResize(Sender: TObject);
    Procedure EditMessageKeyPress(Sender: TObject; Var Key: Char);
    Procedure SendMessage(Sender: TObject);
    Procedure InitializeStream;
    Procedure FinalizeStream;
    Function SwapWord(Value: Word): Word;
    Procedure AppendMessageToViewer(Msg: RServerChatMessage);
    Procedure UsersListDblClick(Sender: TObject);
    Procedure SetStatus(Status: String);
    Procedure SetChatEnabled(Val: Boolean);
    Procedure OpenLoginModal;
    Procedure PlayNotificationSound(Msg: RServerChatMessage);
    Procedure MenuItemAboutClick(Sender: TObject);
    Procedure ConnectToServer;
    Procedure DisconnectFromServer;
    Procedure SetConnectionStatus(Connected: Boolean);
    Function GetStateMessage(WasConnectedMessge: String;
                             WasNotConnectedMessage: String): String;
    Procedure CommSocketSocksError(Sender: TObject; Error: Integer;
                                   Msg: String);
    Procedure CommSocketError(Sender: TObject);
    Procedure MenuItemConnectClick(Sender: TObject);
    Procedure MenuItemDisconnectClick(Sender: TObject);
    Procedure MenuItemAutoScrollClick(Sender: TObject);
    Procedure MenuItemExitClick(Sender: TObject);
    Function GetUserByID(UserID: String): PUser;
    Function GetUserIndexByID(UserID: String): Integer;
    Function GetRoomName(RoomID: String): String;
    Procedure SetRoomName(RoomName: String);
    procedure SetStartTimeFromString(const TimeStr: String);
    procedure SrvTimeCounterTimer(Sender: TObject);
    Private 
      RoomIds: TStringList;
      FReceiveBuffer: array [0..8191] Of char;
      FBufferedDataLength: Integer;
      ChatUsers: TList;
      LoginModalShown: Boolean;
      CurrentUser: PUser;
      CurrentRoom: String;
      ChatMessageStream: TMemoryStream;
      SelectedUserTo: PUser;
      IsLogginIn: Boolean;
      IsFirstMessage: Boolean;
      ReadyForNotifications: Boolean;
      IsKicked: Boolean;
      IsManualDisconnect: Boolean;
      ServerTime: TDateTime;
    Public 
    { Public declarations }
  End;


Var 
  MainForm: TMainForm;


Implementation

Uses ConnDiag;

{$R *.DFM}

Procedure TMainForm.InitializeStream;

Const 
  HtmlStart: string = '<html><body marginheight="0" marginwidth="0">';

Var 
  HtmlStartBuffer: PChar;
Begin
  { Initialize the memory stream only once }
  If Not Assigned(ChatMessageStream) Then
    Begin
      ChatMessageStream := TMemoryStream.Create;
      GetMem(HtmlStartBuffer, Length(HtmlStart) + 1);
      Try
        StrPCopy(HtmlStartBuffer, HtmlStart);
        ChatMessageStream.Write(HtmlStartBuffer^, Length(HtmlStart));
        { Use Length instead of StrLen for accurate byte count }
      Finally
        FreeMem(HtmlStartBuffer, Length(HtmlStart) + 1);
    End;
End;
End;

Procedure TMainForm.FinalizeStream;
Begin
  { Free the memory stream when done }
  If Assigned(ChatMessageStream) Then
    Begin
      ChatMessageStream.Free;
      ChatMessageStream := Nil;
    End;
End;

Procedure TMainForm.SetRoomName(RoomName: String);
Begin
  If RoomName = '' Then
    MainForm.Caption := 'Old''aVista Chat!'
  Else
    MainForm.Caption := '[' + RoomName + '] - Old''aVista Chat!';
End;

Procedure TMainForm.SetStatus(Status: String);
Begin
  LblConnection.Caption := Status;
End;

Procedure TMainForm.SetChatEnabled(Val: Boolean);

Var 
  I: Integer;
Begin
  UsersList.Enabled := Val;
  EditMessage.Enabled := Val;
  BtnSend.Enabled := Val;
  MsgHtmlViewer.Enabled := Val;                                                               
  CkPrivately.Enabled := Val;
  CmbSpeechMode.Enabled := Val;
  LblUserTo.Enabled := Val;
  MenuItemAutoScroll.Enabled := Val;

  If Val = False Then
    Begin
      IsFirstMessage := True;
      LoginModalShown := False;
      CurrentUser := Nil;
      CurrentRoom := '';
      SelectedUserTo := Nil;
      IsLogginIn := False;
      ReadyForNotifications := False;
      IsManualDisconnect := False;
      SetRoomName('');

      MsgHtmlViewer.Clear;

      If ChatUsers <> Nil Then
        For I := 0 To ChatUsers.Count - 1 Do
          Begin
            Dispose(PUser(ChatUsers[I]));
            UsersList.Items.Delete(I);
          End;

      LblUserTo.Caption := 'Everyone';
      LblUserTo.Font.Color := HtmlToDelphiColor('#000000');
      CkPrivately.Checked := False;
      CmbSpeechMode.ItemIndex := 0;

      ChatUsers.Free;
      ChatUsers := Nil;
      RoomIds.Free;
      RoomIds := Nil;

      FinalizeStream;
    End;
End;

Procedure TMainForm.PlayNotificationSound(Msg: RServerChatMessage);

Var 
  ActiveWindow: HWnd;
Begin
  ActiveWindow := GetActiveWindow;
  If ((Msg.FromUser <> Nil) And
     (Msg.FromUser^.UserID = CurrentUser^.UserID)) Or
     (Msg.IsSystemMessage) Or
     (Msg.IsHistory) Or
     (ActiveWindow = Handle) Or
     (Not ReadyForNotifications) Then
    Exit;

  sndPlaySound('notif.wav', SND_ASYNC Or SND_NODEFAULT);
End;

Function TMainForm.GetUserByID(UserID: String): PUser;

Var 
  I: Integer;
Begin
  Result := Nil;
  For I := 0 To ChatUsers.Count - 1 Do
    If PUser(ChatUsers[I])^.UserID = UserID Then
      Begin
        Result := PUser(ChatUsers[I]);
        Exit;
      End;

    { Check if the ID matches the current user }
  If CurrentUser^.UserID = UserID Then
    Result := CurrentUser;
End;

Function TMainForm.GetRoomName(RoomId: String): String;

Var 
  I: Integer;
Begin
  If (Not Assigned(RoomIds)) Or (RoomIds = Nil) Or (RoomIds.Count <= 0)
    Then
    Begin
      Result := '';
      Exit;
    End;

  Result := '';
  For I := 0 To RoomIds.Count - 1 Do
    If RoomIds[I] = RoomId Then
      Begin
        Result := ConnectionDialog.RoomSelector.Items[I];
        Exit;
      End;

  If Assigned(CurrentUser) And (CurrentUser^.UserID = RoomID) Then
    Result := '';
End;

Function TMainForm.GetUserIndexByID(UserID: String): Integer;

Var 
  I: Integer;
Begin
  If (Not Assigned(ChatUsers)) Or (ChatUsers = Nil) Or (ChatUsers.Count <= 0)
    Then
    Begin
      Result := -1;
      Exit;
    End;

  Result := -1; { Return -1 if the user is not found }
  For I := 0 To ChatUsers.Count - 1 Do
    If PUser(ChatUsers[I])^.UserID = UserID Then
      Begin
        Result := I;
        Exit;
      End;

  { Check if the ID matches the current user }
  If Assigned(CurrentUser) And (CurrentUser^.UserID = UserID) Then
    Result := -2; { Special case for current user, if needed }
End;

Procedure TMainForm.AppendMessageToViewer(Msg: RServerChatMessage);

Var 
  StringBuilder: TStringStreamBuilder;
  Stream: TMemoryStream;
  UserColor, SystemMessageReplacement: string;
  Position: Integer;

Begin
  StringBuilder := TStringStreamBuilder.Create;
  Try
    If Not IsFirstMessage Then
      StringBuilder.Append('<br /><br />')
    Else
      IsFirstMessage := False;


    { If the message is directed to the current user, start the table wrapper }
    If (Msg.ToUser <> Nil) And (Msg.ToUser^.UserID = CurrentUser^.UserID) Then
      Begin
        StringBuilder.Append('<table bgcolor="#E0E0E0" border="1" ');
        StringBuilder.Append('bordercolor="#DDDDDD" width="100%" ');
        StringBuilder.Append('cellspacing="0" cellpadding="2"><tr><td>');
      End;

    { Start building the HTML content }
    StringBuilder.Append('<font color="#777777" size="-2">');
    StringBuilder.Append('[' + Msg.Time + '] ');
    StringBuilder.Append('</font>');


    If Not Msg.IsSystemMessage Then
      Begin
        StringBuilder.Append('<font size="-1">');

        StringBuilder.Append('<strong>');

        If Msg.FromUser = Nil Then
          StringBuilder.Append('Everyone')
        Else
          StringBuilder.Append('<font color="' + Msg.FromUser^.Color + '">' +
                               Msg.FromUser^.Nickname + '</font>');

        StringBuilder.Append('</strong> ');

        If Msg.Privately Then
          StringBuilder.Append('privately ');

      { Handle different speech modes }
        If Msg.SpeechMode = 'says-to' Then
          StringBuilder.Append('says to ')
        Else If Msg.SpeechMode = 'screams-at' Then
               StringBuilder.Append('screams at ')
        Else If Msg.SpeechMode = 'whispers-to' Then
               StringBuilder.Append('whispers to<');

        StringBuilder.Append('<strong>');
        If Msg.ToUser = Nil Then
          StringBuilder.Append('Everyone')
        Else
          StringBuilder.Append('<font color="' + Msg.ToUser^.Color + '">' +
                               Msg.ToUser^.Nickname + '</font>');
        StringBuilder.Append('</strong>:');
        StringBuilder.Append('</font>');
        StringBuilder.Append('<br />');

        If Msg.SpeechMode = 'says-to' Then
          StringBuilder.Append(Msg.Message)
        Else If Msg.SpeechMode = 'screams-at' Then
               StringBuilder.Append('<font size="4"><strong>' + Msg.Message +
                                    '</strong></font>')
        Else If Msg.SpeechMode = 'whispers-to' Then
               StringBuilder.Append('<font size="-1"><i>' + Msg.Message +
                                    '</i></font>');
      End
    Else
      Begin
        SystemMessageReplacement := Msg.Message;
        Position := Pos('{nickname}', SystemMessageReplacement);
        While Position > 0 Do
          If Msg.SystemMessageSubject <> Nil Then
            Begin
              Delete(SystemMessageReplacement, Position, 10);
              Insert('<font color="' + Msg.SystemMessageSubject^.Color +
                     '"><strong>' +
                     Msg.SystemMessageSubject^.Nickname + '</strong></font>',
                     SystemMessageReplacement, Position);
              Position := Pos('{nickname}', SystemMessageReplacement);
            End;
        StringBuilder.Append(SystemMessageReplacement);
      End;

    { If the message is directed to the current user, close the table wrapper }
    If (Msg.ToUser <> Nil) And (Msg.ToUser^.UserID = CurrentUser^.UserID) Then
      StringBuilder.Append('</td></tr></table>');

    Stream := StringBuilder.GetStream;

    { Ensure ChatMessageStream is initialized }
    If Not Assigned(ChatMessageStream) Then
      ChatMessageStream := TMemoryStream.Create;

    { Move to the end of ChatMessageStream before appending }
    ChatMessageStream.Position := ChatMessageStream.Size;

    { Append the content from StringBuilder's stream }
    ChatMessageStream.CopyFrom(Stream, Stream.Size);

    { Load the final stream into the HTML viewer }
    Self.MsgHtmlViewer.LoadFromStream(ChatMessageStream);

    If MenuItemAutoScroll.Checked Then
      Self.MsgHtmlViewer.VScrollBarPosition := 
                                               Self.MsgHtmlViewer.
                                               VScrollBarRange;

    PlayNotificationSound(Msg);
  Finally
    StringBuilder.Free;
    FreeServerChatMessage(Msg);
End;
End;


Procedure TMainForm.SendMessage(Sender: TObject);
Var 
  Msg: PChar;       { The message to send, now PChar }
  MessageRec: RMessage;
  SpchMode: String;
  MsgLength: Word;
Begin
  If Length(EditMessage.Text) <= 0 Then
    Exit;

  { Set the speech mode based on the selection }
  Case CmbSpeechMode.ItemIndex Of 
    0: SpchMode := 'says-to';
    1: SpchMode := 'screams-at';
    2: SpchMode := 'whispers-to';
    Else
      SpchMode := 'says-to';
  End;

  { Fill the MessageRec structure }
  With MessageRec Do
    Begin
      UserID := CurrentUser^.UserID;

      If (SelectedUserTo <> Nil) Then
        UserTo := SelectedUserTo^.UserID
      Else
        UserTo := '';

      SpeechMode := SpchMode;
      Message := EditMessage.Text;
      Privately := CkPrivately.Checked;
      RoomID := CurrentRoom;
    End;

  { Create the message with the header and content }
  Msg := CreateSendMessageMessage(MessageRec, MsgLength);

  { Send the message through the socket }
  CommSocket.Send(Msg, MsgLength);

  { Free the allocated memory for the message }
  FreeMem(Msg, MsgLength);  { Free the memory using the correct size }

  { Clear the message input }
  EditMessage.Text := '';

  { Reset speech mode if necessary }
  If CmbSpeechMode.ItemIndex = 1 Then
    CmbSpeechMode.ItemIndex := 0;
End;

Procedure TMainForm.BtnSendClick(Sender: TObject);
Begin
  SendMessage(self);
End;

Procedure TMainForm.ProcessColorList(Msg: PChar);

Var 
  ColorList: RColorList;
Begin
  ColorList := ParseColorListMessage(Msg);
  ConnectionDialog.NicknameColors := ColorList.Colors;
  ConnectionDialog.ColorSelector.Items := ColorList.Names;
  ConnectionDialog.ColorSelector.ItemIndex := 0;

  OpenLoginModal;
End;

Procedure TMainForm.ProcessServerError(Msg: PChar);

Var 
  ServerErrorMsg: RServerError;
Begin
  ServerErrorMsg := ParseServerError(Msg);

  MessageDlg(ServerErrorMsg.Msg, mtError, [mbOK], 0);

  If IsLogginIn Then
    OpenLoginModal;
End;

Procedure TMainForm.OpenLoginModal;
Var 
  Result: TModalResult;
  Msg: PChar;
  MsgLength: Word;
Begin
  { Check if RoomIds and NicknameColors are assigned and non-empty }
  If (Not Assigned(RoomIds)) Or (RoomIds.Count <= 0) Or
     (Not Assigned(ConnectionDialog.NicknameColors)) Or
     (ConnectionDialog.NicknameColors.Count <= 0) Then
    Exit;

  IsLogginIn := True;
  Result := ConnectionDialog.ShowModal;
  If Result = mrOk Then
    Begin
      { Set the current room based on the user's selection }
      CurrentRoom := RoomIds[ConnectionDialog.RoomSelector.ItemIndex];

      { Create the register user message and receive the message length as output }
      Msg := CreateRegisterUserMessage(
               CurrentRoom,
               ConnectionDialog.NicknameEdit.Text,
               ConnectionDialog.NicknameColors[ConnectionDialog.ColorSelector.ItemIndex],
               MsgLength);  { MessageLength is now returned here }

      { Send the message through the socket }
      CommSocket.Send(Msg, MsgLength);

      { Free the allocated memory for the message }
      FreeMem(Msg, MsgLength);
    End
  Else
    Application.Terminate;

  LoginModalShown := True;
End;

Procedure TMainForm.ProcessRoomList(Msg: PChar);

Var 
  ListItem: RRoomList;
Begin
  If Assigned(RoomIds) Then
    RoomIds.Free;

  ListItem := ParseRoomListMessage(Msg);

  RoomIds := ListItem.RoomIds;

  If Assigned(ConnectionDialog) And (ConnectionDialog.Visible) Then
    Exit;

  ConnectionDialog.RoomSelector.Items := ListItem.Names;
  ConnectionDialog.RoomSelector.ItemIndex := 0;

  OpenLoginModal;
End;

Procedure TMainForm.ProcessUserRegistrationSuccess(Msg: PChar);

Var 
  UserItem: PUser;
  ParsedUser: RUser;
  ListIndex: Integer;
  RoomName: String;
Begin
  RoomName := GetRoomName(CurrentRoom);
  SetRoomName(RoomName);

  New(UserItem);

  ParsedUser := ParseServerUserRegistrationSuccessMessage(Msg);

  New(CurrentUser);
  CurrentUser^.UserID := ParsedUser.UserID;
  CurrentUser^.Nickname := ParsedUser.Nickname;
  CurrentUser^.Color := ParsedUser.Color;
  CurrentUser^.RoomID := ParsedUser.RoomID;

  With (UserItem^) Do
    Begin
      UserID := '';
      Nickname := 'Everyone';
      Color := '#000000';
      RoomID := CurrentUser^.RoomID;
    End;

  UsersList.Items.Insert(0, UserItem^.Nickname);

  If Not Assigned(ChatUsers) Then
    ChatUsers := TList.Create;

  ChatUsers.Insert(0, UserItem);

{Add (me) to username}
  ListIndex := GetUserIndexByID(ParsedUser.UserID);

  If ListIndex >= 0 Then
    UsersList.Items[ListIndex] := ParsedUser.Nickname + ' (Me)';

  SetChatEnabled(True);

  IsLogginIn := False;
  ReadyForNotifications := True;

  UsersList.ItemIndex := 0;
End;

Procedure TMainForm.ProcessUserListAdd(Msg: PChar);

Var 
  UserItem: PUser;
  ListNickname: String;
Begin
  New(UserItem);
  UserItem^ := ParseUserAddMessage(Msg);

  If Not Assigned(ChatUsers) Then
    ChatUsers := TList.Create;

  ListNickname := UserItem^.Nickname;

  If (Assigned(CurrentUser)) And (CurrentUser^.UserID = UserItem^.UserID) Then
    ListNickname := UserItem^.Nickname + ' (Me)';

  ChatUsers.Add(UserItem);
  UsersList.Items.Add(ListNickname);
End;

Procedure TMainForm.ProcessUserListRemove(Msg: PChar);

Var 
  UserItem: RUserRemove;
  I: Integer;
  P: PUser;
Begin
  If (Not Assigned(ChatUsers)) Or (ChatUsers = Nil) Or (ChatUsers.Count <= 0)
    Then
    Exit;

  UserItem := ParseUserRemoveMessage(Msg);

  If (Assigned(SelectedUserTo)) And (SelectedUserTo <> Nil) And (SelectedUserTo^
     .UserID = UserItem.UserID) Then
    Begin
      SelectedUserTo := PUser(ChatUsers[0]);
      LblUserTo.Caption := SelectedUserTo^.Nickname;
      LblUserTo.Font.Color := HtmlToDelphiColor(SelectedUserTo^.Color);
    End;

  I := GetUserIndexByID(UserItem.UserID);

  If I < 0 Then
    Exit;

  Dispose(PUser(ChatUsers[I]));
  ChatUsers.Delete(I);

  UsersList.Items.Delete(I);
End;

Procedure TMainForm.ProcessMessageSent(Msg: PChar);

Var 
  ChatMessage: RServerChatMessage;
Begin
  ChatMessage := ParseServerChatMessageSentMessage(Msg);
  AppendMessageToViewer(ChatMessage);
End;

Procedure TMainForm.ProcessUserKicked(Msg: PChar);

Var 
  KickMessage: RServerUserKickedMessage;
Begin
  KickMessage := ParseServerUserKickedMessage(Msg);
  IsKicked := True;
  DisconnectFromServer;

  MessageDlg(KickMessage.Reason, mtError, [mbOK], 0);
End;

Procedure TmainForm.ProcessServerTime(Msg: PChar);

Var 
  ServerTimeMessage: RServerTimeMessage;
Begin
  ServerTimeMessage := ParseServerTimeMessage(Msg);

  SetStartTimeFromString(ServerTimeMessage.Time);
End;

Procedure TMainForm.ProcessMessage(MessageType: Word; MessageLength: Word; MessageContent: PChar);
Begin
  { Handle the message based on its type }
  If MessageType = SERVER_ERROR Then
    ProcessServerError(MessageContent)
  Else If MessageType = SERVER_COLOR_LIST Then
         ProcessColorList(MessageContent)
  Else If MessageType = SERVER_ROOM_LIST Then
         ProcessRoomList(MessageContent)
  Else If MessageType = SERVER_USER_REGISTRATION_SUCCESS Then
         ProcessUserRegistrationSuccess(MessageContent)
  Else If MessageType = SERVER_USER_LIST_ADD Then
         ProcessUserListAdd(MessageContent)
  Else If MessageType = SERVER_USER_LIST_REMOVE Then
         ProcessUserListRemove(MessageContent)
  Else If MessageType = SERVER_MESSAGE_SENT Then
         ProcessMessageSent(MessageContent)
  Else If MessageType = SERVER_USER_KICKED Then
         ProcessUserKicked(MessageContent)
  Else If MessageType = SERVER_TIME Then
         ProcessServerTime(MessageContent);
End;


Function TMainForm.SwapWord(Value: Word): Word;
Begin
  Result := (Value Shr 8) Or (Value Shl 8);
End;

Procedure TMainForm.CommSocketDataAvailable(Sender: TObject; ErrCode: Word);
Var
  LReceivedLength, LBufferIndex: Integer;
  LMessageType, LMessageLength: Word;
  LHeaderSize: Integer;
  LMessageContent: PChar;
Begin
  If CommSocket.State = wsClosed Then
  Begin
    CommSocketSessionClosed(Sender, ErrCode);
    Exit;
  End;

  { Receive the data and append it to the existing buffer }
  LReceivedLength := TWSocket(Sender).Receive(@FReceiveBuffer[FBufferedDataLength], 
                    SizeOf(FReceiveBuffer) - FBufferedDataLength - 1);

  If LReceivedLength <= 0 Then Exit; { No data received }

  { Update buffer length }
  FBufferedDataLength := FBufferedDataLength + LReceivedLength;

  { Header size is 4 bytes: 2 bytes for message type, 2 bytes for message length }
  LHeaderSize := 4;
  LBufferIndex := 0;

  While LBufferIndex + LHeaderSize <= FBufferedDataLength Do
  Begin
    { Read the message type (2 bytes) }
    Move(FReceiveBuffer[LBufferIndex], LMessageType, 2);
    LMessageType := SwapWord(LMessageType); { Convert from network byte order }

    { Read the message length (2 bytes) }
    Move(FReceiveBuffer[LBufferIndex + 2], LMessageLength, 2);
    LMessageLength := SwapWord(LMessageLength);

    { Validate message length }
    If (LMessageLength = 0) Or (LMessageLength > (SizeOf(FReceiveBuffer) - LHeaderSize)) Then
    Begin
      { Invalid length, discard buffer }
      FBufferedDataLength := 0;
      Exit;
    End;

    { Check if the full message is available }
    If (LBufferIndex + LHeaderSize + LMessageLength) > FBufferedDataLength Then Break; 

    { Allocate memory for the message content, with a null terminator for safety }
    GetMem(LMessageContent, LMessageLength + 1);
    If LMessageContent = Nil Then Exit; { Memory allocation failed }

    { Clear the allocated memory to avoid any garbage characters or extra bytes }
    FillChar(LMessageContent^, LMessageLength + 1, 0);

    { Copy exactly LMessageLength bytes from the buffer to LMessageContent }
    Move(FReceiveBuffer[LBufferIndex + LHeaderSize], LMessageContent^, LMessageLength);

    { Pass the message to ProcessMessage (content passed as-is) }
    Self.ProcessMessage(LMessageType, LMessageLength, LMessageContent);

    { Free the allocated memory for the message content }
    FreeMem(LMessageContent, LMessageLength + 1);

    { Move the buffer index to the next message }
    Inc(LBufferIndex, LHeaderSize + LMessageLength);
  End;

  { Move any leftover data (incomplete message) to the beginning of the buffer }
  If LBufferIndex < FBufferedDataLength Then
  Begin
    Move(FReceiveBuffer[LBufferIndex], FReceiveBuffer[0], FBufferedDataLength - LBufferIndex);
    FBufferedDataLength := FBufferedDataLength - LBufferIndex;
  End
  Else
  Begin
    FBufferedDataLength := 0; { Reset buffer when all data is processed }
  End;
End;

Procedure TMainForm.Login;
Var
  Msg: PChar;
  MsgLength: Word;
Begin
  OpenLoginModal;

  If (Not Assigned(RoomIds)) Or (RoomIds.Count <= 0) Then
  Begin
    { Send the message with no payload (4-byte header only) }
    Msg := BuildMessageWithHeaderNoPayload(CLIENT_ROOM_LIST_REQUEST, MsgLength);
    CommSocket.Send(Msg, MsgLength);  { Send the message with the correct length }
    FreeMem(Msg, MsgLength);  { Free the allocated memory }
  End;

  If (Not Assigned(ConnectionDialog.NicknameColors)) Or (ConnectionDialog.NicknameColors.Count <= 0) Then
  Begin
    { Send the message with no payload (4-byte header only) }
    Msg := BuildMessageWithHeaderNoPayload(CLIENT_COLOR_LIST_REQUEST, MsgLength);
    CommSocket.Send(Msg, MsgLength);  { Send the message with the correct length }
    FreeMem(Msg, MsgLength);  { Free the allocated memory }
  End;
End;


Procedure TMainForm.CommSocketSessionConnected(Sender: TObject;
                                               ErrCode: Word);
Begin
  If (LoginModalShown = False) And (CommSocket.State = wsConnected) Then
    Self.Login;


  If (CommSocket.State = wsConnected) Then
    SetConnectionStatus(True);

End;

Function TMainForm.GetStateMessage(WasConnectedMessge: String;
                                   WasNotConnectedMessage: String): String;
Begin
  If MenuItemConnect.Enabled Then
    Result := WasNotConnectedMessage
  Else
    Result := WasConnectedMessge;
End;

Procedure TMainForm.CommSocketSessionClosed(Sender: TObject;
                                            ErrCode: Word);

Var 
  Error: String;
  Message: String;
Begin
  Error := WSocketErrorDesc(ErrCode);
  If Not IsKicked And Not IsManualDisconnect Then
    Begin
      If (Error = 'No Error') Or (Error = 'Socket is not connected')  Then
        Message := GetStateMessage('Connection with the server lost.',
                   'Could not connect to the server ' +
                   'at this time, try again later.');

      If (Message <> '') Then
        MessageDlg(Message, mtError, [mbOK], 0);
    End;

  SetConnectionStatus(False);
  SetChatEnabled(False);
End;

Procedure TMainForm.CommSocketSocksConnected(Sender: TObject;
                                             ErrCode: Word);
Begin
  SetConnectionStatus(True)
End;

Procedure TMainForm.SetConnectionStatus(Connected: Boolean);
Begin
  MenuItemConnect.Enabled := Not Connected;
  MenuItemDisconnect.Enabled := Connected;

  If Connected Then
    SetStatus('Connected!')
  Else
    SetStatus('Disconnected.')
End;

Procedure TMainForm.ConnectToServer;
Begin
  CmbSpeechMode.ItemIndex := 0;
  SetChatEnabled(False);

  If CommSocket.State = wsClosed Then
    Begin
      CommSocket.SocksLevel := '5';

      CommSocket.SocksServer         := '';
      CommSocket.SocksPort           := '1080';
      CommSocket.Proto               := 'tcp';
      CommSocket.Addr                := ServerURL;
      CommSocket.Port                := ServerPort;
      CommSocket.Connect;

      SetConnectionStatus(False);

      SetStatus('Connecting...');
    End;
End;

Procedure TMainForm.DisconnectFromServer;
Begin
  If CommSocket.State <> wsClosed Then
    Try
      CommSocket.Close;
    Except
      on E: Exception Do
            ShowMessage('Error closing socket: ' + E.Message);
End;
End;

Procedure TMainForm.FormActivate(Sender: TObject);
Begin
  ConnectToServer;
End;

Procedure TMainForm.UsersListDrawItem(Control: TWinControl; Index: Integer;
                                      Rect: TRect; State: TOwnerDrawState);

Var 
  TextColor: TColor;
  UserItem: PUser;
  TextHeightValue: Integer;
  TextTop: Integer;
  MainText: String;
  Icon: TIcon;
  IconLeft: Integer;
  IconRect: TRect;
Begin
  If (Not Assigned(ChatUsers)) Or (ChatUsers = Nil) Or (Index >= ChatUsers.Count
     ) Then
    Exit;

  UserItem := PUser(ChatUsers[Index]);

  With (Control as TListBox).Canvas Do
    Begin
    { Set background color }
      If odSelected In State Then
        Begin
          Brush.Color := HtmlToDelphiColor(UserItem^.Color);
          TextColor := clWhite;
        End
      Else
        Begin
          Brush.Color := UsersList.Color;
          TextColor := HtmlToDelphiColor(UserItem^.Color);
        End;

    { Fill the entire rectangle with the background color }
      FillRect(Rect);

    { Set the font color and remove any previous brush setting }
      Font.Color := TextColor;
      Brush.Style := bsClear;

    { Calculate the text height and adjust the vertical position }
      TextHeightValue := TextHeight('W');
      TextTop := Rect.Top + (Rect.Bottom - Rect.Top - TextHeightValue) Div 2;

    { Separate the main text from the "(Me)" part if it exists }
      MainText := (Control as TListBox).Items[Index];
      If (Length(MainText) >= 4) And (Copy(MainText, Length(MainText) - 3, 4) =
         '(Me)') Then
        Begin
          MainText := Copy(MainText, 1, Length(MainText) - 4);
          { Remove "(Me)" from the text }

      { Draw the main text without "(Me)" }
          TextOut(Rect.Left + 2, TextTop, MainText);

      { Load the 32x32 icon }
          Icon := TIcon.Create;
          Try
            Icon.LoadFromFile('me.ico');  { Load your 32x32 icon file }

        { Define the target rectangle for drawing the icon as 16x16 }
            IconLeft := Rect.Left + 2 + TextWidth(MainText);
            IconRect.Left := IconLeft;
            IconRect.Top := Rect.Top + (Rect.Bottom - Rect.Top - 16) Div 2;
            IconRect.Right := IconLeft + 16;
            IconRect.Bottom := IconRect.Top + 16;

        { Draw the icon cropped to 16x16 using StretchDraw }
            StretchDraw(IconRect, Icon);
          Finally
            Icon.Free;
        End;
    End
    Else
      Begin
      { Draw the main text normally if "(Me)" is not present }
        TextOut(Rect.Left + 2, TextTop, MainText);
      End;

    { Draw the focus rectangle if the item is focused }
  If odFocused In State Then
    DrawFocusRect(Rect);
End;
End;



Procedure TMainForm.FormDestroy(Sender: TObject);

Var 
  I: Integer;
Begin
  If CommSocket.State <> wsClosed Then
    Try
      CommSocket.Close;
    Except
      on E: Exception Do
            ShowMessage('Error closing socket: ' + E.Message);
End;

If (Assigned(ChatUsers)) And (ChatUsers <> Nil) Then
  For I := 0 To ChatUsers.Count - 1 Do
    Begin
      If (ChatUsers[I] <> Nil) Then
        Dispose(PUser(ChatUsers[I]));
    End;

ChatUsers.Free;
ChatUsers := Nil;
RoomIds.Free;
RoomIds := Nil;

FinalizeStream;
End;

Procedure TMainForm.FormCreate(Sender: TObject);
Begin
  If Not Assigned(RoomIds) Then
    RoomIds := TStringList.Create;

  If Not Assigned(ChatUsers) Then
    ChatUsers := TList.Create;

  IsLogginIn := False;
  IsFirstMessage := True;
  ReadyForNotifications := False;
  IsKicked := False;
  IsManualDisconnect := False;
End;

Procedure TMainForm.FormResize(Sender: TObject);

Var 
  ButtonSpace: Integer;
Begin
  BtnSend.Left := ClientWidth - BtnSend.Width - 3;
  EditMessage.Width := ClientWidth - (EditMessage.Left * 2) - BtnSend.Width - 4;
End;

Procedure TMainForm.EditMessageKeyPress(Sender: TObject; Var Key: Char);
Begin
  If Key = #13 Then
    Begin
      SendMessage(self);
      Key := #0;
    End;
End;

Procedure TMainForm.UsersListDblClick(Sender: TObject);
Begin
  SelectedUserTo := PUser(ChatUsers[UsersList.ItemIndex]);
  LblUserTo.Caption := SelectedUserTo^.Nickname;
  LblUserTo.Font.Color := HtmlToDelphiColor(SelectedUserTo^.Color);
End;

Procedure TMainForm.MenuItemAboutClick(Sender: TObject);
Begin
  AboutBox.ShowModal;
End;

Procedure TMainForm.CommSocketSocksError(Sender: TObject; Error: Integer;
                                         Msg: String);
Begin
  ShowMessage(Msg);
End;

Procedure TMainForm.CommSocketError(Sender: TObject);
Begin
     {Do nothing}
End;

Procedure TMainForm.MenuItemConnectClick(Sender: TObject);
Begin
  ConnectToServer;
End;

Procedure TMainForm.MenuItemDisconnectClick(Sender: TObject);
Begin
  IsManualDisconnect := True;
  DisconnectFromServer;
End;

Procedure TMainForm.MenuItemAutoScrollClick(Sender: TObject);
Begin
  MenuItemAutoScroll.Checked := Not MenuItemAutoScroll.Checked;
End;

Procedure TMainForm.MenuItemExitClick(Sender: TObject);
Begin
  IsManualDisconnect := True;
  DisconnectFromServer;
  Close;
End;

procedure TMainForm.SetStartTimeFromString(const TimeStr: String);
var
  Hour, Min, Sec: Integer;
  AmPm: String;
begin
  SrvTimeCounter.Enabled := False;
  { Extract hour, minute, second }
  Hour := StrToInt(Copy(TimeStr, 1, 2));
  Min  := StrToInt(Copy(TimeStr, 4, 2));
  Sec  := StrToInt(Copy(TimeStr, 7, 2));
  AmPm := Copy(TimeStr, 10, 2); { Extract AM/PM part }

  { Convert 12-hour format to 24-hour format }
  if (AmPm = 'PM') and (Hour < 12) then
    Hour := Hour + 12
  else if (AmPm = 'AM') and (Hour = 12) then
    Hour := 0; { Convert 12 AM to 00 }

  { Encode the time }
  ServerTime := EncodeTime(Hour, Min, Sec, 0);

  { Display the time in AM/PM format }
  LblServerTime.Caption := 'Server Time: ' + FormatDateTime('hh:nn:ss AM/PM', ServerTime);

  SrvTimeCounter.Enabled := True;
end;

procedure TMainForm.SrvTimeCounterTimer(Sender: TObject);
begin
  { Increment time by 1 second }
  ServerTime := ServerTime + (1 / 86400);

  { Display the time in AM/PM format }
  LblServerTime.Caption := 'Server Time: ' + FormatDateTime('hh:nn:ss AM/PM', ServerTime);
end;

End.
