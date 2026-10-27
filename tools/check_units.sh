#!/bin/bash
# ---------------------------------------------------------------------------
# check_units.sh - find out which units in a flat src/ directory really compile.
#
# Usage:
#   tools/check_units.sh <src-dir> [<failing-units-out>]
#
# Why this exists: FPC stops at the first broken unit, and a package manifest
# that names a unit which does not compile makes the whole package build fail.
# This script compiles every unit that declares "unit <name>;" by generating a
# program that uses all of them, then drops the unit that failed and retries,
# until the build is clean. That isolates each broken unit individually.
#
# Output: one line per failing unit (unit :: first error), then a summary.
# Exit code: 0 when every unit compiled, 1 when any failed, 2 on usage error.
#
# Feed the passing units to the manifest generators:
#   tools/check_units.sh src /tmp/broken.txt && \
#     grep -vxFf /tmp/broken.txt <(ls src/*.pas | xargs -n1 basename | sed 's/\.pas$//') \
#       > tools/<project>-units.txt
#
# Limitations: flat directory only (no subdirectories), and a file whose name
# does not match its "unit" identifier is reported as a failure - FPC requires
# them to match.
# ---------------------------------------------------------------------------
set -u

if [ $# -lt 1 ]; then
  sed -n '3,12p' "$0"
  exit 2
fi

src=${1%/}
faillist=${2:-}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if [ ! -d "$src" ]; then
  echo "check_units.sh: '$src' is not a directory" >&2
  exit 2
fi

units=$(cd "$src" && grep -l '^unit ' *.pas 2>/dev/null | sed 's/\.pas$//' | grep -vE '[ ()]' | sort -f)
if [ -z "$units" ]; then
  echo "check_units.sh: no units found in '$src'" >&2
  exit 2
fi

# Sanity: a .pas file with neither "unit" nor "program" in its first 60 lines is
# almost always truncated, and the probe below can never see it - it would pass
# silently. Report it so a half-written file cannot be packaged by accident.
for f in "$src"/*.pas; do
  [ -e "$f" ] || continue
  if ! head -60 "$f" | grep -qE '^[[:space:]]*(unit|program|library)[[:space:]]'; then
    echo "check_units.sh: WARNING: $(basename "$f") declares neither unit nor program" >&2
  fi
done

# The sweep above ignores filenames containing a space or parenthesis (FPC
# cannot map such a name to a unit reliably). Report them: a silently skipped
# file could hide a broken unit or a "(copy)" duplicate that never gets cleaned.
skipped=$(cd "$src" && ls *.pas 2>/dev/null | grep -E '[ ()]' || true)
if [ -n "$skipped" ]; then
  echo "check_units.sh: WARNING: skipped by name (NOT compile-checked):" >&2
  printf '%s\n' "$skipped" | sed 's/^/  /' >&2
fi

total=$(echo "$units" | wc -l)
failed=''

for _ in $(seq 1 $((total + 1))); do
  {
    echo 'program check_units_probe;'
    echo '{$MODE OBJFPC}{$H+}'
    echo 'uses'
    echo "$units" | sed 's/^/  /' | sed '$!s/$/,/'
    echo '  ;'
    echo 'begin'
    echo 'end.'
  } > "$work/probe.pas"

  ( cd "$src" && fpc -Mobjfpc -Sh -Fu. -Fi. -FU"$work" -FE"$work" "$work/probe.pas" \
      > "$work/log" 2>&1 )
  rc=$?

  if [ $rc -eq 0 ]; then
    break
  fi

  bad=$(grep -oE '^[A-Za-z0-9_]+\.pas\([0-9]+,[0-9]+\) (Error|Fatal):' "$work/log" \
        | head -1 | sed 's/\.pas.*//')

  if [ -z "$bad" ] || [ "$bad" = check_units_probe ]; then
    echo "check_units.sh: unclassified failure - inspect the log below" >&2
    sed -n '1,40p' "$work/log" >&2
    exit 1
  fi

  echo "$bad :: $(grep -E "^$bad\.pas\([0-9]+,[0-9]+\) (Error|Fatal):" "$work/log" | head -1)"
  failed="$failed$bad"$'\n'
  units=$(echo "$units" | grep -vx "$bad" || true)

  if [ -z "$units" ]; then
    break
  fi
done

ok=$(echo "$units" | grep -c . || true)
nfail=$(printf '%s' "$failed" | grep -c . || true)

if [ -n "$faillist" ]; then
  printf '%s' "$failed" > "$faillist"
fi

echo "----"
echo "compiled: $ok / $total    failed: $nfail"

if [ "$nfail" -ne 0 ]; then
  exit 1
fi
