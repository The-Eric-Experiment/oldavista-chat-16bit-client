
Unit Main;

Interface

Uses 
SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
Forms, Dialogs, StdCtrls, WSocket, ExtCtrls, ProtocolMessages, MMSystem,
Readhtml, Htmlview, StrmBldr, GIFImage, Toolbar, Buttons, Menus, About;

Type 
  PUser = ^RUser;

Type 
  TMainForm = Class(TForm)
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
    Procedure ProcessMessage(Msg: PChar);
    Procedure ProcessMessageSent(Msg: PChar);
    Procedure ProcessUserKicked(Msg: PChar);
    Procedure Login;
    Procedure FormDestroy(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormResize(Sender: TObject);
    Procedure EditMessageKeyPress(Sender: TObject; Var Key: Char);
    Procedure SendMessage(Sender: TObject);
    Procedure InitializeStream;
    Procedure FinalizeStream;
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
    Private 
      RoomIds: TStringList;
      FRcvBuf: array [0..8191] Of char;
      FRcvCnt: Integer;
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

Procedure TMainForm.SetStatus(Status: String);
Begin
  StatusPanel.Caption := Status;
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

Procedure TMainForm.AppendMessageToViewer(Msg: RServerChatMessage);

Var 
  StringBuilder: TStringStreamBuilder;
  Stream: TMemoryStream;
  UserColor, SystemMessageReplacement: string;
  Position: Integer;

Function GetUserByID(UserID: String): PUser;

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

    { Ensure scrollbar is correctly positioned at the end }
    Self.MsgHtmlViewer.VScrollBarPosition := 
                                             Self.MsgHtmlViewer.VScrollBarRange;

    PlayNotificationSound(Msg);
  Finally
    StringBuilder.Free;
    FreeServerChatMessage(Msg);
End;
End;


Procedure TMainForm.SendMessage(Sender: TObject);

Var Msg: String;

Var MessageRec: RMessage;

Var SpchMode: String;
Begin
  Case CmbSpeechMode.ItemIndex Of 
    0: SpchMode := 'says-to';
    1: SpchMode := 'screams-at';
    2: SpchMode := 'whispers-to';
    Else
      SpchMode := 'says-to';
  End;

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

  Msg := CreateSendMessageMessage(MessageRec);

  CommSocket.SendStr(Msg);
  EditMessage.Text := '';
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
Begin
  If (Not Assigned(RoomIds)) Or
     (RoomIds.Count <= 0) Or
     (Not Assigned(ConnectionDialog.NicknameColors)) Or
     (ConnectionDialog.NicknameColors.Count <= 0) Then
    Exit;

  IsLogginIn := True;
  Result := ConnectionDialog.ShowModal;
  If Result = mrOk Then
    Begin
      CurrentRoom := RoomIds[ConnectionDialog.RoomSelector.ItemIndex];
      CommSocket.SendStr(
                         CreateRegisterUserMessage(
                         CurrentRoom,
                         ConnectionDialog.NicknameEdit.Text,
                         ConnectionDialog.NicknameColors[ConnectionDialog.
                         ColorSelector.ItemIndex]));
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
Begin
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

  SetChatEnabled(True);

  IsLogginIn := False;
  ReadyForNotifications := True;

  UsersList.ItemIndex := 0;
End;

Procedure TMainForm.ProcessUserListAdd(Msg: PChar);

Var 
  UserItem: PUser;
Begin
  New(UserItem);
  UserItem^ := ParseUserAddMessage(Msg);

  If Not Assigned(ChatUsers) Then
    ChatUsers := TList.Create;

  ChatUsers.Add(UserItem);
  UsersList.Items.Add(UserItem^.Nickname);
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

  If SelectedUserTo^.UserID = UserItem.UserID Then
    Begin
      SelectedUserTo := PUser(ChatUsers[0]);
      LblUserTo.Caption := SelectedUserTo^.Nickname;
      LblUserTo.Font.Color := HtmlToDelphiColor(SelectedUserTo^.Color);
    End;

  For I := 0 To ChatUsers.Count - 1 Do
    Begin
      P := PUser(ChatUsers[I]);
      If P^.UserID = UserItem.UserID Then
        Begin
          Dispose(PUser(ChatUsers[I]));
          ChatUsers.Delete(I);

          UsersList.Items.Delete(I);

          Break;
        End;
    End;
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

Procedure TMainForm.ProcessMessage(Msg: PChar);

Var 
  MessageType: String;
Begin
  MessageType := GetMessageType(Msg);

  If MessageType = SERVER_ERROR Then
    ProcessServerError(Msg)
  Else If MessageType = SERVER_COLOR_LIST Then
         ProcessColorList(Msg)
  Else If MessageType = SERVER_ROOM_LIST Then
         ProcessRoomList(Msg)
  Else If MessageType = SERVER_USER_REGISTRATION_SUCCESS Then
         ProcessUserRegistrationSuccess(Msg)
  Else If MessageType = SERVER_USER_LIST_ADD Then
         ProcessUserListAdd(Msg)
  Else If MessageType = SERVER_USER_LIST_REMOVE Then
         ProcessUserListRemove(Msg)
  Else If MessageType = SERVER_MESSAGE_SENT Then
         ProcessMessageSent(Msg)
  Else If MessageType = SERVER_USER_KICKED Then
         ProcessUserKicked(Msg)
  Else
    ShowMessage('Unknown Message');
End;

Procedure TMainForm.CommSocketDataAvailable(Sender: TObject; ErrCode: Word);

Var 
  Len, I, J: Integer;
  messageBuffer: PChar;
  bufferSize, oldBufferSize: Integer;
  messageBufferLen: Integer;
Begin
  If CommSocket.State = wsClosed Then
    Begin
      CommSocketSessionClosed(Sender, ErrCode);
      Exit;
    End;


  { Set an initial buffer size }
  bufferSize := 1024;
  GetMem(messageBuffer, bufferSize);
  messageBuffer[0] := #0;
          { Initialize the buffer to be an empty string }
  messageBufferLen := 0;

  { Receive the data that has arrived, put it after the data already here }
  Len := TWSocket(Sender).Receive(@FRcvBuf[FRcvCnt], SizeOf(FRcvBuf) -
         FRcvCnt -
         1);
  If Len <= 0 Then
    Begin
      FreeMem(messageBuffer, bufferSize);
      Exit;
    End;

  { Update our counter }
  FRcvCnt := FRcvCnt + Len;
  { Place a null byte at the end of the buffer }
  FRcvBuf[FRcvCnt] := #0;

  I := 0;
  While I < FRcvCnt Do
    If FRcvBuf[I] = #13 Then
      Begin
      { Concatenate characters up to this point into the messageBuffer }
        For J := 0 To I - 1 Do
          If FRcvBuf[J] <> #0 Then
            Begin
              If messageBufferLen + 1 >= bufferSize Then
                Begin
            { Expand the buffer if necessary }
                  oldBufferSize := bufferSize;
                  bufferSize := bufferSize * 2;
                  ReallocMem(messageBuffer, oldBufferSize, bufferSize);
                End;
              messageBuffer[messageBufferLen] := FRcvBuf[J];
              Inc(messageBufferLen);
            End;

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
      End
    Else
      Inc(I);

  { Free the allocated memory for the message buffer }
  FreeMem(messageBuffer, bufferSize);
End;


Procedure TMainForm.Login;
Begin
  OpenLoginModal;

  If (Not Assigned(RoomIds)) Or
     (RoomIds.Count <= 0) Then
    CommSocket.SendStr(CLIENT_ROOM_LIST_REQUEST);

  If (Not Assigned(ConnectionDialog.NicknameColors)) Or
     (ConnectionDialog.NicknameColors.Count <= 0) Then
    CommSocket.SendStr(CLIENT_COLOR_LIST_REQUEST);
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
      CommSocket.Addr                := '192.168.1.60';
      CommSocket.Port                := '8081';
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
Begin
  If (Not Assigned(ChatUsers)) Or (ChatUsers = Nil) Or (Index >= ChatUsers.Count) Then
    Exit;

  UserItem := PUser(ChatUsers[Index]);
  With (Control as TListBox).Canvas Do
    Begin


      If Assigned(UserItem) Then
        TextColor := HtmlToDelphiColor(UserItem^.Color)
      Else
        TextColor := clBlack;

      If odSelected In State Then
        Brush.Color := $00FFD2A6
      Else
        Brush.Color := UsersList.Color;

      FillRect(Rect);
      Font.Color := TextColor;
      TextOut(Rect.Left, Rect.Top, (Control as TListBox).Items[Index]);


      If odFocused In State Then DrawFocusRect(Rect)
        {Brush.Color := UsersList.Color;};
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

End.
