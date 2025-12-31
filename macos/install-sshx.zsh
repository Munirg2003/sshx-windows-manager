#!/bin/zsh
# File: install-sshx.zsh
# Purpose: macOS SSHX installer (educational)

set -euo pipefail

echo "[INFO] Starting SSHX install for macOS"

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Please run with sudo"
  exit 1
fi

WORKDIR="/usr/local/sshx"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[INFO] Downloading SSHX installer"
curl -fsSL https://sshx.io/install.sh -o install.sh

chmod +x install.sh
./install.sh

echo "[INFO] SSHX installation completed"

