#!/usr/bin/env bash
# File: manage.sh
# Purpose: Universal Platform-Independent Entry Point for SSHX-Manager
# This script detects the OS and delegates execution to the appropriate manager.

set -e

# Detect OS
OS_TYPE="Unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Check for Termux (Android)
    if [ -d "/data/data/com.termux" ]; then
        OS_TYPE="Android"
    else
        OS_TYPE="Linux"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS_TYPE="Windows"
else
    # Fallback to uname if OSTYPE is not set or unique
    UNAME_S="$(uname -s)"
    case "${UNAME_S}" in
        Linux*)
            if [ -d "/data/data/com.termux" ]; then
                OS_TYPE="Android"
            else
                OS_TYPE="Linux"
            fi
            ;;
        Darwin*)
            OS_TYPE="macOS"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS_TYPE="Windows"
            ;;
    esac
fi

echo "[INFO] Detected Platform: $OS_TYPE"

# Delegate Execution
case "$OS_TYPE" in
    "Windows")
        echo "[INFO] Launching PowerShell Manager..."
        # Check if running in a shell that can find powershell.exe
        if command -v powershell.exe >/dev/null 2>&1; then
            powershell.exe -ExecutionPolicy Bypass -File "sshx-manager.ps1"
        else
            echo "[ERROR] powershell.exe not found in PATH."
            exit 1
        fi
        ;;
    "Linux")
        echo "[INFO] Launching Linux Manager with sudo..."
        if [ -f "linux/sshx-manager.sh" ]; then
            sudo bash "linux/sshx-manager.sh"
        else
            echo "[ERROR] linux/sshx-manager.sh not found."
            exit 1
        fi
        ;;
    "macOS")
        echo "[INFO] Launching macOS Manager with sudo..."
        if [ -f "macos/sshx-manager.zsh" ]; then
            sudo zsh "macos/sshx-manager.zsh"
        else
            echo "[ERROR] macos/sshx-manager.zsh not found."
            exit 1
        fi
        ;;
    "Android")
        echo "[INFO] Launching Termux Manager..."
        if [ -f "android/sshx-manager-termux.sh" ]; then
            bash "android/sshx-manager-termux.sh"
        else
            echo "[ERROR] android/sshx-manager-termux.sh not found."
            exit 1
        fi
        ;;
    *)
        echo "[ERROR] Unsupported Platform: $OS_TYPE"
        echo "Please manually run the script in the respective OS folder."
        exit 1
        ;;
esac
