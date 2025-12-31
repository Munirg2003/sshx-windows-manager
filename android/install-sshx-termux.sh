#!/data/data/com.termux/files/usr/bin/bash
# File: install-sshx-termux.sh
# Purpose: Android (Termux) SSHX installer
# Scope: User-space only (no root required)

set -euo pipefail

echo "[INFO] SSHX installer for Android (Termux)"
echo "[INFO] Running in user-space (non-root)"

# Update Termux packages
pkg update -y
pkg upgrade -y

# Install required tools
pkg install -y curl openssh

# Working directory
WORKDIR="$HOME/sshx"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[INFO] Downloading SSHX installer"
curl -fsSL https://sshx.io/install.sh -o install.sh

chmod +x install.sh
./install.sh

echo "[SUCCESS] SSHX installed in Termux environment"
echo "[INFO] Run SSHX manually from Termux when needed"
