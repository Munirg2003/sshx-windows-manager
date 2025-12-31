# ===============================
# File: sshx-functions.Tests.ps1
# Purpose: Unit tests for SSHX functions
# ===============================

# Import module under test
Import-Module "$PSScriptRoot\..\sshx-functions.psm1" -Force

Describe "SSHX Core Function Tests" {

    Context "Admin detection" {
        It "Test-Admin returns a boolean" {
            $result = Test-Admin
            $result | Should -BeOfType [bool]
        }
    }

    Context "OS Information" {
        It "Get-OSInfo returns OS properties" {
            $os = Get-OSInfo
            $os | Should -Not -BeNullOrEmpty
        }
    }

    Context "Hash verification logic" {
        It "Verify-FileHash throws on mismatch" {
            $tempFile = New-TemporaryFile
            Set-Content $tempFile "test"

            { Verify-FileHash -FilePath $tempFile -ExpectedHash "BADHASH" } |
                Should -Throw
        }
    }

    Context "Install path logic" {
        It "InstallDir variable is defined" {
            $Global:InstallDir | Should -Not -BeNullOrEmpty
        }
    }
}
