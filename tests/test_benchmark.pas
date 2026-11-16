// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
program test_benchmark;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  LightStrings;

{$INLINE ON}

type
  TStrArray = array of string;

  TScore = record
    LightMs: Double;
    StdMs: Double;
  end;

var
  TotalLight, TotalStd: Double;

{ Returns milliseconds elapsed since StartMs, updates StartMs to now. }
function ElapsedMs(var StartMs: QWord): Double; inline;
var
  NowMs: QWord;
begin
  NowMs := GetTickCount64;
  Result := (NowMs - StartMs) * 1.0;
  StartMs := NowMs;
end;

{ Generate N deterministic strings (no commas/quotes). }
function MakeStrings(N: NativeInt): TStrArray;
var
  i, j, Len: NativeInt;
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
  begin
    Len := (i mod 50) + 1;
    SetLength(Result[i], Len);
    for j := 1 to Len do
      Result[i][j] := Chr(Ord('a') + (i * 31 + j) mod 26);
  end;
end;

{ Generate N numbered strings "item<N>_<M>" then shuffle. }
function MakeNumberedStrings(N: NativeInt): TStrArray;
var
  i, Part: NativeInt;
  Tmp: string;
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
  begin
    Part := i div 100;
    Result[i] := 'item' + IntToStr(Part) + '_' + IntToStr(i mod 100);
  end;

  { Fisher-Yates. The previous version copied Result[Part] into Result[i]
    instead of swapping, which duplicated entries and lost others, so the
    sorted input was not a permutation of the generated strings. }
  for i := N - 1 downto 1 do
  begin
    Part := Random(i + 1);
    Tmp := Result[i];
    Result[i] := Result[Part];
    Result[Part] := Tmp;
  end;
end;

{ Generate strings with comma/space content. }
function MakeCommaStrings(N: NativeInt): TStrArray;
var
  i: NativeInt;
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
  begin
    if i mod 3 = 0 then
      Result[i] := 'simple'
    else if i mod 3 = 1 then
      Result[i] := '"quoted, value"'
    else
      Result[i] := 'space value';
  end;
end;

{ Generate name=value pairs. }
procedure MakePairs(N: NativeInt; var Names, Values: TStrArray);
var
  i: NativeInt;
begin
  for i := 0 to N - 1 do
  begin
    Names[i] := 'key_' + IntToStr(i);
    Values[i] := 'val_' + IntToStr(i);
  end;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 1: Add                                                   }
{ ------------------------------------------------------------------ }

function BenchmarkAdd(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  i: NativeInt;
begin
  Arr := MakeStrings(N);

  LL.Init(N);
  Start := GetTickCount64;
  for i := 0 to N - 1 do
    LL.Add(Arr[i]);
  Result.LightMs := ElapsedMs(Start);

  SL := TStringList.Create;
  SL.Capacity := N;
  Start := GetTickCount64;
  for i := 0 to N - 1 do
    SL.Add(Arr[i]);
  Result.StdMs := ElapsedMs(Start);

  if LL.Count <> SL.Count then
    WriteLn('  WARNING: add count mismatch (', LL.Count, ' vs ', SL.Count, ')');

  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 2: IndexOf                                               }
{ ------------------------------------------------------------------ }

function BenchmarkIndexOf(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  i, Dummy: NativeInt;
begin
  Arr := MakeStrings(N);

  LL.Init(N);
  SL := TStringList.Create;
  SL.Capacity := N;
  for i := 0 to N - 1 do
  begin
    LL.Add(Arr[i]);
    SL.Add(Arr[i]);
  end;

  Start := GetTickCount64;
  for i := 0 to 999 do
    Dummy := LL.IndexOf(Arr[N - 1]);
  Result.LightMs := ElapsedMs(Start);

  Start := GetTickCount64;
  for i := 0 to 999 do
    Dummy := SL.IndexOf(Arr[N - 1]);
  Result.StdMs := ElapsedMs(Start);

  { Validate outside the timed region: both containers must agree. }
  if LL.IndexOf(Arr[N - 1]) <> SL.IndexOf(Arr[N - 1]) then
    WriteLn('  WARNING: IndexOf disagrees with TStringList');

  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 3: Sort                                                  }
{ ------------------------------------------------------------------ }

