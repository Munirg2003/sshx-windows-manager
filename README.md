# 🛡️ SSHX-Manager (Multi-OS) — v6.0.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Security](https://img.shields.io/badge/Security-Audit%20Ready-brightgreen.svg)](#security-model)

**SSHX-Manager** is an advanced, high-performance management suite designed to simplify the lifecycle of the [sshx.io](https://sshx.io/) binary across complex, multi-platform environments. Whether you are on Windows, Linux, macOS, or Android (Termux), SSHX-Manager provides a unified, secure, and robust interface to deploy and manage your collaborative terminal sessions.

---

## ❤️ Special Thanks & Credits

This project would not be possible without the incredible work of **Ethan Zhang (@ekzhang)**, the original creator of **sshx.io**. 

> "sshx is a drop-in multi-user terminal sharing tool that just works."

We would like to express our deepest gratitude to Ethan for developing such a transformative tool for the developer community. This manager is designed to respect and enhance the original SSHX experience while providing platform-native management capabilities.

- **Official Website**: [sshx.io](https://sshx.io/)
- **Upstream Repository**: [ekzhang/sshx](https://github.com/ekzhang/sshx)

---

## ✨ Key Features

- **🚀 Universal Entrypoint**: Auto-detection logic that identifies your OS and launches the correct manager instantly.
- **🎨 Platform-Consistent UI**: A unified TUI (Terminal User Interface) with clean ASCII headers and status tracking across all shells.
- **🛡️ Secure by Design**: 
    - Full transparency with no hidden background processes.
    - Windows-native self-elevation and execution policy handling.
    - Explicit consent model for security-sensitive operations (e.g., Antivirus exclusions).
- **📋 State Persistence**: Intelligent tracking of installation paths, running PIDs, and captured session URLs.
- **⚙️ Lifecycle Management**: One-click install, background service emulation, and complete uninstallation.

---

## 🖥️ Supported Platforms

| OS | Management Tool | Privilege Model | Persistence Method |
|:---|:---|:---|:---|
| **Windows** | `sshx-manager.ps1` | Administrator (Auto-elevating) | Scheduled Task |
| **Linux** | `sshx-manager.sh` | Sudo / Root | Background Process |
| **macOS** | `sshx-manager.zsh` | Sudo | Background Process |
| **Android** | `sshx-manager-termux.sh` | User-space (Termux) | Manual Execution |

---

## 🚀 Getting Started

### 🌐 Direct Execution (One-Line)

Run the manager instantly from your terminal without cloning the repository:

| Platform | Production One-Line Command |
|:---|:---|
| **Windows** | `powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/windows/sshx-manager.ps1)"` |
| **Linux** | `curl -sSfL https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/linux/sshx-manager.sh \| sudo bash` |
| **macOS** | `curl -sSfL https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/macos/sshx-manager.zsh \| sudo zsh` |
| **Android** | `curl -sSfL https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/android/sshx-manager-termux.sh \| bash` |

### 📦 Local Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Munirg2003/SSHX-manager-MultiOS-v2.git
   cd SSHX-manager-MultiOS-v2
   ```

2. **Run the Universal Manager:**
   - **Windows**: `.\manage.ps1`
   - **Unix-like**: `chmod +x manage.sh && ./manage.sh`

---

## 🔧 Platform Deep Dives

### 🪟 Windows (The Gold Standard)
The Windows manager is built on modern PowerShell 5.1+ and offers the most comprehensive features:
- **Auto-Elevation**: Automatically requests Administrator rights.
- **Antivirus Handling**: Optionally adds/removes exclusions for Microsoft Defender with user consent.
- **Auto-Start**: Leverages Windows Task Scheduler for persistent access upon logon.
- **Path Resolution**: Correctly handles `Program Files` environments on both x64 and x86 systems.

### 🐧 Linux & 🍎 macOS
Native shell implementations (`bash` and `zsh`) provide:
- **Background Management**: Uses `nohup` and PID tracking to keep sessions alive.
- **Dependency Check**: Automatically verifies `curl`, `tar`, and `procps` availability.
- **System Integration**: Installs to `/usr/local/bin` for global access.

### 🤖 Android (Termux)
Optimized for the mobile environment:
- **Zero Root Required**: Operates entirely within the Termux user-space.
- **Automated Setup**: Installs `openssh` and `curl` automatically via `pkg`.

---

## 🛡️ Security Model

SSHX-Manager follows the principle of **Least Surprise**:
1. **Transparency**: Every script is human-readable and open-source.
2. **Minimal Footprint**: State files are stored in standard locations (`ProgramData` on Windows, `$HOME/.sshx` or `/var/lib` on Unix).
3. **No Hidden Telemetry**: We do not collect or report any data about your sessions.
4. **Official Sources**: Binaries are always pulled directly from the official `sshx.io` servers.

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 📞 Support & Feedback

If you enjoy using SSHX-Manager, please consider giving the repository a ⭐! It helps others find the project.

- **Issues**: [github.com/Munirg2003/SSHX-manager-MultiOS-v2/issues](https://github.com/Munirg2003/SSHX-manager-MultiOS-v2/issues)
- **Discussion**: Open a new thread in the GitHub Discussions tab.

---

*Disclaimer: This project is a community-maintained manager and is not officially affiliated with the sshx.io core team.*