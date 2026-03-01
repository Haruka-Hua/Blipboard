#!/bin/bash
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
    echo "Error: Virtual environment not found. Please run ./install.sh first."
    exit 1
fi

source .venv/bin/activate
echo "Starting client (requires sudo for keyboard listening)..."
sudo .venv/bin/python blipboard_client.py