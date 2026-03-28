function Invoke-Identity-C1Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'C1-DC1 AD, DNS, and DHCP summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection '3.3 / 3.6 / Appendix B' -SuccessPatterns @('c1.local', 'Running', '172.30.64.') -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Import-Module DnsServer -ErrorAction SilentlyContinue
        Import-Module DhcpServer -ErrorAction SilentlyContinue
        'HOST=' + $env:COMPUTERNAME
        'DOMAIN=' + (Get-ADDomain).DNSRoot
        Get-Service DNS, NTDS, DHCPServer | Format-Table -HideTableHeaders Name, Status
        Get-DnsServerZone | Select-Object -ExpandProperty ZoneName
        Get-DhcpServerv4Scope | Format-Table -HideTableHeaders ScopeId, StartRange, EndRange, State
    }

    Invoke-ToolkitWinrmTest -Name 'C1-DC2 AD and DNS summary' -ComputerName (Get-ToolkitHost 'C1DC2').Address -Device 'C1-DC2' -DocSection '3.3 / 3.6' -SuccessPatterns @('c1.local', 'Running') -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        Import-Module DnsServer -ErrorAction SilentlyContinue
        'HOST=' + $env:COMPUTERNAME
        'DOMAIN=' + (Get-ADDomain).DNSRoot
        Get-Service DNS, NTDS | Format-Table -HideTableHeaders Name, Status
        Get-DnsServerZone | Select-Object -ExpandProperty ZoneName
    }

}

function Invoke-Identity-C2Tests {
    [CmdletBinding()]
    param()

    $c2dc1 = Get-ToolkitHost 'C2DC1'
    $c2dc2 = Get-ToolkitHost 'C2DC2'
    $c2client = Get-ToolkitHost 'C2Client1'

    Invoke-ToolkitSshTest -Name 'C2-DC1 Samba AD, DNS, and DHCP summary' -Host $c2dc1.Address -User $c2dc1.LinuxUser -Device $c2dc1.DisplayName -DocSection '3.3 / 3.6 / Appendix B' -SuccessPatterns @('c2-dc1', 'has address 172.30.64.146', 'failover peer', 'primary;') -Commands @(
        'hostnamectl --static',
        'host c2-dc1.c2.local 127.0.0.1',
        'host c2-dc2.c2.local 127.0.0.1',
        'test -x /usr/bin/samba-tool && echo SAMBA_TOOL=present',
        'grep -E ''failover peer|primary;|mclt|split|load balance'' /etc/dhcp/dhcpd.conf'
    )

    Invoke-ToolkitSshTest -Name 'C2-DC2 Samba AD, DNS, and DHCP summary' -Host $c2dc2.Address -User $c2dc2.LinuxUser -Device $c2dc2.DisplayName -DocSection '3.3 / 3.6 / Appendix B' -SuccessPatterns @('c2-dc2', 'has address 172.30.64.147', 'failover peer', 'secondary;') -Commands @(
        'hostnamectl --static',
        'host c2-dc1.c2.local 127.0.0.1',
        'host c2-dc2.c2.local 127.0.0.1',
        'test -x /usr/bin/samba-tool && echo SAMBA_TOOL=present',
        'grep -E ''failover peer|secondary;|load balance'' /etc/dhcp/dhcpd.conf'
    )

    Invoke-ToolkitSshTest -Name 'C2-Client1 DHCP and name resolution summary' -Host $c2client.Address -User $c2client.LinuxUser -Device $c2client.DisplayName -DocSection '3.6 / Appendix B' -SuccessPatterns @('172.30.64.', '172.30.64.65', '172.30.64.146') -Commands @(
        'hostnamectl --static',
        'nslookup c2-dc1.c2.local 172.30.64.146',
        'nmcli dev show | grep -E ''IP4.ADDRESS|IP4.GATEWAY|IP4.DNS'''
    )
}

function Show-IdentityMenu {
    [CmdletBinding()]
    param()

    do {
        Show-ToolkitHeader -Title 'Identity, DNS, and DHCP'
        Write-Host '1. Test Company 1 server identity stack (C1-DC1, C1-DC2)'
        Write-Host '2. Test Company 2 identity stack (C2-DC1, C2-DC2, C2-Client1)'
        Write-Host '3. Run all identity tests'
        Write-Host '0. Return to main menu'
        Write-Host ''

        switch (Read-Host 'Select an option') {
            '1' { Invoke-ToolkitBatch -Label 'Identity - Company 1' -ScriptBlock { Invoke-Identity-C1Tests }; Pause-Toolkit }
            '2' { Invoke-ToolkitBatch -Label 'Identity - Company 2' -ScriptBlock { Invoke-Identity-C2Tests }; Pause-Toolkit }
            '3' {
                Invoke-ToolkitBatch -Label 'Identity - all tests' -ScriptBlock {
                    Invoke-Identity-C1Tests
                    Invoke-Identity-C2Tests
                }
                Pause-Toolkit
            }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Export-ModuleMember -Function @(
    'Invoke-Identity-C1Tests',
    'Invoke-Identity-C2Tests',
    'Show-IdentityMenu'
)
