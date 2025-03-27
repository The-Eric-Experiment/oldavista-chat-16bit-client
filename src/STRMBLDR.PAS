
Unit StrmBldr;

Interface

Uses 
Classes;

Type 
  TStringStreamBuilder = Class
    Private 
      FMemoryStream: TMemoryStream;
    Public 
      constructor Create;
      destructor Destroy;
      override;
      Procedure Append(Const AString: String);
      Function GetStream: TMemoryStream;
  End;

Implementation

Uses 
SysUtils;

{ TStringStreamBuilder }

constructor TStringStreamBuilder.Create;
Begin
  inherited Create;
  FMemoryStream := TMemoryStream.Create;
End;

destructor TStringStreamBuilder.Destroy;
Begin
  FMemoryStream.Free;
  inherited Destroy;
End;

Procedure TStringStreamBuilder.Append(Const AString: String);

Var 
  P: PChar;
  StrLength: Integer;
Begin
  StrLength := Length(AString);
  GetMem(P, StrLength + 1);
  Try
    StrPCopy(P, AString);
    FMemoryStream.Write(P^, StrLength);
  Finally
    FreeMem(P, StrLength + 1);
End;
End;

Function TStringStreamBuilder.GetStream: TMemoryStream;
Begin
  Result := FMemoryStream;
  FMemoryStream.Position := 0;  { Reset the stream position to the beginning }
End;

End.
