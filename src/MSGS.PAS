
Unit ProtocolMessages;

Interface

Uses 
SysUtils, Classes, PCharLst, Graphics;

Type 
  RServerError = Record
    Msg: String
  End;

  RColorList = Record
    Colors: TStringList;
    Names: TStringList;
  End;

  RRoomList = Record
    RoomIds: TStringList;
    Names: TStringList;
  End;

  RMessageType = Record
    MsgType: String;
    MsgContent: String;
  End;

  RUser = Record
    UserID: String;
    Nickname: String;
    Color: String;
    RoomID: String;
  End;

  PUser = ^RUser;

  RUserRemove = Record
    UserID: String;
    RoomID: String;
  End;

  RMessage = Record
    UserID: String;
    UserTo: String;
    SpeechMode: String;
    Message: String;
    Privately: Boolean;
    RoomID: String
  End;

  RServerChatMessage = Record
    RoomID: String;
    FromUser: PUser;
    ToUser: PUser;
    Privately: Boolean;
    SpeechMode: String;
    Time: String;
    IsSystemMessage: Boolean;
    SystemMessageSubject: PUser;
    IsHistory: Boolean;
    Message: String;
  End;

  RServerUserKickedMessage = Record
    Reason: String;
  End;

Const 
  SERVER_ERROR = '0';
  SERVER_COLOR_LIST = '1';
  SERVER_ROOM_LIST = '2';
  SERVER_USER_REGISTRATION_SUCCESS = '3';
  SERVER_USER_LIST_ADD = '4';
  SERVER_USER_LIST_REMOVE = '5';
  SERVER_USER_LIST_UPDATE = '6';
  SERVER_MESSAGE_SENT = '7';
  SERVER_USER_KICKED = '8';
  CLIENT_REGISTER_USER = '100';
  CLIENT_SEND_MESSAGE = '101';
  CLIENT_COLOR_LIST_REQUEST = '105';
  CLIENT_ROOM_LIST_REQUEST = '106';


Function GetMessageType(Value: PChar): String;
Function GetMessageAsList(Value: PChar; FullMessage: Boolean): TPCharList;
Function GetListField(Value: PChar): TStringList;
Function Quotation(Input: String): String;
Function ParseServerError(Content: PChar): RServerError;
Function ParseColorListMessage(Content: PChar): RColorList;
Function ParseRoomListMessage(Content: PChar): RRoomList;
Function ParseServerUser(Content: PChar; FullMessage: Boolean): RUser;
Function ParseUserAddMessage(Content: PChar): RUser;
Function ParseUserRemoveMessage(Content: PChar): RUserRemove;
Function ParseServerUserRegistrationSuccessMessage(Content: PChar): RUser;
Function ParseServerChatMessageSentMessage(Content: PChar): RServerChatMessage;
Function ParseServerUserKickedMessage(Content: PChar): RServerUserKickedMessage;
Function CreateRegisterUserMessage (RoomId: String; Nickname: String; Color:
                                    String): String;
Function CreateSendMessageMessage(Msg: RMessage): String;
Function HtmlToDelphiColor(Const HtmlColor: String): TColor;
Function DelphiToHtmlColor(Color: TColor): string;
Procedure FreeServerChatMessage(Var Message: RServerChatMessage);

Implementation

Function HtmlToDelphiColor(Const HtmlColor: String): TColor;

Var 
  R, G, B: string;
  ColorStr: string;
Begin
  If (Length(HtmlColor) = 7) And (HtmlColor[1] = '#') Then
    Begin
      R := Copy(HtmlColor, 2, 2);
      G := Copy(HtmlColor, 4, 2);
      B := Copy(HtmlColor, 6, 2);

      ColorStr := '$' + B + G + R;  { Delphi expects BGR format }
      Result := StringToColor(ColorStr);
    End
  Else
    raise Exception.Create('Invalid HTML color format');
End;

Function DelphiToHtmlColor(Color: TColor): string;

Var 
  ColorValue: Longint;
  R, G, B: Byte;
