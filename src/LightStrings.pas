// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
unit LightStrings;

{$mode objfpc}{$H+}
{$Modeswitch AdvancedRecords}
{$Modeswitch TypeHelpers}
{$INLINE ON}
{$POINTERMATH ON}
{$RANGECHECKS OFF}

interface

const
  GROWTH_CHUNK = 1048576;

{$IFDEF WINDOWS}
  LineEnding = #13#10;
{$ELSE}
  LineEnding = #10;
{$ENDIF}

type
   PStr = ^string;

  TBuildStr = record
    FBuffer: PChar;
    FCapacity: NativeInt;
    FLength: NativeInt;

    class function MinVal(A, B: NativeInt): NativeInt; static; inline;
    class function MaxVal(A, B: NativeInt): NativeInt; static; inline;

    procedure Grow(Required: NativeInt);

    class operator Initialize(var Str: TBuildStr);
    class operator Finalize(var Str: TBuildStr);
    class operator Copy(constref Src: TBuildStr; var Dest: TBuildStr);

    procedure Init(InitialCapacity: NativeInt = 256); inline;
    procedure EnsureCapacity(MinCapacity: NativeInt); inline;

    procedure Append(const S: string); inline;
    procedure Append(const P: PChar; Len: NativeInt); inline;
    procedure Append(const C: Char); inline;
    procedure Append(Value: Int64);
    procedure AppendLine(const S: string = ''); inline;

    procedure Chop(N: NativeInt); inline;
    procedure Clear; inline;
    function ToString: string;

    function GetLength: NativeInt; inline;
    procedure SetLength(NewLength: NativeInt);
    function GetCapacity: NativeInt; inline;
    procedure SetCapacity(NewCapacity: NativeInt);
    function GetChar(Index: NativeInt): Char; inline;
    procedure SetChar(Index: NativeInt; Value: Char); inline;

    property Length: NativeInt read GetLength write SetLength;
    property Capacity: NativeInt read GetCapacity write SetCapacity;
    property Chars[Index: NativeInt]: Char read GetChar write SetChar; default;
  end;

  PStrList = ^TStrList;

  TStrListEnumerator = record
  private
    FList: PStrList;
    FIndex: NativeInt;
    function GetCurrent: string; inline;
  public
    function MoveNext: Boolean; inline;
    property Current: string read GetCurrent;
  end;

  TStrList = record
  private
    procedure QuickSort(var A: array of string; iLo, iHi: NativeInt);
    procedure NaturalQuickSort(var A: array of string; iLo, iHi: NativeInt);
    function SortedInsertIndex(const S: string): NativeInt;
    function AddSlow(const S: string): NativeInt;
  public
    FItems: array of string;
    FCount: NativeInt;
    FDelimiter: Char;
    FStrictDelimiter: Boolean;
    FSorted: Boolean;

    class operator Initialize(var List: TStrList);
    class operator Finalize(var List: TStrList);
    class operator Copy(constref Src: TStrList; var Dest: TStrList);

    procedure Init(InitialCapacity: NativeInt = 16); inline;
    function Add(const S: string): NativeInt; inline;
    procedure Clear; inline;
    function GetEnumerator: TStrListEnumerator; inline;

    { Sorting / search }
    procedure Sort;
    procedure NaturalSort;
    procedure Reverse;
    function IndexOf(const S: string): NativeInt;
    function ItemOf(const S: string): NativeInt; inline;

    { Mutation }
    procedure Delete(Index: NativeInt);
    procedure Insert(Index: NativeInt; const S: string);
    procedure Exchange(Index1, Index2: NativeInt);
    procedure Move(CurIndex, NewIndex: NativeInt);
    procedure MoveItem(CurIndex, NewIndex: NativeInt); inline;

    { Name/Value }
    const NameValueSeparator: Char = '=';
    function IndexOfName(const Name: string): NativeInt;
    function GetName(Index: NativeInt): string;
    function GetValueFromIndex(Index: NativeInt): string;
    procedure SetValueFromIndex(Index: NativeInt; const Value: string);
    function GetValue(const Name: string): string;
    procedure SetValue(const Name, Value: string);
    function AddPair(const AName, AValue: string): NativeInt;

    { Text / Delimited }
    function GetText: string;
    function GetCommaText: string;
    function GetDelimitedText: string;
    function GetItem(Index: NativeInt): string;
    function GetCount: NativeInt;
    function GetCapacity: NativeInt; inline;
    function GetDelimiter: Char;
    function GetStrictDelimiter: Boolean;
    function GetSorted: Boolean;

    procedure SetText(const Value: string);
    procedure SetCommaText(const Value: string);
    procedure SetDelimitedText(const Value: string);
    procedure SetItem(Index: NativeInt; const Value: string);
    procedure SetCapacity(NewCapacity: NativeInt);
    procedure SetDelimiter(const Value: Char);
    procedure SetStrictDelimiter(const Value: Boolean);
    procedure SetSorted(Value: Boolean);

    property Text: string read GetText write SetText;
    property CommaText: string read GetCommaText write SetCommaText;
    property DelimitedText: string read GetDelimitedText write SetDelimitedText;
    property Items[Index: NativeInt]: string read GetItem write SetItem; default;
    property Count: NativeInt read GetCount;
    property Capacity: NativeInt read GetCapacity write SetCapacity;
    property Delimiter: Char read GetDelimiter write SetDelimiter;
    property StrictDelimiter: Boolean read GetStrictDelimiter write SetStrictDelimiter;
    property Sorted: Boolean read GetSorted write SetSorted;
    property Names[Index: NativeInt]: string read GetName;
    property ValueFromIndex[Index: NativeInt]: string read GetValueFromIndex write SetValueFromIndex;
    property Values[const Name: string]: string read GetValue write SetValue;

    { File I/O }
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);

    { Sorted }
    function Find(const S: string; out Index: NativeInt): Boolean;
  end;

{ ------------------------------------------------------------------- }
{  TStringView — zero-copy view into an existing string                }
{ ------------------------------------------------------------------- }

type
  TStringView = record
  private
    FData: PChar;
    FLength: NativeInt;

    function GetChar(Index: NativeInt): Char; inline;
  public
    class function Create(const S: string): TStringView; static; inline;

    function IsEmpty: Boolean; inline;
    function Length: NativeInt; inline;
    property Chars[Index: NativeInt]: Char read GetChar; default;

    function beginsWith(const S: string): Boolean;
    function beginsWith(C: Char): Boolean; inline;
    function endsWith(const S: string): Boolean;
    function endsWith(C: Char): Boolean; inline;
    function contains(const S: string): Boolean;
    function find(const S: string): TStringView;
    function trim: TStringView;
    function trimLeft: TStringView;
    function trimRight: TStringView;
    function splitAtFind(const Sep: string; out Before, After: TStringView): Boolean; inline;
    function toInt(out Value: Integer): Boolean;
    function toInt64(out Value: Int64): Boolean;
    function toString: string; inline;
    function slice(Start: NativeInt; Count: NativeInt = MaxInt): TStringView;
  end;

  TStringViewHelper = type helper for String
    function View: TStringView; inline;
  end;

