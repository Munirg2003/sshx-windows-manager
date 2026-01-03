# SSHX-Manager (Windows) — v6.0 (Improved)

SSHX.IO Windows Management System v6.0 — an improved PowerShell manager to install, run, monitor, and optionally auto-start the `sshx` binary on Windows while preserving the original UX, icons and visual design.

This README is intentionally comprehensive and written for public distribution. It does not include embedded scripts or executable code blocks; instead it documents features, behavior, security guidance, release and repository best practices, and a pre-publication checklist so the project is ready for GitHub publication.

Special thanks
- Heartfelt thanks to the original SSHX developer and community. In particular, thank you to Ethan Zhang (@ekzhang) for creating and maintaining SSHX. See the official project pages:
  - SSHX homepage: https://sshx.io/
  - upstream repository: https://github.com/ekzhang/sshx
- Acknowledge all contributors and maintainers who help test, triage, and secure the project.

Overview
- Purpose: Provide a safe, robust Windows PowerShell management script that installs, manages, and auto-starts the cross-platform SSHX binary on Windows endpoints.
- Goals preserved: maintain a clean, TUI-style interactive interface (box headers, status indicators) while maximizing compatibility and robustness across all Windows PowerShell versions.
- Target audience: system administrators, operators, and power users tasked with deploying `sshx` on Windows endpoints.

Key features (what this project provides)
- One-line web-install friendly entrypoint while clearly warning about remote execution risks.
- Interactive TUI-style menu for common operations: Install, Start, Stop, configure auto-start, inspect AV status, toggle AV consent.
- Full install pipeline: download ZIP archive, optional checksum verification, extract, copy sshx.exe to Program Files, unblock, launch, and capture stdout/stderr to log files.
- State persistence via JSON (installation path, running state, PIDs, last download metadata, scheduled task status).
- Optional Antivirus handling with explicit consent: detect common AV processes, add/remove Microsoft Defender exclusions, temporarily disable/restore Defender realtime monitoring (only with consent).
- Scheduled Task management: create/remove a per-user logon task with an option to avoid elevated RunLevel by default.
- Dry-run mode to preview actions without effect.
- Centralized timestamped, colorized logging and a manager log file under ProgramData to preserve the present UI design and messages.
- Idempotent operations and robust error handling with cleanup on failure.

Important links and upstream references
- Official SSHX website: https://sshx.io/
- SSHX upstream repo (binaries, docs, issue tracking): https://github.com/ekzhang/sshx
- Include upstream acknowledgements in your release notes and LICENSE as required by the upstream license.

Security notes (read this first)
- Running scripts fetched from the web (e.g., using `irm | iex`) is inherently risky. Only run one-line installers from trusted sources.
- Stopping antivirus, disabling Defender realtime monitoring, and adding exclusions substantially reduce endpoint protection. The script will only perform such actions with explicit consent (interactive or a force flag). These changes are reversible in the script, but they expose the machine while performed.
- The download process uses HTTPS. For integrity the manager supports SHA256 checksum verification. For production usage, always publish and verify the checksum (or ideally a signature) in the GitHub Release.
- Consider signing the PowerShell script and releasing signed binaries. Encourage users to verify signatures before running any installer.

Installation options (high-level)
- Local execution: Run the PowerShell script directly from a terminal. The script will automatically request required Administrator privileges and apply the necessary execution policy: `.\sshx-manager.ps1`
- Remote one-line install: Execute directly from the web with automatic elevation: `powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/sshx-manager.ps1)"`
- CI/packaging: package the manager into a signed release and attach the sshx archive as a release asset.

Runtime behavior and design decisions preserved
- Visual/UI: A clean ASCII-based boxed header and standard status indicators ([OK], [X], [!]) are used to ensure 100% compatibility across all Windows environments.
- Logs and outputs: the script logs to ProgramData\SSHX-Manager and writes sshx stdout/stderr to files. Users can review logs to diagnose issues.
- Default install location: Program Files (x64) with Program Files fallback for 32-bit environments.

