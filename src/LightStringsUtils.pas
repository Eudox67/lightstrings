// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
unit LightStringsUtils;

{$mode objfpc}{$H+}
{$INLINE ON}
{$POINTERMATH ON}

interface

type
  { Simple dynamic array of strings for Split/Join. }
  TStringArray = array of string;

{ Check if Str starts with Sub. }
function BeginsWith(const Str, Sub: string): Boolean; inline;

{ Check if Str ends with Sub. }
function EndsWith(const Str, Sub: string): Boolean; inline;

{ Case-sensitive substring search. }
function Contains(const Str, Sub: string): Boolean; inline;

{ Case-insensitive substring search. }
function ContainsI(const Str, Sub: string): Boolean; inline;

{ Trim leading whitespace (space, tab, CR, LF). Returns new string. }
function TrimLeft(const S: string): string;

{ Trim trailing whitespace (space, tab, CR, LF). Returns new string. }
function TrimRight(const S: string): string;

{ Trim both leading and trailing whitespace. Returns new string. }
function Trim(const S: string): string;

{ Split S by separator Sep. Returns array of substrings.
  Empty strings are included (e.g. "a,,b" split by "," gives 3 items). }
function Split(const S: string; const Sep: string): TStringArray;

{ Join array of strings with Sep between each pair. }
function Join(const Arr: TStringArray; const Sep: string): string;

