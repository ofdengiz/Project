function Invoke-Backup-Server2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'Server2 Veeam services and repository drives' -ComputerName (Get-ToolkitHost 'Server2').Address -Device 'Server2' -DocSection '3.8 / Appendix D' -SuccessPatterns @('RUNNING_VEEAM_SERVICES=', 'REPO_DRIVES=') -ScriptBlock {
        $runningCount = (Get-Service *Veeam* -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }).Count
        $repoDrives = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -in @('S', 'T', 'V') }).Name -join ','
        'RUNNING_VEEAM_SERVICES=' + $runningCount
        'REPO_DRIVES=' + $repoDrives
        Get-Service *Veeam* -ErrorAction SilentlyContinue | Format-Table -HideTableHeaders Name, Status
    }
}

function Invoke-Backup-ClientAgentTests {
    [CmdletBinding()]
    param()

    Write-Host '[MANUAL] C1-Client1 backup agent footprint' -ForegroundColor Yellow
    Write-Host 'Open: Client_Experience_Checklist.md'
    Write-Host 'Show:'
    Write-Host '- Veeam Agent installation in Programs and Features, Services, or the system tray'
    Write-Host '- The client remains domain joined and aligned with the Company 1 desktop experience'
    Write-Host ''
}

function Invoke-Backup-OffsiteConnectivityTests {
    [CmdletBinding()]
    param()

    $repo = Get-ToolkitHost 'Site2Repo'
    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 offsite repository control port' -Address $repo.Address -Port 6160 -Device $repo.DisplayName -DocSection '3.8.3 / 3.10.1'
}

function Show-BackupMenu {
    [CmdletBinding()]
    param()

    do {
        Show-ToolkitHeader -Title 'Backup and Recovery'
        Write-Host '1. Test Server2 Veeam services and repository drives'
        Write-Host '2. Show manual check for C1-Client1 backup agent'
        Write-Host '3. Test Site 2 offsite connectivity'
        Write-Host '4. Show manual checklist index'
        Write-Host '5. Run all backup tests'
        Write-Host '0. Return to main menu'
        Write-Host ''

        switch (Read-Host 'Select an option') {
            '1' { Invoke-ToolkitBatch -Label 'Backup - Server2 Veeam services' -ScriptBlock { Invoke-Backup-Server2Tests }; Pause-Toolkit }
            '2' { Invoke-ToolkitBatch -Label 'Backup - C1 client agent footprint' -ScriptBlock { Invoke-Backup-ClientAgentTests }; Pause-Toolkit }
            '3' { Invoke-ToolkitBatch -Label 'Backup - Site 2 offsite connectivity' -ScriptBlock { Invoke-Backup-OffsiteConnectivityTests }; Pause-Toolkit }
            '4' { Show-ChecklistIndex; Pause-Toolkit }
            '5' {
                Invoke-ToolkitBatch -Label 'Backup - all tests' -ScriptBlock {
                    Invoke-Backup-Server2Tests
                    Invoke-Backup-ClientAgentTests
                    Invoke-Backup-OffsiteConnectivityTests
                }
                Pause-Toolkit
            }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Export-ModuleMember -Function @(
    'Invoke-Backup-Server2Tests',
    'Invoke-Backup-ClientAgentTests',
    'Invoke-Backup-OffsiteConnectivityTests',
    'Show-BackupMenu'
)
