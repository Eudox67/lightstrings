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
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
  begin
    Part := i div 100;
    Result[i] := 'item' + IntToStr(Part) + '_' + IntToStr(i mod 100);
  end;
  for i := N - 1 downto 1 do
  begin
    Part := Random(i + 1);
    Result[i] := Result[Part];
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
    S := LL.Values(Names[N - 1]);
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
    Builder.Append('Testing string append number ' + IntToStr(i) + sLineBreak);
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
{  Main                                                               }
{ ------------------------------------------------------------------ }
const
 size = 2000000;
var
  S: TScore;
begin
  Randomize;
  TotalLight := 0;
  TotalStd := 0;

  WriteLn('=== LightStrings vs TStringList Benchmark ===');
  WriteLn;

  Write('Benchmark 1: Add (2,000,000 items)... ');
  S := BenchmarkAdd(size);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 2: IndexOf (2,000,000 items, 100 searches)... ');
  S := BenchmarkIndexOf(size);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 3: Sort (2,000,000 items)... ');
  S := BenchmarkSort(size);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 4: NaturalSort vs CustomSort (2,000,000 items)... ');
  S := BenchmarkNaturalCustomSort(2000000);
  WriteLn(Format('LightStrings NaturalSort: %.1f ms | TStringList CustomSort+NaturalCompare: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 5: Text (2,000,000 items)... ');
  S := BenchmarkText(size);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 6: CommaText (2,000,000 items)... ');
  S := BenchmarkCommaText(size);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 7: Name/Value (2,000,000 items, 100 lookups)... ');
  S := BenchmarkNameValue(size);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 8: File I/O (80,000 items)... ');
  S := BenchmarkFileIO(80000);
  WriteLn(Format('LightStrings: %.1f ms | TStringList: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 9: TBuildStr vs TStringList.Text (2,000,000 appends)... ');
  S := BenchmarkBuilder(size);
  WriteLn(Format('TBuildStr: %.1f ms | TStringList.Text: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  Write('Benchmark 10: TStringView vs Copy+Pos (2,000,000 lines, 24 fields each)... ');
  S := BenchmarkStringView(size);
  WriteLn(Format('TStringView: %.1f ms | Copy+Pos: %.1f ms | Ratio: %.2fx', [S.LightMs, S.StdMs, S.LightMs / S.StdMs]));
  TotalLight += S.LightMs;
  TotalStd += S.StdMs;

  WriteLn;
  WriteLn('=== Summary ===');
  WriteLn(Format('LightStrings total: %.1f ms', [TotalLight]));
  WriteLn(Format('TStringList total: %.1f ms', [TotalStd]));
  WriteLn(Format('Overall ratio: %.2fx', [TotalLight / TotalStd]));
end.