{ Standalone string utility functions }

function NaturalCompareText(const S1, S2: string): Integer;
function LastChar(const S: string): Char; inline;
function LastChars(const S: string; Count: NativeInt): string;

implementation

{ ------------------------------------------------------------------- }
{  Helper functions (replacements for SysUtils routines)              }
{ ------------------------------------------------------------------- }

{
function QuoteStr(const S: string; QuoteChar: Char): string;
var
  i, j, L, Extra: Integer;
begin
  L := System.Length(S);
  Extra := 0;
  for i := 1 to L do
    if S[i] = QuoteChar then
      Inc(Extra);
  SetLength(Result, L + Extra + 2);
  Result[1] := QuoteChar;
  j := 2;
  for i := 1 to L do
  begin
    if S[i] = QuoteChar then
    begin
      Result[j] := QuoteChar;
      Inc(j);
    end;
    Result[j] := S[i];
    Inc(j);
  end;
  Result[j] := QuoteChar;
end;
}

procedure AppendQuoted(var Builder: TBuildStr; P: PChar; L: NativeInt; QuoteChar: Char);
var
  i, Extra: NativeInt;
  Dest: PChar;
begin
  Extra := 0;
  for i := 0 to L - 1 do
    if P[i] = QuoteChar then
      Inc(Extra);

  if Builder.FLength + L + Extra + 2 > Builder.FCapacity then
    Builder.Grow(Builder.FLength + L + Extra + 2);

  Dest := @Builder.FBuffer[Builder.FLength];
  Dest^ := QuoteChar;
  Inc(Dest);

  if Extra = 0 then
  begin
    if L > 0 then
    begin
      Move(P^, Dest^, L * SizeOf(Char));
      Inc(Dest, L);
    end;
  end
  else
  begin
    for i := 0 to L - 1 do
    begin
      if P[i] = QuoteChar then
      begin
        Dest^ := QuoteChar;
        Inc(Dest);
      end;
      Dest^ := P[i];
      Inc(Dest);
    end;
  end;

  Dest^ := QuoteChar;
  Inc(Builder.FLength, L + Extra + 2);
end;

function DequoteStr(const S: string; QuoteChar: Char): string;
var
  L, i, j: Integer;
begin
  L := System.Length(S);
  if (L >= 2) and (S[1] = QuoteChar) and (S[L] = QuoteChar) then
  begin
    SetLength(Result, L - 2);
    j := 1;
    i := 2;
    while i <= L - 1 do
    begin
      if (i < L - 1) and (S[i] = QuoteChar) and (S[i+1] = QuoteChar) then
      begin
        Result[j] := QuoteChar;
        Inc(j);
        Inc(i, 2);
      end
      else
      begin
        Result[j] := S[i];
        Inc(j);
        Inc(i);
      end;
    end;
    SetLength(Result, j - 1);
  end
  else
    Result := S;
end;

{ ------------------------------------------------------------------- }
{  TBuildStr                                                           }
{ ------------------------------------------------------------------- }

class function TBuildStr.MinVal(A, B: NativeInt): NativeInt;
begin
  if A < B then Result := A else Result := B;
end;

class function TBuildStr.MaxVal(A, B: NativeInt): NativeInt;
begin
  if A > B then Result := A else Result := B;
end;

procedure TBuildStr.Grow(Required: NativeInt);
var
  PreferredGrowth, MinRequiredGrowth: NativeInt;
begin
  if Required <= FCapacity then Exit;

  PreferredGrowth := MinVal(FCapacity, GROWTH_CHUNK);
  MinRequiredGrowth := Required - FCapacity;
  FCapacity := FCapacity + MaxVal(MinRequiredGrowth, PreferredGrowth);
  FCapacity := (FCapacity + 15) and (not NativeInt(15));

  ReallocMem(FBuffer, FCapacity * SizeOf(Char));
end;

class operator TBuildStr.Initialize(var Str: TBuildStr);
begin
  Str.FBuffer := nil;
  Str.FCapacity := 0;
  Str.FLength := 0;
end;

class operator TBuildStr.Finalize(var Str: TBuildStr);
begin
  if Str.FBuffer <> nil then
  begin
    FreeMem(Str.FBuffer);
    Str.FBuffer := nil;
  end;
end;

class operator TBuildStr.Copy(constref Src: TBuildStr; var Dest: TBuildStr);
begin
  // FPC initializes the destination but does not finalize it before Copy, so
  // an existing buffer would leak (and self-assignment would free the source).
  if Dest.FBuffer = Src.FBuffer then Exit;
  if Dest.FBuffer <> nil then
    FreeMem(Dest.FBuffer);

  Dest.FLength := Src.FLength;
  Dest.FCapacity := Src.FCapacity;

  if Src.FBuffer <> nil then
  begin
    GetMem(Dest.FBuffer, Dest.FCapacity * SizeOf(Char));
    if Dest.FLength > 0 then
      Move(Src.FBuffer^, Dest.FBuffer^, Dest.FLength * SizeOf(Char));
  end
  else
  begin
    Dest.FBuffer := nil;
    Dest.FCapacity := 0;
  end;
end;

procedure TBuildStr.Init(InitialCapacity: NativeInt);
begin
  // Init may be called on an already-used builder; release the old buffer or
  // it leaks (Finalize only ever sees the last one).
  if FBuffer <> nil then
    FreeMem(FBuffer);

  FCapacity := InitialCapacity;
  if FCapacity <= 0 then FCapacity := 256;
  FLength := 0;
  GetMem(FBuffer, FCapacity * SizeOf(Char));
end;

procedure TBuildStr.EnsureCapacity(MinCapacity: NativeInt);
begin
  if MinCapacity > FCapacity then
    Grow(MinCapacity);
end;

procedure TBuildStr.Append(const S: string);
var
  L: NativeInt;
begin
  L := System.Length(S);

  if FLength + L > FCapacity then
    Grow(FLength + L);

  if L > 0 then
    System.Move(PChar(Pointer(S))^, FBuffer[FLength], L * SizeOf(Char));

  Inc(FLength, L);
end;

procedure TBuildStr.Append(const P: PChar; Len: NativeInt);
begin
  if Len <= 0 then Exit;

  if FLength + Len > FCapacity then
    Grow(FLength + Len);

  Move(P^, FBuffer[FLength], Len * SizeOf(Char));
  Inc(FLength, Len);
end;

procedure TBuildStr.Append(const C: Char);
begin
  if FLength >= FCapacity then
    Grow(FLength + 1);

  FBuffer[FLength] := C;
  Inc(FLength);
end;