Antivirus handling details and guidance
- Detection: the script checks for typical AV process names (MsMpEng, NisSrv, ESET, Kaspersky, Avira). This is a best-effort approach — vendor processes and EDR solutions vary.
- Consent model: AV operations are performed only with explicit user consent or an explicit force flag for advanced users. When consent is granted:
  - The script will attempt to disable Defender realtime monitoring (via Set-MpPreference) and stop vendor processes where permitted.
  - The script will add exclusions for InstallDir, WorkingDir and sshx.exe (reversible).
  - On completion, the script attempts to restore Defender settings and remove temporary exclusions unless permanent exclusions were explicitly requested.
- Caveats: Some AV/EDR products will prevent programmatic stopping or exclusion manipulation. Always coordinate with security teams in corporate environments.

Scheduled Task behavior
- Task name: SSHX-AutoStart
- Trigger: user logon
- Principle: creates a per-user task; by default the script creates the task with an elevated runlevel only if requested — safer defaults are used.
- Idempotency: creating the task replaces existing task with the same name to avoid duplicates; removal is supported and verified.

State and logs
- State file: JSON stored in ProgramData\SSHX-Manager (includes IsInstalled, IsRunning, PIDs, InstallPath, Version, LastDownloadCheck, LastURL, ScheduledTaskStatus).
- Logs: manager log (timestamped entries) and sshx stdout/stderr logs for troubleshooting.
- The script will not print or alter the visual elements used for design and branding.

Release & distribution best practices (recommended)
- Do not include the large sshx binary in the main source tree. Instead:
  - Attach the binary to GitHub Releases as an asset.
  - Publish a SHA256 checksum (and preferably a detached signature) in the release notes and the repo's release manifest.
- Add the following files to the repository before public publishing:
  - LICENSE (choose an appropriate license, e.g., MIT or Apache-2.0)
  - CODE_OF_CONDUCT.md (Contributor Covenant)
  - CONTRIBUTING.md (PR and issue process, test guidelines)
  - SECURITY.md (security contact and disclosure process)
  - .github/ISSUE_TEMPLATE/ and .github/PULL_REQUEST_TEMPLATE.md
  - .github/workflows/ci.yml to run static checks (PSScriptAnalyzer) and optional smoke tests
  - CHANGELOG.md with release notes and acknowledgements
- Use GitHub Releases to attach the sshx ZIP and provide checksum and signature info.
- Add branch protection rules and require at least one approving review for changes to main.

Pre-publication checklist (recommended)
- Verify the whole script runs end-to-end in a clean Windows VM with Defender enabled to validate consent and restoration flows.
- Publish the sshx binary to GitHub Release and compute SHA256 locally; embed the hash in release notes.
- Consider GPG signing of the release artifacts (detached signature). Publish the public signing key on your profile and in release notes.
- Run PSScriptAnalyzer with strict rules and fix findings flagged as errors.
- Add Pester tests that perform unit tests of idempotent logic (mock download & AV operations) in CI.
- Add smoke tests to ensure Start/Stop, Scheduled Task creation, and state persistence functions work in a controlled environment.
- Add a documented rollback plan (how to remove scheduled task, stop process, remove exclusions) in the README.
- Provide clear support and issue reporting guidance in SECURITY.md and CONTRIBUTING.md.
- Make sure all image assets (logo, screenshots) are present under docs/ and referenced in README without breaking the design.

Suggested improvements and possible feature additions (without changing UX)
- Add digital signature verification (e.g., GPG or Authenticode) for download artifacts so users can verify authenticity, not just integrity.
- Option to register sshx as a Windows service (for environments that prefer service management over scheduled tasks).
- Modularize the code into a PowerShell module (psm1) with exported functions to enable unit-testing and re-use from other scripts or automation tooling.
- Add a silent mode suitable for automated deployments (CI/CD) with explicit flags for AV consent and checksum, and clear logging.
- Implement log rotation and retention policies for stdout/stderr and manager logs.
- Add telemetry opt-in (anonymous usage metrics) with explicit consent, or a debugging mode that optionally uploads logs to a secure endpoint when troubleshooting is requested.
- Provide wrappers or packaging for Windows package managers: Chocolatey, WinGet, and a Docker container for Linux/macOS packaging.
- Publish example policies and guidance for enterprise deployment (Intune, SCCM) to help sysadmins deploy at scale safely.
- Provide a signed release of the PowerShell script (Authenticode) and verify signature on install.

