# SSHX-Manager (Multi-OS) — v6.0.0

SSHX.IO Multi-OS Management System — a robust, cross-platform management suite to install, run, monitor, and manage the `sshx` binary on Windows, Linux, macOS, and Android (Termux).

## Supported Platforms

| OS | Script | Privileges | Persistence |
|---|---|---|---|
| **Windows** | `sshx-manager.ps1` | Administrator (Self-elevating) | Scheduled Task |
| **Linux** | `linux/sshx-manager.sh` | Root (Sudo required) | Manual/Scripts |
| **macOS** | `macos/sshx-manager.zsh` | Sudo required | Manual/Scripts |
| **Android** | `android/sshx-manager-termux.sh` | User-space (Termux) | Manual |

## Overview

This project provides safe, robust management scripts that simplify the deployment and operation of the [sshx.io](https://sshx.io/) binary across different endpoints. It preserves a consistent "Management System" UX with clean ASCII headers, status tracking, and interactive menus.

## Installation & Usage

### 🚀 Universal Entry Point (Recommended)
You can use the universal entry point to automatically detect your OS and launch the correct manager:

**Unix-like (Linux, macOS, Android/Termux):**
```bash
chmod +x manage.sh
./manage.sh
```

**Windows (PowerShell):**
```powershell
.\manage.ps1
```

---

### Platform-Specific Execution

### 🪟 Windows
Run the PowerShell script directly. It will automatically request required Administrator privileges and apply the necessary execution policy:
```powershell
.\sshx-manager.ps1
```

### 🐧 Linux
Requires `bash`, `curl`, and `sudo`:
```bash
sudo bash linux/sshx-manager.sh
```

### 🍎 macOS
Requires `zsh` and `sudo`:
```zsh
sudo zsh macos/sshx-manager.zsh
```

### 🤖 Android (Termux)
No root required. Run within the Termux environment:
```bash
bash android/sshx-manager-termux.sh
```

## Key Features

- **Platform Consistent UI**: Clean ASCII-based boxed headers and standard status indicators ([OK], [X], [!]) across all platforms.
- **Interactive Management**: TUI-style menus for common operations: Install, Status, Start, Stop, and Uninstall.
- **State Tracking**: Persistent tracking of installation status and captured URLs.
- **Security First**: 
  - Transparent logic with no hidden background processes (except where explicitly configured like Windows Scheduled Tasks).
  - Explicit consent model for sensitive operations (like Windows Defender exclusions).
  - Web-install friendly with clear warnings and easy-to-read code.

## Security Notes

- Running scripts fetched from the web is inherently risky. Always verify script contents before executing.
- **Windows Only**: Managing Defender exclusions and real-time monitoring is done only with explicit user consent.
- **Downloads**: All scripts fetch the official binary from `https://sshx.io/install.sh` or official release URLs over HTTPS.

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Special Thanks

- **Ethan Zhang (@ekzhang)** for creating and maintaining [SSHX](https://sshx.io/).
- All contributors who help test and secure the project.