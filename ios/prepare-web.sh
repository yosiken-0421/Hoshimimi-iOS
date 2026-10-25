#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$SCRIPT_DIR/../dist/index.html" ]; then
  echo 'dist/index.html がありません。ゲーム本体を先に生成してください。' >&2
  exit 1
fi
mkdir -p "$SCRIPT_DIR/Hoshimimi/Web"
cp -R "$SCRIPT_DIR/../dist/." "$SCRIPT_DIR/Hoshimimi/Web/"
