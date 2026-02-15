#!/bin/bash
# 确保在脚本所在目录执行
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
    echo "Error: Virtual environment not found. Please run ./install.sh first."
    exit 1
fi

source .venv/bin/activate

.venv/bin/python blipboard_server.py