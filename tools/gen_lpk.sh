#!/bin/bash
# ---------------------------------------------------------------------------
# gen_lpk.sh - generate a Lazarus package (.lpk, Tier 3) for a project whose
#              units live in a flat src/ directory.
#
# Usage:
#   tools/gen_lpk.sh <package> <units-file> <licence> <author> <description> \
#                    <includes:yes|no> [output]
#
# Example:
#   tools/gen_lpk.sh vsmath tools/vsmath-units.txt 'Apache-2.0' \
#       'vsmath Contributors' 'Single-precision SIMD matrix/vector math' \
#       yes vsmath.lpk
#
# <includes> is "yes" when the units {$I}-include a shared file from src/
# (vMath_CPU.inc for vsmath/vmath). That adds <IncludeFiles Value="src"/>,
# which is what makes the IDE and lazbuild resolve the include.
#
# NOTE - <package> must not equal any unit name, case-insensitively. Lazarus
# writes the package main unit as <package>.pas (unit <package>;) and
# TLazPackageGraph.SavePackageMainSource skips any package file whose unit name
# matches it, so e.g. a package "lightstrings" silently builds without the unit
# LightStrings and still exits 0. This script refuses such a name; use "<x>_pkg".
#
# The XML shape mirrors pasrocm.lpk (Lazarus 3.x, package version 5): one
# <Item> per unit, unit output in lib/$(TargetCPU)-$(TargetOS), and
# UsageOptions/UnitPath exporting $(PkgOutDir) to consuming projects.
# ---------------------------------------------------------------------------
set -eu

if [ $# -lt 6 ]; then
  sed -n '3,28p' "$0"
  exit 2
fi

pkg=$1
units=$2
lic=$3
author=$4
desc=$5
hasinc=$6
out=${7:-$pkg.lpk}

if [ ! -f "$units" ]; then
  echo "gen_lpk.sh: unit list '$units' not found" >&2
  exit 1
fi

# Normalise the list once: a CRLF or padded unit list would defeat the
# collision check below and put "name\r" into the generated XML.
work=$(mktemp)
trap 'rm -f "$work"' EXIT
sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$units" \
  | grep -v '^$' > "$work" || true

# A Lazarus package's main unit is <package>.pas, declaring "unit <package>;".
# TLazPackageGraph.SavePackageMainSource skips every package file whose unit name
# compares equal to that main unit, case-insensitively (it uses
# CompareDottedIdentifiers, which upper-cases both sides):
#
#   procedure UseUnit(AnUnitName: string);
#   begin
#     if CompareDottedIdentifiers(PChar(AnUnitName),PChar(PkgUnitName))=0 then exit;
#
# A package named after one of its own units therefore builds *without that
# unit* and still exits 0 - the generated <package>.pas simply does not list it.
# Refuse to create such a package; the caller must pick a distinct name.
collision=$(grep -ixF -- "$pkg" "$work" || true)
if [ -n "$collision" ]; then
  echo "gen_lpk.sh: ERROR: package name '$pkg' collides with unit '$collision'." >&2
  echo "  Lazarus would silently leave that unit out of <package>.pas." >&2
  echo "  Use a distinct, lowercase package name, e.g. '${pkg,,}_pkg', and name" >&2
  echo "  the file ${pkg,,}_pkg.lpk accordingly." >&2
  exit 1
fi

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<CONFIG>'
  echo '  <Package Version="5">'
  echo "    <Name Value=\"$pkg\"/>"
  echo '    <Type Value="RunTime"/>'
  echo "    <Author Value=\"$author\"/>"
  echo "    <License Value=\"$lic\"/>"
  echo "    <Description Value=\"$desc\"/>"
  echo '    <CompilerOptions>'
  echo '      <Version Value="11"/>'
  echo '      <SearchPaths>'
  echo '        <OtherUnitFiles Value="src"/>'
  if [ "$hasinc" = yes ]; then
    echo '        <IncludeFiles Value="src"/>'
  fi
  echo '        <UnitOutputDirectory Value="lib/$(TargetCPU)-$(TargetOS)"/>'
  echo '      </SearchPaths>'
  echo '      <Parsing>'
  echo '        <SyntaxOptions>'
  echo '          <Mode Value="ObjFPC"/>'
  echo '        </SyntaxOptions>'
  echo '      </Parsing>'
  echo '      <Other>'
  echo '        <CustomOptions Value="-Mobjfpc -Sh"/>'
  echo '      </Other>'
  echo '    </CompilerOptions>'
  echo '    <Files>'
  while read -r u; do
    [ -n "$u" ] || continue
    echo '      <Item>'
    echo "        <Filename Value=\"src/$u.pas\"/>"
    echo "        <UnitName Value=\"$u\"/>"
    echo '      </Item>'
  done < "$work"
  echo '    </Files>'
  echo '    <UsageOptions>'
  echo '      <UnitPath Value="$(PkgOutDir)"/>'
  echo '    </UsageOptions>'
  echo '    <PublishOptions>'
  echo '      <Version Value="2"/>'
  echo '      <UseFileFilters Value="True"/>'
  echo '    </PublishOptions>'
  echo '  </Package>'
  echo '</CONFIG>'
} > "$out"

echo "gen_lpk.sh: wrote $out ($(grep -c '<Item>' "$out") units)"
