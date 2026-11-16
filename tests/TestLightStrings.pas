// ###########################################################
// #### LightStrings - stack-based string handling for Free Pascal
// ####
// #### Copyright 2026 Eudox67. All rights reserved.
// #### Licensed under the MIT License - see LICENSE.
// ###########################################################
unit TestLightStrings;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  LightStrings, LightStringsUtils;

type
  { TBuildStr }
  TBuilderTests = class(TTestCase)
  published
    procedure TestAppendString;
    procedure TestAppendPChar;
    procedure TestAppendLine;
    procedure TestAppendInt64;
    procedure TestLengthProperty;
    procedure TestCapacityAndEnsure;
    procedure TestCharsProperty;
    procedure TestChop;
    procedure TestClear;
  end;

  { TStrList }
  TStrListTests = class(TTestCase)
  published
    procedure TestAddWithoutInit;
    procedure TestInsertAndDelete;
    procedure TestSortAndFind;
    procedure TestSortedAddKeepsOrder;
    procedure TestExchangeAndMoveItem;
    procedure TestMove;
    procedure TestAddReturnsIndex;
    procedure TestCapacity;
    procedure TestForEachEnumerator;
    procedure TestTextRoundTrip;
    procedure TestDelimitedText;
    procedure TestNameValue;
    procedure TestNameValueWrite;
  end;

  { TStringView }
  TStringViewTests = class(TTestCase)
  published
    procedure TestCharsBounds;
    procedure TestSlice;
    procedure TestTrimAndSplitAtFind;
    procedure TestParsing;
  end;

  { LightStringsUtils }
  TUtilsTests = class(TTestCase)
  published
    procedure TestSplitJoin;
    procedure TestTrimFamily;
    procedure TestPrefixSuffix;
    procedure TestPredicates;
    procedure TestReverseUtf8;
  end;

implementation

{ ------------------------------------------------------------------- }
{  TBuildStr                                                          }
{ ------------------------------------------------------------------- }

procedure TBuilderTests.TestAppendString;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('hello');
  B.Append(' world');
  AssertEquals('Append concatenates strings', 'hello world', B.ToString);
end;

procedure TBuilderTests.TestAppendPChar;
const
  Source = 'abcdef';
var
  B: TBuildStr;
begin
  B.Init;
  B.Append(PChar(Source), 3);
  B.Append(PChar(Source) + 3, 3);
  AssertEquals('Append(PChar, Len) copies exactly Len characters',
    'abcdef', B.ToString);
end;

procedure TBuilderTests.TestAppendLine;
var
  B: TBuildStr;
  Expected: string;
begin
  B.Init;
  B.AppendLine('a');
  B.AppendLine('b');
  Expected := 'a' + System.LineEnding + 'b' + System.LineEnding;
  AssertEquals('AppendLine terminates each line', Expected, B.ToString);
end;

procedure TBuilderTests.TestAppendInt64;
var
  B: TBuildStr;
  N: Int64;
begin
  B.Init;
  N := 0;
  B.Append(N);
  AssertEquals('Append(Int64) renders zero', '0', B.ToString);

  B.Clear;
  B.Append(42);
  AssertEquals('Append accepts an integer literal', '42', B.ToString);

  B.Clear;
  N := -42;
  B.Append(N);
  AssertEquals('Append(Int64) renders a negative value', '-42', B.ToString);

  B.Clear;
  B.Append(High(Int64));
  AssertEquals('Append(Int64) renders High(Int64)',
    '9223372036854775807', B.ToString);

  B.Clear;
  B.Append(Low(Int64));
  AssertEquals('Append(Int64) renders Low(Int64)',
    '-9223372036854775808', B.ToString);

  B.Clear;
  B.Append('n=');
  N := 7;
  B.Append(N);
  AssertEquals('Append(Int64) composes with strings', 'n=7', B.ToString);
end;