function BenchmarkSort(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  i: NativeInt;
begin
  Arr := MakeStrings(N);

  LL.Init(N);
  SL := TStringList.Create;
  SL.Capacity := N;
  SL.Sorted := False;
  for i := 0 to N - 1 do
  begin
    LL.Add(Arr[i]);
    SL.Add(Arr[i]);
  end;

  Start := GetTickCount64;
  LL.Sort;
  Result.LightMs := ElapsedMs(Start);

  Start := GetTickCount64;
  SL.Sort;
  Result.StdMs := ElapsedMs(Start);

  { Validate outside the timed region: same count, same order. Both input sets
    are lowercase, so LightStrings' byte order and TStringList's CompareText
    order coincide here - the timings still measure different comparators. }
  if LL.Count <> SL.Count then
    WriteLn('  WARNING: sort count mismatch (', LL.Count, ' vs ', SL.Count, ')')
  else
    for i := 0 to LL.Count - 1 do
      if LL[i] <> SL[i] then
      begin
        WriteLn('  WARNING: sort content mismatch at index ', i);
        Break;
      end;

  SL.Free;
end;

{ TStringListSortCompare wrapper that calls NaturalCompareText }
function NaturalCompareForSort(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := NaturalCompareText(List[Index1], List[Index2]);
end;

{ ------------------------------------------------------------------ }
{  Benchmark 4: NaturalSort vs CustomSort (NaturalCompareText)        }
{ ------------------------------------------------------------------ }

function BenchmarkNaturalCustomSort(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  i: NativeInt;
begin
  Arr := MakeNumberedStrings(N);

  LL.Init(N);
  SL := TStringList.Create;
  SL.Capacity := N;
  for i := 0 to N - 1 do
  begin
    LL.Add(Arr[i]);
    SL.Add(Arr[i]);
  end;

  Start := GetTickCount64;
  LL.NaturalSort;
  Result.LightMs := ElapsedMs(Start);

  Start := GetTickCount64;
  SL.CustomSort(@NaturalCompareForSort);
  Result.StdMs := ElapsedMs(Start);

  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 5: Text                                                  }
{ ------------------------------------------------------------------ }

function BenchmarkText(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  T: string;
  i: NativeInt;
begin
  Arr := MakeStrings(N);

  LL.Init(N);
  for i := 0 to N - 1 do
    LL.Add(Arr[i]);

  Start := GetTickCount64;
  T := LL.Text;
  Result.LightMs := ElapsedMs(Start);
  LL.FItems := nil;

  LL.Init(N);
  LL.Text := T;

  SL := TStringList.Create;
  SL.Capacity := N;
  for i := 0 to N - 1 do
    SL.Add(Arr[i]);

  Start := GetTickCount64;
  T := SL.Text;
  Result.StdMs := ElapsedMs(Start);

  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 6: CommaText                                             }
{ ------------------------------------------------------------------ }

function BenchmarkCommaText(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  T: string;
  i: NativeInt;
begin
  Arr := MakeCommaStrings(N);

  LL.Init(N);
  SL := TStringList.Create;
  SL.Capacity := N;
  for i := 0 to N - 1 do
  begin
    LL.Add(Arr[i]);
    SL.Add(Arr[i]);
  end;

  Start := GetTickCount64;
  T := LL.CommaText;
  Result.LightMs := ElapsedMs(Start);

  Start := GetTickCount64;
  T := SL.CommaText;
  Result.StdMs := ElapsedMs(Start);

  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 7: Name/Value                                            }
{ ------------------------------------------------------------------ }

function BenchmarkNameValue(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Names, Values: TStrArray;
  Start: QWord;
  i, Dummy: NativeInt;
  S: string;
begin
  SetLength(Names, N);
  SetLength(Values, N);
  MakePairs(N, Names, Values);

  LL.Init(N);
  SL := TStringList.Create;
  SL.Capacity := N;
  for i := 0 to N - 1 do
  begin
    LL.AddPair(Names[i], Values[i]);
    SL.AddPair(Names[i], Values[i]);
  end;

  Start := GetTickCount64;
  for i := 0 to 99 do
    S := LL.Values[Names[N - 1]];
  Result.LightMs := ElapsedMs(Start);

  Start := GetTickCount64;
  for i := 0 to 99 do
    S := SL.Values[Names[N - 1]];
  Result.StdMs := ElapsedMs(Start);

  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 8: File I/O                                              }
{ ------------------------------------------------------------------ }

function BenchmarkFileIO(N: NativeInt): TScore;
var
  LL: TStrList;
  SL: TStringList;
  Arr: TStrArray;
  Start: QWord;
  FName: string;
  i: NativeInt;
begin
  Arr := MakeStrings(N);

  FName := '/tmp/benchmark_strings.txt';

  LL.Init(N);
  for i := 0 to N - 1 do
    LL.Add(Arr[i]);

  Start := GetTickCount64;
  LL.SaveToFile(FName);
  LL.FItems := nil;
  LL.Init(N);
  LL.LoadFromFile(FName);
  Result.LightMs := ElapsedMs(Start);

  SL := TStringList.Create;
  SL.Capacity := N;
  for i := 0 to N - 1 do
    SL.Add(Arr[i]);

  Start := GetTickCount64;
  SL.SaveToFile(FName);
  SL.Clear;
  SL.LoadFromFile(FName);
  Result.StdMs := ElapsedMs(Start);

  SL.Free;
  DeleteFile(FName);
end;

{ ------------------------------------------------------------------ }
{  Benchmark 9: TBuildStr vs TStringList.Text                         }
{ ------------------------------------------------------------------ }

function BenchmarkBuilder(N: NativeInt): TScore;
var
  Builder: TBuildStr;
  SL: TStringList;
  i: NativeInt;
  S: string;
  Start: QWord;
begin
  Builder.Init(256);
  Start := GetTickCount64;
  for i := 0 to N - 1 do
  begin
    { Append(Int64) renders on the stack: zero IntToStr heap allocations. }
    Builder.Append('Testing string append number ');
    Builder.Append(i);
    Builder.Append(sLineBreak);
  end;
  S := Builder.ToString;
  Result.LightMs := ElapsedMs(Start);

  SL := TStringList.Create;
  SL.Capacity := N;
  Start := GetTickCount64;
  for i := 0 to N - 1 do
    SL.Add('Testing string append number ' + IntToStr(i));
  S := SL.Text;
  Result.StdMs := ElapsedMs(Start);
  SL.Free;
end;

{ ------------------------------------------------------------------ }
{  Benchmark 10: TStringView vs Copy+Pos                              }
{ ------------------------------------------------------------------ }

function BenchmarkStringView(N: NativeInt): TScore;
const
  CSV_LINE = 'alpha,beta,gamma,delta,epsilon,zeta,eta,theta,iota,kappa,' +
             'lambda,mu,nu,xi,omicron,pi,rho,sigma,tau,upsilon,phi,chi,psi,omega';
var
  BigCSV: string;
  i: NativeInt;
  View: TStringView;
  Before, After: TStringView;
  Start: QWord;
  CountLight, CountStd: NativeInt;
  SL: TStringList;
  P, C: NativeInt;
begin
  BigCSV := '';
  for i := 0 to N - 1 do
    BigCSV := BigCSV + CSV_LINE + sLineBreak;

  CountLight := 0;
  Start := GetTickCount64;
  View := TStringView.Create(BigCSV);
  while View.splitAtFind(sLineBreak, Before, After) do
  begin
    Inc(CountLight);
    View := After;
  end;
  Result.LightMs := ElapsedMs(Start);

  CountStd := 0;
  Start := GetTickCount64;
  SL := TStringList.Create;
  try
    SL.Text := BigCSV;
    for i := 0 to SL.Count - 1 do
    begin
      P := 1; C := 0;
      while P <= Length(SL[i]) do
      begin
        P := System.Pos(',', SL[i], P);
        if P = 0 then Break;
        Inc(C);
        Inc(P);
      end;
      Inc(CountStd, C + 1);
    end;
  finally
    SL.Free;
  end;
  Result.StdMs := ElapsedMs(Start);
end;

{ ------------------------------------------------------------------ }
{  BenchDisplay                                                      }
{ ------------------------------------------------------------------ }

function FormatRatio(LightMs, StdMs: Double): string;
begin
  if LightMs < StdMs then
    Result := Format('%.2fx faster', [StdMs / LightMs])
  else if LightMs > StdMs then
    Result := Format('%.2fx slower', [LightMs / StdMs])
  else
    Result := '1.00x (tie)';
end;

procedure BenchHeader;
begin
  WriteLn(Format('%-42s | %12s | %12s | %-15s',
    ['Benchmark', 'LightStrings', 'TStringList', 'Result']));
  WriteLn(StringOfChar('-', 43) + '+' +
          StringOfChar('-', 14) + '+' +
          StringOfChar('-', 14) + '+' +
          StringOfChar('-', 16));
end;

procedure BenchDivider;
begin
  WriteLn(StringOfChar('-', 43) + '+' +
          StringOfChar('-', 14) + '+' +
          StringOfChar('-', 14) + '+' +
          StringOfChar('-', 16));
end;

procedure BenchBegin(const Name: string);
begin
  Write(Format('%-42s | ', [Name]));
  Flush(Output);
end;

procedure BenchDisplay(Score: TScore);
var
  LightStr, StdStr: string;
begin
  LightStr := Format('%.1f ms', [Score.LightMs]);
  StdStr   := Format('%.1f ms', [Score.StdMs]);
  WriteLn(Format('%12s | %12s | %-15s',
    [LightStr, StdStr, FormatRatio(Score.LightMs, Score.StdMs)]));
end;

{ ------------------------------------------------------------------ }
{  Main                                                               }
{ ------------------------------------------------------------------ }
const
  size = 2000000;
var
  S, TotalScore: TScore;
begin
  Randomize;
  TotalLight := 0;
  TotalStd := 0;

  WriteLn('=== LightStrings vs TStringList Benchmark ===');
  WriteLn;
  BenchHeader;

  BenchBegin('1. Add (2,000,000 items)');
  S := BenchmarkAdd(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('2. IndexOf (2M items, 1000 searches)');
  S := BenchmarkIndexOf(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('3. Sort (2M items; byte vs CompareText)');
  S := BenchmarkSort(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('4. NaturalSort vs CustomSort (2M items)');
  S := BenchmarkNaturalCustomSort(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('5. Text (2,000,000 items)');
  S := BenchmarkText(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('6. CommaText (2,000,000 items)');
  S := BenchmarkCommaText(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('7. Name/Value (2M items, 100 lookups)');
  S := BenchmarkNameValue(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('8. File I/O (80,000 items)');
  S := BenchmarkFileIO(80000);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('9. TBuildStr vs TStringList.Text (2M)');
  S := BenchmarkBuilder(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchBegin('10. TStringView vs Copy+Pos (2M x 24)');
  S := BenchmarkStringView(size);
  BenchDisplay(S);
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  BenchDivider;
  TotalScore.LightMs := TotalLight;
  TotalScore.StdMs := TotalStd;
  BenchBegin('Total');
  BenchDisplay(TotalScore);
end.
