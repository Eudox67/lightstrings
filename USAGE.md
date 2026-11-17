# Using LightStrings

A side-by-side guide: standard `TStringList` / `TStringBuilder` code on the
left, LightStrings `TStrList` / `TBuildStr` code on the right. The APIs were
deliberately aligned, so most of the time **the only thing that changes is the
declaration** — and the `Create` / `try` / `finally` / `Free` ceremony
disappears.

## The one thing to know first

LightStrings types are **advanced records**, not classes. Declaring a variable
gives you a working, empty container. No constructor, no destructor, no
`try/finally` — storage is released automatically when the variable goes out of
scope, *even when an exception unwinds through it*.

```pascal
var
  L: TStrList;    // ready to use, empty
  B: TBuildStr;   // ready to use, empty
```

Quick start (from the LightStrings checkout root; see the
[README](README.md) for installation options):

```bash
fpc @lightstrings.cfg myprog.pas -FU/tmp/units -FE/tmp/units
```

---

## TStrList vs TStringList

### 1. Create, add, read, iterate

**TStringList** (`Classes`):

```pascal
uses SysUtils, Classes;

procedure Demo;
var
  SL: TStringList;
  S: string;
begin
  SL := TStringList.Create;
  try
    SL.Add('alpha');
    SL.Add('beta');
    SL.Add('gamma');

    WriteLn('count: ', SL.Count);   // count: 3
    WriteLn('first: ', SL[0]);      // first: alpha
    for S in SL do
      WriteLn(S);
  finally
    SL.Free;
  end;
end;
```

**TStrList** (`LightStrings`):

```pascal
uses SysUtils, LightStrings;

procedure Demo;
var
  L: TStrList;
  S: string;
begin
  L.Add('alpha');
  L.Add('beta');
  L.Add('gamma');

  WriteLn('count: ', L.Count);      // count: 3
  WriteLn('first: ', L[0]);         // first: alpha
  for S in L do
    WriteLn(S);
end;   // storage released here — automatically
```

Same verbs, same `for S in ...` loop, seven fewer lines of lifetime
management. If you know the size up front, preallocate — the equivalent of
`SL.Capacity := 1000`:

```pascal
L.Init(1000);   // optional; Add auto-grows when you skip it
```

### 2. Sorting and searching

**TStringList**:

```pascal
SL := TStringList.Create;
try
  SL.Add('gamma');
  SL.Add('alpha');
  SL.Add('beta');
  SL.Sort;
  WriteLn(SL.IndexOf('beta'));   // 1
  SL.Sorted := True;             // keeps itself sorted from now on
  SL.Add('aaa');
  WriteLn(SL[0]);                // aaa
finally
  SL.Free;
end;
```

**TStrList**:

```pascal
L.Add('gamma');
L.Add('alpha');
L.Add('beta');
L.Sort;
WriteLn(L.IndexOf('beta'));      // 1
L.Sorted := True;                // Add now inserts in order
L.Add('aaa');
WriteLn(L[0]);                   // aaa

if L.Find('beta', I) then        // binary search — sorted lists only
  WriteLn('found at ', I);       // found at 2
```

Two things worth knowing:

* `Sort`/`Find` compare **byte-wise** (case-sensitive, `'Z' < 'a'`), while
  `TStringList.Sort` uses case-insensitive `CompareText`.
* `NaturalSort` is a bonus with no `TStringList` equivalent: it orders
  `item2` before `item10` the way a human would.

### 3. Name = value pairs (settings, headers, key/value files)

**TStringList**:

```pascal
SL := TStringList.Create;
try
  SL.AddPair('host', 'localhost');
  SL.Values['port'] := '8080';       // adds the pair
  WriteLn(SL.Values['host']);        // localhost
  WriteLn(SL.Names[0]);              // host
  WriteLn(SL.ValueFromIndex[0]);     // localhost
  SL.Values['port'] := '9090';       // updates in place
  SL.Values['port'] := '';           // deletes the pair
finally
  SL.Free;
end;
```

**TStrList** — the body is character-for-character identical:

```pascal
L.AddPair('host', 'localhost');
L.Values['port'] := '8080';          // adds the pair
WriteLn(L.Values['host']);           // localhost
WriteLn(L.Names[0]);                 // host
WriteLn(L.ValueFromIndex[0]);        // localhost
L.Values['port'] := '9090';          // updates in place
L.Values['port'] := '';              // deletes the pair
```

### 4. Text, delimited text, and files

**TStringList**:

```pascal
SL := TStringList.Create;
try
  SL.Text := 'one' + sLineBreak + 'two';
  WriteLn(SL.Count);                 // 2

  SL.Delimiter := ';';
  SL.StrictDelimiter := True;
  SL.DelimitedText := 'a;b;c';
  WriteLn(SL[1]);                    // b
  WriteLn(SL.CommaText);             // a,b,c

  SL.SaveToFile('/tmp/list.txt');
  SL.Clear;
  SL.LoadFromFile('/tmp/list.txt');
  WriteLn(SL.Count);                 // 3
finally
  SL.Free;
end;
```

**TStrList**:

```pascal
L.Text := 'one' + sLineBreak + 'two';
WriteLn(L.Count);                    // 2

L.Delimiter := ';';
L.StrictDelimiter := True;
L.DelimitedText := 'a;b;c';
WriteLn(L[1]);                       // b
WriteLn(L.CommaText);                // a,b,c

L.SaveToFile('/tmp/list.txt');
L.Clear;
L.LoadFromFile('/tmp/list.txt');
WriteLn(L.Count);                    // 3
```

Blank lines survive `Text` and file round-trips in both.

### 5. Capacity and mutation

Every `TStrings` mutation verb exists with the same name and arguments:

