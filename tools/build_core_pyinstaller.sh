#!/usr/bin/env bash
set -euo pipefail

# Build standalone Linux executables for core Python scripts using PyInstaller.
# Run this from the repository root (script will cd into core/).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT/core"

echo "== Building core executables with PyInstaller =="

# Activate virtualenv if present
if [ -d ".venv" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

pip install --upgrade pip
pip install pyinstaller

# Build one-file executables
pyinstaller --onefile --name blipboard_server blipboard_server.py
pyinstaller --onefile --name blipboard_client blipboard_client.py

# Copy built binaries to core/ top-level so packaging can pick them up
if [ -d "dist" ]; then
  cp -f dist/blipboard_server ./ || true
  cp -f dist/blipboard_client ./ || true
  chmod +x blipboard_server blipboard_client || true
  echo "Built binaries copied to core/"
else
  echo "PyInstaller did not produce a dist/ directory — check build logs" >&2
  exit 2
fi

echo "Done."
