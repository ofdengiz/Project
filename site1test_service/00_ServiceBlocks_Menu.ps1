[CmdletBinding()]
param(
    [switch]$SelfTest,
    [ValidateSet('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')]
    [string]$MainOption,
    [string]$SubOption,
    [switch]$SkipPause
)

$toolkitRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$modules = @(
    '02_Modules\Common.psm1',
    '02_Modules\ServiceBlocks.Tests.psm1'
)

foreach ($module in $modules) {
    Import-Module (Join-Path $toolkitRoot $module) -Force -DisableNameChecking
}

Initialize-TestToolkit -RootPath $toolkitRoot | Out-Null

function Invoke-AllServiceBlockTests {
    Invoke-ServiceBlock1
    Invoke-ServiceBlock2
    Invoke-ServiceBlock3
    Invoke-ServiceBlock4
    Invoke-ServiceBlock5
}

function Invoke-ServiceBlockSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BlockNumber,
        [string]$SubSelection,
        [switch]$SkipPause
    )

    $handlers = @{
        '1' = @{
            Title = 'Service Block 1 - Remote Access / DHCP / Account Administration'
            Hotseat1Label = 'Hotseat 1 - Company 1 & MSP'
            Hotseat2Label = 'Hotseat 2 - Company 2 & MSP'
            Hotseat1 = { Invoke-SB1-Hotseat1Tests }
            Hotseat2 = { Invoke-SB1-Hotseat2Tests }
            All      = { Invoke-ServiceBlock1 }
        }
        '2' = @{
            Title = 'Service Block 2 - DNS / HTTPS'
            Hotseat1Label = 'Hotseat 1 - Company 1 & MSP'
            Hotseat2Label = 'Hotseat 2 - Company 2 & MSP'
            Hotseat1 = { Invoke-SB2-Hotseat1Tests }
            Hotseat2 = { Invoke-SB2-Hotseat2Tests }
            All      = { Invoke-ServiceBlock2 }
        }
        '3' = @{
            Title = 'Service Block 3 - Site 1 Hypervisor / vRouter'
            Hotseat1Label = 'Hotseat 1 - MSP Site 1'
            Hotseat2Label = 'Hotseat 2 - MSP Site 2'
            Hotseat1 = { Invoke-SB3-Hotseat1Tests }
            Hotseat2 = { Invoke-SB3-Hotseat2Tests }
            All      = { Invoke-ServiceBlock3 }
        }
        '4' = @{
            Title = 'Service Block 4 - Replicated File Server / ISCSI'
            Hotseat1Label = 'Hotseat 1 - Company 1'
            Hotseat2Label = 'Hotseat 2 - Company 2'
            Hotseat1 = { Invoke-SB4-Hotseat1Tests }
            Hotseat2 = { Invoke-SB4-Hotseat2Tests }
            All      = { Invoke-ServiceBlock4 }
        }
        '5' = @{
            Title = 'Service Block 5 - VEEAM / Misc'
            Hotseat1Label = 'Hotseat 1 - MSP'
            Hotseat2Label = 'Hotseat 2 - Site 1 Physical Inspection'
            Hotseat1 = { Invoke-SB5-Hotseat1Tests }
            Hotseat2 = { Invoke-SB5-Hotseat2Tests }
            All      = { Invoke-ServiceBlock5 }
            Guide    = { Show-ServiceBlock5PhysicalInspectionGuide }
        }
    }

    $handler = $handlers[$BlockNumber]
    $singleSelection = $PSBoundParameters.ContainsKey('SubSelection')

    do {
        Show-ToolkitHeader -Title $handler.Title
        Write-Host "1. Run $($handler.Hotseat1Label) tests"
        Write-Host "2. Run $($handler.Hotseat2Label) tests"
        Write-Host '3. Run full Service Block'
        if ($BlockNumber -eq '5') {
            Write-Host '4. Show physical inspection guide'
        }
        Write-Host '0. Return to main menu'
        Write-Host ''

        $selection = if ($singleSelection) {
            $value = $SubSelection
            $SubSelection = $null
            $value
        }
        else {
            Read-Host 'Select an option'
        }

        switch ($selection) {
            '1' {
                Invoke-ToolkitBatch -Label $handler.Hotseat1Label -ScriptBlock $handler.Hotseat1
                if (-not $SkipPause) { Pause-Toolkit }
            }
            '2' {
                Invoke-ToolkitBatch -Label $handler.Hotseat2Label -ScriptBlock $handler.Hotseat2
                if (-not $SkipPause) { Pause-Toolkit }
            }
            '3' {
                Invoke-ToolkitBatch -Label $handler.Title -ScriptBlock $handler.All
                if (-not $SkipPause) { Pause-Toolkit }
            }
            '4' {
                if ($BlockNumber -eq '5') {
                    & $handler.Guide
                    if (-not $SkipPause) { Pause-Toolkit }
                }
                else {
                    Write-Host 'Invalid selection.' -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            '0' { return }
            default {
                Write-Host 'Invalid selection.' -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        if ($singleSelection) {
            return
        }
    } while ($true)
}

function Invoke-MainSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Selection,
        [string]$SubSelection,
        [switch]$SkipPause
    )

    switch ($Selection) {
        '1' {
            if ($PSBoundParameters.ContainsKey('SubSelection')) {
                Invoke-ServiceBlockSelection -BlockNumber '1' -SubSelection $SubSelection -SkipPause:$SkipPause
            }
            else {
                Invoke-ServiceBlockSelection -BlockNumber '1' -SkipPause:$SkipPause
            }
        }
        '2' {
            if ($PSBoundParameters.ContainsKey('SubSelection')) {
                Invoke-ServiceBlockSelection -BlockNumber '2' -SubSelection $SubSelection -SkipPause:$SkipPause
            }
            else {
                Invoke-ServiceBlockSelection -BlockNumber '2' -SkipPause:$SkipPause
            }
        }
        '3' {
            if ($PSBoundParameters.ContainsKey('SubSelection')) {
                Invoke-ServiceBlockSelection -BlockNumber '3' -SubSelection $SubSelection -SkipPause:$SkipPause
            }
            else {
                Invoke-ServiceBlockSelection -BlockNumber '3' -SkipPause:$SkipPause
            }
        }
        '4' {
            if ($PSBoundParameters.ContainsKey('SubSelection')) {
                Invoke-ServiceBlockSelection -BlockNumber '4' -SubSelection $SubSelection -SkipPause:$SkipPause
            }
            else {
                Invoke-ServiceBlockSelection -BlockNumber '4' -SkipPause:$SkipPause
            }
        }
        '5' {
            if ($PSBoundParameters.ContainsKey('SubSelection')) {
                Invoke-ServiceBlockSelection -BlockNumber '5' -SubSelection $SubSelection -SkipPause:$SkipPause
            }
            else {
                Invoke-ServiceBlockSelection -BlockNumber '5' -SkipPause:$SkipPause
            }
        }
        '6' {
            Invoke-ToolkitBatch -Label 'All Service Blocks - automated sequence' -ScriptBlock { Invoke-AllServiceBlockTests }
            if (-not $SkipPause) { Pause-Toolkit }
        }
        '7' {
            Show-ServiceBlockCoverage
            if (-not $SkipPause) { Pause-Toolkit }
        }
        '8' {
            Show-ServiceBlock5PhysicalInspectionGuide
            if (-not $SkipPause) { Pause-Toolkit }
        }
        '9' {
            Export-ToolkitSummary | Out-Null
            if (-not $SkipPause) { Pause-Toolkit }
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
    return
}

if ($PSBoundParameters.ContainsKey('MainOption')) {
    if ($PSBoundParameters.ContainsKey('SubOption')) {
        Invoke-MainSelection -Selection $MainOption -SubSelection $SubOption -SkipPause:$SkipPause
    }
    else {
        Invoke-MainSelection -Selection $MainOption -SkipPause:$SkipPause
    }
    return
}

do {
    Show-ToolkitHeader -Title 'Main Menu'
    Write-Host '1. Service Block 1 - Remote Access / DHCP / Account Administration'
    Write-Host '2. Service Block 2 - DNS / HTTPS'
    Write-Host '3. Service Block 3 - Site 1 Hypervisor / vRouter'
    Write-Host '4. Service Block 4 - Replicated File Server / ISCSI'
    Write-Host '5. Service Block 5 - VEEAM / Misc'
    Write-Host '6. Run all automated Service Block tests'
    Write-Host '7. Show Service Block coverage review'
    Write-Host '8. Show Service Block 5 physical inspection guide'
    Write-Host '9. Export summary report'
    Write-Host '0. Exit'
    Write-Host ''

    switch (Read-Host 'Select an option') {
        '1' { Invoke-MainSelection -Selection '1' }
        '2' { Invoke-MainSelection -Selection '2' }
        '3' { Invoke-MainSelection -Selection '3' }
        '4' { Invoke-MainSelection -Selection '4' }
        '5' { Invoke-MainSelection -Selection '5' }
        '6' { Invoke-MainSelection -Selection '6' }
        '7' { Invoke-MainSelection -Selection '7' }
        '8' { Invoke-MainSelection -Selection '8' }
        '9' { Invoke-MainSelection -Selection '9' }
        '0' { break }
        default {
            Write-Host 'Invalid selection.' -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
