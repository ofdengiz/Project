function Invoke-Network-CoreEndpointTests {
    [CmdletBinding()]
    param()

    $targets = @(
        @{ Name = 'Proxmox GUI'; Device = 'Proxmox VE'; Address = (Get-ToolkitHost 'Proxmox').Address; Port = 8006; Section = '3.5 / 3.10.2' },
        @{ Name = 'Grafana GUI'; Device = 'Jumpbox Ubuntu'; Address = (Get-ToolkitHost 'JumpboxUbuntu').Address; Port = 3000; Section = '3.9.2 / 3.10.2' },
        @{ Name = 'Cockpit GUI'; Device = 'C2-DC1'; Address = (Get-ToolkitHost 'C2DC1').Address; Port = 9090; Section = '3.9.3' },
        @{ Name = 'Windows Admin Center'; Device = 'Jumpbox Windows'; Address = (Get-ToolkitHost 'JumpboxWin10').Address; Port = 6600; Section = '3.9.4' },
        @{ Name = 'Lab Switch SSH'; Device = 'Lab Switch'; Address = (Get-ToolkitHost 'LabSwitch').Address; Port = 22; Section = '3.4.2 / 3.10.2' },
        @{ Name = 'OPNsense GUI'; Device = 'OPNsense'; Address = (Get-ToolkitHost 'OPNsense').Address; Port = 80; Section = '3.2 / 3.10.2' }
    )

    foreach ($target in $targets) {
        Invoke-ToolkitLocalEndpointTest -Name $target.Name -Address $target.Address -Port $target.Port -Device $target.Device -DocSection $target.Section
    }
}

function Invoke-Network-WindowsInventoryTests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'Server2 IP summary' -ComputerName (Get-ToolkitHost 'Server2').Address -Device 'Server2' -DocSection '3.2 / Appendix A' -SuccessPatterns @('192.168.64.20') -ScriptBlock {
        hostname
        ipconfig
    }

    Invoke-ToolkitWinrmTest -Name 'C1-DC1 IP summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection '3.2 / Appendix A' -SuccessPatterns @('172.30.64.130') -ScriptBlock {
        hostname
        ipconfig
    }
}

function Invoke-Network-LinuxInterfaceTests {
    [CmdletBinding()]
    param()

    $c2dc1 = Get-ToolkitHost 'C2DC1'
    $c2dc2 = Get-ToolkitHost 'C2DC2'
    $jump = Get-ToolkitHost 'JumpboxUbuntu'

    Invoke-ToolkitSshTest -Name 'C2-DC1 interface summary' -Host $c2dc1.Address -User $c2dc1.LinuxUser -Device $c2dc1.DisplayName -DocSection '3.2 / Appendix A' -SuccessPatterns @('c2-dc1', '172.30.64.146') -Commands @(
        'hostnamectl --static',
        'ip -br a'
    )

    Invoke-ToolkitSshTest -Name 'C2-DC2 interface summary' -Host $c2dc2.Address -User $c2dc2.LinuxUser -Device $c2dc2.DisplayName -DocSection '3.2 / Appendix A' -SuccessPatterns @('c2-dc2', '172.30.64.147') -Commands @(
        'hostnamectl --static',
        'ip -br a'
    )

    Invoke-ToolkitSshTest -Name 'Jumpbox Ubuntu interface summary' -Host $jump.Address -User $jump.LinuxUser -Device $jump.DisplayName -DocSection '3.2 / Table 6' -SuccessPatterns @('172.30.64.180') -Commands @(
        'hostnamectl --static',
        'ip -br a',
        'ip route'
    )
}

function Show-NetworkMenu {
    [CmdletBinding()]
    param()

    do {
        Show-ToolkitHeader -Title 'Network and Addressing'
        Write-Host '1. Test core management endpoints and ports'
        Write-Host '2. Test Windows IP inventories (Server2 and C1-DC1)'
        Write-Host '3. Test Linux interface inventories (C2-DC1, C2-DC2, Jumpbox Ubuntu)'
        Write-Host '4. Show manual checklist index'
        Write-Host '5. Run all network tests'
        Write-Host '0. Return to main menu'
        Write-Host ''

        switch (Read-Host 'Select an option') {
            '1' { Invoke-ToolkitBatch -Label 'Network - core management endpoints' -ScriptBlock { Invoke-Network-CoreEndpointTests }; Pause-Toolkit }
            '2' { Invoke-ToolkitBatch -Label 'Network - Windows IP inventories' -ScriptBlock { Invoke-Network-WindowsInventoryTests }; Pause-Toolkit }
            '3' { Invoke-ToolkitBatch -Label 'Network - Linux interface inventories' -ScriptBlock { Invoke-Network-LinuxInterfaceTests }; Pause-Toolkit }
            '4' { Show-ChecklistIndex; Pause-Toolkit }
            '5' {
                Invoke-ToolkitBatch -Label 'Network - all tests' -ScriptBlock {
                    Invoke-Network-CoreEndpointTests
                    Invoke-Network-WindowsInventoryTests
                    Invoke-Network-LinuxInterfaceTests
                }
                Pause-Toolkit
            }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Export-ModuleMember -Function @(
    'Invoke-Network-CoreEndpointTests',
    'Invoke-Network-WindowsInventoryTests',
    'Invoke-Network-LinuxInterfaceTests',
    'Show-NetworkMenu'
)
