unit ProtocolMessages;

interface

uses
  SysUtils, Classes;

type
  RColorList = record
    Colors: TStringList;
    Names: TStringList;
  end;

  RRoomListItem = record
    RoomId: String;
    Name: String;
  end;

  RMessageType = record
    MsgType: String;
    MsgContent: String;
  end;

  RUser = record
    UserID: String;
    Nickname: String;
    Color: String;
    RoomID: String;
  end;

  RUserRemove = record
    UserID: String;
    RoomID: String;
  end;

  RMessage = record
    UserID: String;
    UserTo: String;
    SpeechMode: String;
    Message: String;
    Privately: Boolean;
    RoomID: String
  end;

  RServerChatMessage = record
    FromNickname: String;
    FromID: String;
    ToNickname: String;
    ToID: String;
    Text: String;
  end;

const
  SERVER_ERROR = '0';
  SERVER_COLOR_LIST = '1';
  SERVER_ROOM_LIST_START = '2';
  SERVER_ROOM_LIST_ITEM = '3';
  SERVER_ROOM_LIST_END = '4';
  SERVER_USER_REGISTRATION_SUCCESS = '5';
  SERVER_USER_LIST_ADD = '6';
  SERVER_USER_LIST_REMOVE = '7';
  SERVER_USER_LIST_UPDATE = '8';
  SERVER_MESSAGE_SENT = '10';
  CLIENT_REGISTER_USER = '100';
  CLIENT_SEND_MESSAGE = '101';
  CLIENT_COLOR_LIST_REQUEST = '105';
  CLIENT_ROOM_LIST_REQUEST = '106';


function GetMessageType(Value: String): String;
function GetMessageAsList(Value: String): TStringList;
function GetListField(Value: String): TStringList;
function Quotation(Input: String): String;
function ParseColorListMessage(Content: String): RColorList;
function ParseRoomListItemMessage(Content: String): RRoomListItem;
function ParseUserAddMessage(Content: String): RUser;
function ParseUserRemoveMessage(Content: String): RUserRemove;
function ParseServerUserRegistratoinSuccessMessage(Content: String): RUser;
function ParseServerChatMessageSentMessage(Content: String): RServerChatMessage;
function CreateRegisterUserMessage(RoomId: String; Nickname: String; Color: String): String;
function CreateSendMessageMessage(Msg: RMessage): String;
implementation

function GetMessageType(Value: String): String;
var
  i: Integer;
  MessageType: String;
  c: Char;
begin
  MessageType := '';
  for i := 1 to Length(Value) do
  begin
    c := Value[i];
    if c = ' ' then
      break;

    MessageType := MessageType + c;
  end;

  Result := MessageType;
end;

function GetMessageAsList(Value: String): TStringList;
var
  i: Integer;
  MessageContent: TStringList;
  c: Char;
  FoundFirstSpace: Boolean;
  IsWithinQuotes: Boolean;
  Accumulator: String;
  TotalLetters: Integer;
begin
  MessageContent := TStringList.Create;
  IsWithinQuotes := False;
  FoundFirstSpace := False;
  Accumulator := '';
  TotalLetters := Length(Value);
  
  {If the string doesn't end in " then we need to add one more count
   so we can get the last character of the string}
  if (TotalLetters > 0) and (Value[TotalLetters] <> '"') then
    TotalLetters := TotalLetters + 1;

  for i := 1 to TotalLetters do
  begin
    if i <= Length(Value) then
      c := Value[i]
    else
      c := ' ';  { Treat end of string as a space to trigger final add }

    if ((c = ' ') and not IsWithinQuotes) or (i = TotalLetters) then
    begin
      FoundFirstSpace := True;
      if (Accumulator <> '') or (IsWithinQuotes) then
      begin
        MessageContent.Add(Accumulator);
        Accumulator := '';
      end;
      continue;
    end;

    if FoundFirstSpace then
    begin
      if c = '"' then
      begin
        if IsWithinQuotes then
        begin
          IsWithinQuotes := False;
          MessageContent.Add(Accumulator);  { Add empty string if Accumulator is empty }
          Accumulator := '';
        end
        else
          IsWithinQuotes := True;
        continue;
      end;
      Accumulator := Accumulator + c;
    end;
  end;

  Result := MessageContent;
end;


function GetListField(Value: String): TStringList;
var
  i: Integer;
  MessageContent: TStringList;
  c: Char;
  IsWithinQuotes: Boolean;
  Accumulator: String;
  TotalLetters: Integer;
