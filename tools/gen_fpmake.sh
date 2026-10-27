#!/bin/bash
# ---------------------------------------------------------------------------
# gen_fpmake.sh - generate an fpmake.pp (Tier 1 package installer) for a
#                 project whose units live in a flat src/ directory.
#
# Usage:
#   tools/gen_fpmake.sh <package> <units-file> <oses> <cpus> <licence> \
#                       <author> <description> [output]
#
# Example:
#   tools/gen_fpmake.sh vsmath tools/vsmath-units.txt \
#       'linux, win32, win64' 'x86_64, i386' 'Apache-2.0' 'vsmath Contributors' \
#       'Single-precision SIMD matrix/vector math for Free Pascal'
#
# <units-file> holds one unit name per line (no .pas suffix), sorted, e.g. the
# output of tools/check_units.sh. Regenerate fpmake.pp after any unit is added,
# renamed or excluded - an AddUnit that names a missing file makes fpmake fail.
# ---------------------------------------------------------------------------
set -eu

if [ $# -lt 7 ]; then
  sed -n '3,18p' "$0"
  exit 2
fi

pkg=$1
units=$2
oses=$3
cpus=$4
lic=$5
author=$6
desc=$7
out=${8:-fpmake.pp}

if [ ! -f "$units" ]; then
  echo "gen_fpmake.sh: unit list '$units' not found" >&2
  exit 1
fi

# Normalise the list once: a CRLF or padded unit list would otherwise end up
# embedded in the generated manifest as "name\r", which fpmake cannot resolve.
work=$(mktemp)
trap 'rm -f "$work"' EXIT
sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$units" \
  | grep -v '^$' > "$work" || true

{
  echo 'program fpmake;'
  echo
  echo '{$mode objfpc}{$H+}'
  echo
  echo 'uses'
  echo '{$ifdef unix}'
  echo '  cthreads,'
  echo '{$endif}'
  echo '  fpmkunit;'
  echo
  echo 'var'
  echo '  P: TPackage;'
  echo 'begin'
  echo '  with Installer do'
  echo '  begin'
  echo "    P := AddPackage('$pkg');"
  echo "    P.Version := '1.0.0';"
  echo "    P.Author := '$author';"
  echo "    P.License := '$lic';"
  echo "    P.Description := '$desc';"
  echo
  echo "    P.OSes := [$oses];"
  echo "    P.CPUs := [$cpus];"
  echo
  echo '    // SourcePath locates the files named in AddUnit; UnitPath feeds -Fu'
  echo '    // and IncludePath feeds -Fi for the shared *.inc files.'
  echo "    P.SourcePath.Add('src');"
  echo "    P.UnitPath.Add('src');"
  echo "    P.IncludePath.Add('src');"
  echo
  echo '    // The units declare {$mode objfpc} themselves; stating it keeps the'
  echo '    // package build identical to a hand-written fpc invocation.'
  echo "    P.Options.Add('-Mobjfpc');"
  echo
  echo '    // fpmkunit injects an implicit dependency on the "rtl" package, which'
  echo '    // needs a per-package unit-config file (<unitdir>/rtl/rtl.fpc) that'
  echo '    // many FPC installs do not ship; the lookup then aborts with'
  echo '    //   Could not find unit directory for dependency package "rtl"'
  echo '    // The compiler already knows where its own RTL is, so the dependency'
  echo '    // is dropped and this package needs no external resolution.'
  echo '    P.Dependencies.Clear;'
  echo
  while read -r u; do
    [ -n "$u" ] || continue
    echo "    P.Targets.AddUnit('$u.pas');"
  done < "$work"
  echo
  echo '    Run;'
  echo '  end;'
  echo 'end.'
} > "$out"

echo "gen_fpmake.sh: wrote $out ($(grep -c 'P.Targets.AddUnit' "$out") units)"