procedure TBuildStr.Append(Value: Int64);
var
  Buf: array[0..20] of Char;
  U: QWord;
  Neg: Boolean;
  Idx: NativeInt;
begin
  if Value = 0 then
  begin
    Append('0');
    Exit;
  end;

  if Value < 0 then
  begin
    Neg := True;
    // Two's complement in QWord avoids overflow even for Low(Int64).
    U := QWord(not Value) + 1;
  end
  else
  begin
    Neg := False;
    U := QWord(Value);
  end;

  // Render backwards into a stack buffer: no heap allocation at all.
  Idx := 21;
  while U > 0 do
  begin
    Dec(Idx);
    Buf[Idx] := Char(Ord('0') + (U mod 10));
    U := U div 10;
  end;

  if Neg then
  begin
    Dec(Idx);
    Buf[Idx] := '-';
  end;

  Append(@Buf[Idx], 21 - Idx);
end;

procedure TBuildStr.AppendLine(const S: string);
begin
  Append(S);
  Append(LineEnding);
end;

procedure TBuildStr.Chop(N: NativeInt);
begin
  if N <= 0 then Exit;
  if N >= FLength then
    FLength := 0
  else
    Dec(FLength, N);
end;

procedure TBuildStr.Clear;
begin
  FLength := 0;
end;

function TBuildStr.ToString: string;
begin
  // System-qualified: TBuildStr.SetLength would otherwise shadow the routine.
  System.SetLength(Result, FLength);
  if FLength > 0 then
    System.Move(FBuffer[0], PChar(Pointer(Result))^, FLength * SizeOf(Char));
end;

function TBuildStr.GetLength: NativeInt;
begin
  Result := FLength;
end;

procedure TBuildStr.SetLength(NewLength: NativeInt);
begin
  if NewLength < 0 then
  begin
    RunError(201);
    Exit;
  end;

  if NewLength > FCapacity then
    Grow(NewLength);

  // TStringBuilder semantics: extension is zero-filled, shrinking truncates.
  if NewLength > FLength then
    FillChar(FBuffer[FLength], (NewLength - FLength) * SizeOf(Char), 0);

  FLength := NewLength;
end;

function TBuildStr.GetCapacity: NativeInt;
begin
  Result := FCapacity;
end;

procedure TBuildStr.SetCapacity(NewCapacity: NativeInt);
begin
  if NewCapacity < FLength then
  begin
    RunError(201);
    Exit;
  end;

  if NewCapacity = FCapacity then Exit;

  if NewCapacity = 0 then
  begin
    if FBuffer <> nil then
    begin
      FreeMem(FBuffer);
      FBuffer := nil;
    end;
    FCapacity := 0;
  end
  else
  begin
    ReallocMem(FBuffer, NewCapacity * SizeOf(Char));
    FCapacity := NewCapacity;
  end;
end;

