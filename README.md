# LightStrings

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Open Source](https://img.shields.io/badge/Open_Source-Yes-teal)](https://opensource.org/licenses/MIT)
![Free Pascal](https://img.shields.io/badge/Free_Pascal-3.2.2%2B-orange)
![Lazarus](https://img.shields.io/badge/Lazarus-lightstrings__pkg.lpk-1E5AA8)
![Platform](https://img.shields.io/badge/Platform-Any_FPC_Target-555555)
![Dependencies](https://img.shields.io/badge/Dependencies-None-007EC6)
![Tests](https://img.shields.io/badge/FPCUnit-31_tests-brightgreen)

Stack-based string handling for Free Pascal: `TBuildStr` (a growable builder
without the `TStringList` heap dance), `TStrList` (a thin `TStringList`
alternative), `TStringView` (a non-owning view), plus a small set of string
helpers. All types are **advanced records**, so they live on the stack and are
released automatically through FPC's management operators.

No external dependencies: both units use only the implicit `System` unit.

Works with the plain Free Pascal compiler (CLI) and with Lazarus — no external
build tool.

## Coverage

| Unit | Types / functions |
|---|---|
| `LightStrings.pas` | `TBuildStr` — `Init`, `Append(string)`, `Append(PChar, Len)`, `Append(Char)`, `Append(Int64)`, `AppendLine`, `EnsureCapacity`, `Chop`, `Clear`, `ToString`, properties `Length`, `Capacity`, `Chars[]` (default); `TStrList` — `Init`, `Add` (returns the item index), `AddPair`, `Insert`, `Delete`, `Clear`, `Sort`, `NaturalSort`, `Reverse`, `IndexOf`, `IndexOfName`, `Exchange`, `Move`, `MoveItem`, `GetEnumerator` (`for S in List`), properties `Items[]` (default), `Count`, `Capacity`, `Text`, `CommaText`, `DelimitedText`, `Delimiter`, `StrictDelimiter`, `Sorted`, `Names[]`, `ValueFromIndex[]`, `Values[]`; `TStringView` — `Chars[]` |
| `LightStringsUtils.pas` | `Split`, `Join`, `Trim`, `TrimLeft`, `TrimRight`, `BeginsWith`, `EndsWith`, `Contains`, `ContainsI`, `Reverse`, `PrependIfMissing`, `AppendIfMissing` |

### Behaviour notes

Deliberate choices, and the places where this is not a drop-in `TStringList`.

| Topic | Behaviour |
|---|---|
| `Items[]` / `Chars[]` | Unchecked by design (the unit compiles without range checks). `TStringView.Chars[]` returns `#0` outside `0 .. Length-1`, and `TStringView.slice` clamps negative offsets instead of reading before the buffer. |
| `Sorted` / `Sort` | `Sort` sets `Sorted`, and `Add` keeps a sorted list sorted. `Insert`, `SetItem`, `Exchange`, `Move`/`MoveItem` and `Reverse` clear `Sorted`, because they can break the byte order `Find` searches for. `Find` returns `False` unless `Sorted` is set. `NaturalSort` does **not** set `Sorted` (natural order is not byte order). |
| `Add` / `AddPair` | Return the index the item actually landed at — the sorted insertion point when `Sorted` is set, the append position otherwise (like `TStrings.Add`). |
| `Values[]` / `ValueFromIndex[]` | Writable, matching `TStrings`: writing a non-empty value updates the pair (or adds it when the name is missing); writing `''` deletes the entry. |
| `Capacity` | Exposes the allocated storage; setting it grows or shrinks the array (shrinking below `Count` is a range error, `RunError(201)`). `Add` still auto-grows past a manually set capacity. |
| `Move` vs `MoveItem` | `Move` matches the `TStrings` name; `MoveItem` is kept as an inline alias. Both shift string pointers (no per-item copy) and clear `Sorted`. |
| `Text` | Blank lines are preserved by both `Text` and `LoadFromFile`, so a `Text` round-trip is lossless. |
| `Clear` | Drops the items logically but keeps the allocated array (and the string references) for reuse; release the record to free the memory. |
| `TBuildStr.Chars[]` | Bounds-checked like `TStringBuilder.Chars`: out-of-range access is a range error (`RunError(201)`), unlike the unchecked `TStrList.Items[]` or the `#0`-sentinel `TStringView.Chars[]`. |
| `TBuildStr.Length` | `TStringBuilder` semantics: extending zero-fills (`#0`) the new tail, shrinking truncates; negative lengths are a range error. |
| `TBuildStr.Capacity` | Exact reallocation (no growth rounding, unlike the internal `Grow`); `0` releases the buffer; below `Length` is a range error. `EnsureCapacity` uses the amortized growth strategy instead. |
| `Append(Int64)` | Allocation-free: renders backwards into a 21-char stack buffer, handles `Low(Int64)` via two's-complement negation, and accepts `Integer`/`NativeInt`/`Int64` values through a single overload. |
| `StrictDelimiter` | `True` disables quoting entirely (an item containing the delimiter then cannot round-trip), matching `TStrings`. |
| `toInt` / `toInt64` | Strict: the whole view must be numeric — no trailing characters — and out-of-range input returns `False` instead of wrapping. |
| `Reverse` (Utils) | UTF-8 aware: code points are reversed, multi-byte sequences stay intact. |
| Sort order | `Sort`/`Find` compare whole strings byte-wise (as `<` does), not case-insensitively like `TStringList.Sort`. |

## Requirements

| Component | Version / notes |
|---|---|
| Free Pascal | 3.2.2 or newer (developed and verified against FPC 3.3.1) |
| OS / CPU | any target FPC supports; verified on linux-x86_64 |
| Lazarus | optional — only for the `.lpk` installation route |

## How to use LightStrings

Pick the integration that fits your workflow.

### Option 1 — native FPC package (`fpmake`)

```bash
fpc fpmake.pp                       # build the installer (once)
./fpmake compile                    # -> units/<target>/*.ppu
./fpmake install --prefix="$HOME/.local"
```

Stock `fpc.cfg` files that contain
`-Fu<prefix>/lib/fpc/$fpcversion/units/$fpctarget/*` discover the package
automatically. If yours lists package directories explicitly, add it once (FPC
does not expand environment variables inside config files):

```bash
UNITDIR="$HOME/.local/lib/fpc/$(fpc -iV)/units/$(fpc -iTP)-$(fpc -iTO)/lightstrings"
echo "-Fu$UNITDIR" >> ~/.fpc.cfg
```

Now any project can say `uses LightStrings, LightStringsUtils;`. To uninstall,
delete that `lightstrings` directory plus the matching
`fpmkinst/<target>/lightstrings.fpm` manifest, if present.

### Option 2 — zero-install response file (`lightstrings.cfg`)

Nothing is written outside the checkout — ideal when LightStrings is a git
submodule. Its paths are relative, so run `fpc` from the project root:

```bash
cd /path/to/LightStrings
fpc @lightstrings.cfg my_program.pas -FU/tmp/units
```

`lightstrings.cfg` supplies `-Mobjfpc -Sh -Fusrc`. Always add `-FU<dir>` (create
it first) so the compiler does not write `.ppu`/`.o` next to the sources.

### Option 3 — Lazarus package (`lightstrings_pkg.lpk`)

**IDE:** *Package → Open Package File (.lpk)* → `lightstrings_pkg.lpk` →
**Compile** → *Use → Add to Project*.

**Command line:**

```bash
lazbuild lightstrings_pkg.lpk                    # -> lib/$(TargetCPU)-$(TargetOS)/*.ppu
lazbuild --add-package lightstrings_pkg.lpk my_project.lpi
lazbuild my_project.lpi
```

The package exports `src` to every project that uses it, so
`uses LightStrings;` needs no further configuration.

> **Why `lightstrings_pkg` and not `lightstrings`?** Lazarus generates a package
> unit named after the package (`<package>.pas`) and silently *skips* any
> package file whose unit name matches it (`TLazPackageGraph.SavePackageMainSource`
> in `packager`). A package called `lightstrings` therefore drops
> `src/LightStrings.pas` from the build and leaves a stub `lightstrings.pas`
> that shadows the real unit on case-insensitive unit lookup. The `_pkg` suffix
> keeps the package name distinct from every unit name.

### Can I use more than one?

Yes — the options are not mutually exclusive. Option 1 **and** Option 3 is the
common combination: the installed package serves plain `fpc`/`lazbuild` builds,
the Lazarus package gives the IDE its source-level tooling.

| Setup | `fpc` CLI | `lazbuild` | IDE Code Tools (completion, *Ctrl+Click*) |
| --- | :-: | :-: | :-: |
| Only Option 1 (installed + `-Fu`) | yes | yes | **no** — only `.ppu`/`.o` are installed |
| Only Option 2 (`@lightstrings.cfg`) | yes | with the same `-Fu` flags in the project | no |
| Only Option 3 (`lightstrings_pkg.lpk`) | with `-Fu src` | yes | **yes** |
| Option 1 + Option 3 | yes | yes | yes |

## Examples and benchmarks

```bash
mkdir -p /tmp/ls-build
fpc @lightstrings.cfg tests/test_benchmark.pas -FU/tmp/ls-build -FE/tmp/ls-build
/tmp/ls-build/test_benchmark
```

**Example Results**
```bash
=== LightStrings vs TStringList Benchmark ===

Benchmark                                  | LightStrings |  TStringList | Result         
-------------------------------------------+--------------+--------------+----------------
1. Add (2,000,000 items)                   |      31.0 ms |      87.0 ms | 2.81x faster   
2. IndexOf (2M items, 1000 searches)       |       2.0 ms |      11.0 ms | 5.50x faster   
3. Sort (2M items; byte vs CompareText)    |    1406.0 ms |    2821.0 ms | 2.01x faster   
4. NaturalSort vs CustomSort (2M items)    |   10562.0 ms |   11656.0 ms | 1.10x faster   
5. Text (2,000,000 items)                  |      65.0 ms |      50.0 ms | 1.30x slower   
6. CommaText (2,000,000 items)             |     150.0 ms |     617.0 ms | 4.11x faster   
7. Name/Value (2M items, 100 lookups)      |    1432.0 ms |    8815.0 ms | 6.16x faster   
8. File I/O (80,000 items)                 |      16.0 ms |     313.0 ms | 19.56x faster  
9. TBuildStr vs TStringList.Text (2M)      |     168.0 ms |     329.0 ms | 1.96x faster   
10. TStringView vs Copy+Pos (2M x 24)      |      47.0 ms |    1282.0 ms | 27.28x faster  
-------------------------------------------+--------------+--------------+----------------
Total                                      |   13879.0 ms |   25981.0 ms | 1.87x faster
```

`tests/regression.pas` is the self-checking program for the memory-safety and
semantic fixes; build it with `-gh` so the heap trace covers them too:

```bash
mkdir -p /tmp/ls-reg
fpc @lightstrings.cfg -gh tests/regression.pas -FU/tmp/ls-reg -FE/tmp/ls-reg
/tmp/ls-reg/regression        # exits 0 when every check passes
```

## Tests

`tests/TestLightStrings.pas` is an FPCUnit suite covering the public API of
both units; `tests/testrunner.pas` is the console runner that registers it.

```bash
mkdir -p /tmp/ls-tests
fpc @lightstrings.cfg tests/testrunner.pas -FU/tmp/ls-tests -FE/tmp/ls-tests
/tmp/ls-tests/testrunner                          # 31 tests, 0 failures
```

`tests/regression.pas` above is kept separate on purpose: it is the `-gh`
memory-safety probe, while the FPCUnit suite is the behavioural gate.

## Project layout

```
LightStrings/
├── src/                    # the two library units
├── tests/                  # FPCUnit suite + runner, smoke, regression, benchmark
├── fpmake.pp               # Tier 1: native FPC package installer
├── lightstrings.cfg        # Tier 2: FPC response file
├── lightstrings_pkg.lpk    # Tier 3: Lazarus package
├── README.md
├── LICENSE                 # MIT
└── .gitignore
```

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Eudox67.
