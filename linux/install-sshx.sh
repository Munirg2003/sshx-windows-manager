#!/usr/bin/env bash
# File: install-sshx.sh
# Purpose: Linux SSHX installer (educational)

set -euo pipefail

echo "[INFO] Starting SSHX install for Linux"

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Please run as root (sudo)"
  exit 1
fi

WORKDIR="/opt/sshx"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[INFO] Downloading SSHX installer"
curl -fsSL https://sshx.io/install.sh -o install.sh

chmod +x install.sh
./install.sh

echo "[INFO] SSHX installation completed"