function TBuildStr.GetChar(Index: NativeInt): Char;
begin
  if (Index < 0) or (Index >= FLength) then
  begin
    RunError(201);
    Exit(#0);
  end;
  Result := FBuffer[Index];
end;

procedure TBuildStr.SetChar(Index: NativeInt; Value: Char);
begin
  if (Index < 0) or (Index >= FLength) then
  begin
    RunError(201);
    Exit;
  end;
  FBuffer[Index] := Value;
end;

{ ------------------------------------------------------------------- }
{  TStrList — managed record operators                                 }
{ ------------------------------------------------------------------- }

class operator TStrList.Initialize(var List: TStrList);
begin
  List.FCount := 0;
  List.FItems := nil;
  List.FDelimiter := ',';
  List.FStrictDelimiter := False;
  List.FSorted := False;
end;

class operator TStrList.Finalize(var List: TStrList);
begin
  List.FItems := nil;
  List.FCount := 0;
end;

class operator TStrList.Copy(constref Src: TStrList; var Dest: TStrList);
var
  i: NativeInt;
begin
  Dest.FCount := Src.FCount;
  Dest.FDelimiter := Src.FDelimiter;
  Dest.FStrictDelimiter := Src.FStrictDelimiter;
  Dest.FSorted := Src.FSorted;
  SetLength(Dest.FItems, System.Length(Src.FItems));
  for i := 0 to Src.FCount - 1 do
    Dest.FItems[i] := Src.FItems[i];
end;

{ ------------------------------------------------------------------- }
{  TStrList — core methods                                             }
{ ------------------------------------------------------------------- }

procedure TStrList.Init(InitialCapacity: NativeInt);
begin
  FCount := 0;
  if InitialCapacity <= 0 then InitialCapacity := 16;
  SetLength(FItems, InitialCapacity);
end;

function TStrList.SortedInsertIndex(const S: string): NativeInt;
var
  Lo, Hi, Mid: NativeInt;
begin
  Lo := 0;
  Hi := FCount - 1;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FItems[Mid] < S then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
  Result := Lo;
end;

function TStrList.AddSlow(const S: string): NativeInt;
var
  Cap, Index, i: NativeInt;
begin
  Cap := System.Length(FItems);
  if Cap = 0 then
  begin
    // A default-initialized record has no storage: grow from zero, not 0 * 2.
    Cap := 16;
    SetLength(FItems, Cap);
  end
  else if FCount >= Cap then
    SetLength(FItems, Cap * 2);

  if FSorted then
  begin
    // Keep the invariant Find depends on: a sorted list stays sorted.
    Index := SortedInsertIndex(S);
    for i := FCount downto Index + 1 do
      FItems[i] := FItems[i - 1];
  end
  else
    Index := FCount;

  FItems[Index] := S;
  Inc(FCount);
  Result := Index;
end;

function TStrList.Add(const S: string): NativeInt;
begin
  if (not FSorted) and (FCount < System.Length(FItems)) then
  begin
    Result := FCount;
    FItems[Result] := S;
    Inc(FCount);
  end
  else
    Result := AddSlow(S);
end;

procedure TStrList.Clear;
begin
  FCount := 0;
end;

{ ------------------------------------------------------------------- }
{  TStrList — enumeration                                              }
{ ------------------------------------------------------------------- }

function TStrListEnumerator.GetCurrent: string;
begin
  Result := FList^.FItems[FIndex];
end;

function TStrListEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList^.FCount;
end;

function TStrList.GetEnumerator: TStrListEnumerator;
begin
  Result.FList := @Self;
  Result.FIndex := -1;
end;

{ ------------------------------------------------------------------- }
{  TStrList — getters                                                  }
{ ------------------------------------------------------------------- }

function TStrList.GetCount: NativeInt;
begin
  Result := FCount;
end;

function TStrList.GetCapacity: NativeInt;
begin
  Result := System.Length(FItems);
end;

function TStrList.GetDelimiter: Char;
begin
  Result := FDelimiter;
end;

function TStrList.GetStrictDelimiter: Boolean;
begin
  Result := FStrictDelimiter;
end;

function TStrList.GetSorted: Boolean;
begin
  Result := FSorted;
end;

function TStrList.GetItem(Index: NativeInt): string;
begin
  Result := FItems[Index];
end;

function TStrList.GetText: string;
var
  i, ItemCount, TotalLen, L: NativeInt;
  ItemPtr: PStr;
  P: PChar;
begin
  ItemCount := FCount;
  if ItemCount = 0 then Exit('');

  ItemPtr := @FItems[0];
  TotalLen := 0;
  for i := 0 to Count - 1 do
    TotalLen := TotalLen + System.Length(ItemPtr[i]);

  TotalLen := TotalLen + System.Length(LineEnding) * ItemCount;

  SetLength(Result, TotalLen);
  if TotalLen = 0 then Exit;
  P := PChar(Pointer(Result));

  for i := 0 to Count - 1 do
  begin
    L := System.Length(ItemPtr[i]);
    if L > 0 then
    begin
      System.Move(PChar(Pointer(ItemPtr[i]))^, P^, L * SizeOf(Char));
      Inc(P, L);
    end;
    {$IFDEF WINDOWS}
    P[0] := #13;
    P[1] := #10;
    Inc(P, 2);
    {$ELSE}
    P^ := LineEnding;
    Inc(P);
    {$ENDIF}
  end;
end;

function TStrList.GetCommaText: string;
begin
  Result := GetDelimitedText;
end;

function TStrList.GetDelimitedText: string;
var
  i, j, L, ItemCount: NativeInt;
  P: PChar;
  Delim, C: Char;
  Strict, NeedsQuote: Boolean;
  Builder: TBuildStr;
begin
  ItemCount := FCount;
  if ItemCount = 0 then Exit('');

  Delim := FDelimiter;
  Strict := FStrictDelimiter;
  Builder.Init(Count * 64);

  for i := 0 to Count - 1 do
  begin
    if i > 0 then Builder.Append(Delim);

    L := System.Length(FItems[i]);
    P := PChar(Pointer(FItems[i]));

    if Strict then
      Builder.Append(P, L)
    else
    begin
      NeedsQuote := False;
      for j := 0 to L - 1 do
      begin
        C := P[j];
        if (C = Delim) or (C = '"') or (C = ' ') then
        begin
          NeedsQuote := True;
          Break;
        end;
      end;

      if NeedsQuote then
        AppendQuoted(Builder, P, L, '"')
      else
        Builder.Append(P, L);
    end;
  end;

  Result := Builder.ToString;
end;

{ ------------------------------------------------------------------- }
{  TStrList — setters                                                  }
{ ------------------------------------------------------------------- }

procedure TStrList.SetText(const Value: string);
var
  P, Start: PChar;
  Line: string;
  L: NativeInt;
begin
  Self.Clear;

  if Value = '' then Exit;

  P := PChar(Value);
  Start := P;

  while P^ <> #0 do
  begin
    if (P^ = #13) or (P^ = #10) then
    begin
      L := P - Start;
      if L > 0 then
      begin
        SetLength(Line, L);
        System.Move(Start^, Line[1], L * SizeOf(Char));
      end
      else
        Line := '';
      // Blank lines are real items; dropping them loses data on a Text round-trip.
      Self.Add(Line);

      if (P^ = #13) and (P[1] = #10) then Inc(P);
      Start := P + 1;
    end;
    Inc(P);
  end;

  if P > Start then
  begin
    L := P - Start;
    SetLength(Line, L);
    System.Move(Start^, Line[1], L * SizeOf(Char));
    Self.Add(Line);
  end;
end;

procedure TStrList.SetItem(Index: NativeInt; const Value: string);
begin
  // Changing an item in place can break the ordering Find relies on.
  if FSorted and (FItems[Index] <> Value) then
    FSorted := False;
  FItems[Index] := Value;
end;

procedure TStrList.SetCapacity(NewCapacity: NativeInt);
begin
  if NewCapacity < FCount then
  begin
    RunError(201);
    Exit;
  end;
  if NewCapacity <> System.Length(FItems) then
    SetLength(FItems, NewCapacity);
end;

procedure TStrList.SetDelimiter(const Value: Char);
begin
  FDelimiter := Value;
end;

procedure TStrList.SetStrictDelimiter(const Value: Boolean);
begin
  FStrictDelimiter := Value;
end;

procedure TStrList.SetSorted(Value: Boolean);
begin
  if FSorted = Value then Exit;
  FSorted := Value;
  if FSorted then
    Sort;
end;

procedure TStrList.SetCommaText(const Value: string);
var
  SavedDelim: Char;
begin
  SavedDelim := FDelimiter;
  FDelimiter := ',';
  SetDelimitedText(Value);
  FDelimiter := SavedDelim;
end;

procedure TStrList.SetDelimitedText(const Value: string);
var
  P, Start: PChar;
  S: string;
  L: NativeInt;
  InQuote: Boolean;
begin
  Self.Clear;
  if Value = '' then Exit;

  P := PChar(Value);
  Start := P;
  InQuote := False;

  while P^ <> #0 do
  begin
    case P^ of
      '"':
        InQuote := not InQuote;

      #10, #13:
        begin
          { Skip line breaks in delimited mode }
        end;

      else
        if (not InQuote) and (P^ = FDelimiter) then
        begin
          L := P - Start;
          SetLength(S, L);
          if L > 0 then System.Move(Start^, S[1], L * SizeOf(Char));
          Self.Add(DequoteStr(S, '"'));
          Start := P + 1;
        end;
    end;
    Inc(P);
  end;

  if P > Start then
  begin
    L := P - Start;
    SetLength(S, L);
    System.Move(Start^, S[1], L * SizeOf(Char));
    Self.Add(DequoteStr(S, '"'));
  end;
end;

{ ------------------------------------------------------------------- }
{  TStrList — Sorting & IndexOf                                        }
{ ------------------------------------------------------------------- }

procedure TStrList.QuickSort(var A: array of string; iLo, iHi: NativeInt);
var
  Lo, Hi: NativeInt;
  ItemPtr: PStr;
  PivotPtr, TempPtr: Pointer;
begin
  ItemPtr := PStr(@A[0]);
  Lo := iLo;
  Hi := iHi;
  PivotPtr := Pointer(ItemPtr[(Lo + Hi) shr 1]);
  repeat
    while ItemPtr[Lo] < PStr(@PivotPtr)^ do Inc(Lo);
    while ItemPtr[Hi] > PStr(@PivotPtr)^ do Dec(Hi);
    if Lo <= Hi then
    begin
      TempPtr := PPointer(ItemPtr)[Lo];
      PPointer(ItemPtr)[Lo] := PPointer(ItemPtr)[Hi];
      PPointer(ItemPtr)[Hi] := TempPtr;
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;

  if Hi > iLo then QuickSort(A, iLo, Hi);
  if Lo < iHi then QuickSort(A, Lo, iHi);
end;

procedure TStrList.NaturalQuickSort(var A: array of string; iLo, iHi: NativeInt);
var
  Lo, Hi: NativeInt;
  ItemPtr: PStr;
  PivotPtr, TempPtr: Pointer;
begin
  ItemPtr := PStr(@A[0]);
  Lo := iLo;
  Hi := iHi;
  PivotPtr := Pointer(ItemPtr[(Lo + Hi) shr 1]);
  repeat
    while NaturalCompareText(ItemPtr[Lo], PStr(@PivotPtr)^) < 0 do Inc(Lo);
    while NaturalCompareText(ItemPtr[Hi], PStr(@PivotPtr)^) > 0 do Dec(Hi);
    if Lo <= Hi then
    begin
      TempPtr := PPointer(ItemPtr)[Lo];
      PPointer(ItemPtr)[Lo] := PPointer(ItemPtr)[Hi];
      PPointer(ItemPtr)[Hi] := TempPtr;
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;

  if Hi > iLo then NaturalQuickSort(A, iLo, Hi);
  if Lo < iHi then NaturalQuickSort(A, Lo, iHi);
end;


procedure TStrList.Sort;
begin
  if FCount > 1 then
    QuickSort(FItems, 0, FCount - 1);
  // The list is now in ascending order, which is what Find assumes.
  FSorted := True;
end;

procedure TStrList.NaturalSort;
begin
  if FCount > 1 then
    NaturalQuickSort(FItems, 0, FCount - 1);
  // Natural order is not the byte order Find binary-searches for, so the
  // sorted flag must not claim it is.
  FSorted := False;
end;

procedure TStrList.Reverse;
var
  i, j: NativeInt;
  Ptrs: PPointer;
  TempPtr: Pointer;
begin
  if FCount > 1 then
  begin
    Ptrs := PPointer(@FItems[0]);
    i := 0;
    j := FCount - 1;
    while i < j do
    begin
      TempPtr := Ptrs[i];
      Ptrs[i] := Ptrs[j];
      Ptrs[j] := TempPtr;
      Inc(i);
      Dec(j);
    end;
  end;
  // Descending order is not the ordering Find relies on.
  FSorted := False;
end;

function TStrList.IndexOf(const S: string): NativeInt;
var
  i, ItemCount, SL, ByteLen: NativeInt;
  ItemPtr: PStr;
  SPtr, ItemP: PChar;
  FirstChar: Char;
begin
  ItemCount := FCount;
  if ItemCount = 0 then Exit(-1);

  ItemPtr := @FItems[0];
  SL := System.Length(S);

  if SL = 0 then
  begin
    for i := 0 to ItemCount - 1 do
      if System.Length(ItemPtr[i]) = 0 then
        Exit(i);
    Exit(-1);
  end;

  SPtr := PChar(Pointer(S));
  FirstChar := SPtr^;
  ByteLen := SL * SizeOf(Char);

  for i := 0 to ItemCount - 1 do
  begin
    if System.Length(ItemPtr[i]) = SL then
    begin
      ItemP := PChar(Pointer(ItemPtr[i]));
      if (ItemP = SPtr) or
         ((ItemP^ = FirstChar) and (CompareByte(ItemP^, SPtr^, ByteLen) = 0)) then
        Exit(i);
    end;
  end;

  Result := -1;
end;

function TStrList.ItemOf(const S: string): NativeInt;
begin
  Result := IndexOf(S);
end;

{ ------------------------------------------------------------------- }
{  TStrList — Mutation                                                 }
{ ------------------------------------------------------------------- }

procedure TStrList.Delete(Index: NativeInt);
var
  i: NativeInt;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RunError(201);
    Exit;
  end;

  Dec(FCount);
  for i := Index to FCount - 1 do
    FItems[i] := FItems[i + 1];
  FItems[FCount] := '';
end;

procedure TStrList.Insert(Index: NativeInt; const S: string);
var
  OldCap, i: NativeInt;
begin
  if (Index < 0) or (Index > FCount) then
  begin
    RunError(201);
    Exit;
  end;

  OldCap := System.Length(FItems);
  if OldCap = 0 then
  begin
    // Default-initialized record: grow from zero instead of 0 * 2.
    OldCap := 16;
    SetLength(FItems, OldCap);
  end
  else if FCount >= OldCap then
    SetLength(FItems, OldCap * 2);

  for i := FCount downto Index + 1 do
    FItems[i] := FItems[i - 1];
  FItems[Index] := S;
  Inc(FCount);

  // An insertion at an arbitrary position can break the ordering Find relies
  // on, so the sorted flag cannot be trusted afterwards.
  FSorted := False;
end;

procedure TStrList.Exchange(Index1, Index2: NativeInt);
var
  Temp: string;
begin
  if (Index1 < 0) or (Index1 >= FCount) or
     (Index2 < 0) or (Index2 >= FCount) then
  begin
    RunError(201);
    Exit;
  end;

  if Index1 = Index2 then Exit;

  Temp := FItems[Index1];
  FItems[Index1] := FItems[Index2];
  FItems[Index2] := Temp;

  // Swapping two items generally breaks the ordering Find relies on.
  FSorted := False;
end;

procedure TStrList.Move(CurIndex, NewIndex: NativeInt);
var
  TempPtr: Pointer;
  Ptrs: PPointer;
  i: NativeInt;
begin
  if CurIndex = NewIndex then Exit;
  if (CurIndex < 0) or (CurIndex >= FCount) or
     (NewIndex < 0) or (NewIndex >= FCount) then
  begin
    RunError(201);
    Exit;
  end;

  // Shift raw string pointers: no per-element reference-count traffic.
  Ptrs := PPointer(@FItems[0]);
  TempPtr := Ptrs[CurIndex];
  if CurIndex < NewIndex then
  begin
    for i := CurIndex to NewIndex - 1 do
      Ptrs[i] := Ptrs[i + 1];
  end
  else
  begin
    for i := CurIndex downto NewIndex + 1 do
      Ptrs[i] := Ptrs[i - 1];
  end;
  Ptrs[NewIndex] := TempPtr;

  // Reordering breaks the ordering Find relies on.
  FSorted := False;
end;

procedure TStrList.MoveItem(CurIndex, NewIndex: NativeInt);
begin
  Move(CurIndex, NewIndex);
end;

{ ------------------------------------------------------------------- }
{  TStrList — Name / Value                                             }
{ ------------------------------------------------------------------- }

function TStrList.IndexOfName(const Name: string): NativeInt;
var
  i, NameLen, ItemLen: NativeInt;
  P: PChar;
begin
  NameLen := System.Length(Name);
  for i := 0 to FCount - 1 do
  begin
    ItemLen := System.Length(FItems[i]);
    if ItemLen > NameLen then
    begin
      P := PChar(FItems[i]);
      if (P[NameLen] = NameValueSeparator) and
         (CompareByte(P^, PChar(Name)^, NameLen * SizeOf(Char)) = 0) then
        Exit(i);
    end;
  end;
  Result := -1;
end;

function TStrList.GetName(Index: NativeInt): string;
var
  P: NativeInt;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RunError(201);
    Exit;
  end;

  P := System.Pos(NameValueSeparator, FItems[Index]);
  if P > 0 then
    Result := System.Copy(FItems[Index], 1, P - 1)
  else
    Result := '';
end;

function TStrList.GetValueFromIndex(Index: NativeInt): string;
var
  P: NativeInt;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RunError(201);
    Exit;
  end;

  P := System.Pos(NameValueSeparator, FItems[Index]);
  if P > 0 then
    Result := System.Copy(FItems[Index], P + 1, System.Length(FItems[Index]) - P)
  else
    Result := '';
end;

procedure TStrList.SetValueFromIndex(Index: NativeInt; const Value: string);
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    RunError(201);
    Exit;
  end;

  // TStrings semantics: an empty value removes the entry entirely.
  if Value <> '' then
    SetItem(Index, GetName(Index) + NameValueSeparator + Value)
  else
    Delete(Index);
end;

function TStrList.GetValue(const Name: string): string;
var
  Idx: NativeInt;
begin
  Idx := IndexOfName(Name);
  if Idx >= 0 then
    Result := GetValueFromIndex(Idx)
  else
    Result := '';
end;

procedure TStrList.SetValue(const Name, Value: string);
var
  Idx: NativeInt;
begin
  Idx := IndexOfName(Name);
  if Value <> '' then
  begin
    if Idx >= 0 then
      SetItem(Idx, Name + NameValueSeparator + Value)
    else
      AddPair(Name, Value);
  end
  else if Idx >= 0 then
    Delete(Idx);
end;

function TStrList.AddPair(const AName, AValue: string): NativeInt;
begin
  // Add returns the real insertion index, which differs from FCount when the
  // list is sorted.
  Result := Self.Add(AName + NameValueSeparator + AValue);
end;

{ ------------------------------------------------------------------- }
{  TStrList — File I/O (using standard Pascal file routines)          }
{ ------------------------------------------------------------------- }

procedure TStrList.SaveToFile(const FileName: string);
var
  F: File;
  Buf: string;
  TotalBytes, Offset: NativeInt;
  Chunk: LongInt;
begin
  Buf := GetText;
  TotalBytes := System.Length(Buf) * SizeOf(Char);

  Assign(F, FileName);
  Rewrite(F, 1);
  try
    Offset := 0;
    while Offset < TotalBytes do
    begin
      if TotalBytes - Offset > High(LongInt) then
        Chunk := High(LongInt)
      else
        Chunk := LongInt(TotalBytes - Offset);
      BlockWrite(F, PByte(Pointer(Buf))[Offset], Chunk);
      Inc(Offset, Chunk);
    end;
  finally
    Close(F);
  end;
end;

procedure TStrList.LoadFromFile(const FileName: string);
var
  F: File;
  Size: Int64;
  Buf: string;
  P, Start, EndP: PChar;
  Line: string;
  L, Cap: NativeInt;
  {$IF SizeOf(Char) = 1}
  Idx: SizeInt;
  {$ENDIF}
begin
  Self.Clear;

  Assign(F, FileName);
  {$I-}
  Reset(F, 1);
  {$I+}
  if IOResult <> 0 then Exit;

  Size := FileSize(F);
  if Size <= 0 then
  begin
    Close(F);
    Exit;
  end;

  System.SetLength(Buf, Size);
  BlockRead(F, PChar(Pointer(Buf))^, Size);
  Close(F);

  P := PChar(Pointer(Buf));
  EndP := P + Size;

  {$IF SizeOf(Char) = 1}
  if (not FSorted) and (System.IndexByte(P^, Size, 13) < 0) then
  begin
    Cap := System.Length(FItems);
    Start := P;
    while Start < EndP do
    begin
      Idx := System.IndexByte(Start^, EndP - Start, 10);
      if Idx < 0 then
        L := EndP - Start
      else
        L := Idx;

      if FCount >= Cap then
      begin
        if Cap = 0 then Cap := 16 else Cap := Cap * 2;
        System.SetLength(FItems, Cap);
      end;

      if L > 0 then
      begin
        System.SetLength(FItems[FCount], L);
        System.Move(Start^, PChar(Pointer(FItems[FCount]))^, L * SizeOf(Char));
      end
      else
        FItems[FCount] := '';
      Inc(FCount);

      if Idx < 0 then Break;
      Inc(Start, Idx + 1);
    end;
    Exit;
  end;
  {$ENDIF}

  Start := P;
  while P < EndP do
  begin
    if (P^ = #13) or (P^ = #10) then
    begin
      L := P - Start;
      if L > 0 then
      begin
        System.SetLength(Line, L);
        System.Move(Start^, PChar(Pointer(Line))^, L * SizeOf(Char));
      end
      else
        Line := '';
      Self.Add(Line);

      if (P^ = #13) and (P + 1 < EndP) and (P[1] = #10) then Inc(P);
      Start := P + 1;
    end;
    Inc(P);
  end;

  if P > Start then
  begin
    L := P - Start;
    System.SetLength(Line, L);
    System.Move(Start^, PChar(Pointer(Line))^, L * SizeOf(Char));
    Self.Add(Line);
  end;
end;

{ ------------------------------------------------------------------- }
{  TStrList — Sorted / Find                                            }
{ ------------------------------------------------------------------- }

function TStrList.Find(const S: string; out Index: NativeInt): Boolean;
var
  Lo, Hi, Mid: NativeInt;
begin
  Result := False;
  Index := -1;
  if not FSorted then Exit;

  Lo := 0;
  Hi := FCount - 1;
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) div 2;
    if FItems[Mid] = S then
    begin
      Index := Mid;
      Exit(True);
    end
    else if FItems[Mid] < S then
      Lo := Mid + 1
    else
      Hi := Mid - 1;
  end;
  Index := Lo;  { insertion point }
end;

{ ------------------------------------------------------------------- }
{  TStringView                                                         }
{ ------------------------------------------------------------------- }

class function TStringView.Create(const S: string): TStringView;
begin
  Result.FData := PChar(S);
  Result.FLength := System.Length(S);
//  Result.FGuard := S;
end;

function TStringView.GetChar(Index: NativeInt): Char;
begin
  // Unchecked by design elsewhere in the unit, but a read must never leave the
  // buffer: out-of-range indices yield #0 instead of whatever precedes it.
  if (Index < 0) or (Index >= FLength) or (FData = nil) then
    Result := #0
  else
    Result := FData[Index];
end;

function TStringView.IsEmpty: Boolean;
begin
  Result := FLength = 0;
end;

function TStringView.Length: NativeInt;
begin
  Result := FLength;
end;

function TStringView.beginsWith(const S: string): Boolean;
var
  L: NativeInt;
begin
  L := System.Length(S);
  if L > FLength then Exit(False);
  if L = 0 then Exit(True);
  Result := CompareByte(FData^, PChar(S)^, L * SizeOf(Char)) = 0;
end;

function TStringView.beginsWith(C: Char): Boolean;
begin
  Result := (FLength > 0) and (FData[0] = C);
end;

function TStringView.endsWith(const S: string): Boolean;
var
  L: NativeInt;
begin
  L := System.Length(S);
  if L > FLength then Exit(False);
  if L = 0 then Exit(True);
  Result := CompareByte(FData[FLength - L], PChar(S)^, L * SizeOf(Char)) = 0;
end;

function TStringView.endsWith(C: Char): Boolean;
begin
  Result := (FLength > 0) and (FData[FLength - 1] = C);
end;

function TStringView.contains(const S: string): Boolean;
var
  L, SL: NativeInt;
  i: NativeInt;
begin
  SL := System.Length(S);
  if SL = 0 then Exit(True);
  if SL > FLength then Exit(False);
  L := FLength - SL;
  for i := 0 to L do
    if CompareByte(FData[i], PChar(S)^, SL * SizeOf(Char)) = 0 then
      Exit(True);
  Result := False;
end;

function TStringView.find(const S: string): TStringView;
var
  SL, L, i: NativeInt;
begin
  Result.FData := nil;
  Result.FLength := 0;
//  Result.FGuard := FGuard;

  SL := System.Length(S);
  if SL = 0 then
  begin
    Result.FData := FData;
    Result.FLength := 0;
    Exit;
  end;
  if SL > FLength then Exit;

  L := FLength - SL;
  for i := 0 to L do
    if CompareByte(FData[i], PChar(S)^, SL * SizeOf(Char)) = 0 then
    begin
      Result.FData := @FData[i];
      Result.FLength := SL;
      Exit;
    end;
end;

function IsSpace(C: Char): Boolean; inline;
begin
  Result := (C = ' ') or (C = #9) or (C = #10) or (C = #13);
end;

function TStringView.trim: TStringView;
var
  Lo, Hi: NativeInt;
begin
  Lo := 0;
  while (Lo < FLength) and IsSpace(FData[Lo]) do Inc(Lo);
  Hi := FLength - 1;
  while (Hi >= Lo) and IsSpace(FData[Hi]) do Dec(Hi);

  if Lo <= Hi then
  begin
    Result.FData := @FData[Lo];
    Result.FLength := Hi - Lo + 1;
  end
  else
  begin
    Result.FData := nil;
    Result.FLength := 0;
  end;
end;

function TStringView.trimLeft: TStringView;
var
  Lo: NativeInt;
begin
  Lo := 0;
  while (Lo < FLength) and IsSpace(FData[Lo]) do Inc(Lo);

  if Lo < FLength then
  begin
    Result.FData := @FData[Lo];
    Result.FLength := FLength - Lo;
  end
  else
  begin
    Result.FData := nil;
    Result.FLength := 0;
  end;
end;

function TStringView.trimRight: TStringView;
var
  Hi: NativeInt;
begin
  Hi := FLength - 1;
  while (Hi >= 0) and IsSpace(FData[Hi]) do Dec(Hi);

  Result.FData := FData;
  Result.FLength := Hi + 1;
end;

function TStringView.splitAtFind(const Sep: string; out Before, After: TStringView): Boolean;
var
  SepLen, i, MaxI: NativeInt;
  {$IF SizeOf(Char) = 1}
  Idx, Offset: SizeInt;
  FirstByte: Byte;
  {$ENDIF}
begin
  SepLen := System.Length(Sep);
  if SepLen = 0 then
  begin
    Before.FData := nil;
    Before.FLength := 0;
    After := Self;
    Exit(True);
  end;

  if FLength < SepLen then
  begin
    Before := Self;
    After.FData := nil;
    After.FLength := 0;
    Exit(False);
  end;

  {$IF SizeOf(Char) = 1}
  if SepLen = 1 then
  begin
    Idx := System.IndexByte(FData^, FLength, Byte(Sep[1]));
    if Idx >= 0 then
    begin
      Before.FData := FData;
      Before.FLength := Idx;
      After.FData := @FData[Idx + 1];
      After.FLength := FLength - Idx - 1;
      Exit(True);
    end;
    Before := Self;
    After.FData := nil;
    After.FLength := 0;
    Exit(False);
  end;

  i := 0;
  MaxI := FLength - SepLen;
  FirstByte := Byte(Sep[1]);
  while i <= MaxI do
  begin
    Offset := System.IndexByte(FData[i], MaxI - i + 1, FirstByte);
    if Offset < 0 then Break;
    Inc(i, Offset);
    if CompareByte(FData[i], PChar(Pointer(Sep))^, SepLen) = 0 then
    begin
      Before.FData := FData;
      Before.FLength := i;
      After.FData := @FData[i + SepLen];
      After.FLength := FLength - i - SepLen;
      Exit(True);
    end;
    Inc(i);
  end;
  {$ELSE}
  MaxI := FLength - SepLen;
  for i := 0 to MaxI do
    if CompareByte(FData[i], PChar(Pointer(Sep))^, SepLen * SizeOf(Char)) = 0 then
    begin
      Before.FData := FData;
      Before.FLength := i;
      After.FData := @FData[i + SepLen];
      After.FLength := FLength - i - SepLen;
      Exit(True);
    end;
  {$ENDIF}

  Before := Self;
  After.FData := nil;
  After.FLength := 0;
  Result := False;
end;


function TStringView.toInt(out Value: Integer): Boolean;
var
  P: PChar;
  Neg: Boolean;
  Accum: Int64;
  Digit: Integer;
  Remaining: NativeInt;
begin
  Value := 0;
  if (FLength = 0) or (FData = nil) then Exit(False);

  P := FData;
  Remaining := FLength;

  Neg := False;
  if P^ = '-' then
  begin
    Neg := True;
    Inc(P);
    Dec(Remaining);
  end
  else if P^ = '+' then
  begin
    Inc(P);
    Dec(Remaining);
  end;

  if Remaining = 0 then Exit(False);

  Accum := 0;
  while Remaining > 0 do
  begin
    // The whole view must be a number: no trailing or embedded characters.
    if (P^ < '0') or (P^ > '9') then Exit(False);
    Digit := Ord(P^) - Ord('0');
    // Guard the accumulator before it overflows, then range-check below.
    if Accum > (High(Int64) - Digit) div 10 then Exit(False);
    Accum := Accum * 10 + Digit;
    Inc(P);
    Dec(Remaining);
  end;

  if Neg then
    Accum := -Accum;

  if (Accum < Low(Integer)) or (Accum > High(Integer)) then Exit(False);

  Value := Accum;
  Result := True;
end;

function TStringView.toInt64(out Value: Int64): Boolean;
var
  P: PChar;
  Neg: Boolean;
  Accum: Int64;
  Digit: Integer;
  Remaining: NativeInt;
begin
  Value := 0;
  if (FLength = 0) or (FData = nil) then Exit(False);

  P := FData;
  Remaining := FLength;

  Neg := False;
  if P^ = '-' then
  begin
    Neg := True;
    Inc(P);
    Dec(Remaining);
  end
  else if P^ = '+' then
  begin
    Inc(P);
    Dec(Remaining);
  end;

  if Remaining = 0 then Exit(False);

  // Accumulate negatively so that Low(Int64) itself stays representable.
  Accum := 0;
  while Remaining > 0 do
  begin
    if (P^ < '0') or (P^ > '9') then Exit(False);
    Digit := Ord(P^) - Ord('0');
    if Accum < (Low(Int64) + Digit) div 10 then Exit(False);
    Accum := Accum * 10 - Digit;
    Inc(P);
    Dec(Remaining);
  end;

  if Neg then
    Value := Accum
  else
  begin
    // -Low(Int64) does not fit in an Int64.
    if Accum = Low(Int64) then Exit(False);
    Value := -Accum;
  end;

  Result := True;
end;

function TStringView.toString: string;
begin
  SetLength(Result, FLength);
  if FLength > 0 then
    Move(FData^, PChar(Pointer(Result))^, FLength * SizeOf(Char));
end;

function TStringView.slice(Start: NativeInt; Count: NativeInt): TStringView;
begin
  if Count < 0 then Count := 0;
  if Start < 0 then
  begin
    Inc(Count, Start);
    Start := 0;
  end;

  if (Start >= FLength) or (Count <= 0) then
  begin
    Result.FData := nil;
    Result.FLength := 0;
    Exit;
  end;

  if Count > FLength - Start then
    Count := FLength - Start;

  Result.FData := @FData[Start];
  Result.FLength := Count;
end;

function TStringViewHelper.View: TStringView;
begin
  Result := TStringView.Create(Self);
end;

{ ------------------------------------------------------------------- }
{  Standalone string utility functions — natural compare               }
{ ------------------------------------------------------------------- }

function NaturalCompareText(const S1, S2: string): Integer;

  function ScanText(const S: string; Sp: SizeInt): SizeInt;
  begin
    Result := Sp;
    repeat
      while not (PChar(Pointer(S))[Result] in ['0' .. '9', #0]) do
        Inc(Result);
      if Result >= Length(S) then
        exit;
      if PChar(Pointer(S))[Result] in ['0' .. '9'] then
      begin
        while (Result > Sp) and (PChar(Pointer(S))[Result - 1] in [' ']) do
          Dec(Result);
        exit;
      end;
      Inc(Result);
    until false;
  end;

  function InitNumber(out Sp: SizeInt; const S: string; Start: SizeInt): boolean;
  begin
    Sp := Start;
    while PChar(Pointer(S))[Sp] in [' '] do
      Inc(Sp);
    while (PChar(Pointer(S))[Sp] in ['0']) and (PChar(Pointer(S))[Sp + 1] in ['0' .. '9']) do
      Inc(Sp);
    Result := PChar(Pointer(S))[Sp] in ['0' .. '9'];
  end;

  function NextDigit(const S: string; var Sp: SizeInt): Integer;
  var
    Ch: Char;
  begin
    Ch := PChar(Pointer(S))[Sp];
    if Ch in ['0' .. '9'] then
    begin
      Result := Ord(Ch) - Ord('0');
      Inc(Sp);
    end else
      Result := -1;
  end;

  function ScanAndCompareTexts(const S1: string; var S1p: SizeInt; const S2: string; var S2p: SizeInt): Integer;
  var
    S1e, S2e: SizeInt;
    L1, L2, MinLen: SizeInt;
    P1, P2: PChar;
    C1, C2: Char;
    i: SizeInt;
  begin
    S1e := ScanText(S1, S1p);
    S2e := ScanText(S2, S2p);
    L1 := S1e - S1p;
    L2 := S2e - S2p;

    P1 := PChar(Pointer(S1)) + S1p;
    P2 := PChar(Pointer(S2)) + S2p;

    if L1 <= L2 then
      MinLen := L1
    else
      MinLen := L2;

    for i := 0 to MinLen - 1 do
    begin
      C1 := P1[i];
      C2 := P2[i];
      if C1 <> C2 then
      begin
        C1 := UpCase(C1);
        C2 := UpCase(C2);
        if C1 <> C2 then
        begin
          Result := Ord(C1 > C2) - Ord(C1 < C2);
          S1p := S1e;
          S2p := S2e;
          Exit;
        end;
      end;
    end;

    Result := Ord(L1 > L2) - Ord(L1 < L2);
    S1p := S1e;
    S2p := S2e;
  end;

  function ScanAndCompareNumbers(const S1: string; var S1p: SizeInt; const S2: string; var S2p: SizeInt): Integer;
  var
    C1p, C2p: SizeInt;
    Digit1, Digit2: Integer;
  begin
    if not InitNumber(C1p, S1, S1p) or not InitNumber(C2p, S2, S2p) then
      Exit(0);
    Result := 0;

    repeat
      Digit1 := NextDigit(S1, C1p);
      Digit2 := NextDigit(S2, C2p);
      if (Digit1 < 0) <> (Digit2 < 0) then
        Exit(2 * Ord(Digit2 < 0) - 1);
      if Digit1 < 0 then
        Break;
      if Result = 0 then
        Result := Ord(Digit1 > Digit2) - Ord(Digit1 < Digit2);
    until false;

    if Result = 0 then
      Result := Ord(C1p - S1p > C2p - S2p) - Ord(C1p - S1p < C2p - S2p);
    S1p := C1p;
    S2p := C2p;
  end;

var
  S1p, S1n, S2p, S2n: SizeInt;
begin
  S1p := 0;
  S2p := 0;
  S1n := Length(S1);
  S2n := Length(S2);
  while (S1p < S1n) and (S2p < S2n) do
  begin
    Result := ScanAndCompareTexts(S1, S1p, S2, S2p);
    if Result <> 0 then
      Exit;
    Result := ScanAndCompareNumbers(S1, S1p, S2, S2p);
    if Result <> 0 then
      Exit;
  end;
  Result := Ord(S1p < S1n) - Ord(S2p < S2n);
end;

function LastChar(const S: string): Char;
begin
  if S <> '' then
    Result := PChar(Pointer(S))[Length(S) - 1]
  else
    Result := #0;
end;

function LastChars(const S: string; Count: NativeInt): string;
var
  L: NativeInt;
begin
  L := Length(S);
  if Count >= L then Exit(S);
  if Count <= 0 then Exit('');
  SetLength(Result, Count);
  Move(PChar(Pointer(S))[L - Count], PChar(Pointer(Result))^, Count * SizeOf(Char));
end;

end.
