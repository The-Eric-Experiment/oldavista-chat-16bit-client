unit ProtocolMessages;

interface

uses
  SysUtils, Classes, PCharLst, Graphics;

type
  RServerError = record
    Msg: String
  end;

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

  PUser = ^RUser;

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
    RoomID: String;
    FromUser: PUser;
    ToUser: PUser;
    Privately: Boolean;
    SpeechMode: String;
    Time: String;
    IsSystemMessage: Boolean;
    SystemMessageSubject: PUser;
    Message: String;
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


function GetMessageType(Value: PChar): String;
function GetMessageAsList(Value: PChar; FullMessage: Boolean): TPCharList;
function GetListField(Value: PChar): TStringList;
function Quotation(Input: String): String;
function ParseServerError(Content: PChar): RServerError;
function ParseColorListMessage(Content: PChar): RColorList;
function ParseRoomListItemMessage(Content: PChar): RRoomListItem;
function ParseServerUser(Content: PChar; FullMessage: Boolean): RUser;
function ParseUserAddMessage(Content: PChar): RUser;
function ParseUserRemoveMessage(Content: PChar): RUserRemove;
function ParseServerUserRegistrationSuccessMessage(Content: PChar): RUser;
function ParseServerChatMessageSentMessage(Content: PChar): RServerChatMessage;
function CreateRegisterUserMessage(RoomId: String; Nickname: String; Color: String): String;
function CreateSendMessageMessage(Msg: RMessage): String;
function HtmlToDelphiColor(const HtmlColor: string): TColor;
function DelphiToHtmlColor(Color: TColor): string;
procedure FreeServerChatMessage(var Message: RServerChatMessage);
implementation

function HtmlToDelphiColor(const HtmlColor: string): TColor;
var
  R, G, B: string;
  ColorStr: string;
begin
  if (Length(HtmlColor) = 7) and (HtmlColor[1] = '#') then
  begin
    R := Copy(HtmlColor, 2, 2);
    G := Copy(HtmlColor, 4, 2);
    B := Copy(HtmlColor, 6, 2);

    ColorStr := '$' + B + G + R;  { Delphi expects BGR format }
    Result := StringToColor(ColorStr);
  end
  else
    raise Exception.Create('Invalid HTML color format');
end;

function DelphiToHtmlColor(Color: TColor): string;
var
  ColorValue: Longint;
  R, G, B: Byte;
