# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [6.0.0] - 2026-01-03

### Added
- Native self-elevation logic: Script automatically requests Administrator privileges if run without them.
- Automatic Execution Policy bypass for local execution.
- Robust path resolution using `$env:ProgramFiles` for better compatibility.

### Changed
- **BREAKING**: Replaced all emojis and special UI characters with ASCII equivalents (`[OK]`, `(!)`, etc.) to ensure 100% compatibility with Windows PowerShell 5.1 and older terminal environments.
- Renamed internal functions to strictly follow PowerShell Verb-Noun naming conventions (e.g., `Toggle-SSHXService` -> `Invoke-SSHXToggle`).
- Streamlined the interactive menu for faster operation and cleaner visual style.

### Fixed
- Fixed a `MethodException` related to `ProgramFilesX64` call in PowerShell 5.1.
- Resolved multiple PSScriptAnalyzer warnings for unused variables and unapproved verbs.
- Fixed a "flash and disappear" issue caused by parsing errors in legacy PowerShell versions.

## [5.9.0] - 2025-12-25
- Initial version of the multi-OS manager for Windows.
