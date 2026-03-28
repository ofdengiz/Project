[CmdletBinding()]
param(
    [switch]$SelfTest
)

$toolkitRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$modules = @(
    '02_Modules\Common.psm1',
    '02_Modules\Network.Tests.psm1',
    '02_Modules\Identity.Tests.psm1',
    '02_Modules\Storage.Tests.psm1',
    '02_Modules\Backup.Tests.psm1',
    '02_Modules\ValueAdd.Tests.psm1',
    '02_Modules\Access.Tests.psm1'
)

foreach ($module in $modules) {
    Import-Module (Join-Path $toolkitRoot $module) -Force -DisableNameChecking
}

Initialize-TestToolkit -RootPath $toolkitRoot | Out-Null

function Invoke-CoreTestSequence {
    Invoke-Network-CoreEndpointTests
    Invoke-Identity-C1Tests
    Invoke-Identity-C2Tests
    Invoke-Storage-Server2Tests
    Invoke-Storage-C1InitiatorTests
    Invoke-Storage-C2Tests
    Invoke-Backup-Server2Tests
    Invoke-ValueAdd-GrafanaTests
    Invoke-ValueAdd-CockpitTests
    Invoke-ValueAdd-WacTests
    Invoke-Access-VpnTests
    Invoke-Access-AdminPathTests
    Invoke-Access-SegmentationTests
}

if ($SelfTest) {
    Test-ToolkitIntegrity
    return
}

do {
    Show-ToolkitHeader -Title 'Main Menu'
    Write-Host '1. Network and Addressing'
    Write-Host '2. Identity, DNS, and DHCP'
    Write-Host '3. Storage and SAN'
    Write-Host '4. Backup and Recovery'
    Write-Host '5. Value Added Features'
    Write-Host '6. VPN and Administrative Access'
    Write-Host '7. Manual GUI Checklists'
    Write-Host '8. Run All Core Tests'
    Write-Host '9. Export Summary Report'
    Write-Host '0. Exit'
    Write-Host ''

    switch (Read-Host 'Select an option') {
        '1' { Show-NetworkMenu }
        '2' { Show-IdentityMenu }
        '3' { Show-StorageMenu }
        '4' { Show-BackupMenu }
        '5' { Show-ValueAddMenu }
        '6' { Show-AccessMenu }
        '7' { Show-ChecklistIndex; Pause-Toolkit }
        '8' { Invoke-ToolkitBatch -Label 'Core test sequence' -ScriptBlock { Invoke-CoreTestSequence }; Pause-Toolkit }
        '9' { Export-ToolkitSummary | Out-Null; Pause-Toolkit }
        '0' { break }
        default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($true)
