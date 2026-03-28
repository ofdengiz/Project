[CmdletBinding()]
param(
    [switch]$SelfTest,
    [ValidateSet('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'M', 'E')]
    [string]$MainOption,
    [switch]$SkipPause
)

$toolkitRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$modules = @(
    '02_Modules\Common.psm1',
    '02_Modules\ServiceBlocks.Tests.psm1',
    '02_Modules\Group6.Tests.psm1'
)

foreach ($module in $modules) {
    Import-Module (Join-Path $toolkitRoot $module) -Force -DisableNameChecking
}

Initialize-TestToolkit -RootPath $toolkitRoot | Out-Null

function Invoke-MainSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Selection,
        [switch]$SkipPause
    )

    switch ($Selection.ToUpperInvariant()) {
        '1' {
            Invoke-ToolkitBatch -Label 'Hotseat 1 - Company 1 + MSP integrated self-test' -ScriptBlock { Invoke-Group6Hotseat1Tests }
        }
        '2' {
            Invoke-ToolkitBatch -Label 'Hotseat 2 - Company 2 + MSP integrated self-test' -ScriptBlock { Invoke-Group6Hotseat2Tests }
        }
        '3' {
            Invoke-ToolkitBatch -Label 'Service Block 1 - Remote Access / DHCP / Account Administration (both sites)' -ScriptBlock { Invoke-Group6ServiceBlock1 }
        }
        '4' {
            Invoke-ToolkitBatch -Label 'Service Block 2 - DNS / HTTPS (both sites)' -ScriptBlock { Invoke-Group6ServiceBlock2 }
        }
        '5' {
            Invoke-ToolkitBatch -Label 'Service Block 3 - Hypervisor / vRouter / Inter-site Policy' -ScriptBlock { Invoke-Group6ServiceBlock3 }
        }
        '6' {
            Invoke-ToolkitBatch -Label 'Service Block 4 - File Services / ISCSI (both sites)' -ScriptBlock { Invoke-Group6ServiceBlock4 }
        }
        '7' {
            Invoke-ToolkitBatch -Label 'Service Block 5 - Backup / Misc (both sites)' -ScriptBlock { Invoke-Group6ServiceBlock5 }
        }
        '8' {
            Invoke-ToolkitBatch -Label 'All Group 6 automated tests' -ScriptBlock { Invoke-Group6AllTests }
        }
        '9' {
            Show-Group6Coverage
            if (-not $SkipPause) { Pause-Toolkit }
        }
        'M' {
            Show-Group6ManualGuide
            if (-not $SkipPause) { Pause-Toolkit }
        }
        'E' {
            Export-ToolkitSummary | Out-Null
        }
        '0' { return }
        default {
            Write-Host 'Invalid selection.' -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

if ($SelfTest) {
    Test-ToolkitIntegrity
    Test-ServiceBlockCoverage
    Test-Group6Coverage
    return
}

if ($PSBoundParameters.ContainsKey('MainOption')) {
    Invoke-MainSelection -Selection $MainOption -SkipPause:$SkipPause
    return
}

do {
    Show-ToolkitHeader -Title 'Main Menu'
    Write-Host '1. Hotseat 1 - Company 1 + MSP integrated self-test'
    Write-Host '2. Hotseat 2 - Company 2 + MSP integrated self-test'
    Write-Host '3. Service Block 1 - Remote Access / DHCP / Account Administration (both sites)'
    Write-Host '4. Service Block 2 - DNS / HTTPS (both sites)'
    Write-Host '5. Service Block 3 - Hypervisor / vRouter / Inter-site Policy'
    Write-Host '6. Service Block 4 - File Services / ISCSI (both sites)'
    Write-Host '7. Service Block 5 - Backup / Misc (both sites)'
    Write-Host '8. Run all automated Group 6 tests'
    Write-Host '9. Show Group 6 coverage review'
    Write-Host 'M. Show manual follow-up guide'
    Write-Host 'E. Export summary report'
    Write-Host '0. Exit'
    Write-Host ''

    switch ((Read-Host 'Select an option').ToUpperInvariant()) {
        '1' { Invoke-MainSelection -Selection '1' }
        '2' { Invoke-MainSelection -Selection '2' }
        '3' { Invoke-MainSelection -Selection '3' }
        '4' { Invoke-MainSelection -Selection '4' }
        '5' { Invoke-MainSelection -Selection '5' }
        '6' { Invoke-MainSelection -Selection '6' }
        '7' { Invoke-MainSelection -Selection '7' }
        '8' { Invoke-MainSelection -Selection '8' }
        '9' { Invoke-MainSelection -Selection '9' }
        'M' { Invoke-MainSelection -Selection 'M' }
        'E' { Invoke-MainSelection -Selection 'E' }
        '0' { break }
        default {
            Write-Host 'Invalid selection.' -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
