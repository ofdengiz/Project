function Invoke-Storage-Server2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'Server2 iSCSI target inventory' -ComputerName (Get-ToolkitHost 'Server2').Address -Device 'Server2' -DocSection '3.7 / Appendix C' -SuccessPatterns @('c1-dc1', 'c2-dc1') -ScriptBlock {
        Get-IscsiServerTarget | Format-Table -HideTableHeaders TargetName, Status, TargetIqn
    }

    Invoke-ToolkitWinrmTest -Name 'Server2 disk and volume summary' -ComputerName (Get-ToolkitHost 'Server2').Address -Device 'Server2' -DocSection '3.7 / Table 14 / Appendix C' -SuccessPatterns @('Online') -ScriptBlock {
        Get-Disk | Format-Table -HideTableHeaders Number, FriendlyName, OperationalStatus, Size
        Get-Volume | Format-Table -HideTableHeaders DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size
    }
}

function Invoke-Storage-C1InitiatorTests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'C1-DC1 iSCSI initiator summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection '3.7 / Table 15 / Appendix C' -SuccessPatterns @('True') -ScriptBlock {
        Get-IscsiSession | Format-Table -HideTableHeaders TargetNodeAddress, InitiatorPortalAddress, IsConnected
        Get-Disk | Format-Table -HideTableHeaders Number, FriendlyName, OperationalStatus, Size
    }

    Invoke-ToolkitWinrmTest -Name 'C1-DC2 iSCSI initiator summary' -ComputerName (Get-ToolkitHost 'C1DC2').Address -Device 'C1-DC2' -DocSection '3.7 / Table 15 / Appendix C' -SuccessPatterns @('True') -ScriptBlock {
        Get-IscsiSession | Format-Table -HideTableHeaders TargetNodeAddress, InitiatorPortalAddress, IsConnected
        Get-Disk | Format-Table -HideTableHeaders Number, FriendlyName, OperationalStatus, Size
    }
}

function Invoke-Storage-C2Tests {
    [CmdletBinding()]
    param()

    $c2dc1 = Get-ToolkitHost 'C2DC1'
    $c2dc2 = Get-ToolkitHost 'C2DC2'

    Invoke-ToolkitSshTest -Name 'C2-DC1 iSCSI and Gluster summary' -Host $c2dc1.Address -User $c2dc1.LinuxUser -Device $c2dc1.DisplayName -DocSection '3.7 / Tables 14A-18 / Appendix C' -SuccessPatterns @('172.30.64.194', 'gv0', '/data/brick1', '/mnt/sync_disk') -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume status || true',
        'findmnt /data/brick1 || true',
        'mount | grep sync_disk || true',
        'grep -E "\\[C2_Public\\]|\\[C2_Private\\]" /etc/samba/smb.conf'
    )

    Invoke-ToolkitSshTest -Name 'C2-DC2 iSCSI and Gluster summary' -Host $c2dc2.Address -User $c2dc2.LinuxUser -Device $c2dc2.DisplayName -DocSection '3.7 / Tables 14A-18 / Appendix C' -SuccessPatterns @('172.30.64.194', 'gv0', '/data/brick1', '/mnt/sync_disk') -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume status || true',
        'findmnt /data/brick1 || true',
        'mount | grep sync_disk || true',
        'grep -E "\\[C2_Public\\]|\\[C2_Private\\]" /etc/samba/smb.conf'
    )
}

function Show-StorageMenu {
    [CmdletBinding()]
    param()

    do {
        Show-ToolkitHeader -Title 'Storage and SAN'
        Write-Host '1. Test Server2 storage and iSCSI targets'
        Write-Host '2. Test Company 1 Windows iSCSI initiators'
        Write-Host '3. Test Company 2 Linux iSCSI and Gluster'
        Write-Host '4. Show manual checklist index'
        Write-Host '5. Run all storage tests'
        Write-Host '0. Return to main menu'
        Write-Host ''

        switch (Read-Host 'Select an option') {
            '1' { Invoke-ToolkitBatch -Label 'Storage - Server2' -ScriptBlock { Invoke-Storage-Server2Tests }; Pause-Toolkit }
            '2' { Invoke-ToolkitBatch -Label 'Storage - Company 1 initiators' -ScriptBlock { Invoke-Storage-C1InitiatorTests }; Pause-Toolkit }
            '3' { Invoke-ToolkitBatch -Label 'Storage - Company 2 Linux iSCSI and Gluster' -ScriptBlock { Invoke-Storage-C2Tests }; Pause-Toolkit }
            '4' { Show-ChecklistIndex; Pause-Toolkit }
            '5' {
                Invoke-ToolkitBatch -Label 'Storage - all tests' -ScriptBlock {
                    Invoke-Storage-Server2Tests
                    Invoke-Storage-C1InitiatorTests
                    Invoke-Storage-C2Tests
                }
                Pause-Toolkit
            }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Export-ModuleMember -Function @(
    'Invoke-Storage-Server2Tests',
    'Invoke-Storage-C1InitiatorTests',
    'Invoke-Storage-C2Tests',
    'Show-StorageMenu'
)
