#!/bin/zsh
set -euo pipefail

# Prefer full Xcode toolchain if installed (avoids CLT module conflicts)
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

# Usage: scripts/build-test.sh [suffix]
# Examples:
#   scripts/build-test.sh 0   => .dist/easykey0
#   scripts/build-test.sh 01  => .dist/easykey01
# If omitted, auto-increment from existing .dist/easykey* files.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/easykey/main.swift"
OUTDIR="$ROOT/.dist"

mkdir -p "$OUTDIR"

suffix="${1:-}"
if [[ -z "$suffix" ]]; then
  # Auto-pick next numeric suffix
  last=$(ls -1 "$OUTDIR" 2>/dev/null | grep -E '^easykey[0-9]+' | sed -E 's/^easykey(0*)([0-9]+)$/\2/' | sort -n | tail -n 1 || true)
  if [[ -z "$last" ]]; then
    suffix=0
  else
    next=$((last + 1))
    # Keep zero padding if last had it
    padlen=$(ls -1 "$OUTDIR" | grep -E "^easykey0+${last}$" >/dev/null 2>&1 && echo 1 || echo 0)
    if [[ "$padlen" == 1 ]]; then
      # Determine width from first matching file
      width=$(ls -1 "$OUTDIR" | grep -E "^easykey0+${last}$" | head -n1 | sed -E 's/^easykey(0+)[0-9]+$/\1/' | awk '{ print length }')
      suffix=$(printf "%0*d" $width $next)
    else
      suffix=$next
    fi
  fi
fi

BIN="$OUTDIR/easykey${suffix}"

# Build with Xcode toolchain if available; fallback to swiftc
if command -v xcodebuild >/dev/null 2>&1; then
  # Try using xcrun swiftc for consistent SDK
  SDK_PATH=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)
  if [[ -n "$SDK_PATH" ]]; then
    xcrun --sdk macosx swiftc -O -g -sdk "$SDK_PATH" "$SRC" -o "$BIN" -framework Security -framework LocalAuthentication
  else
    swiftc -O -g "$SRC" -o "$BIN" -framework Security -framework LocalAuthentication
  fi
else
  # No xcodebuild; still try xcrun
  if command -v xcrun >/dev/null 2>&1; then
    SDK_PATH=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)
    if [[ -n "$SDK_PATH" ]]; then
      xcrun --sdk macosx swiftc -O -g -sdk "$SDK_PATH" "$SRC" -o "$BIN" -framework Security -framework LocalAuthentication
    else
      swiftc -O -g "$SRC" -o "$BIN" -framework Security -framework LocalAuthentication
    fi
  else
    swiftc -O -g "$SRC" -o "$BIN" -framework Security -framework LocalAuthentication
  fi
fi

chmod +x "$BIN"

echo "Built: $BIN"
