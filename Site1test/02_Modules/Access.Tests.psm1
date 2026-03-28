function Invoke-Access-VpnTests {
    [CmdletBinding()]
    param()

    $repo = Get-ToolkitHost 'Site2Repo'
    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 repository VPN path (6160)' -Address $repo.Address -Port 6160 -Device $repo.DisplayName -DocSection '3.10.1'
}

function Invoke-Access-AdminPathTests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitLocalEndpointTest -Name 'SSH to Jumpbox Ubuntu' -Address (Get-ToolkitHost 'JumpboxUbuntu').Address -Port 22 -Device 'Jumpbox Ubuntu' -DocSection '3.10.2'
    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C2-DC1' -Address (Get-ToolkitHost 'C2DC1').Address -Port 22 -Device 'C2-DC1' -DocSection '3.10.2'
    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C1-Client2' -Address (Get-ToolkitHost 'C1Client2').Address -Port 22 -Device 'C1-Client2' -DocSection '3.10.2'
    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C2-Client1' -Address (Get-ToolkitHost 'C2Client1').Address -Port 22 -Device 'C2-Client1' -DocSection '3.10.2'
    Invoke-ToolkitLocalEndpointTest -Name 'RDP to C1-DC1' -Address (Get-ToolkitHost 'C1DC1').Address -Port 3389 -Device 'C1-DC1' -DocSection '3.10.2'
    Invoke-ToolkitLocalEndpointTest -Name 'RDP to Server2' -Address (Get-ToolkitHost 'Server2').Address -Port 3389 -Device 'Server2' -DocSection '3.10.2'
}

function Invoke-Access-SegmentationTests {
    [CmdletBinding()]
    param()

    $c1linux = Get-ToolkitHost 'C1Client2'
    $c2client = Get-ToolkitHost 'C2Client1'

    Invoke-ToolkitSshTest -Name 'C1 client tenant and management isolation' -Host $c1linux.Address -User $c1linux.LinuxUser -Device $c1linux.DisplayName -DocSection '3.2 / 3.7 / 3.10.2' -SuccessPatterns @('C1_DNS_REACHABLE', 'C2_DNS_BLOCKED', 'MGMT_BLOCKED', 'C2_SAN_BLOCKED') -Commands @(
        'nc -z -w 3 172.30.64.130 53 >/dev/null 2>&1 && echo C1_DNS_REACHABLE || echo C1_DNS_BLOCKED',
        'nc -z -w 3 172.30.64.146 53 >/dev/null 2>&1 && echo C2_DNS_REACHABLE || echo C2_DNS_BLOCKED',
        'nc -z -w 3 192.168.64.10 8006 >/dev/null 2>&1 && echo MGMT_REACHABLE || echo MGMT_BLOCKED',
        'nc -z -w 3 172.30.64.194 3260 >/dev/null 2>&1 && echo C2_SAN_REACHABLE || echo C2_SAN_BLOCKED'
    )

    Invoke-ToolkitSshTest -Name 'C2 client tenant and management isolation' -Host $c2client.Address -User $c2client.LinuxUser -Device $c2client.DisplayName -DocSection '3.2 / 3.7 / 3.10.2' -SuccessPatterns @('C2_DNS_REACHABLE', 'C1_DNS_BLOCKED', 'MGMT_BLOCKED', 'C1_SAN_BLOCKED') -Commands @(
        'nc -z -w 3 172.30.64.146 53 >/dev/null 2>&1 && echo C2_DNS_REACHABLE || echo C2_DNS_BLOCKED',
        'nc -z -w 3 172.30.64.130 53 >/dev/null 2>&1 && echo C1_DNS_REACHABLE || echo C1_DNS_BLOCKED',
        'nc -z -w 3 192.168.64.10 8006 >/dev/null 2>&1 && echo MGMT_REACHABLE || echo MGMT_BLOCKED',
        'nc -z -w 3 172.30.64.186 3260 >/dev/null 2>&1 && echo C1_SAN_REACHABLE || echo C1_SAN_BLOCKED'
    )
}

function Show-AccessMenu {
    [CmdletBinding()]
    param()

    do {
        Show-ToolkitHeader -Title 'VPN, Segmentation, and Administrative Access'
        Write-Host '1. Test Site 1 to Site 2 VPN path'
        Write-Host '2. Test SSH and RDP administrative paths'
        Write-Host '3. Test tenant, management, and iSCSI isolation'
        Write-Host '4. Show manual checklist index'
        Write-Host '5. Run all access tests'
        Write-Host '0. Return to main menu'
        Write-Host ''

        switch (Read-Host 'Select an option') {
            '1' { Invoke-ToolkitBatch -Label 'Access - Site 1 to Site 2 VPN path' -ScriptBlock { Invoke-Access-VpnTests }; Pause-Toolkit }
            '2' { Invoke-ToolkitBatch -Label 'Access - SSH and RDP paths' -ScriptBlock { Invoke-Access-AdminPathTests }; Pause-Toolkit }
            '3' { Invoke-ToolkitBatch -Label 'Access - tenant, management, and iSCSI isolation' -ScriptBlock { Invoke-Access-SegmentationTests }; Pause-Toolkit }
            '4' { Show-ChecklistIndex; Pause-Toolkit }
            '5' {
                Invoke-ToolkitBatch -Label 'Access - all tests' -ScriptBlock {
                    Invoke-Access-VpnTests
                    Invoke-Access-AdminPathTests
                    Invoke-Access-SegmentationTests
                }
                Pause-Toolkit
            }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Export-ModuleMember -Function @(
    'Invoke-Access-VpnTests',
    'Invoke-Access-AdminPathTests',
    'Invoke-Access-SegmentationTests',
    'Show-AccessMenu'
)