begin
  ColorValue := ColorToRGB(Color);  { Ensure color is in RGB format }
  R := (ColorValue and $000000FF);
  G := (ColorValue and $0000FF00) shr 8;
  B := (ColorValue and $00FF0000) shr 16;

  Result := Format('#%.2X%.2X%.2X', [R, G, B]);  { Format as #RRGGBB }
end;


function GetMessageType(Value: PChar): String;
var
  i: Integer;
  MessageType: String;
  c: Char;
begin
  MessageType := '';
  i := 0;
  while Value[i] <> #0 do
  begin
    c := Value[i];
    if c = ' ' then
      Break;
    MessageType := MessageType + c;
    Inc(i);
  end;

  Result := MessageType;
end;

function GetMessageAsList(Value: PChar; FullMessage: Boolean): TPCharList;
var
  i: Integer;
  MessageContent: TPCharList;
  c: Char;
  FoundFirstSpace: Boolean;
  IsWithinQuotes: Boolean;
  Accumulator: PChar;
  AccumIndex: Integer;
  Escaping: Boolean;
const
  MaxAccumLen = 1024;  { Adjust this size based on your needs }
begin
  MessageContent := TPCharList.Create;
  IsWithinQuotes := False;
  FoundFirstSpace := not FullMessage;
  Escaping := False;

  { Allocate a fixed buffer for Accumulator }
  GetMem(Accumulator, MaxAccumLen);
  AccumIndex := 0;
  Accumulator[0] := #0;  { Initialize as an empty string }

  i := 0;
  while Value[i] <> #0 do
  begin
    c := Value[i];

    if Escaping then
    begin
      if AccumIndex < MaxAccumLen - 1 then
      begin
        Accumulator[AccumIndex] := c;
        Inc(AccumIndex);
        Accumulator[AccumIndex] := #0;  { Null-terminate the string }
      end;
      Escaping := False;
      Inc(i);
      Continue;
    end;

    if c = '\' then
    begin
      Escaping := True;
      Inc(i);
      Continue;
    end;

    if ((c = ' ') and not IsWithinQuotes) then
    begin
      FoundFirstSpace := True;

      if (AccumIndex > 0) or (IsWithinQuotes) then
      begin
        MessageContent.Add(StrNew(Accumulator));  { Add a copy of Accumulator }
        AccumIndex := 0;
        Accumulator[0] := #0;  { Reset Accumulator }
      end;
    end
    else if FoundFirstSpace then
      if c = '"' then
      begin
        if IsWithinQuotes then
        begin
          IsWithinQuotes := False;
          MessageContent.Add(StrNew(Accumulator));  { Add a copy of Accumulator }
          AccumIndex := 0;
          Accumulator[0] := #0;  { Reset Accumulator }
        end
        else
          IsWithinQuotes := True;
      end
      else
      if AccumIndex < MaxAccumLen - 1 then
      begin
        Accumulator[AccumIndex] := c;
        Inc(AccumIndex);
        Accumulator[AccumIndex] := #0;  { Null-terminate the string }
      end;

    Inc(i);
  end;

  { Add the last accumulated string if any }
  if AccumIndex > 0 then
    MessageContent.Add(StrNew(Accumulator));

  FreeMem(Accumulator, MaxAccumLen);  { Free the Accumulator memory }

  Result := MessageContent;
end;


function GetListField(Value: PChar): TStringList;
var
  i: Integer;
  MessageContent: TStringList;
  c: Char;
  IsWithinQuotes: Boolean;
  Accumulator: String;
begin
  MessageContent := TStringList.Create;
  IsWithinQuotes := False;
  Accumulator := '';
  
  i := 0;
  if (Value[0] = '[') and (Value[1] = ']') then
  begin
    i := 2;  { Start parsing after the brackets }

    while Value[i] <> #0 do
    begin
      c := Value[i];

      if ((c = ',') and not IsWithinQuotes) then
      begin
        if Accumulator <> '' then
        begin
          MessageContent.Add(Accumulator);
          Accumulator := '';
        end;
      end
      else if c = '"' then
        IsWithinQuotes := not IsWithinQuotes
      else
        Accumulator := Accumulator + c;

      Inc(i);
    end;

    { Add the last accumulated string if any }
    if Accumulator <> '' then
      MessageContent.Add(Accumulator);
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

function ParseServerError(Content: PChar): RServerError;
var
  Fields: TPCharList;
  ServerErrorMsg: RServerError;
begin
  try
    Fields := GetMessageAsList(Content, True);

    with ServerErrorMsg do
    begin
      Msg := StrPas(Fields.Get(0));
    end;
  finally
    Fields.Free; { Free the TPCharList to avoid memory leaks }
  end;

  Result := ServerErrorMsg;
end;


function ParseColorListMessage(Content: PChar): RColorList;
var
  Fields: TPCharList;
  ColorListMsg: RColorList;
begin
  try
    Fields := GetMessageAsList(Content, True);

    with ColorListMsg do
    begin
      Colors := GetListField(Fields.Get(0));
      Names := GetListField(Fields.Get(1));
    end;
  finally
    Fields.Free; { Free the TPCharList to avoid memory leaks }
  end;

  Result := ColorListMsg;
end;

function ParseRoomListItemMessage(Content: PChar): RRoomListItem;
var
  Fields: TPCharList;
  ListItem: RRoomListItem;
begin
  try
    Fields := GetMessageAsList(Content, True);

    with ListItem do
    begin
      RoomId := StrPas(Fields.Get(0));  { Convert PChar to String }
      Name := StrPas(Fields.Get(1));    { Convert PChar to String }
    end;
  finally
    Fields.Free;  { Free the TPCharList }
  end;

  Result := ListItem;
end;

function ParseServerUser(Content: PChar; FullMessage: Boolean): RUser;
var
  Fields: TPCharList;
  ListItem: RUser;
begin
  try
    Fields := GetMessageAsList(Content, FullMessage);

    with ListItem do
    begin
      UserId := StrPas(Fields.Get(0));     { Convert PChar to String }
      Nickname := StrPas(Fields.Get(1));   { Convert PChar to String }
      Color := StrPas(Fields.Get(2));      { Convert PChar to String }
      RoomID := StrPas(Fields.Get(3));     { Convert PChar to String }
    end;
  finally
    Fields.Free;  { Free the TPCharList }
  end;

  Result := ListItem;
end;

function ParseUserAddMessage(Content: PChar): RUser;
begin
  Result := ParseServerUser(Content, True);
end;

function ParseUserRemoveMessage(Content: PChar): RUserRemove;
var
  Fields: TPCharList;
  ListItem: RUserRemove;
begin
  try
    Fields := GetMessageAsList(Content, True);

    with ListItem do
    begin
      UserId := StrPas(Fields.Get(0));     { Convert PChar to String }
      RoomID := StrPas(Fields.Get(1));     { Convert PChar to String }
    end;
  finally
    Fields.Free;  { Free the TPCharList }
  end;

  Result := ListItem;
end;

function ParseServerUserRegistrationSuccessMessage(Content: PChar): RUser;
begin
  Result := ParseServerUser(Content, True);
end;

procedure FreeServerChatMessage(var Message: RServerChatMessage);
begin
  if Message.FromUser <> nil then
  begin
    Dispose(Message.FromUser);
    Message.FromUser := nil;
  end;

  if Message.ToUser <> nil then
  begin
    Dispose(Message.ToUser);
    Message.ToUser := nil;
  end;

  if Message.SystemMessageSubject <> nil then
  begin
    Dispose(Message.SystemMessageSubject);
    Message.SystemMessageSubject := nil;
  end;
end;

function ParseServerChatMessageSentMessage(Content: PChar): RServerChatMessage;
var
  Fields: TPCharList;
  Message: RServerChatMessage;
  MFrom: PChar;
  MTo: PChar;
  MSystemMessageSubject: PChar;
  TempUser: RUser;
begin
  try
    Fields := GetMessageAsList(Content, True);

    with Message do
    begin
      RoomID := StrPas(Fields.Get(0));

      MFrom := Fields.Get(1);
      MTo := Fields.Get(2);

      if (MFrom <> nil) and (MFrom^ <> #0) then
      begin
        New(FromUser);
        TempUser := ParseServerUser(MFrom, False);
        FromUser^ := TempUser;
      end
      else
        FromUser := nil;

      if (MTo <> nil) and (MTo^ <> #0) then
      begin
        New(ToUser);
        TempUser := ParseServerUser(MTo, False);
        ToUser^ := TempUser;
      end
      else
        ToUser := nil;

      if StrPas(Fields.Get(3)) = 'true' then
        Privately := True
      else
        Privately := False;

      SpeechMode := StrPas(Fields.Get(4));
      Time := StrPas(Fields.Get(5));

      if StrPas(Fields.Get(6)) = 'true' then
        IsSystemMessage := True
      else
        IsSystemMessage := False;

      MSystemMessageSubject := Fields.Get(7);

      if (MSystemMessageSubject <> nil) and (MSystemMessageSubject^ <> #0) then
      begin
        New(SystemMessageSubject);
        TempUser := ParseServerUser(MSystemMessageSubject, False);
        SystemMessageSubject^ := TempUser;
      end
      else
        SystemMessageSubject := nil;

      Message := StrPas(Fields.Get(8));
    end;
  finally
    Fields.Free;  { Free the TPCharList }
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
