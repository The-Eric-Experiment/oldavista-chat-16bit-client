unit PCharLst;

interface

uses
  SysUtils, Classes;

const
  MaxPCharListSize = 1024; { Adjust this value as needed }

type
  TPCharList = class
  private
    FItems: array[0..MaxPCharListSize - 1] of PChar;
    FCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Item: PChar);
    function Get(Index: Integer): PChar;
    property Count: Integer read FCount;
  end;

implementation

constructor TPCharList.Create;
begin
  inherited Create;
  FCount := 0;
end;

destructor TPCharList.Destroy;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do
    StrDispose(FItems[i]);
  inherited Destroy;
end;

procedure TPCharList.Add(Item: PChar);
begin
  if FCount < MaxPCharListSize then
  begin
    FItems[FCount] := StrNew(Item); { Allocate memory and store the PChar }
    Inc(FCount);
  end
  else
    raise Exception.Create('TPCharList is full');
end;

function TPCharList.Get(Index: Integer): PChar;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := FItems[Index]
  else
    Result := nil;
end;

end.