Begin
  ColorValue := ColorToRGB(Color);  { Ensure color is in RGB format }
  R := (ColorValue And $000000FF);
  G := (ColorValue And $0000FF00) shr 8;
  B := (ColorValue And $00FF0000) shr 16;

  Result := Format('#%.2X%.2X%.2X', [R, G, B]);  { Format as #RRGGBB }
End;


Function GetMessageType(Value: PChar): String;

Var 
  i: Integer;
  MessageType: String;
  c: Char;
Begin
  MessageType := '';
  i := 0;
  While Value[i] <> #0 Do
    Begin
      c := Value[i];
      If c = ' ' Then
        Break;
      MessageType := MessageType + c;
      Inc(i);
    End;

  Result := MessageType;
End;

Function GetMessageAsList(Value: PChar; FullMessage: Boolean): TPCharList;

Var 
  i: Integer;
  MessageContent: TPCharList;
  c: Char;
  FoundFirstSpace: Boolean;
  IsWithinQuotes: Boolean;
  ListStartIndex: Integer;
  IsWithinList: Boolean;
  Accumulator: PChar;
  AccumIndex: Integer;
  Escaping: Boolean;

Const 
  MaxAccumLen = 1024;  { Adjust this size based on your needs }
Begin
  MessageContent := TPCharList.Create;
  IsWithinQuotes := False;
  IsWithinList := False;
  FoundFirstSpace := Not FullMessage;
  Escaping := False;

  { Allocate a fixed buffer for Accumulator }
  GetMem(Accumulator, MaxAccumLen);
  AccumIndex := 0;
  Accumulator[0] := #0;  { Initialize as an empty string }

  i := 0;
  While Value[i] <> #0 Do
    Begin
      c := Value[i];

      If Escaping Then
        Begin
          If AccumIndex < MaxAccumLen - 1 Then
            Begin
              Accumulator[AccumIndex] := c;
              Inc(AccumIndex);
              Accumulator[AccumIndex] := #0;  { Null-terminate the string }
            End;
          Escaping := False;
          Inc(i);
          Continue;
        End;

      If c = '\' Then
        Begin
          Escaping := True;
          Inc(i);
          Continue;
        End;

      If (c = '[') And Not IsWithinQuotes Then
        Begin
      { Check if this is really a list by finding the matching ] }
          ListStartIndex := i;
          While (Value[i] <> #0) And (Value[i] <> ']') Do
            Inc(i);
          If Value[i] = ']' Then
            Begin
              IsWithinList := True;
              i := ListStartIndex;  { Reset i to the start of the list }
            End
          Else
            Begin
              i := ListStartIndex;
              { No matching ], treat [ as normal character }
            End;
        End;

      If ((c = ' ') And Not IsWithinQuotes) Then
        Begin
          FoundFirstSpace := True;

          If (AccumIndex > 0) Or (IsWithinQuotes) Then
            Begin
              MessageContent.Add(StrNew(Accumulator));
              { Add a copy of Accumulator }
              AccumIndex := 0;
              Accumulator[0] := #0;  { Reset Accumulator }
            End;
        End
      Else If FoundFirstSpace Then
             If c = '"' Then
               Begin
                 If IsWithinQuotes Then
                   Begin
                     IsWithinQuotes := False;

                     If (Not IsWithinList) Then
                       Begin
                         MessageContent.Add(StrNew(Accumulator));
                         { Add a copy of Accumulator }
                         AccumIndex := 0;
                         Accumulator[0] := #0;  { Reset Accumulator }
                       End;
                   End
                 Else
                   IsWithinQuotes := True;
               End
      Else
        If AccumIndex < MaxAccumLen - 1 Then
          Begin
            Accumulator[AccumIndex] := c;
            Inc(AccumIndex);
            Accumulator[AccumIndex] := #0;  { Null-terminate the string }
          End;

      Inc(i);
    End;

  { Add the last accumulated string if any }
  If AccumIndex > 0 Then
    MessageContent.Add(StrNew(Accumulator));

  FreeMem(Accumulator, MaxAccumLen);  { Free the Accumulator memory }

  Result := MessageContent;
End;


Function GetListField(Value: PChar): TStringList;

Var 
  i: Integer;
  MessageContent: TStringList;
  c: Char;
  IsWithinQuotes: Boolean;
  Accumulator: String;
Begin
  MessageContent := TStringList.Create;
  IsWithinQuotes := False;
  Accumulator := '';

  i := 0;
  If (Value[0] = '[') And (Value[1] = ']') Then
    Begin
      i := 2;  { Start parsing after the brackets }

      While Value[i] <> #0 Do
        Begin
          c := Value[i];

          If ((c = ',') And Not IsWithinQuotes) Then
            Begin
              If Accumulator <> '' Then
                Begin
                  MessageContent.Add(Accumulator);
                  Accumulator := '';
                End;
            End
          Else If c = '"' Then
                 IsWithinQuotes := Not IsWithinQuotes
          Else
            Accumulator := Accumulator + c;

          Inc(i);
        End;

    { Add the last accumulated string if any }
      If Accumulator <> '' Then
        MessageContent.Add(Accumulator);
    End;

  Result := MessageContent;
End;

Function Quotation(Input: String): String;

Var 
  i: Integer;
  HasSpace: Boolean;
Begin
  HasSpace := False;
  For i := 1 To Length(Input) Do
    If Input[i] = ' ' Then
      Begin
        HasSpace := True;
        break;
      End;

  If (HasSpace = True) Or (Length(Input) = 0) Then
    Result := '"' + Input + '"'
  Else
    Result := Input;
End;

Function ParseServerError(Content: PChar): RServerError;

Var 
  Fields: TPCharList;
  ServerErrorMsg: RServerError;
Begin
  Try
    Fields := GetMessageAsList(Content, True);

    With ServerErrorMsg Do
      Begin
        Msg := StrPas(Fields.Get(0));
      End;
  Finally
    Fields.Free; { Free the TPCharList to avoid memory leaks }
End;

Result := ServerErrorMsg;
End;


Function ParseColorListMessage(Content: PChar): RColorList;

Var 
  Fields: TPCharList;
  ColorListMsg: RColorList;
Begin
  Try
    Fields := GetMessageAsList(Content, True);

    With ColorListMsg Do
      Begin
        Colors := GetListField(Fields.Get(0));
        Names := GetListField(Fields.Get(1));
      End;
  Finally
    Fields.Free; { Free the TPCharList to avoid memory leaks }
End;

Result := ColorListMsg;
End;

Function ParseRoomListMessage(Content: PChar): RRoomList;

Var 
  Fields: TPCharList;
  ListItem: RRoomList;
Begin
  Try
    Fields := GetMessageAsList(Content, True);

    With ListItem Do
      Begin
        RoomIds := GetListField(Fields.Get(0));
        Names := GetListField(Fields.Get(1));
      End;
  Finally
    Fields.Free;
End;

Result := ListItem;
End;

Function ParseServerUser(Content: PChar; FullMessage: Boolean): RUser;

Var 
  Fields: TPCharList;
  ListItem: RUser;
Begin
  Try
    Fields := GetMessageAsList(Content, FullMessage);

    With ListItem Do
      Begin
        UserId := StrPas(Fields.Get(0));
        Nickname := StrPas(Fields.Get(1));
        Color := StrPas(Fields.Get(2));
        RoomID := StrPas(Fields.Get(3));
      End;
  Finally
    Fields.Free;  { Free the TPCharList }
End;

Result := ListItem;
End;

Function ParseServerUserKickedMessage(Content: PChar): RServerUserKickedMessage;

Var 
  Fields: TPCharList;
  ListItem: RServerUserKickedMessage;
Begin
  Try
    Fields := GetMessageAsList(Content, True);

    With ListItem Do
      Begin
        Reason := StrPas(Fields.Get(0));
      End;
  Finally
    Fields.Free;  { Free the TPCharList }
End;

Result := ListItem;
End;

Function ParseUserAddMessage(Content: PChar): RUser;
Begin
  Result := ParseServerUser(Content, True);
End;

Function ParseUserRemoveMessage(Content: PChar): RUserRemove;

Var 
  Fields: TPCharList;
  ListItem: RUserRemove;
Begin
  Try
    Fields := GetMessageAsList(Content, True);

    With ListItem Do
      Begin
        UserId := StrPas(Fields.Get(0));
        RoomID := StrPas(Fields.Get(1));
      End;
  Finally
    Fields.Free;  { Free the TPCharList }
End;

Result := ListItem;
End;

Function ParseServerUserRegistrationSuccessMessage(Content: PChar): RUser;
Begin
  Result := ParseServerUser(Content, True);
End;

Procedure FreeServerChatMessage(Var Message: RServerChatMessage);
Begin
  If Message.FromUser <> Nil Then
    Begin
      Dispose(Message.FromUser);
      Message.FromUser := Nil;
    End;

  If Message.ToUser <> Nil Then
    Begin
      Dispose(Message.ToUser);
      Message.ToUser := Nil;
    End;

  If Message.SystemMessageSubject <> Nil Then
    Begin
      Dispose(Message.SystemMessageSubject);
      Message.SystemMessageSubject := Nil;
    End;
End;

Function ParseServerChatMessageSentMessage(Content: PChar): RServerChatMessage;

Var 
  Fields: TPCharList;
  Message: RServerChatMessage;
  MFrom: PChar;
  MTo: PChar;
  MSystemMessageSubject: PChar;
  TempUser: RUser;
Begin
  Try
    Fields := GetMessageAsList(Content, True);

    With Message Do
      Begin
        RoomID := StrPas(Fields.Get(0));

        MFrom := Fields.Get(1);
        MTo := Fields.Get(2);

        If (MFrom <> Nil) And (MFrom^ <> #0) Then
          Begin
            New(FromUser);
            TempUser := ParseServerUser(MFrom, False);
            FromUser^ := TempUser;
          End
        Else
          FromUser := Nil;

        If (MTo <> Nil) And (MTo^ <> #0) Then
          Begin
            New(ToUser);
            TempUser := ParseServerUser(MTo, False);
            ToUser^ := TempUser;
          End
        Else
          ToUser := Nil;

        If StrPas(Fields.Get(3)) = 'true' Then
          Privately := True
        Else
          Privately := False;

        SpeechMode := StrPas(Fields.Get(4));
        Time := StrPas(Fields.Get(5));

        If StrPas(Fields.Get(6)) = 'true' Then
          IsSystemMessage := True
        Else
          IsSystemMessage := False;

        MSystemMessageSubject := Fields.Get(7);

        If (MSystemMessageSubject <> Nil) And (MSystemMessageSubject^ <> #0)
          Then
          Begin
            New(SystemMessageSubject);
            TempUser := ParseServerUser(MSystemMessageSubject, False);
            SystemMessageSubject^ := TempUser;
          End
        Else
          SystemMessageSubject := Nil;

        If StrPas(Fields.Get(8)) = 'true' Then
          IsHistory := True
        Else
          IsHistory := False;

        Message := StrPas(Fields.Get(9));
      End;
  Finally
    Fields.Free;  { Free the TPCharList }
End;

Result := Message;
End;


Function CreateRegisterUserMessage(RoomId: String; Nickname: String; Color:
                                   String): String;
Begin
  Result := CLIENT_REGISTER_USER + ' ' + Quotation(Nickname) + ' ' + Color + ' '
            + RoomId;
End;

Function CreateSendMessageMessage(Msg: RMessage): String;

Var 
  StrPrivately: String;
Begin
  With Msg Do
    Begin
      If Privately = True Then
        StrPrivately := 'true'
      Else
        StrPrivately := 'false';

      Result := CLIENT_SEND_MESSAGE + ' ' + UserID + ' ' + Quotation(UserTo) +
                ' ' +
                SpeechMode + ' ' + Quotation(Message) + ' ' + StrPrivately + ' '
                + RoomID;
    End;
End;

End.
