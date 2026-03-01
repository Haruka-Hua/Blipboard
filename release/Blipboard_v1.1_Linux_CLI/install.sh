#!/bin/bash
set -e 

echo "Updating apt cache..."
sudo apt update

sudo apt install -y python3 python3-pip

# Install typical Linux dependencies for Bluetooth and clipboard
echo "Installing system dependencies (bluez, xclip)..."
sudo apt install -y bluez bluez-utils xclip

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

echo
echo "Notes:"
echo "- Ensure the built core executables in ./core have execute permission (chmod +x)."
echo "- To allow non-root access to Bluetooth sockets you may need to set capabilities on the binary," \
    "for example:"
echo "    sudo setcap 'cap_net_raw,cap_net_admin+eip' ./core/blipboard_server"
echo "  or run the server with sudo."
echo "- If clipboard operations fail, ensure xclip is installed (installed above)."