begin
  MessageContent := TStringList.Create;
  IsWithinQuotes := False;
  Accumulator := '';
  TotalLetters := Length(Value);
  { TODO, THIS MIGHT HAVE ISSUES WHERE IT DOESN'T KNOW WHEN THE ARRAY ENDS }
  if (Value[1] = '[') and (Value[2] = ']') then
    for i := 3 to TotalLetters do
    begin
      c := Value[i];

      if ((c = ',') and (IsWithinQuotes = False)) or (i = TotalLetters) then
      begin
        if Accumulator <> '' then
        begin
          MessageContent.Add(Accumulator);
          Accumulator := '';
        end;
        continue;
      end;

      if c = '"' then
      begin
        if IsWithinQuotes = True then
          IsWithinQuotes := False
        else
          IsWithinQuotes := True;
        continue;
      end;
      Accumulator := Accumulator + c;
    end;

  Result := MessageContent;
end;

function Quotation(Input: String): String;
var
  i: Integer;
  HasSpace: Boolean;
begin
  HasSpace := False;
  for i := 1 to Length(Input) do
    if Input[i] = ' ' then
    begin
      HasSpace := True;
      break;
    end;

  if (HasSpace = True) or (Length(Input) = 0) then
    Result := '"' + Input + '"'
  else
    Result := Input;
end;

function ParseColorListMessage(Content: String): RColorList;
var
  i: Integer;
  Fields: TStringList;
  ColorList: TStringList;
  ColorNames: TStringList;
  ColorListMsg: RColorList;
begin
  try
    Fields := GetMessageAsList(Content);

    with ColorListMsg do
    begin
      Colors := GetListField(Fields[0]);
      Names := GetListField(Fields[1]);
    end
  finally
    Fields.Free;
  end;

  Result := ColorListMsg;
end;

function ParseRoomListItemMessage(Content: String): RRoomListItem;
var
  i: Integer;
  Fields: TStringList;
  ListItem: RRoomListItem;
begin
  try
    Fields := GetMessageAsList(Content);

    with ListItem do
    begin
      RoomId := Fields[0];
      Name := Fields[1];
    end;
  finally
    Fields.Free;
  end;

  Result := ListItem;
end;

function ParseUserAddMessage(Content: String): RUser;
var
  i: Integer;
  Fields: TStringList;
  ListItem: RUser;
begin
  try
    Fields := GetMessageAsList(Content);

    with ListItem do
    begin
      UserId := Fields[0];
      Nickname := Fields[1];
      Color := Fields[2];
      RoomID := Fields[3];
    end;
  finally
    Fields.Free;
  end;

  Result := ListItem;
end;

function ParseUserRemoveMessage(Content: String): RUserRemove;
var
  i: Integer;
  Fields: TStringList;
  ListItem: RUserRemove;
begin
  try
    Fields := GetMessageAsList(Content);

    with ListItem do
    begin
      UserId := Fields[0];
      RoomID := Fields[1];
    end;
  finally
    Fields.Free;
  end;

  Result := ListItem;
end;

function ParseServerUserRegistratoinSuccessMessage(Content: String): RUser;
var
  i: Integer;
  Fields: TStringList;
  ListItem: RUser;
begin
  try
    Fields := GetMessageAsList(Content);

    with ListItem do
    begin
      UserId := Fields[0];
      Nickname := Fields[1];
      Color := Fields[2];
      RoomID := Fields[3];
    end;
  finally
    Fields.Free;
  end;

  Result := ListItem;
end;

function ParseServerChatMessageSentMessage(Content: String): RServerChatMessage;
var
  i: Integer;
  Fields: TStringList;
  Message: RServerChatMessage;
begin
  try
    Fields := GetMessageAsList(Content);

    with Message do
    begin
      FromNickname := Fields[0];
      FromID := Fields[1];
      ToNickname := Fields[2];
      ToID := Fields[3];
      Text := Fields[4];
    end;
  finally
    Fields.Free;
  end;

  Result := Message;
end;

function CreateRegisterUserMessage(RoomId: String; Nickname: String; Color: String): String;
begin
  Result := CLIENT_REGISTER_USER + ' ' + Quotation(Nickname) + ' ' + Color + ' ' + RoomId;
end;

function CreateSendMessageMessage(Msg: RMessage): String;
var
  StrPrivately: String;
begin
  with Msg do
  begin
    if Privately = True then
      StrPrivately := 'true'
    else
      StrPrivately := 'false';

    Result := CLIENT_SEND_MESSAGE + ' ' + UserID + ' ' + Quotation(UserTo) + ' ' +
      SpeechMode + ' ' + Quotation(Message) + ' ' + StrPrivately + ' ' + RoomID;
  end;
end;

end.
