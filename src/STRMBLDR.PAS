unit StrmBldr;

interface

uses
  Classes;

type
  TStringStreamBuilder = class
  private
    FMemoryStream: TMemoryStream;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Append(const AString: string);
    function GetStream: TMemoryStream;
  end;

implementation

uses
  SysUtils;

{ TStringStreamBuilder }

constructor TStringStreamBuilder.Create;
begin
  inherited Create;
  FMemoryStream := TMemoryStream.Create;
end;

destructor TStringStreamBuilder.Destroy;
begin
  FMemoryStream.Free;
  inherited Destroy;
end;

procedure TStringStreamBuilder.Append(const AString: string);
var
  P: PChar;
  StrLength: Integer;
begin
  StrLength := Length(AString);
  GetMem(P, StrLength + 1);
  try
    StrPCopy(P, AString);
    FMemoryStream.Write(P^, StrLength);
  finally
    FreeMem(P, StrLength + 1);
  end;
end;

function TStringStreamBuilder.GetStream: TMemoryStream;
begin
  Result := FMemoryStream;
  FMemoryStream.Position := 0;  { Reset the stream position to the beginning }
end;

end.

