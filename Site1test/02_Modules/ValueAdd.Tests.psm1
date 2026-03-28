function Invoke-ValueAdd-GrafanaTests {
    [CmdletBinding()]
    param()

    $jump = Get-ToolkitHost 'JumpboxUbuntu'

    Invoke-ToolkitSshTest -Name 'Jumpbox Ubuntu Grafana and InfluxDB health' -Host $jump.Address -User $jump.LinuxUser -Device $jump.DisplayName -DocSection '3.9.2' -SuccessPatterns @('grafana', 'influxdb', '"database"\s*:\s*"ok"') -Commands @(
        'docker ps --format "{{.Names}} {{.Status}}"',
        'curl -s http://127.0.0.1:3000/api/health'
    )
}

function Invoke-ValueAdd-CockpitTests {
    [CmdletBinding()]
    param()

    $c2dc1 = Get-ToolkitHost 'C2DC1'
    Invoke-ToolkitLocalEndpointTest -Name 'Cockpit HTTPS endpoint' -Address $c2dc1.Address -Port 9090 -Device $c2dc1.DisplayName -DocSection '3.9.3'

    Invoke-ToolkitSshTest -Name 'C2-DC1 Cockpit service state' -Host $c2dc1.Address -User $c2dc1.LinuxUser -Device $c2dc1.DisplayName -DocSection '3.9.3' -SuccessPatterns @('active') -Commands @(
        'systemctl is-active cockpit.socket 2>/dev/null || true',
        'systemctl is-active cockpit.service 2>/dev/null || true'
    )
}

function Invoke-ValueAdd-WacTests {
    [CmdletBinding()]
    param()

    $jump = Get-ToolkitHost 'JumpboxWin10'
    Invoke-ToolkitLocalEndpointTest -Name 'Windows Admin Center HTTPS endpoint' -Address $jump.Address -Port 6600 -Device $jump.DisplayName -DocSection '3.9.4'

    try {
        $candidateNames = @(
            'WindowsAdminCenter',
            'WindowsAdminCenterAccountManagement',
            'ServerManagementGateway'
        )
        $services = Get-Service -Name $candidateNames -ErrorAction SilentlyContinue

        if (-not $services) {
            $services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -like 'Windows Admin Center*' -or $_.DisplayName -like 'Server Management*'
            }
        }

        if ($services) {
            $serviceOutput = $services | Sort-Object Name | Format-Table -HideTableHeaders Name, Status, StartType | Out-String
            $primaryRunning = @($services | Where-Object {
                $_.Name -eq 'WindowsAdminCenter' -and $_.Status -eq 'Running'
            }).Count -gt 0

            if (-not $primaryRunning) {
                $primaryRunning = @($services | Where-Object {
                    $_.DisplayName -like 'Windows Admin Center*' -and $_.Status -eq 'Running'
                }).Count -gt 0
            }

            $status = if ($primaryRunning) { 'PASS' } else { 'REVIEW' }
        }
        else {
            $serviceOutput = '[no Windows Admin Center service matched the known service names]'
            $status = 'REVIEW'
        }

        $result = New-ToolkitResult -Name 'Jumpbox Windows Admin Center service' -Status $status -Device $jump.DisplayName -DocSection '3.9.4' -Method 'Local PowerShell' -Details $serviceOutput
    }
    catch {
        $result = New-ToolkitResult -Name 'Jumpbox Windows Admin Center service' -Status 'FAIL' -Device $jump.DisplayName -DocSection '3.9.4' -Method 'Local PowerShell' -Details $_.Exception.Message
    }

    Add-ToolkitResult -Result $result
    Write-ToolkitResult -Result $result
}

function Show-ValueAddMenu {
    [CmdletBinding()]
    param()

    do {
        Show-ToolkitHeader -Title 'Value Added Features'
        Write-Host '1. Test Grafana and InfluxDB health'
        Write-Host '2. Test Cockpit endpoint and service state'
        Write-Host '3. Test Windows Admin Center endpoint and service state'
        Write-Host '4. Show manual checklist index'
        Write-Host '5. Run all value-added tests'
        Write-Host '0. Return to main menu'
        Write-Host ''

        switch (Read-Host 'Select an option') {
            '1' { Invoke-ToolkitBatch -Label 'Value add - Grafana and InfluxDB' -ScriptBlock { Invoke-ValueAdd-GrafanaTests }; Pause-Toolkit }
            '2' { Invoke-ToolkitBatch -Label 'Value add - Cockpit' -ScriptBlock { Invoke-ValueAdd-CockpitTests }; Pause-Toolkit }
            '3' { Invoke-ToolkitBatch -Label 'Value add - Windows Admin Center' -ScriptBlock { Invoke-ValueAdd-WacTests }; Pause-Toolkit }
            '4' { Show-ChecklistIndex; Pause-Toolkit }
            '5' {
                Invoke-ToolkitBatch -Label 'Value add - all tests' -ScriptBlock {
                    Invoke-ValueAdd-GrafanaTests
                    Invoke-ValueAdd-CockpitTests
                    Invoke-ValueAdd-WacTests
                }
                Pause-Toolkit
            }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Export-ModuleMember -Function @(
    'Invoke-ValueAdd-GrafanaTests',
    'Invoke-ValueAdd-CockpitTests',
    'Invoke-ValueAdd-WacTests',
    'Show-ValueAddMenu'
)