{ Prepend Prefix if Str doesn't already start with it. }
function PrependIfMissing(const Str, Prefix: string): string;

{ Append Suffix if Str doesn't already end with it. }
function AppendIfMissing(const Str, Suffix: string): string;

{ Reverse a string. UTF-8 aware: code points are reversed, while the bytes of
  each (multi-byte) sequence stay in their original order, so the result is
  still valid UTF-8 for valid UTF-8 input. }
function Reverse(const S: string): string;

implementation

{ ------------------------------------------------------------------- }
{  Local helper (replaces AnsiUpperCase from SysUtils)                }
{ ------------------------------------------------------------------- }

function UpperCaseStr(const S: string): string;
var
  i: Integer;
begin
  SetLength(Result, System.Length(S));
  for i := 1 to System.Length(S) do
    Result[i] := UpCase(S[i]);   // UpCase is in System
end;

{ ------------------------------------------------------------------- }
{  Implementations                                                    }
{ ------------------------------------------------------------------- }

function BeginsWith(const Str, Sub: string): Boolean;
var
  SL: NativeInt;
begin
  SL := System.Length(Sub);
  if SL > System.Length(Str) then Exit(False);
  Result := CompareByte(PChar(Str)^, PChar(Sub)^, SL * SizeOf(Char)) = 0;
end;

function EndsWith(const Str, Sub: string): Boolean;
var
  SL, StrLen: NativeInt;
begin
  SL := System.Length(Sub);
  StrLen := System.Length(Str);
  if SL > StrLen then Exit(False);
  Result := CompareByte(PChar(Str)[StrLen - SL], PChar(Sub)^, SL * SizeOf(Char)) = 0;
end;

function Contains(const Str, Sub: string): Boolean;
begin
  // System.Pos is a highly optimized routine.
  Result := (Sub = '') or (System.Pos(Sub, Str) > 0);
end;

function ContainsI(const Str, Sub: string): Boolean;
begin
  // ASCII-only case-insensitive search via temporary uppercase copies.
  Result := System.Pos(UpperCaseStr(Sub), UpperCaseStr(Str)) > 0;
end;

function IsSpace(C: Char): Boolean; inline;
begin
  Result := (C = ' ') or (C = #9) or (C = #10) or (C = #13);
end;

function TrimLeft(const S: string): string;
var
  Lo, L: NativeInt;
begin
  L := System.Length(S);
  Lo := 1;
  while (Lo <= L) and IsSpace(S[Lo]) do Inc(Lo);
  if Lo > L then
    Result := ''
  else
  begin
    SetLength(Result, L - Lo + 1);
    Move(PChar(S)[Lo - 1], PChar(Result)^, (L - Lo + 1) * SizeOf(Char));
  end;
end;

function TrimRight(const S: string): string;
var
  Hi: NativeInt;
begin
  Hi := System.Length(S);
  while (Hi >= 1) and IsSpace(S[Hi]) do Dec(Hi);
  if Hi = 0 then
    Result := ''
  else
  begin
    SetLength(Result, Hi);
    Move(PChar(S)^, PChar(Result)^, Hi * SizeOf(Char));
  end;
end;

function Trim(const S: string): string;
var
  Lo, Hi: NativeInt;
begin
  Lo := 1;
  Hi := System.Length(S);
  while (Lo <= Hi) and IsSpace(S[Lo]) do Inc(Lo);
  while (Hi >= Lo) and IsSpace(S[Hi]) do Dec(Hi);
  if Lo > Hi then
    Result := ''
  else
  begin
    SetLength(Result, Hi - Lo + 1);
    Move(PChar(S)[Lo - 1], PChar(Result)^, (Hi - Lo + 1) * SizeOf(Char));
  end;
end;

function Split(const S: string; const Sep: string): TStringArray;
var
  SepLen, StrLen, i, Start, Count: NativeInt;
begin
  Result := nil;
  Count := 0;

  SepLen := System.Length(Sep);
  StrLen := System.Length(S);

  if SepLen = 0 then
  begin
    // No separator: return the whole string as one item
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;

  Start := 1;
  i := 1;
  while i <= StrLen - SepLen + 1 do
  begin
    if CompareByte(PChar(S)[i - 1], PChar(Sep)^, SepLen * SizeOf(Char)) = 0 then
    begin
      SetLength(Result, Count + 1);
      Result[Count] := System.Copy(S, Start, i - Start);
      Inc(Count);
      Inc(i, SepLen);
      Start := i;
    end
    else
      Inc(i);
  end;

  // Last piece
  SetLength(Result, Count + 1);
  Result[Count] := System.Copy(S, Start, StrLen - Start + 1);
end;

function Join(const Arr: TStringArray; const Sep: string): string;
var
  i, Count, SepLen, TotalLen: NativeInt;
  P: PChar;
begin
  Count := System.Length(Arr);
  if Count = 0 then Exit('');

  SepLen := System.Length(Sep);

  TotalLen := System.Length(Arr[0]);
  for i := 1 to Count - 1 do
    Inc(TotalLen, SepLen + System.Length(Arr[i]));

  SetLength(Result, TotalLen);
  if TotalLen = 0 then Exit;

  P := PChar(Result);

  // Copy first item
  Move(PChar(Arr[0])^, P^, System.Length(Arr[0]) * SizeOf(Char));
  Inc(P, System.Length(Arr[0]));

  // Copy separator + item for remaining
  for i := 1 to Count - 1 do
  begin
    Move(PChar(Sep)^, P^, SepLen * SizeOf(Char));
    Inc(P, SepLen);
    Move(PChar(Arr[i])^, P^, System.Length(Arr[i]) * SizeOf(Char));
    Inc(P, System.Length(Arr[i]));
  end;
end;

function PrependIfMissing(const Str, Prefix: string): string;
begin
  if BeginsWith(Str, Prefix) then
    Result := Str
  else
    Result := Prefix + Str;
end;

function AppendIfMissing(const Str, Suffix: string): string;
begin
  if EndsWith(Str, Suffix) then
    Result := Str
  else
    Result := Str + Suffix;
end;

function Reverse(const S: string): string;
var
  i, j, Start, Len, L: NativeInt;
begin
  L := System.Length(S);
  SetLength(Result, L);
  if L = 0 then Exit;

  i := L;   { 1-based index of the last byte of the next code point to emit }
  j := 1;
  while i >= 1 do
  begin
    { Walk back over continuation bytes (10xxxxxx) to the leading byte. }
    Start := i;
    while (Start > 1) and ((Ord(S[Start]) and $C0) = $80) do
      Dec(Start);

    Len := i - Start + 1;
    Move(PChar(S)[Start - 1], PChar(Result)[j - 1], Len);
    Inc(j, Len);
    i := Start - 1;
  end;
end;

end.
