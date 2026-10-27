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
| `LightStringsUtils.pas` | `Split`, `Join`, `Trim`, `TrimLeft`, `TrimRight`, `BeginsWith`, `EndsWith`, `Contains`, `ContainsI`, `UpperCaseStr`, `Reverse`, `PrependIfMissing`, `AppendIfMissing` |

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

## Project layout

```
LightStrings/
├── src/                    # the two library units
├── tests/                  # benchmark + smoke program
├── fpmake.pp               # Tier 1: native FPC package installer
├── lightstrings.cfg        # Tier 2: FPC response file
├── lightstrings_pkg.lpk    # Tier 3: Lazarus package
├── README.md
├── LICENSE                 # MIT
└── .gitignore
```

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Eudox67.
