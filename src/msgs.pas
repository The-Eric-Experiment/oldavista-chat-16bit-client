unit ProtocolMessages;

interface

uses
  SysUtils, Classes;

type
    RColorList = record
        Colors: TStringList;
    end;

    RRoomListItem = record
        RoomId: String;
        Name: String;
    end;

    RMessageType = record
        MsgType: String;
        MsgContent: String;
    end;

const
     SERVER_ERROR = '0';
     SERVER_COLOR_LIST = '1';
     SERVER_ROOM_LIST_START = '2';
     SERVER_ROOM_LIST_ITEM = '3';
     SERVER_ROOM_LIST_END = '4';
     SERVER_USER_REGISTRATION_SUCCESS = '5';
     CLIENT_REGISTER_USER = '100';
     CLIENT_COLOR_LIST_REQUEST = '105';
     CLIENT_ROOM_LIST_REQUEST = '106';


function GetMessageType(Value: String): String;
function GetMessageAsList(Value: String): TStringList;
function GetListField(Value: String): TStringList;
function Quotation(Input: String): String;
function ParseColorListMessage(Content: String): RColorList;
function ParseRoomListItemMessage(Content: String): RRoomListItem;
function CreateRegisterUserMessage(RoomId: String; Nickname: String; Color: String): String;
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
     if Value[TotalLetters] <> '"' then
        TotalLetters := TotalLetters + 1;

     for i := 0 to TotalLetters do
     begin
        c := Value[i];

        if ((c = ' ') and (IsWithinQuotes = False)) or (i = TotalLetters) then
        begin
             FoundFirstSpace := True;
             if Accumulator <> '' then
             begin
                  MessageContent.Add(Accumulator);
                  Accumulator := '';
             end;
             continue;
        end;

        if FoundFirstSpace = True then
        begin
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
     begin
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

     If HasSpace = True then
        Result := '"' + Input + '"'
     else
         Result := Input;
end;

function ParseColorListMessage(Content: String): RColorList;
var
   i: Integer;
   Fields: TStringList;
   ColorList: TStringList;
   ColorListMsg: RColorList;
begin
     Try
          Fields := GetMessageAsList(Content);

          with ColorListMsg do
          begin
               Colors := GetListField(Fields[0]);
          end;
     Finally
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
     Try
          Fields := GetMessageAsList(Content);

          with ListItem do
          begin
               RoomId := Fields[0];
               Name := Fields[1];
          end;
     Finally
            Fields.Free;
     end;

     Result := ListItem;
end;

function CreateRegisterUserMessage(RoomId: String; Nickname: String; Color: String): String;
begin
     Result := CLIENT_REGISTER_USER + ' ' + RoomId + ' ' + Quotation(Nickname) + ' ' + Color;
end;

end.


