#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTDIR="$ROOT/.dist"
BINDIR="$ROOT/bin"

mkdir -p "$BINDIR"

if [[ $# -lt 1 ]]; then
  echo "usage: scripts/link-test.sh <suffix> (e.g., 0 or 01)" >&2
  exit 2
fi
suffix="$1"
SRC="$OUTDIR/easykey${suffix}"
DST="$BINDIR/easykey${suffix}"

if [[ ! -x "$SRC" ]]; then
  echo "error: build artifact not found: $SRC" >&2
  exit 1
fi

rm -f "$DST"
ln -s "$SRC" "$DST"
chmod +x "$SRC"

echo "Linked: $DST -> $SRC"