```pascal
L.Capacity := 1024;         // preallocate, like SL.Capacity := 1024
L.Add('a');
L.Add('b');
L.Add('c');
L.Insert(1, 'x');           // a x b c
L.Delete(0);                // x b c
L.Exchange(0, 2);           // c b x
L.Move(0, 2);               // b x c   (MoveItem also works — kept as an alias)
L.Reverse;                  // c x b
```

### 6. Add returns the index — in both

```pascal
I := SL.Add('item');        // TStrings.Add returns Integer
I := L.Add('item');         // TStrList.Add returns NativeInt
```

With `Sorted := True`, both return the position the item actually landed at.

---

## TBuildStr vs TStringBuilder

### 1. Building a string

**TStringBuilder** (`SysUtils`):

```pascal
uses SysUtils;

procedure Demo;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('Hello');
    SB.Append(', ');
    SB.Append('world');
    SB.Append('!');
    WriteLn(SB.ToString);            // Hello, world!
  finally
    SB.Free;
  end;
end;
```

**TBuildStr** (`LightStrings`):

```pascal
uses SysUtils, LightStrings;

procedure Demo;
var
  B: TBuildStr;
begin
  B.Init;                  // optional: reserves 256 chars up front
  B.Append('Hello');
  B.Append(', ');
  B.Append('world');
  B.Append('!');
  WriteLn(B.ToString);               // Hello, world!
end;
```

Even `Init` is optional — `Append` allocates on demand. `ToString` is the
same final step as `TStringBuilder`: it hands you one flat string.

### 2. Numbers and lines

**TStringBuilder**:

```pascal
SB.AppendLine('report');
SB.Append('total: ');
SB.Append(12345);
```

**TBuildStr** — same calls, and the number never touches the heap:

```pascal
B.AppendLine('report');
B.Append('total: ');
B.Append(12345);           // rendered on the stack; handles Low(Int64) too
```

`Append(Int64)` accepts `Integer`, `NativeInt` and `Int64` values and integer
literals through a single overload — no `IntToStr`, no temporary string.

### 3. Length, Capacity, Chars, EnsureCapacity

The `TStringBuilder` property set exists under the same names:

```pascal
// TStringBuilder                     // TBuildStr
SB.EnsureCapacity(4096);              B.EnsureCapacity(4096);
SB.Capacity := 8192;                  B.Capacity := 8192;
C := SB.Chars[0];                     C := B.Chars[0];   // or just B[0]
SB.Chars[0] := 'X';                   B.Chars[0] := 'X'; // or B[0] := 'X'
SB.Length := 10;                      B.Length := 10;    // #0-fills the tail
```

`Chars[]` is the default property and is bounds-checked in both; shrinking
`Length` truncates in both.

### 4. The pattern LightStrings is built for: big loops

```pascal
B.Init(1 shl 20);                     // one up-front reservation
for I := 0 to 999999 do
begin
  B.Append('item ');
  B.Append(I);                        // no IntToStr allocation
  B.Append(sLineBreak);
end;
S := B.ToString;                      // one final string
```

A million lines, one buffer, zero per-iteration heap traffic. The same loop
with `S := S + 'item ' + IntToStr(I) + sLineBreak` reallocates and copies the
whole accumulated string on every pass — that is the trap `TBuildStr` (like
`TStringBuilder`) exists to avoid, minus the object lifetime management.

---

## Value semantics: the one *real* difference

`TStringList` variables are **references**; `TStrList`/`TBuildStr` variables
are **values**. Assignment copies the container instead of aliasing it:

```pascal
var
  A, B: TStrList;
begin
  A.Add('one');
  B := A;          // deep copy (with TStringList, B := A would alias!)
  B[0] := 'two';
  WriteLn(A[0]);   // one   — TStringList would print two
end;
```

This is usually what you want from a local helper container — no accidental
sharing, no double-free. When passing lists around, use `var` (or `constref`
for read-only access) so you don't pay for a copy:

```pascal
procedure Fill(var L: TStrList);      // no copy, callee fills the caller's list
begin
  L.Add('data');
end;

procedure Report(constref L: TStrList);  // no copy, read-only
var
  S: string;
begin
  for S in L do
    WriteLn(S);
end;
```

## What LightStrings deliberately doesn't do

| Topic | Note |
|---|---|
| Not a `TStrings` descendant | `TStrList` is a record, so it cannot be passed to APIs that expect `TStrings`/`TStringList` parameters. Copy across with `Text` when you hit such an API. |
| No `Objects[]` / `AddObject` | It stores strings only — that's where the weight savings come from. |
| Sort order | Byte-wise and case-sensitive (`TStringList.Sort` is case-insensitive). |
| `Items[]` unchecked | Reads/writes outside `0..Count-1` are your responsibility, as documented in the README. (`TBuildStr.Chars[]` *is* checked.) |
| `Sorted` flag | `Insert`, `Items[] :=`, `Exchange`, `Move`, `Reverse` clear it, because they can break the order `Find` relies on. |
| No fluent chaining | `TStringBuilder.Append` returns `Self` so calls can chain; `TBuildStr.Append` is a plain procedure. |
| No `Duplicates`, `CaseSensitive`, `OnChange`, ... | The long tail of `TStrings` options is not implemented. See the README behaviour table for the full list of deliberate choices. |

## How much faster is it?

From the benchmark in the [README](README.md) (2,000,000 items,
linux-x86_64): `Add` ~2.8×, `IndexOf` ~5×, `CommaText` ~4×, name/value lookups
~6×, file I/O ~19×, and the builder loop ~2× faster than `TStringList.Text` —
with less code to write. Run it yourself:

```bash
fpc @lightstrings.cfg tests/test_benchmark.pas -FU/tmp/ls-build -FE/tmp/ls-build
/tmp/ls-build/test_benchmark
```