#!/bin/bash
set -e 

echo "Updating apt cache..."
sudo apt update

sudo apt install -y python3 python3-pip

PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
VENV_PKG="python${PY_VER}-venv"

echo "Detected Python ${PY_VER}. Installing ${VENV_PKG}..."
if ! sudo apt install -y "$VENV_PKG"; then
    echo "Specific venv package not found, trying generic python3-venv..."
    sudo apt install -y python3-venv
fi

if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

echo "Installing requirements..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "✅ Setup complete!"