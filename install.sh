#!/usr/bin/env bash
# Link the launcher to this clone so code updates do not need a reinstall.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
SKIP_DEPS=0

for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    -h|--help)
      echo 'Usage: bash install.sh [target_bin_dir] [--skip-deps]'
      exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

if ! command -v bun >/dev/null 2>&1; then
  echo 'Install Bun first: https://bun.sh' >&2
  exit 1
fi
if [[ "$SKIP_DEPS" -eq 0 ]]; then
  (cd "$ROOT" && bun install --frozen-lockfile)
fi
mkdir -p "$TARGET_DIR"
chmod +x "$ROOT/youtube-to-markdown"
ln -sf "$ROOT/youtube-to-markdown" "$TARGET_DIR/youtube-to-markdown"
echo "Installed $TARGET_DIR/youtube-to-markdown -> $ROOT/youtube-to-markdown"
echo "Add $TARGET_DIR to PATH if needed, then run youtube-to-markdown."
