// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
program regression;

{ Regression checks for the defects fixed after testing.

  Build with heaptrc as well, so the memory fixes are covered too:
    fpc @lightstrings.cfg -gh tests/regression.pas -FU/tmp/reg -FE/tmp/reg
    /tmp/reg/regression

  Exit code 0 = every check passed. }

{$mode objfpc}{$H+}

uses
  SysUtils, LightStrings, LightStringsUtils;

var
  Failures: Integer;

procedure Check(const Name: string; Condition: Boolean);
begin
  if Condition then
    WriteLn('ok   ', Name)
  else
  begin
    WriteLn('FAIL ', Name);
    Inc(Failures);
  end;
end;

procedure CheckEqInt(const Name: string; Expected, Actual: Int64);
begin
  Check(Name + ' (expected ' + IntToStr(Expected) + ', got ' + IntToStr(Actual) + ')',
    Expected = Actual);
end;

procedure TestListWithoutInit;
var
  L: TStrList;
begin
  { Add/Insert on a default-initialized record used to write out of bounds
    (Runtime error 216). }
  L.Add('b');
  L.Add('a');
  L.Insert(1, 'ab');
  CheckEqInt('Add without Init keeps count', 3, L.Count);
  Check('Add without Init stores values', (L[0] = 'b') and (L[1] = 'ab') and (L[2] = 'a'));
end;

procedure TestBuilderAssign;
var
  A, B: TBuildStr;
begin
  A.Init;
  A.Append('hello');
  B.Init;
  B.Append('world');
  B := A;                    { used to leak B's buffer }
  Check('builder assignment copies the value', B.ToString = 'hello');
  A := A;                    { self-assignment must not free the buffer }
  Check('builder self-assignment is safe', A.ToString = 'hello');
end;

procedure TestBuilderReInit;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('abc');
  B.Init;                    { used to leak the first buffer }
  CheckEqInt('re-Init clears the builder', 0, System.Length(B.ToString));
end;

procedure TestBuilderChop;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('abc');
  B.Chop(-5);                { used to grow the buffer }
  Check('Chop(negative) is a no-op', B.ToString = 'abc');
  B.Chop(2);
  Check('Chop(2) removes two chars', B.ToString = 'a');
  B.Chop(100);
  CheckEqInt('Chop(too many) empties', 0, System.Length(B.ToString));
end;

procedure TestSortedFind;
var
  L: TStrList;
  Index: NativeInt;
  i: NativeInt;
  Ordered: Boolean;
begin
  L.Init;
  L.Add('b');
  L.Add('a');
  L.Sort;
  Check('Sort marks the list sorted', L.Sorted);
  Check('Find works after Sort', L.Find('a', Index) and (Index = 0));

  { A sorted list must stay sorted when items are added. }
  L.Add('c');
  L.Add('aa');
  Ordered := True;
  for i := 1 to L.Count - 1 do
    if L[i - 1] > L[i] then
      Ordered := False;
  Check('Add keeps a sorted list sorted', Ordered);
  Check('Find still works after Add', L.Find('aa', Index) and (Index < L.Count));

  L.Insert(0, 'zzz');        { arbitrary insertion invalidates the order }
  Check('Insert clears the sorted flag', not L.Sorted);
end;

procedure TestTextRoundTrip;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('');
  L.Add('b');
  L.Text := L.Text;
  CheckEqInt('Text round-trip keeps blank lines', 3, L.Count);
  Check('Text round-trip keeps the blank item',
    (L[0] = 'a') and (L[1] = '') and (L[2] = 'b'));
end;

procedure TestStrictDelimiter;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('b');
  L.StrictDelimiter := True;
  Check('StrictDelimiter disables quoting', L.DelimitedText = 'a,b');

  L.Init;
  L.Add('a b');
  L.StrictDelimiter := False;
  Check('non-strict quotes when needed', L.DelimitedText = '"a b"');
end;

procedure TestViewBounds;
var
  V: TStringView;
begin
  V := TStringView.Create('abcdef');
  Check('Chars[-1] is #0', V.Chars[-1] = #0);
  Check('Chars[Length] is #0', V.Chars[6] = #0);
  Check('slice(2,3) reads normally', V.slice(2, 3).toString = 'cde');
  Check('slice(-2,3) does not read before the buffer', V.slice(-2, 3).toString = 'a');
  Check('slice(-2,5) drops the negative part', V.slice(-2, 5).toString = 'abc');
  Check('slice(1,-1) is empty', V.slice(1, -1).toString = '');
end;

procedure TestParsing;
var
  V: TStringView;
  N: Integer;
  I64: Int64;
begin
  V := TStringView.Create('12');
  Check('toInt(12)', V.toInt(N) and (N = 12));
  V := TStringView.Create('-42');
  Check('toInt(-42)', V.toInt(N) and (N = -42));
  V := TStringView.Create('12abc');
  Check('toInt rejects trailing junk', not V.toInt(N));
  V := TStringView.Create('2147483648');
  Check('toInt rejects overflow', not V.toInt(N));
  V := TStringView.Create('-2147483648');
  Check('toInt accepts Low(Integer)', V.toInt(N) and (N = Low(Integer)));

  V := TStringView.Create('9223372036854775807');
  Check('toInt64 accepts High(Int64)', V.toInt64(I64) and (I64 = High(Int64)));
  V := TStringView.Create('-9223372036854775808');
  Check('toInt64 accepts Low(Int64)', V.toInt64(I64) and (I64 = Low(Int64)));
  V := TStringView.Create('9223372036854775808');
  Check('toInt64 rejects overflow', not V.toInt64(I64));
  V := TStringView.Create('-9223372036854775809');
  Check('toInt64 rejects underflow', not V.toInt64(I64));
end;

procedure TestUtf8Reverse;
var
  S: string;
begin
  Check('Reverse(ASCII)', Reverse('abc') = 'cba');
  { 'h' followed by U+00E9 (C3 A9): code points reversed, bytes within each kept }
  S := 'h' + #$C3#$A9;
  Check('Reverse keeps multi-byte sequences intact', Reverse(S) = #$C3#$A9 + 'h');
  Check('Reverse twice is the identity', Reverse(Reverse(S)) = S);
end;

begin
  Failures := 0;

  TestListWithoutInit;
  TestBuilderAssign;
  TestBuilderReInit;
  TestBuilderChop;
  TestSortedFind;
  TestTextRoundTrip;
  TestStrictDelimiter;
  TestViewBounds;
  TestParsing;
  TestUtf8Reverse;

  WriteLn;
  if Failures = 0 then
    WriteLn('all checks passed')
  else
  begin
    WriteLn(Failures, ' check(s) FAILED');
    Halt(1);
  end;
end.