procedure TBuilderTests.TestLengthProperty;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('abc');
  AssertEquals('Length reports the content size', 3, Integer(B.Length));

  B.Length := 5;
  AssertEquals('Length grows the content', 5, Integer(B.Length));
  AssertTrue('the extension is zero-filled', B.Chars[3] = #0);
  AssertTrue('the extension is zero-filled to the end', B.Chars[4] = #0);
  AssertEquals('the original content survives', 'abc',
    System.Copy(B.ToString, 1, 3));

  B.Length := 2;
  AssertEquals('Length shrinks the content', 'ab', B.ToString);

  B.Length := 0;
  AssertEquals('Length 0 empties the builder', '', B.ToString);
end;

procedure TBuilderTests.TestCapacityAndEnsure;
var
  B: TBuildStr;
begin
  B.Init(16);
  AssertEquals('Init sets the capacity', 16, Integer(B.Capacity));

  B.EnsureCapacity(100);
  AssertTrue('EnsureCapacity grows to at least the request', B.Capacity >= 100);

  B.Append('abc');
  B.Capacity := 64;
  AssertEquals('Capacity can be set exactly', 64, Integer(B.Capacity));
  AssertEquals('changing capacity keeps the content', 'abc', B.ToString);

  B.Clear;
  B.Capacity := 0;
  AssertEquals('Capacity 0 releases the buffer', 0, Integer(B.Capacity));
  B.Append('again');
  AssertEquals('the builder is reusable after Capacity 0', 'again', B.ToString);
end;

procedure TBuilderTests.TestCharsProperty;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('abc');

  AssertTrue('Chars reads a character', B.Chars[1] = 'b');
  AssertTrue('the default indexer reads too', B[2] = 'c');

  B.Chars[0] := 'A';
  B[2] := 'C';
  AssertEquals('Chars writes through to the buffer', 'AbC', B.ToString);
end;

procedure TBuilderTests.TestChop;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('abc');

  B.Chop(-5);
  AssertEquals('Chop(negative) is a no-op', 'abc', B.ToString);

  B.Chop(2);
  AssertEquals('Chop(2) removes two characters', 'a', B.ToString);

  B.Chop(100);
  AssertEquals('Chop beyond the start empties the builder', '', B.ToString);
end;

procedure TBuilderTests.TestClear;
var
  B: TBuildStr;
begin
  B.Init;
  B.Append('abc');
  B.Clear;
  AssertEquals('Clear drops the content', '', B.ToString);
  B.Append('x');
  AssertEquals('the builder is reusable after Clear', 'x', B.ToString);
end;

{ ------------------------------------------------------------------- }
{  TStrList                                                           }
{ ------------------------------------------------------------------- }

procedure TStrListTests.TestAddWithoutInit;
var
  L: TStrList;
begin
  { A default-initialized record has no storage; Add must grow from zero. }
  L.Add('b');
  L.Add('a');
  L.Insert(1, 'ab');
  AssertEquals('Add without Init keeps the count', 3, Integer(L.Count));
  AssertEquals('item 0', 'b', L[0]);
  AssertEquals('item 1', 'ab', L[1]);
  AssertEquals('item 2', 'a', L[2]);
end;

procedure TStrListTests.TestInsertAndDelete;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('b');
  L.Add('c');
  L.Insert(1, 'x');
  AssertEquals('Insert grows the list', 4, Integer(L.Count));
  AssertEquals('inserted item', 'x', L[1]);

  L.Delete(2);
  AssertEquals('Delete shrinks the list', 3, Integer(L.Count));
  AssertEquals('Delete shifts the tail', 'c', L[2]);
end;

procedure TStrListTests.TestSortAndFind;
var
  L: TStrList;
  Index: NativeInt;
begin
  L.Init;
  L.Add('b');
  L.Add('a');
  L.Sort;

  AssertTrue('Sort marks the list sorted', L.Sorted);
  AssertEquals('Sort orders the items', 'a', L[0]);
  AssertTrue('Find locates a sorted item', L.Find('a', Index));
  AssertEquals('Find returns the index', 0, Integer(Index));
  AssertFalse('Find rejects a missing item', L.Find('zz', Index));
end;

procedure TStrListTests.TestSortedAddKeepsOrder;
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

  L.Add('c');
  L.Add('aa');
  Ordered := True;
  for i := 1 to L.Count - 1 do
    if L[i - 1] > L[i] then
      Ordered := False;

  AssertTrue('Add keeps a sorted list sorted', Ordered);
  AssertTrue('Find still works after Add', L.Find('aa', Index));

  L.Insert(0, 'zzz');
  AssertFalse('Insert clears the sorted flag', L.Sorted);
end;

procedure TStrListTests.TestExchangeAndMoveItem;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('b');
  L.Add('c');

  L.Exchange(0, 2);
  AssertEquals('Exchange swaps item 0', 'c', L[0]);
  AssertEquals('Exchange swaps item 2', 'a', L[2]);

  L.MoveItem(2, 0);
  AssertEquals('MoveItem moves the item to the front', 'a', L[0]);
  AssertEquals('MoveItem shifts the tail', 'c', L[1]);
  AssertEquals('MoveItem leaves the rest intact', 'b', L[2]);
  AssertFalse('MoveItem clears the sorted flag', L.Sorted);
end;

procedure TStrListTests.TestTextRoundTrip;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('');
  L.Add('b');

  L.Text := L.Text;
  AssertEquals('Text round-trip keeps blank lines', 3, Integer(L.Count));
  AssertEquals('item 0 survives the round-trip', 'a', L[0]);
  AssertEquals('the blank item survives the round-trip', '', L[1]);
  AssertEquals('item 2 survives the round-trip', 'b', L[2]);
end;

procedure TStrListTests.TestDelimitedText;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('b');
  L.StrictDelimiter := True;
  AssertEquals('StrictDelimiter disables quoting', 'a,b', L.DelimitedText);

  L.Init;
  L.Add('a b');
  L.StrictDelimiter := False;
  AssertEquals('non-strict quoting protects spaces', '"a b"', L.DelimitedText);

  L.DelimitedText := 'a,"b c",d';
  AssertEquals('DelimitedText parses quoted fields', 3, Integer(L.Count));
  AssertEquals('quoted field is dequoted', 'b c', L[1]);
end;

procedure TStrListTests.TestNameValue;
var
  L: TStrList;
  AddedIndex: NativeInt;
begin
  L.Init;
  AddedIndex := L.AddPair('name', 'value');

  AssertEquals('AddPair returns the insertion index', 0, Integer(AddedIndex));
  AssertEquals('IndexOfName finds the pair', 0, Integer(L.IndexOfName('name')));
  AssertEquals('IndexOfName rejects a prefix match', -1,
    Integer(L.IndexOfName('nam')));
  AssertEquals('Names splits the name', 'name', L.Names[0]);
  AssertEquals('ValueFromIndex splits the value', 'value', L.ValueFromIndex[0]);
  AssertEquals('Values looks the value up by name', 'value', L.Values['name']);
  AssertEquals('Values returns empty for a missing name', '', L.Values['missing']);
end;

procedure TStrListTests.TestNameValueWrite;
var
  L: TStrList;
begin
  L.Init;
  L.AddPair('name', 'value');

  L.Values['name'] := 'other';
  AssertEquals('Values[] updates an existing pair', 'other', L.Values['name']);
  AssertEquals('updating keeps the count', 1, Integer(L.Count));

  L.Values['extra'] := 'added';
  AssertEquals('Values[] adds a missing name', 'added', L.Values['extra']);
  AssertEquals('adding grows the count', 2, Integer(L.Count));

  L.ValueFromIndex[0] := 'third';
  AssertEquals('ValueFromIndex[] keeps the name', 'name', L.Names[0]);
  AssertEquals('ValueFromIndex[] replaces the value', 'third', L.Values['name']);

  L.Values['name'] := '';
  AssertEquals('an empty Values[] write deletes the pair', -1,
    Integer(L.IndexOfName('name')));
  AssertEquals('delete shrinks the count', 1, Integer(L.Count));

  L.ValueFromIndex[0] := '';
  AssertEquals('an empty ValueFromIndex[] write deletes the item',
    0, Integer(L.Count));
end;

procedure TStrListTests.TestMove;
var
  L: TStrList;
begin
  L.Init;
  L.Add('a');
  L.Add('b');
  L.Add('c');
  L.Add('d');

  L.Move(0, 2);
  AssertEquals('Move forward shifts the head', 'b', L[0]);
  AssertEquals('Move forward lands the item', 'a', L[2]);
  AssertEquals('Move forward keeps the tail', 'd', L[3]);

  L.Move(3, 1);
  AssertEquals('Move backward lands the item', 'd', L[1]);
  AssertEquals('Move backward shifts the tail', 'a', L[3]);

  L.Move(1, 1);
  AssertEquals('Move to the same index is a no-op', 'd', L[1]);

  L.Sort;
  L.Move(0, 3);
  AssertFalse('Move clears the sorted flag', L.Sorted);
end;

procedure TStrListTests.TestAddReturnsIndex;
var
  L: TStrList;
begin
  L.Init;
  AssertEquals('Add returns the first index', 0, Integer(L.Add('b')));
  AssertEquals('Add returns the append index', 1, Integer(L.Add('d')));

  L.Sort;
  AssertEquals('Add on a sorted list returns the insertion index',
    1, Integer(L.Add('c')));
  AssertEquals('the sorted insert landed at that index', 'c', L[1]);
  AssertEquals('AddPair returns the sorted insertion index',
    0, Integer(L.AddPair('a', 'x')));
end;

procedure TStrListTests.TestCapacity;
var
  L: TStrList;
begin
  L.Init(4);
  AssertEquals('Init sets the capacity', 4, Integer(L.Capacity));

  L.Capacity := 32;
  AssertEquals('Capacity grows the storage', 32, Integer(L.Capacity));

  L.Add('a');
  L.Add('b');
  L.Capacity := 2;
  AssertEquals('Capacity shrinks to the count', 2, Integer(L.Capacity));
  AssertEquals('shrinking keeps the items', 'a', L[0]);
  AssertEquals('shrinking keeps the count', 2, Integer(L.Count));

  L.Add('c');
  AssertTrue('Add still grows past a manual capacity', L.Capacity >= 3);
  AssertEquals('the appended item survives', 'c', L[2]);
end;

procedure TStrListTests.TestForEachEnumerator;
var
  L: TStrList;
  S, Joined: string;
  Visits: NativeInt;
begin
  L.Init;
  L.Add('a');
  L.Add('b');
  L.Add('c');

  Joined := '';
  Visits := 0;
  for S in L do
  begin
    Joined := Joined + S;
    Inc(Visits);
  end;
  AssertEquals('for-in visits every item once', 3, Integer(Visits));
  AssertEquals('for-in yields the items in order', 'abc', Joined);

  L.Clear;
  Visits := 0;
  for S in L do
    Inc(Visits);
  AssertEquals('for-in over an empty list visits nothing', 0, Integer(Visits));
end;

{ ------------------------------------------------------------------- }
{  TStringView                                                        }
{ ------------------------------------------------------------------- }

procedure TStringViewTests.TestCharsBounds;
var
  V: TStringView;
begin
  V := TStringView.Create('abcdef');
  AssertEquals('Length reports the view size', 6, Integer(V.Length));
  AssertFalse('IsEmpty is False for a non-empty view', V.IsEmpty);
  AssertEquals('Chars[0] reads the first character', 'a', V.Chars[0]);
  AssertTrue('Chars[-1] is #0', V.Chars[-1] = #0);
  AssertTrue('Chars[Length] is #0', V.Chars[6] = #0);
  AssertTrue('a view of the empty string is empty',
    TStringView.Create('').IsEmpty);
end;

procedure TStringViewTests.TestSlice;
var
  V: TStringView;
begin
  V := TStringView.Create('abcdef');
  AssertEquals('slice(2,3)', 'cde', V.slice(2, 3).toString);
  AssertEquals('slice(-2,3) clamps the start', 'a', V.slice(-2, 3).toString);
  AssertEquals('slice(-2,5) drops the negative part', 'abc',
    V.slice(-2, 5).toString);
  AssertEquals('slice(1,-1) is empty', '', V.slice(1, -1).toString);
  AssertEquals('slice(4) runs to the end', 'ef', V.slice(4).toString);
  AssertEquals('slice(Length) is empty', '', V.slice(6).toString);
end;

procedure TStringViewTests.TestTrimAndSplitAtFind;
var
  V, Before, After: TStringView;
begin
  V := TStringView.Create('  key = value  ');
  AssertEquals('trim removes both ends', 'key = value', V.trim.toString);
  AssertEquals('trimLeft removes the lead', 'key = value  ', V.trimLeft.toString);
  AssertEquals('trimRight removes the trail', '  key = value', V.trimRight.toString);

  V := TStringView.Create('key = value');
  AssertTrue('splitAtFind reports a separator', V.splitAtFind('=', Before, After));
  AssertEquals('splitAtFind yields the left part', 'key ', Before.toString);
  AssertEquals('splitAtFind yields the right part', ' value', After.toString);

  V := TStringView.Create('novalue');
  AssertFalse('splitAtFind reports a missing separator',
    V.splitAtFind('=', Before, After));
end;

procedure TStringViewTests.TestParsing;
var
  V: TStringView;
  N: Integer;
  I64: Int64;
begin
  V := TStringView.Create('12');
  AssertTrue('toInt(12)', V.toInt(N) and (N = 12));

  V := TStringView.Create('-42');
  AssertTrue('toInt(-42)', V.toInt(N) and (N = -42));

  V := TStringView.Create('12abc');
  AssertFalse('toInt rejects trailing junk', V.toInt(N));

  V := TStringView.Create('');
  AssertFalse('toInt rejects an empty view', V.toInt(N));

  V := TStringView.Create('2147483648');
  AssertFalse('toInt rejects overflow', V.toInt(N));

  V := TStringView.Create('-2147483648');
  AssertTrue('toInt accepts Low(Integer)', V.toInt(N) and (N = Low(Integer)));

  V := TStringView.Create('9223372036854775807');
  AssertTrue('toInt64 accepts High(Int64)',
    V.toInt64(I64) and (I64 = High(Int64)));

  V := TStringView.Create('-9223372036854775808');
  AssertTrue('toInt64 accepts Low(Int64)',
    V.toInt64(I64) and (I64 = Low(Int64)));

  V := TStringView.Create('9223372036854775808');
  AssertFalse('toInt64 rejects overflow', V.toInt64(I64));

  V := TStringView.Create('-9223372036854775809');
  AssertFalse('toInt64 rejects underflow', V.toInt64(I64));
end;

{ ------------------------------------------------------------------- }
{  LightStringsUtils                                                  }
{ ------------------------------------------------------------------- }

procedure TUtilsTests.TestSplitJoin;
var
  Parts: TStringArray;
begin
  Parts := Split('a,b,c', ',');
  AssertEquals('Split yields every field', 3, Length(Parts));
  AssertEquals('Split field 0', 'a', Parts[0]);
  AssertEquals('Split field 2', 'c', Parts[2]);
  AssertEquals('Join reassembles the fields', 'a+b+c', Join(Parts, '+'));

  Parts := Split('a,,b', ',');
  AssertEquals('Split keeps empty fields', 3, Length(Parts));
  AssertEquals('empty field is empty', '', Parts[1]);
end;

procedure TUtilsTests.TestTrimFamily;
begin
  AssertEquals('Trim removes both ends', 'x', Trim('  '#9'x'#13#10'  '));
  AssertEquals('TrimLeft removes the lead', 'x  ', TrimLeft('  x  '));
  AssertEquals('TrimRight removes the trail', '  x', TrimRight('  x  '));
  AssertEquals('Trim of whitespace only is empty', '', Trim('   '));
end;

procedure TUtilsTests.TestPrefixSuffix;
begin
  AssertEquals('PrependIfMissing adds the prefix', 'pre-value',
    PrependIfMissing('value', 'pre-'));
  AssertEquals('PrependIfMissing keeps an existing prefix', 'pre-value',
    PrependIfMissing('pre-value', 'pre-'));

  AssertEquals('AppendIfMissing adds the suffix', 'value.txt',
    AppendIfMissing('value', '.txt'));
  AssertEquals('AppendIfMissing keeps an existing suffix', 'value.txt',
    AppendIfMissing('value.txt', '.txt'));
end;

procedure TUtilsTests.TestPredicates;
begin
  AssertTrue('BeginsWith finds a prefix', BeginsWith('lightstrings', 'light'));
  AssertFalse('BeginsWith rejects a longer needle',
    BeginsWith('light', 'lightstrings'));
  AssertTrue('EndsWith finds a suffix', EndsWith('lightstrings', 'strings'));
  AssertTrue('Contains finds a substring', Contains('lightstrings', 'str'));
  AssertTrue('Contains treats an empty needle as present', Contains('abc', ''));
  AssertFalse('Contains rejects a missing substring', Contains('abc', 'x'));
  AssertTrue('ContainsI ignores case', ContainsI('LightStrings', 'strings'));
  AssertFalse('Contains keeps case sensitivity',
    Contains('LightStrings', 'strings'));
end;

procedure TUtilsTests.TestReverseUtf8;
var
  S: string;
begin
  AssertEquals('Reverse(ASCII)', 'cba', Reverse('abc'));

  { 'h' followed by U+00E9 (C3 A9): the code points swap, the bytes of each
    multi-byte sequence stay in order. }
  S := 'h' + #$C3#$A9;
  AssertEquals('Reverse keeps multi-byte sequences intact',
    #$C3#$A9 + 'h', Reverse(S));
  AssertEquals('Reverse twice is the identity', S, Reverse(Reverse(S)));
end;

initialization
  RegisterTest(TBuilderTests);
  RegisterTest(TStrListTests);
  RegisterTest(TStringViewTests);
  RegisterTest(TUtilsTests);

end.
