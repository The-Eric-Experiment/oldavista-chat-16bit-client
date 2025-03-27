
Unit PCharLst;

Interface

Uses 
SysUtils, Classes;

Const 
  MaxPCharListSize = 1024; { Adjust this value as needed }

Type 
  TPCharList = Class
    Private 
      FItems: array[0..MaxPCharListSize - 1] Of PChar;
      FCount: Integer;
    Public 
      constructor Create;
      destructor Destroy;
      override;
      Procedure Add(Item: PChar);
      Function Get(Index: Integer): PChar;
      property Count: Integer read FCount;
  End;

Implementation

constructor TPCharList.Create;
Begin
  inherited Create;
  FCount := 0;
End;

destructor TPCharList.Destroy;

Var 
  i: Integer;
Begin
  For i := 0 To FCount - 1 Do
    StrDispose(FItems[i]);
  inherited Destroy;
End;

Procedure TPCharList.Add(Item: PChar);
Begin
  If FCount < MaxPCharListSize Then
    Begin
      FItems[FCount] := StrNew(Item); { Allocate memory and store the PChar }
      Inc(FCount);
    End
  Else
    raise Exception.Create('TPCharList is full');
End;

Function TPCharList.Get(Index: Integer): PChar;
Begin
  If (Index >= 0) And (Index < FCount) Then
    Result := FItems[Index]
  Else
    Result := Nil;
End;

End.