Repository-level CI and policy suggestions
- Add GitHub Actions workflow to run PSScriptAnalyzer on all pushes and PRs.
- Add a workflow to run Pester tests in a Windows runner for PR validation.
- Add an automated release workflow to create a GitHub Release on tag creation, upload artifacts, and add checksums.
- Add Dependabot to keep dependencies and action versions up-to-date.
- Add secret scanning and code scanning (GitHub Advanced Security or CodeQL) to help detect accidental leaks and high-risk patterns.

Documentation improvements (what I will do or can help with)
- Expand the README into a docs site (e.g., GitHub Pages) that includes:
  - Installation guides for interactive and unattended installs (no inline scripts printed here, but step-by-step instructions).
  - Full security and AV handling guide with administrator notes for corporate environments.
  - Troubleshooting guide with annotated screenshots of Task Scheduler, Process Explorer, and Defender settings.
  - Example policies for Intune/Group Policy to allow exclusion management for admins (high-level).
  - Developer guide describing the code layout, how to run static analysis, and how to run the Pester tests.
- Produce supplementary repository files: CI workflow, ISSUE/PR templates, SECURITY.md, CONTRIBUTING.md, and a sample release template.
- Draft a formal acknowledgements and credits section and include upstream licensing and developer attribution.

Questions and suggestions for you before publication
- License: which license do you want for this repository? (Common choices: MIT, Apache-2.0, GPL-3.0). If upstream artifacts impose constraints, we should ensure compatibility.
- Binary handling: do you want the sshx zip tracked in the repository, or only attached to Releases (recommended)? If tracked, we should use Git LFS; if not tracked, we must add it to .gitignore and store it in Release assets.
- Signing: do you have a PGP/GPG or Authenticode signing key for releases and/or the PowerShell script? If yes, I can include signing instructions in the release automation.
- CI policy: which checks should be enforced automatically on every PR? (PSScriptAnalyzer only, or Pester tests + CodeQL + release automation?)
- Support and maintenance: who will be listed as maintainers for issues and PR triage? Do you want to add a CODEOWNERS file to help automate review assignment?
- Screenshots & branding: do you have a logo or screenshots to include under docs/logo.png for README beautification?
- Contribution model: do you prefer a "maintainer approves PRs" policy or an open-driven community model with multiple reviewers?
- Release cadence: will releases follow semantic versioning with tags pushed manually, or do you prefer automated packaging and release on merge to main?

Publishing & follow-up actions I can take for you
- Generate the final README (this file is a starting point) and expand into a docs site with pages for each detailed topic.
- Create recommended repository files: LICENSE, CODE_OF_CONDUCT.md, CONTRIBUTING.md, SECURITY.md, ISSUE_TEMPLATEs, PULL_REQUEST_TEMPLATE.md, and .github/workflows/ci.yml.
- Create GitHub Actions workflows for PSScriptAnalyzer and Pester tests, plus an optional release automation workflow that uploads artifacts and adds a checksum automatically on tag creation.
- Draft release notes and an example release with a template that includes SHA256 and signature instructions.

Next step (suggestion)
- Tell me your preferences for: license, binary handling (Release-only vs in-repo), and CI policies. I’ll:
  - produce the repository meta files and CI workflows ready to commit,
  - prepare release notes template including SHA256 and signature instructions,
  - prepare docs pages for publication (GitHub Pages) if you want a docs site.

I’m optimistic this project will be a helpful, safe, and well-documented way for admins to use SSHX on Windows. Tell me your choices for license, binary policy, and CI (or say “surprise me” to accept my recommended defaults: MIT license, binary only as Release asset, PSScriptAnalyzer + Pester CI). I’ll then generate the repo files and workflows for you to review.