
  {

  IRCTags unit, used for parsing irc-styled strings

  STATEMENT: I do not promise any support or new versions of this package.

  {}

unit IRCTags;

interface

uses Graphics, SysUtils;

type
  TColors = array[0..15] of TColor;

var MircColors: TColors;

const
  TAG_BOLD       =  #2;
  TAG_COLOR      =  #3;
  TAG_NORMAL     = #15;
  TAG_INVERSE    = #22;
  TAG_BEGINLINK  = #25;
  TAG_ENDLINK    = #26;
  TAG_UNDERLINE  = #31;
  TAGS: array[0..6] of Char = (TAG_BOLD, TAG_COLOR, TAG_NORMAL, TAG_INVERSE,
    TAG_BEGINLINK, TAG_ENDLINK, TAG_UNDERLINE);

  clrNone       = -1;
  clrWhite      =  0;
  clrBlack      =  1;
  clrNavy       =  2;
  clrGreen      =  3;
  clrRed        =  4;
  clrMaroon     =  5;
  clrPurple     =  6;
  clrOrange     =  7;
  clrYellow     =  8;
  clrLime       =  9;
  clrTeal       = 10;
  clrAqua       = 11;
  clrBlue       = 12;
  clrFuchsia    = 13;
  clrGray       = 14;
  clrSilver     = 15;

function IsTag(S: String): Boolean;
function IsDigit(C: Char): Boolean;
function StripColor(var ColorTag: String): String;
procedure StripColorTag(ColorTag: String; var TextColor, BackColor: Integer);
function TagLength(S: String): Integer;
function StripTag(var S: String): String;
function ReadNextTag(var Source: String): String;
procedure InvertFontStyle(var Style: TFontStyles; AStyle: TFontStyle);
function RemoveTags(Source: String): String;
function TagColor(Fore, Back: Integer): String;

implementation



function IsDigit(C: Char): Boolean;
begin
  Result := C in ['0'..'9'];
end;

function TagColor(Fore, Back: Integer): String;
begin
  Result := TAG_COLOR;

  if Fore >= 0 then
    begin
      Result := Result + IntToStr(Fore mod 15);
      if Back >= 0 then
        begin
          Result := Result + ',' + IntToStr(Back mod 15);
        end;
    end;
end;

procedure StripColorTag(ColorTag: String; var TextColor, BackColor: Integer);
var FCol, BCol: String;
begin
  TextColor := - 1;
  BackColor := - 1;

  Delete(ColorTag, 1, 1);
  FCol := StripColor(ColorTag);
  if FCol <> '' then
    begin
      TextColor := StrToInt(FCol);
      if (Length(ColorTag) > 0) and (ColorTag[1] = ',') then
        begin
          Delete(ColorTag, 1, 1);
          BCol := StripColor(ColorTag);
          BackColor := StrToInt(BCol);
        end;
    end else
    begin
      TextColor := 0;
      BackColor := 0;
    end;
end;

function StripColor(var ColorTag: String): String;
var I, L: Integer;
begin
  Result := '';
  L := Length(ColorTag);
  if L = 0 then
    Exit;

  if L > 2 then
    L := 2;

  for I := 1 to L do
    if IsDigit(ColorTag[I]) then
      begin
        Result := Result + ColorTag[I];
      end else
      Break;

  Delete(ColorTag, 1, Length(Result));
end;

function TagLength(S: String): Integer;
var 
  FCol, BCol: String;
begin
  Result := 0;
  if Length(S) = 0 then
    Exit;

  if S[1] = TAG_BOLD then
    begin
      Result := 1;
    end else
  if S[1] = TAG_NORMAL then
    begin
      Result := 1;
    end else
  if S[1] = TAG_COLOR then
    begin
      Result := 1;
      FCol := StripColor(S);
      if FCol <> '' then
        begin
          Result := Result + Length(FCol);
          if (Length(S) > 0) and (S[1] = ',') then
            begin
              Result := Result + 1;
              BCol := StripColor(S);
              Result := Result + Length(BCol);
            end;
        end else
        begin
        end;
    end else
  if S[1] = TAG_INVERSE then
    begin
      Result := 1;
    end else
  if S[1] = TAG_UNDERLINE then
    begin
      Result := 1;
    end;
end;

function StripTag(var S: String): String;
var 
  FCol, BCol: String;
begin
  if Length(S) = 0 then
    Exit;

  if S[1] = TAG_BOLD then
    begin
      Result := TAG_BOLD;
      Delete(S, 1, 1);
    end else
  if S[1] = TAG_NORMAL then
    begin
      Result := TAG_NORMAL;
      Delete(S, 1, 1);
    end else
  if S[1] = TAG_COLOR then
    begin
      Result := TAG_COLOR;
      Delete(S, 1, 1);
      FCol := StripColor(S);
      if FCol <> '' then
        begin
          Result := Result + FCol;
          if (Length(S) > 0) and (S[1] = ',') then
            begin
              Result := Result +  ',';
              Delete(S, 1, 1);
              BCol := StripColor(S);
              if BCol <> '' then
                Result := Result + BCol;
            end;
        end else
        begin
        end;
    end else
  if S[1] = TAG_INVERSE then
    begin
      Result := TAG_INVERSE;
      Delete(S, 1, 1);
    end else
  if S[1] = TAG_BEGINLINK then
    begin
      Result := TAG_BEGINLINK;
      Delete(S, 1, 1);
    end else
  if S[1] = TAG_ENDLINK then
    begin
      Result := TAG_ENDLINK;
      Delete(S, 1, 1);
    end else
  if S[1] = TAG_UNDERLINE then
    begin
      Result := TAG_UNDERLINE;
      Delete(S, 1, 1);
    end;
end;

procedure InvertFontStyle(var Style: TFontStyles; AStyle: TFontStyle);
begin
  if AStyle in Style then
    Style := Style - [AStyle] else
    Style := Style + [AStyle];
end;

function IsTag(S: String): Boolean;
var All, I, TagPos, NearestTag: Integer;
begin
  Result := False;
  if S = '' then
    Exit;

  NearestTag := 999;
  All := Length(TAGS);
  for I := 1 to All do
    begin
      TagPos := Pos(TAGS[I], S);
      if (TagPos < NearestTag) and (TagPos > 0) then
        NearestTag := TagPos;
    end;

  if NearestTag = 1 then
    Result := True;
end;

function ReadNextTag(var Source: String): String;
var All, I, TagPos, NearestTag: Integer;
begin
  Result := '';
  if Source = '' then
    Exit;

  NearestTag := 999;
  All := Length(TAGS);
  for I := 1 to All do
    begin
      TagPos := Pos(TAGS[I], Source);
      if (TagPos < NearestTag) and (TagPos > 0) then
        NearestTag := TagPos;
    end;

  if NearestTag = 999 then
    begin
      Result := Source;
      Source := '';
    end else
  if NearestTag > 1 then
    begin
      Result := Copy(Source, 1, NearestTag - 1);
      Delete(Source, 1, NearestTag - 1);
    end else
  if NearestTag = 1 then
    begin
      Result := StripTag(Source);
    end;
end;

function RemoveTags(Source: String): String;
var Tag, Src: String;
begin
  Src := Source;
  Result := '';
  repeat
    Tag := ReadNextTag(Src);
    if NOT IsTag(Tag) then
      Result := Result + Tag;
  until Tag = '';
end;

initialization
  MircColors[clrWhite] := clWhite;
  MircColors[clrBlack] := clBlack;
  MircColors[clrNavy] := clNavy;
  MircColors[clrGreen] := clGreen;
  MircColors[clrRed] := clRed;
  MircColors[clrMaroon] := clMaroon;
  MircColors[clrPurple] := clPurple;
  MircColors[clrOrange] := $004080FF;
  MircColors[clrYellow] := clYellow;
  MircColors[clrLime] := clLime;
  MircColors[clrTeal] := clTeal;
  MircColors[clrAqua] := clAqua;
  MircColors[clrBlue] := clBlue;
  MircColors[clrFuchsia] := clFuchsia;
  MircColors[clrGray] := clGray;
  MircColors[clrSilver] := clSilver;
end.

end.
