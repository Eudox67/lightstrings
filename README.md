# LightStrings

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
| `LightStrings.pas` | `TBuildStr` — `Init`, `Append(string)`, `Append(PChar, Len)`, `AppendLine`, `Chop`, `Clear`, `ToString`; `TStrList` — `Init`, `Add`, `Insert`, `Delete`, `Clear`, `Sort`, `NaturalSort`, `Reverse`, `IndexOf`, `IndexOfName`, `Names`, `Values`, `Exchange`, `MoveItem`, properties `Items[]` (default), `Count`, `Text`, `CommaText`, `DelimitedText`, `Delimiter`, `StrictDelimiter`, `Sorted`; `TStringView` — `Chars[]` |
| `LightStringsUtils.pas` | `Split`, `Join`, `Trim`, `TrimLeft`, `TrimRight`, `BeginsWith`, `EndsWith`, `Contains`, `ContainsI`, `Reverse`, `PrependIfMissing`, `AppendIfMissing` |

### Behaviour notes

Deliberate choices, and the places where this is not a drop-in `TStringList`.

| Topic | Behaviour |
|---|---|
| `Items[]` / `Chars[]` | Unchecked by design (the unit compiles without range checks). `TStringView.Chars[]` returns `#0` outside `0 .. Length-1`, and `TStringView.slice` clamps negative offsets instead of reading before the buffer. |
| `Sorted` / `Sort` | `Sort` sets `Sorted`, and `Add` keeps a sorted list sorted. `Insert`, `SetItem`, `Exchange`, `MoveItem` and `Reverse` clear `Sorted`, because they can break the byte order `Find` searches for. `Find` returns `False` unless `Sorted` is set. `NaturalSort` does **not** set `Sorted` (natural order is not byte order). |
| `Text` | Blank lines are preserved by both `Text` and `LoadFromFile`, so a `Text` round-trip is lossless. |
| `Clear` | Drops the items logically but keeps the allocated array (and the string references) for reuse; release the record to free the memory. |
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
/tmp/ls-tests/testrunner                          # 22 tests, 0 failures
```

`tests/regression.pas` above is kept separate on purpose: it is the `-gh`
memory-safety probe, while the FPCUnit suite is the behavioural gate.

## Tools

`tools/` holds the packaging helpers used by this repository:

| Tool | Purpose |
|---|---|
| `tools/check_units.sh src [fail-file]` | Compiles every unit in a flat directory via a generated "uses everything" probe and reports each failure. Exit 0 means every shipped unit compiles. |
| `tools/gen_fpmake.sh <pkg> <units-file> <oses> <cpus> <licence> <author> <desc> [out]` | Regenerates `fpmake.pp` from a unit list. |
| `tools/gen_lpk.sh <pkg> <units-file> <licence> <author> <desc> <includes:yes\|no> [out]` | Regenerates the `.lpk` from the same list; refuses a package name that collides with a unit name. |
| `tools/lightstrings-units.txt` | The unit list both generators consume. Regenerate after adding or removing a unit. |

```bash
tools/check_units.sh src /tmp/broken.txt          # -> "compiled: 2 / 2    failed: 0"
```

## Project layout

```
LightStrings/
├── src/                    # the two library units
├── tests/                  # FPCUnit suite + runner, smoke, regression, benchmark
├── tools/                  # unit checker and package generators
├── fpmake.pp               # Tier 1: native FPC package installer
├── lightstrings.cfg        # Tier 2: FPC response file
├── lightstrings_pkg.lpk    # Tier 3: Lazarus package
├── README.md
├── LICENSE                 # MIT
└── .gitignore
```

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Eudox67.
