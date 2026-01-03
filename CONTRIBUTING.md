# Contributing to SSHX-Manager

First off, thank you for considering contributing to SSHX-Manager! It's people like you who make it such a great tool.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

* **Check the existing issues** to see if the bug has already been reported.
* If you can't find an open issue that describes the problem, **open a new one**. Include a clear title, a description of the bug, and as much relevant information as possible, such as your Windows version and PowerShell version.

### Suggesting Enhancements

* **Open a new issue** with the "enhancement" label.
* Describe the suggested enhancement in detail and explain why it would be useful.

### Pull Requests

1. **Fork the repository** and create your branch from `main`.
2. **If you've added code** that should be tested, add tests.
3. **If you've changed APIs**, update the documentation.
4. **Ensure the test suite passes** (run PSScriptAnalyzer).
5. **Make sure your code lints** (use `Invoke-ScriptAnalyzer`).
6. **Open a Pull Request** with a clear description of the changes.

## Style Guide

* Use PascalCase for function names (Verb-Noun).
* Use camelCase for local variable names.
* Include comments for complex logic.
* Ensure 100% ASCII compatibility for UI elements to maintain PowerShell 5.1 compatibility.

## Testing

Run the following command to verify your changes:
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
```

Thank you!
