function Get-ServiceBlockCoverage {
    [CmdletBinding()]
    param()

    @(
        [pscustomobject]@{ Block = '1'; Hotseat = '1'; Area = 'Remote Access'; Coverage = 'RDP to C1-DC1, C1-DC2, C1-Client1, and C1-WebServer'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '1'; Hotseat = '1'; Area = 'Remote Access'; Coverage = 'SSH to C1-Client2'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '1'; Hotseat = '1'; Area = 'DHCP'; Coverage = 'Company 1 scope, reservations, and live leases on C1-DC1'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '1'; Hotseat = '1'; Area = 'Account Administration'; Coverage = 'Company 1 AD users, named workflow identities, groups, managed endpoint alignment, C1-Client2 local-admin plus c1.local domain-user contexts, and C1-Client1 domain-login evidence'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '1'; Hotseat = '2'; Area = 'Remote Access'; Coverage = 'SSH to C2-DC1, C2-DC2, and C2-Client1'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '1'; Hotseat = '2'; Area = 'DHCP'; Coverage = 'Company 2 DHCP failover on C2-DC1 and C2-DC2 plus client lease proof'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '1'; Hotseat = '2'; Area = 'Account Administration'; Coverage = 'Company 2 Samba users, named workflow identities, groups, and C2-Client1 local-admin plus c2.local domain-user login-session proof'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '1'; Area = 'DNS'; Coverage = 'Company 1 zones, forwarders, recursion, and web host records'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '1'; Area = 'HTTPS'; Coverage = 'Company 1 HTTPS reachability plus hostname-only access enforcement checks'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '2'; Area = 'DNS'; Coverage = 'Company 2 internal and external resolution plus secondary DNS proof'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '2'; Area = 'HTTPS'; Coverage = 'Company 2 HTTPS reachability plus hostname-only access enforcement checks'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '3'; Hotseat = '1'; Area = 'Site 1 Hypervisor'; Coverage = 'Proxmox management reachability and tenant segmentation proof'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '3'; Hotseat = '1'; Area = 'vRouter'; Coverage = 'OPNsense reachability and tenant, management, and SAN isolation'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '3'; Hotseat = '1'; Area = 'GUI visual adjunct'; Coverage = 'Proxmox VM inventory and OPNsense interface or rule pages remain visual confirmation items during the live demo'; Mode = 'Manual adjunct' }
        [pscustomobject]@{ Block = '3'; Hotseat = '2'; Area = 'Inter-site Path'; Coverage = 'Site 2 shared repository SMB path from Windows and Ubuntu jumpboxes'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '4'; Hotseat = '1'; Area = 'Replicated File Server'; Coverage = 'Company 1 DFS namespace, DFSR service and replicated-folder evidence, SMB shares, C1-Client1 mapped-drive context evidence, and C1-Client2 per-user Linux share mounts for admin plus c1.local domain users with write-capability checks and private-share isolation'; Mode = 'Automated + server-side' }
        [pscustomobject]@{ Block = '4'; Hotseat = '1'; Area = 'ISCSI'; Coverage = 'Company 1 initiator sessions and SAN disks on C1-DC1, C1-DC2, C1-Client1, and C1-Client2'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '4'; Hotseat = '1'; Area = 'Windows client visual adjunct'; Coverage = 'C1-Client1 interactive browsing of P: and H: plus optional public create/delete proof should still be demonstrated during the live demo'; Mode = 'Manual adjunct' }
        [pscustomobject]@{ Block = '4'; Hotseat = '2'; Area = 'Replicated File Server'; Coverage = 'Company 2 Gluster, Samba public/private share definitions, Site 1 client share mounts, and Site 2 hostname-based SMB access plus per-user private-view proof'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '4'; Hotseat = '2'; Area = 'ISCSI'; Coverage = 'Company 2 iSCSI sessions over dedicated SAN addresses'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '5'; Hotseat = '1'; Area = 'VEEAM'; Coverage = 'Veeam services, repositories, backup copy inventory, recent successful session proof, and Site 2 shared repository SMB path'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '5'; Hotseat = '2'; Area = 'Misc'; Coverage = 'Server1 and Server2 iLO reachability; final role identification remains a manual physical walkthrough'; Mode = 'Automated + manual adjunct' }
    )
}

function Test-ServiceBlockCoverage {
    [CmdletBinding()]
    param()

    $coverage = Get-ServiceBlockCoverage
    $missingBlocks = 1..5 | Where-Object { $_.ToString() -notin $coverage.Block }
    if ($missingBlocks.Count -gt 0) {
        throw "Coverage is missing service block definitions for: $($missingBlocks -join ', ')"
    }

    foreach ($block in 1..5) {
        $hotseats = @($coverage | Where-Object { $_.Block -eq $block.ToString() } | Select-Object -ExpandProperty Hotseat -Unique)
        if ('1' -notin $hotseats -or '2' -notin $hotseats) {
            throw "Coverage for Service Block $block is missing one or more hotseat mappings."
        }
    }

    Write-Host 'Coverage check passed: Service Blocks 1-5 and both hotseat roles are mapped.' -ForegroundColor Green
}

function Show-ServiceBlockCoverage {
    [CmdletBinding()]
    param()

    Show-ToolkitHeader -Title 'Service Block Coverage Review'
    foreach ($block in Get-ServiceBlockCoverage | Group-Object Block | Sort-Object Name) {
        Write-Host ("Service Block {0}" -f $block.Name) -ForegroundColor Cyan
        foreach ($item in $block.Group) {
            Write-Host ("  Hotseat {0} | {1} | {2}" -f $item.Hotseat, $item.Area, $item.Mode)
            Write-Host ("    {0}" -f $item.Coverage)
        }
        Write-Host ''
    }
}

function Show-ServiceBlock5PhysicalInspectionGuide {
    [CmdletBinding()]
    param()

    Show-ToolkitHeader -Title 'Service Block 5 - Physical Inspection Guide'
    Write-Host 'Use Jumpbox Windows (172.30.64.179) and open the two out-of-band management pages below:' -ForegroundColor Yellow
    Write-Host '  https://192.168.64.11'
    Write-Host '  https://192.168.64.21'
    Write-Host ''
    Write-Host 'Explain:' -ForegroundColor Yellow
    Write-Host '  1. Server1 / Proxmox host iLO (192.168.64.11) backs Proxmox VE (192.168.64.10) as the compute platform.'
    Write-Host '  2. Server2 iLO (192.168.64.21) backs Server2 (192.168.64.20) as the storage and backup platform.'
    Write-Host '  3. Management, tenant LAN, and SAN roles line up with the final documentation and physical cabling.'
    Write-Host ''
}

function Resolve-LinuxUserSpecs {
    param(
        [string[]]$Users,
        [object[]]$UserSpecs
    )

    if ($UserSpecs) {
        return @($UserSpecs)
    }

    if (-not $Users -or $Users.Count -eq 0) {
        throw 'Either -Users or -UserSpecs must be provided.'
    }

    $specs = @()
    foreach ($user in $Users) {
        $specs += [pscustomobject]@{
            Name          = $user
            Token         = ($user.ToUpperInvariant() -replace '[^A-Z0-9]', '_')
            HomePath      = "/home/$user"
            RunAsUser     = $user
            WhoAmIValue   = $user
            MountUsername = $user
            WarmupUser    = $user
            CredentialKey = $user
            SessionProbe  = ''
        }
    }

    return $specs
}

function Get-C1Client2LinuxUserSpecs {
    @(
        [pscustomobject]@{
            Name          = 'admin'
            Token         = 'ADMIN'
            HomePath      = '/home/admin'
            RunAsUser     = 'admin'
            WhoAmIValue   = 'admin'
            MountUsername = 'admin'
            WarmupUser    = 'admin'
            CredentialKey = 'admin'
            SessionProbe  = ''
        }
        [pscustomobject]@{
            Name          = 'employee1@c1.local'
            Token         = 'EMPLOYEE1'
            HomePath      = '/home/employee1@c1.local'
            RunAsUser     = 'employee1@c1.local'
            WhoAmIValue   = 'employee1@c1.local'
            MountUsername = 'employee1'
            WarmupUser    = 'employee1@c1.local'
            CredentialKey = 'employee1'
            SessionProbe  = ''
        }
        [pscustomobject]@{
            Name          = 'employee2@c1.local'
            Token         = 'EMPLOYEE2'
            HomePath      = '/home/employee2@c1.local'
            RunAsUser     = 'employee2@c1.local'
            WhoAmIValue   = 'employee2@c1.local'
            MountUsername = 'employee2'
            WarmupUser    = 'employee2@c1.local'
            CredentialKey = 'employee2'
            SessionProbe  = ''
        }
    )
}

function Get-C2Client1LinuxUserSpecs {
    @(
        [pscustomobject]@{
            Name          = 'admin'
            Token         = 'ADMIN'
            HomePath      = '/home/admin'
            RunAsUser     = 'admin'
            WhoAmIValue   = 'admin'
            MountUsername = 'admin'
            WarmupUser    = 'admin'
            CredentialKey = 'admin'
            SessionProbe  = ''
        }
        [pscustomobject]@{
            Name          = 'employee1@c2.local'
            Token         = 'EMPLOYEE1'
            HomePath      = '/home/employee1@c2.local'
            RunAsUser     = 'employee1@c2.local'
            WhoAmIValue   = 'employee1@c2.local'
            MountUsername = 'employee1'
            WarmupUser    = 'employee1@c2.local'
            CredentialKey = 'employee1'
            SessionProbe  = 'RootSu'
        }
        [pscustomobject]@{
            Name          = 'employee2@c2.local'
            Token         = 'EMPLOYEE2'
            HomePath      = '/home/employee2@c2.local'
            RunAsUser     = 'employee2@c2.local'
            WhoAmIValue   = 'employee2@c2.local'
            MountUsername = 'employee2'
            WarmupUser    = 'employee2@c2.local'
            CredentialKey = 'employee2'
            SessionProbe  = 'RootSu'
        }
    )
}

function New-LinuxUserContextCommands {
    param(
        [string[]]$Users,
        [object[]]$UserSpecs
    )

    $commands = @()
    foreach ($spec in Resolve-LinuxUserSpecs -Users $Users -UserSpecs $UserSpecs) {
        $token = $spec.Token
        $commands += "getent passwd '$($spec.Name)' >/dev/null 2>&1 && echo ${token}_ACCOUNT_PRESENT || echo ${token}_ACCOUNT_MISSING"
        $commands += "test -d '$($spec.HomePath)' && echo ${token}_HOME_PRESENT || echo ${token}_HOME_MISSING"
        $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($spec.RunAsUser)' whoami | grep -qx `"$($spec.WhoAmIValue)`" && echo ${token}_IDENTITY_OK || echo ${token}_IDENTITY_MISMATCH"
        $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($spec.RunAsUser)' id || true"
        if ($spec.SessionProbe -eq 'RootSu') {
            $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" timeout 8 su - '$($spec.RunAsUser)' -c 'whoami' 2>/dev/null | grep -qx `"$($spec.WhoAmIValue)`" && echo ${token}_SESSION_OK || echo ${token}_SESSION_FAIL"
            $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" timeout 8 su - '$($spec.RunAsUser)' -c 'pwd' 2>/dev/null | grep -qx `"$($spec.HomePath)`" && echo ${token}_SESSION_HOME_OK || echo ${token}_SESSION_HOME_FAIL"
        }
    }

    return $commands
}

function New-LinuxPerUserMountCommands {
    param(
        [string[]]$Users,
        [object[]]$UserSpecs,

        [Parameter(Mandatory)]
        [string]$SharePrefix,

        [Parameter(Mandatory)]
        [string]$DomainName
    )

    $commands = @()
    foreach ($spec in Resolve-LinuxUserSpecs -Users $Users -UserSpecs $UserSpecs) {
        $token = $spec.Token
        foreach ($shareType in @('Public', 'Private')) {
            $shareToken = $shareType.ToUpperInvariant()
            $path = "$($spec.HomePath)/${SharePrefix}_${shareType}"
            $commands += "findmnt '$path' || true"
            $commands += "findmnt '$path' >/dev/null 2>&1 && echo ${token}_${shareToken}_MOUNT_PRESENT || echo ${token}_${shareToken}_MOUNT_MISSING"
            $commands += "findmnt -no OPTIONS '$path' 2>/dev/null | grep -q `"username=$($spec.MountUsername)`" && echo ${token}_${shareToken}_USERNAME_OK || echo ${token}_${shareToken}_USERNAME_MISSING"
            $commands += "findmnt -no OPTIONS '$path' 2>/dev/null | grep -q `"domain=$DomainName`" && echo ${token}_${shareToken}_DOMAIN_OK || echo ${token}_${shareToken}_DOMAIN_MISSING"
            $commands += "findmnt '$path' >/dev/null 2>&1 && printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($spec.RunAsUser)' ls '$path' >/dev/null 2>&1 && echo ${token}_${shareToken}_SELF_OK || echo ${token}_${shareToken}_SELF_FAIL"
            $commands += "findmnt '$path' >/dev/null 2>&1 && printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($spec.RunAsUser)' test -w '$path' && echo ${token}_${shareToken}_WRITE_OK || echo ${token}_${shareToken}_WRITE_FAIL"
        }
    }

    return $commands
}

function New-LinuxSessionWarmupCommands {
    param(
        [string[]]$Users,
        [object[]]$UserSpecs,

        [Parameter(Mandatory)]
        [ValidateSet('C1', 'C2')]
        [string]$Platform
    )

    $commands = @()
    $specs = Resolve-LinuxUserSpecs -Users $Users -UserSpecs $UserSpecs
    switch ($Platform) {
        'C1' {
            foreach ($spec in $specs) {
                $token = $spec.Token
                $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" test -f /etc/c1-mounts/$($spec.CredentialKey).cred && echo ${token}_CRED_PRESENT || echo ${token}_CRED_MISSING"
                $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" env PAM_USER=`"$($spec.WarmupUser)`" /usr/local/sbin/c1-user-mounts.sh || true"
            }
        }
        'C2' {
            foreach ($spec in $specs) {
                $token = $spec.Token
                $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" test -f /etc/c2-share-creds/$($spec.CredentialKey).cred && echo ${token}_CRED_PRESENT || echo ${token}_CRED_MISSING"
                $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" /usr/local/sbin/c2-share-session --mount-now `"$($spec.WarmupUser)`" || true"
            }
        }
    }

    return $commands
}

function New-LinuxPrivateIsolationCommands {
    param(
        [Parameter(Mandatory)]
        [string]$LinuxPrefix,

        [Parameter(Mandatory)]
        [ValidateSet('C1', 'C2')]
        [string]$Platform,

        [object[]]$UserSpecs
    )

    $commands = @()
    $specs = Resolve-LinuxUserSpecs -Users @('employee1', 'employee2') -UserSpecs $UserSpecs
    $employee1Spec = $specs | Where-Object { $_.Token -eq 'EMPLOYEE1' } | Select-Object -First 1
    $employee2Spec = $specs | Where-Object { $_.Token -eq 'EMPLOYEE2' } | Select-Object -First 1
    if (-not $employee1Spec -or -not $employee2Spec) {
        throw 'Private isolation checks require EMPLOYEE1 and EMPLOYEE2 user specs.'
    }
    $employee1Path = "$($employee1Spec.HomePath)/${LinuxPrefix}_Private"
    $employee2Path = "$($employee2Spec.HomePath)/${LinuxPrefix}_Private"
    $commands += New-LinuxSessionWarmupCommands -Platform $Platform -UserSpecs $specs
    $commands += @(
        "findmnt '$employee1Path' >/dev/null 2>&1 && echo EMPLOYEE1_PRIVATE_MOUNT_PRESENT || echo EMPLOYEE1_PRIVATE_MOUNT_MISSING",
        "findmnt '$employee2Path' >/dev/null 2>&1 && echo EMPLOYEE2_PRIVATE_MOUNT_PRESENT || echo EMPLOYEE2_PRIVATE_MOUNT_MISSING",
        "findmnt '$employee1Path' >/dev/null 2>&1 && printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($employee1Spec.RunAsUser)' ls '$employee1Path' >/dev/null 2>&1 && echo EMPLOYEE1_SELF_PRIVATE_OK || echo EMPLOYEE1_SELF_PRIVATE_FAIL",
        "findmnt '$employee2Path' >/dev/null 2>&1 && printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($employee2Spec.RunAsUser)' ls '$employee2Path' >/dev/null 2>&1 && echo EMPLOYEE2_SELF_PRIVATE_OK || echo EMPLOYEE2_SELF_PRIVATE_FAIL",
        "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($employee1Spec.RunAsUser)' ls '$employee2Path' >/dev/null 2>&1 && echo EMPLOYEE1_CAN_READ_EMPLOYEE2_PRIVATE || echo EMPLOYEE1_BLOCKED_FROM_EMPLOYEE2_PRIVATE",
        "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" -u '$($employee2Spec.RunAsUser)' ls '$employee1Path' >/dev/null 2>&1 && echo EMPLOYEE2_CAN_READ_EMPLOYEE1_PRIVATE || echo EMPLOYEE2_BLOCKED_FROM_EMPLOYEE1_PRIVATE"
    )

    return $commands
}

function Invoke-SB1-Hotseat1Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitLocalEndpointTest -Name 'RDP to C1-DC1' -Address (Get-ToolkitHost 'C1DC1').Address -Port 3389 -Device 'C1-DC1' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Jumpbox Windows can reach Company 1 primary infrastructure over RDP.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.130 -Port 3389')
    Invoke-ToolkitLocalEndpointTest -Name 'RDP to C1-DC2' -Address (Get-ToolkitHost 'C1DC2').Address -Port 3389 -Device 'C1-DC2' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Jumpbox Windows can reach Company 1 secondary infrastructure over RDP.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.131 -Port 3389')
    Invoke-ToolkitLocalEndpointTest -Name 'RDP to C1-Client1' -Address (Get-ToolkitHost 'C1Client1').Address -Port 3389 -Device 'C1-Client1' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Jumpbox Windows can reach the Company 1 Windows client over RDP.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.2 -Port 3389')
    Invoke-ToolkitLocalEndpointTest -Name 'RDP to C1-WebServer' -Address (Get-ToolkitHost 'C1Web').Address -Port 3389 -Device 'C1-WebServer' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Jumpbox Windows can reach the Company 1 web server over RDP for administration.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.162 -Port 3389')
    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C1-Client2' -Address (Get-ToolkitHost 'C1Client2').Address -Port 22 -Device 'C1-Client2' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Jumpbox Windows can reach the Company 1 Linux client over SSH.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.3 -Port 22')

    Invoke-ToolkitWinrmTest -Name 'C1 DHCP scope, reservations, and leases' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 1 / DHCP' -SuccessPatterns @('SCOPE_PRESENT', 'CLIENT1_RESERVATION_PRESENT', 'C1CLIENT2_RESERVATION_PRESENT', 'CLIENT1_LEASE_PRESENT', 'C1CLIENT2_LEASE_PRESENT') -CheckDescription 'From C1-DC1, confirm the Company 1 scope exists and that CLIENT1 and C1-Client2 reservations and leases are present.' -CommandLines @(
        'Get-DhcpServerv4Scope'
        'Get-DhcpServerv4Reservation -ScopeId 172.30.64.0'
        'Get-DhcpServerv4Lease -ScopeId 172.30.64.0'
    ) -ScriptBlock {
        Import-Module DhcpServer -ErrorAction Stop

        $scope = Get-DhcpServerv4Scope -ErrorAction Stop | Where-Object { $_.ScopeId -eq [ipaddress]'172.30.64.0' }
        $reservations = @(Get-DhcpServerv4Reservation -ScopeId ([ipaddress]'172.30.64.0') -ErrorAction SilentlyContinue)
        $leases = @(Get-DhcpServerv4Lease -ScopeId ([ipaddress]'172.30.64.0') -ErrorAction SilentlyContinue)

        if ($scope) { 'SCOPE_PRESENT' } else { 'SCOPE_MISSING' }
        $scope | Format-Table -HideTableHeaders ScopeId, StartRange, EndRange, State

        $client1Reservation = $reservations | Where-Object { $_.IPAddress.IPAddressToString -eq '172.30.64.2' }
        $c1Client2Reservation = $reservations | Where-Object { $_.IPAddress.IPAddressToString -eq '172.30.64.3' }
        if ($client1Reservation) { 'CLIENT1_RESERVATION_PRESENT' } else { 'CLIENT1_RESERVATION_MISSING' }
        if ($c1Client2Reservation) { 'C1CLIENT2_RESERVATION_PRESENT' } else { 'C1CLIENT2_RESERVATION_MISSING' }
        $reservations | Where-Object { $_.IPAddress.IPAddressToString -in @('172.30.64.2', '172.30.64.3') } | Format-Table -HideTableHeaders IPAddress, Name, ClientId

        $client1Lease = $leases | Where-Object { $_.IPAddress.IPAddressToString -eq '172.30.64.2' }
        $c1Client2Lease = $leases | Where-Object { $_.IPAddress.IPAddressToString -eq '172.30.64.3' }
        if ($client1Lease) { 'CLIENT1_LEASE_PRESENT' } else { 'CLIENT1_LEASE_MISSING' }
        if ($c1Client2Lease) { 'C1CLIENT2_LEASE_PRESENT' } else { 'C1CLIENT2_LEASE_MISSING' }
        $leases | Where-Object { $_.IPAddress.IPAddressToString -in @('172.30.64.2', '172.30.64.3') } | Format-Table -HideTableHeaders IPAddress, HostName, AddressState
    }

    Invoke-ToolkitWinrmTest -Name 'C1 AD account administration summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 1 / Account Administration' -SuccessPatterns @('USERS_PRESENT', 'GROUPS_PRESENT', 'ADMIN_USER_PRESENT', 'EMPLOYEE1_USER_PRESENT', 'EMPLOYEE2_USER_PRESENT') -CheckDescription 'From C1-DC1, confirm Company 1 user and group administration objects, including admin, employee1, and employee2, are already present in Active Directory.' -CommandLines @(
        'Get-ADUser -Filter *'
        'Get-ADGroup -Filter *'
    ) -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction Stop

        $users = @(Get-ADUser -Filter * -Properties Enabled | Where-Object { $_.SamAccountName -notlike '*$' })
        $groups = @(Get-ADGroup -Filter * | Where-Object { $_.Name -notlike 'Denied*' })
        $userNames = @($users | Select-Object -ExpandProperty SamAccountName)

        if ($users.Count -gt 0) { 'USERS_PRESENT' } else { 'USERS_MISSING' }
        'USER_COUNT=' + $users.Count
        $users | Select-Object -First 12 SamAccountName, Enabled | Format-Table -HideTableHeaders

        if ($groups.Count -gt 0) { 'GROUPS_PRESENT' } else { 'GROUPS_MISSING' }
        'GROUP_COUNT=' + $groups.Count
        $groups | Select-Object -First 12 Name, GroupScope | Format-Table -HideTableHeaders

        if ('admin' -in $userNames) { 'ADMIN_USER_PRESENT' } else { 'ADMIN_USER_MISSING' }
        if ('employee1' -in $userNames) { 'EMPLOYEE1_USER_PRESENT' } else { 'EMPLOYEE1_USER_MISSING' }
        if ('employee2' -in $userNames) { 'EMPLOYEE2_USER_PRESENT' } else { 'EMPLOYEE2_USER_MISSING' }
    }

    Invoke-ToolkitWinrmTest -Name 'C1 managed endpoint alignment' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-Client1 and C1-Client2 (server-side evidence)' -DocSection 'Service Block 1 / Spot-check alignment' -SuccessPatterns @('CLIENT1_ALIGNMENT_OK', 'C1CLIENT2_ALIGNMENT_OK') -CheckDescription 'From C1-DC1, line up DHCP, DNS, and directory evidence for C1-Client1 and C1-Client2 as managed endpoints.' -CommandLines @(
        'Get-DhcpServerv4Lease -ScopeId 172.30.64.0'
        'Get-DnsServerResourceRecord -ZoneName c1.local -RRType A'
        'Get-ADComputer -Filter * -Properties DNSHostName, IPv4Address'
    ) -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction Stop
        Import-Module DnsServer -ErrorAction Stop
        Import-Module DhcpServer -ErrorAction Stop

        $leases = @(Get-DhcpServerv4Lease -ScopeId ([ipaddress]'172.30.64.0') -ErrorAction SilentlyContinue)
        $records = @(Get-DnsServerResourceRecord -ZoneName 'c1.local' -RRType A -ErrorAction SilentlyContinue)
        $computers = @(Get-ADComputer -Filter * -Properties DNSHostName, IPv4Address)

        $client1Lease = $leases | Where-Object { $_.IPAddress.IPAddressToString -eq '172.30.64.2' }
        $client1Record = $records | Where-Object { $_.RecordData.IPv4Address.IPAddressToString -eq '172.30.64.2' }
        $client1Computer = $computers | Where-Object { $_.Name -like '*CLIENT1*' -or $_.IPv4Address -eq '172.30.64.2' }

        $c1Client2Lease = $leases | Where-Object { $_.IPAddress.IPAddressToString -eq '172.30.64.3' }
        $c1Client2Record = $records | Where-Object { $_.RecordData.IPv4Address.IPAddressToString -eq '172.30.64.3' }
        $c1Client2Computer = $computers | Where-Object { $_.Name -like '*CLIENT2*' -or $_.IPv4Address -eq '172.30.64.3' }

        if ($client1Lease -and $client1Record -and $client1Computer) { 'CLIENT1_ALIGNMENT_OK' } else { 'CLIENT1_ALIGNMENT_MISSING' }
        if ($c1Client2Lease -and $c1Client2Record -and $c1Client2Computer) { 'C1CLIENT2_ALIGNMENT_OK' } else { 'C1CLIENT2_ALIGNMENT_MISSING' }

        'CLIENT1'
        $client1Lease | Format-Table -HideTableHeaders IPAddress, HostName, AddressState
        $client1Record | Select-Object HostName, RecordType, @{Name='IPv4Address'; Expression = { $_.RecordData.IPv4Address.IPAddressToString } } | Format-Table -HideTableHeaders
        $client1Computer | Format-Table -HideTableHeaders Name, DNSHostName, IPv4Address

        'C1CLIENT2'
        $c1Client2Lease | Format-Table -HideTableHeaders IPAddress, HostName, AddressState
        $c1Client2Record | Select-Object HostName, RecordType, @{Name='IPv4Address'; Expression = { $_.RecordData.IPv4Address.IPAddressToString } } | Format-Table -HideTableHeaders
        $c1Client2Computer | Format-Table -HideTableHeaders Name, DNSHostName, IPv4Address
    }

    Invoke-ToolkitSshTest -Name 'C1-Client2 user identity contexts' -Host (Get-ToolkitHost 'C1Client2').Address -User (Get-ToolkitHost 'C1Client2').LinuxUser -Device 'C1-Client2' -DocSection 'Service Block 1 / Account Administration' -SuccessPatterns @(
        'ADMIN_ACCOUNT_PRESENT', 'ADMIN_HOME_PRESENT', 'ADMIN_IDENTITY_OK',
        'EMPLOYEE1_ACCOUNT_PRESENT', 'EMPLOYEE1_HOME_PRESENT', 'EMPLOYEE1_IDENTITY_OK',
        'EMPLOYEE2_ACCOUNT_PRESENT', 'EMPLOYEE2_HOME_PRESENT', 'EMPLOYEE2_IDENTITY_OK'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client2, confirm admin remains available as the local Linux admin account and that employee1 plus employee2 resolve through c1.local domain-user identities used by the Company 1 workflow.' -Commands (New-LinuxUserContextCommands -UserSpecs (Get-C1Client2LinuxUserSpecs))

    Invoke-ToolkitWinrmTest -Name 'C1-Client1 domain login evidence' -ComputerName (Get-ToolkitHost 'C1Client1').Address -Device 'C1-Client1' -DocSection 'Service Block 1 / Account Administration' -SuccessPatterns @(
        'DOMAIN_JOIN_OK',
        'ADMIN_PROFILE_PRESENT',
        'EMPLOYEE1_PROFILE_PRESENT',
        'EMPLOYEE2_PROFILE_PRESENT'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client1, confirm the workstation is joined to c1.local and already contains the admin, employee1, and employee2 user profiles needed for the domain-login workflow.' -CommandLines @(
        'Get-CimInstance Win32_ComputerSystem'
        'Get-CimInstance Win32_UserProfile'
    ) -ScriptBlock {
        $system = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $profiles = @(Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue)
        $targetProfiles = @{
            ADMIN     = 'C:\Users\admin'
            EMPLOYEE1 = 'C:\Users\employee1'
            EMPLOYEE2 = 'C:\Users\employee2'
        }

        if ($system.PartOfDomain -and $system.Domain -ieq 'c1.local') { 'DOMAIN_JOIN_OK' } else { 'DOMAIN_JOIN_MISSING' }
        $system | Select-Object Name, Domain, PartOfDomain | Format-List

        foreach ($entry in $targetProfiles.GetEnumerator()) {
            if ($profiles.LocalPath -contains $entry.Value) {
                '{0}_PROFILE_PRESENT' -f $entry.Key
            }
            else {
                '{0}_PROFILE_MISSING' -f $entry.Key
            }
        }

        $profiles |
            Where-Object { $_.LocalPath -in $targetProfiles.Values } |
            Select-Object SID, LocalPath, Loaded |
            Format-Table -HideTableHeaders
    }
}

function Invoke-SB1-Hotseat2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C2-DC1' -Address (Get-ToolkitHost 'C2DC1').Address -Port 22 -Device 'C2-DC1' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Company 2 primary infrastructure is reachable over SSH.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.146 -Port 22')
    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C2-DC2' -Address (Get-ToolkitHost 'C2DC2').Address -Port 22 -Device 'C2-DC2' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm Company 2 secondary infrastructure is reachable over SSH.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.147 -Port 22')
    Invoke-ToolkitLocalEndpointTest -Name 'SSH to C2-Client1' -Address (Get-ToolkitHost 'C2Client1').Address -Port 22 -Device 'C2-Client1' -DocSection 'Service Block 1 / Remote Access' -CheckDescription 'Confirm the Company 2 client is reachable over SSH.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.66 -Port 22')

    Invoke-ToolkitSshTest -Name 'C2 DHCP failover primary summary' -Host (Get-ToolkitHost 'C2DC1').Address -User (Get-ToolkitHost 'C2DC1').LinuxUser -Device 'C2-DC1' -DocSection 'Service Block 1 / DHCP' -SuccessPatterns @('DHCP_SERVICE_ACTIVE', 'PRIMARY_FAILOVER_PRESENT') -CheckDescription 'On C2-DC1, confirm isc-dhcp-server is active and the failover configuration marks this node as primary.' -DisplayCommands @(
        'systemctl is-active isc-dhcp-server'
        'grep -n "failover peer" /etc/dhcp/dhcpd.conf'
        'grep -n "primary;" /etc/dhcp/dhcpd.conf'
    ) -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active isc-dhcp-server | sed "s/^/DHCP_SERVICE=/"',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" grep -n "failover peer" /etc/dhcp/dhcpd.conf || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" grep -n "primary;" /etc/dhcp/dhcpd.conf || true',
        '[ "$(printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active isc-dhcp-server 2>/dev/null)" = "active" ] && echo DHCP_SERVICE_ACTIVE || echo DHCP_SERVICE_INACTIVE',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" grep -q "primary;" /etc/dhcp/dhcpd.conf && echo PRIMARY_FAILOVER_PRESENT || echo PRIMARY_FAILOVER_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C2 DHCP failover secondary summary' -Host (Get-ToolkitHost 'C2DC2').Address -User (Get-ToolkitHost 'C2DC2').LinuxUser -Device 'C2-DC2' -DocSection 'Service Block 1 / DHCP' -SuccessPatterns @('DHCP_SERVICE_ACTIVE', 'SECONDARY_FAILOVER_PRESENT') -CheckDescription 'On C2-DC2, confirm isc-dhcp-server is active and the failover configuration marks this node as secondary.' -DisplayCommands @(
        'systemctl is-active isc-dhcp-server'
        'grep -n "failover peer" /etc/dhcp/dhcpd.conf'
        'grep -n "secondary;" /etc/dhcp/dhcpd.conf'
    ) -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active isc-dhcp-server | sed "s/^/DHCP_SERVICE=/"',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" grep -n "failover peer" /etc/dhcp/dhcpd.conf || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" grep -n "secondary;" /etc/dhcp/dhcpd.conf || true',
        '[ "$(printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active isc-dhcp-server 2>/dev/null)" = "active" ] && echo DHCP_SERVICE_ACTIVE || echo DHCP_SERVICE_INACTIVE',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" grep -q "secondary;" /etc/dhcp/dhcpd.conf && echo SECONDARY_FAILOVER_PRESENT || echo SECONDARY_FAILOVER_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C2 client lease and resolver summary' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 1 / DHCP' -SuccessPatterns @('172.30.64.66', '172.30.64.65', '172.30.64.146') -CheckDescription 'On C2-Client1, confirm the live client address, gateway, and DNS settings match the Company 2 design.' -Commands @(
        'hostnamectl --static',
        'nmcli dev show | egrep "IP4.ADDRESS|IP4.GATEWAY|IP4.DNS"',
        'nslookup c2-dc1.c2.local 172.30.64.146'
    )

    Invoke-ToolkitSshTest -Name 'C2 Samba account administration summary' -Host (Get-ToolkitHost 'C2DC1').Address -User (Get-ToolkitHost 'C2DC1').LinuxUser -Device 'C2-DC1' -DocSection 'Service Block 1 / Account Administration' -SuccessPatterns @('SAMBA_USERS_PRESENT', 'SAMBA_GROUPS_PRESENT', 'ADMIN_USER_PRESENT', 'EMPLOYEE1_USER_PRESENT', 'EMPLOYEE2_USER_PRESENT', 'C2_FILE_USERS_GROUP_PRESENT') -CheckDescription 'On C2-DC1, confirm Samba AD already contains Company 2 users, groups, and the workflow identities admin, employee1, and employee2.' -DisplayCommands @(
        'samba-tool user list'
        'samba-tool group list'
    ) -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool user list | sed -n "1,20p"',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool group list | sed -n "1,20p"',
        '[ "$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool user list 2>/dev/null | wc -l)" -gt 0 ] && echo SAMBA_USERS_PRESENT || echo SAMBA_USERS_MISSING',
        '[ "$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool group list 2>/dev/null | wc -l)" -gt 0 ] && echo SAMBA_GROUPS_PRESENT || echo SAMBA_GROUPS_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool user list 2>/dev/null | grep -qx "admin" && echo ADMIN_USER_PRESENT || echo ADMIN_USER_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool user list 2>/dev/null | grep -qx "employee1" && echo EMPLOYEE1_USER_PRESENT || echo EMPLOYEE1_USER_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool user list 2>/dev/null | grep -qx "employee2" && echo EMPLOYEE2_USER_PRESENT || echo EMPLOYEE2_USER_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool group list 2>/dev/null | grep -qx "c2_file_users" && echo C2_FILE_USERS_GROUP_PRESENT || echo C2_FILE_USERS_GROUP_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C2-Client1 user identity contexts' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 1 / Account Administration' -SuccessPatterns @(
        'ADMIN_ACCOUNT_PRESENT', 'ADMIN_HOME_PRESENT', 'ADMIN_IDENTITY_OK',
        'EMPLOYEE1_ACCOUNT_PRESENT', 'EMPLOYEE1_HOME_PRESENT', 'EMPLOYEE1_IDENTITY_OK', 'EMPLOYEE1_SESSION_OK', 'EMPLOYEE1_SESSION_HOME_OK',
        'EMPLOYEE2_ACCOUNT_PRESENT', 'EMPLOYEE2_HOME_PRESENT', 'EMPLOYEE2_IDENTITY_OK', 'EMPLOYEE2_SESSION_OK', 'EMPLOYEE2_SESSION_HOME_OK'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-Client1, confirm admin remains available as the local Linux admin account and that employee1@c2.local plus employee2@c2.local can complete c2.local domain-user login sessions into their own Linux home directories used by the Company 2 workflow.' -Commands (New-LinuxUserContextCommands -UserSpecs (Get-C2Client1LinuxUserSpecs))
}

function Invoke-SB2-Hotseat1Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'C1 DNS zones and forwarders' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 2 / DNS' -SuccessPatterns @('FORWARD_ZONE_PRESENT', 'MSDCS_ZONE_PRESENT', 'REVERSE_ZONE_PRESENT', 'FORWARDERS_PRESENT') -CheckDescription 'On C1-DC1, confirm the expected forward and reverse zones exist and that upstream forwarders are configured for recursion.' -CommandLines @(
        'Get-DnsServerZone'
        'Get-DnsServerForwarder'
    ) -ScriptBlock {
        Import-Module DnsServer -ErrorAction Stop

        $zones = @(Get-DnsServerZone -ErrorAction Stop)
        $forwarders = @(Get-DnsServerForwarder -ErrorAction SilentlyContinue)

        if ($zones.ZoneName -contains 'c1.local') { 'FORWARD_ZONE_PRESENT' } else { 'FORWARD_ZONE_MISSING' }
        if ($zones.ZoneName -contains '_msdcs.c1.local') { 'MSDCS_ZONE_PRESENT' } else { 'MSDCS_ZONE_MISSING' }
        if ($zones.ZoneName -contains '64.30.172.in-addr.arpa') { 'REVERSE_ZONE_PRESENT' } else { 'REVERSE_ZONE_MISSING' }
        if ($forwarders.Count -gt 0) { 'FORWARDERS_PRESENT' } else { 'FORWARDERS_MISSING' }

        $zones | Select-Object -ExpandProperty ZoneName
        $forwarders | Format-Table -HideTableHeaders IPAddress, Timeout
    }

    Invoke-ToolkitWinrmTest -Name 'C1 DNS recursion and web host record summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 2 / DNS' -SuccessPatterns @('WEB_A_RECORD_PRESENT', 'WEB_REVERSE_RECORD_PRESENT', 'PUBLIC_RECURSION_OK') -CheckDescription 'On C1-DC1, confirm Company 1 DNS resolves the deployed web server and can complete a recursive public lookup.' -CommandLines @(
        'Resolve-DnsName -Name microsoft.com -Server 172.30.64.130'
        'Get-DnsServerResourceRecord -ZoneName c1.local -RRType A'
        'Get-DnsServerResourceRecord -ZoneName 64.30.172.in-addr.arpa -RRType PTR'
    ) -ScriptBlock {
        Import-Module DnsServer -ErrorAction Stop

        $webRecord = Get-DnsServerResourceRecord -ZoneName 'c1.local' -RRType A -ErrorAction SilentlyContinue | Where-Object {
            $_.RecordData.IPv4Address.IPAddressToString -eq '172.30.64.162'
        }
        $reverseRecord = Get-DnsServerResourceRecord -ZoneName '64.30.172.in-addr.arpa' -RRType PTR -ErrorAction SilentlyContinue | Where-Object {
            $_.HostName -eq '162'
        }
        $publicLookup = Resolve-DnsName -Name 'microsoft.com' -Server '172.30.64.130' -ErrorAction SilentlyContinue

        if ($webRecord) { 'WEB_A_RECORD_PRESENT' } else { 'WEB_A_RECORD_MISSING' }
        if ($reverseRecord) { 'WEB_REVERSE_RECORD_PRESENT' } else { 'WEB_REVERSE_RECORD_MISSING' }
        if ($publicLookup) { 'PUBLIC_RECURSION_OK' } else { 'PUBLIC_RECURSION_FAILED' }

        $webRecord | Select-Object HostName, RecordType, @{Name='IPv4Address'; Expression = { $_.RecordData.IPv4Address.IPAddressToString } } | Format-Table -HideTableHeaders
        $reverseRecord | Select-Object HostName, RecordType, @{Name='PtrDomainName'; Expression = { $_.RecordData.PtrDomainName } } | Format-Table -HideTableHeaders
        $publicLookup | Select-Object -First 5 Name, QueryType, IPAddress | Format-Table -HideTableHeaders
    }

    Invoke-ToolkitLocalEndpointTest -Name 'C1 web server HTTPS endpoint' -Address (Get-ToolkitHost 'C1Web').Address -Port 443 -Device 'C1-WebServer' -DocSection 'Service Block 2 / HTTPS' -CheckDescription 'Confirm the Company 1 web server is reachable on TCP 443 from the approved jumpbox workflow.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.162 -Port 443')
    Invoke-ToolkitHttpTest -Name 'C1 web application HTTPS response' -Uri 'https://c1-webserver.c1.local/' -Device 'C1-WebServer' -DocSection 'Service Block 2 / HTTPS' -Method 'HTTPS GET' -CheckDescription 'Request the Company 1 web page over HTTPS and confirm a valid response is returned from the tenant DNS host name.' -CommandLines @("Invoke-WebRequest -Uri 'https://c1-webserver.c1.local/' -SkipCertificateCheck")
    Invoke-ToolkitHttpRejectionTest -Name 'C1 web application direct IP rejection' -Uris @('https://172.30.64.162/', 'http://172.30.64.162/') -Device 'C1-WebServer' -DocSection 'Service Block 2 / HTTPS' -Method 'HTTP/HTTPS rejection' -CheckDescription 'Request the Company 1 web page by direct IP and confirm HTTP and HTTPS access are rejected so the tenant site is only consumed through https://c1-webserver.c1.local/.' -CommandLines @("Invoke-WebRequest -Uri 'https://172.30.64.162/' -SkipCertificateCheck", "Invoke-WebRequest -Uri 'http://172.30.64.162/'")
}

function Invoke-SB2-Hotseat2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitSshTest -Name 'C2 DNS internal and external resolution summary' -Host (Get-ToolkitHost 'C2DC1').Address -User (Get-ToolkitHost 'C2DC1').LinuxUser -Device 'C2-DC1' -DocSection 'Service Block 2 / DNS' -SuccessPatterns @('INTERNAL_LOOKUP_OK', 'SECONDARY_LOOKUP_OK', 'WEB_LOOKUP_OK', 'EXTERNAL_LOOKUP_OK') -CheckDescription 'On C2-DC1, confirm Company 2 DNS resolves its internal records, the secondary controller, the web server host record, and recursive external lookups.' -Commands @(
        'host c2-dc1.c2.local 127.0.0.1',
        'host c2-dc2.c2.local 127.0.0.1',
        'host c2-webserver.c2.local 127.0.0.1',
        'host microsoft.com 127.0.0.1',
        'host c2-dc1.c2.local 127.0.0.1 >/dev/null 2>&1 && echo INTERNAL_LOOKUP_OK || echo INTERNAL_LOOKUP_FAILED',
        'host c2-dc2.c2.local 127.0.0.1 >/dev/null 2>&1 && echo SECONDARY_LOOKUP_OK || echo SECONDARY_LOOKUP_FAILED',
        'host c2-webserver.c2.local 127.0.0.1 >/dev/null 2>&1 && echo WEB_LOOKUP_OK || echo WEB_LOOKUP_FAILED',
        'host microsoft.com 127.0.0.1 >/dev/null 2>&1 && echo EXTERNAL_LOOKUP_OK || echo EXTERNAL_LOOKUP_FAILED'
    )

    Invoke-ToolkitLocalEndpointTest -Name 'C2 web server HTTPS endpoint' -Address (Get-ToolkitHost 'C2Web').Address -Port 443 -Device 'C2-WebServer' -DocSection 'Service Block 2 / HTTPS' -CheckDescription 'Confirm the Company 2 web server is reachable on TCP 443 from the approved jumpbox workflow.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.170 -Port 443')
    Invoke-ToolkitSshTest -Name 'C2 web application HTTPS response' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 2 / HTTPS' -SuccessPatterns @('HTTPS_FQDN_STATUS=200', 'HTTPS_FQDN_BODY_OK') -CheckDescription 'From C2-Client1, request the Company 2 web page over HTTPS and confirm the tenant DNS host name returns a valid response.' -Commands @(
        'curl -sk -o /dev/null -w "HTTPS_FQDN_STATUS=%{http_code}\n" https://c2-webserver.c2.local/',
        'curl -sk https://c2-webserver.c2.local/ >/dev/null 2>&1 && echo HTTPS_FQDN_BODY_OK || echo HTTPS_FQDN_BODY_FAIL'
    )
    Invoke-ToolkitSshTest -Name 'C2 web application non-FQDN rejection' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 2 / HTTPS' -SuccessPatterns @('HTTPS_IP_REJECTED', 'HTTP_IP_REJECTED', 'HTTP_FQDN_REJECTED') -CheckDescription 'From C2-Client1, confirm the Company 2 website only permits https://c2-webserver.c2.local and rejects direct-IP access plus HTTP requests.' -Commands @(
        'code=$(curl -sk -o /dev/null -w "%{http_code}" https://172.30.64.170/ || true); if [ "$code" = "403" ] || [ "$code" = "000" ]; then echo HTTPS_IP_REJECTED; else echo HTTPS_IP_ALLOWED:$code; fi',
        'code=$(curl -s -o /dev/null -w "%{http_code}" http://172.30.64.170/ || true); if [ "$code" = "403" ] || [ "$code" = "000" ]; then echo HTTP_IP_REJECTED; else echo HTTP_IP_ALLOWED:$code; fi',
        'code=$(curl -s -o /dev/null -w "%{http_code}" http://c2-webserver.c2.local/ || true); if [ "$code" = "403" ] || [ "$code" = "000" ]; then echo HTTP_FQDN_REJECTED; else echo HTTP_FQDN_ALLOWED:$code; fi'
    )
}

function Invoke-SB3-Hotseat1Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitLocalEndpointTest -Name 'Proxmox GUI endpoint' -Address (Get-ToolkitHost 'Proxmox').Address -Port 8006 -Device 'Proxmox VE' -DocSection 'Service Block 3 / Site 1 Hypervisor' -CheckDescription 'Confirm the Proxmox management interface is reachable on TCP 8006.' -CommandLines @('Test-NetConnection -ComputerName 192.168.64.10 -Port 8006')
    Invoke-ToolkitLocalEndpointTest -Name 'OPNsense GUI endpoint' -Address (Get-ToolkitHost 'OPNsense').Address -Port 80 -Device 'OPNsense' -DocSection 'Service Block 3 / vRouter' -CheckDescription 'Confirm the OPNsense web interface is reachable on TCP 80.' -CommandLines @('Test-NetConnection -ComputerName 172.30.64.1 -Port 80')

    Invoke-ToolkitSshTest -Name 'C1 tenant isolation from C1-Client2' -Host (Get-ToolkitHost 'C1Client2').Address -User (Get-ToolkitHost 'C1Client2').LinuxUser -Device 'C1-Client2' -DocSection 'Service Block 3 / vRouter policy' -SuccessPatterns @('C1_DNS_REACHABLE', 'C2_DNS_BLOCKED', 'MGMT_BLOCKED', 'C2_SAN_BLOCKED') -MissingEvidenceStatus 'FAIL' -ReviewOnErrorPatterns @('timed out') -ReviewGuidance 'The SSH session timed out before all tenant-isolation probes returned. Re-run the test or verify C1-Client2 responsiveness before treating this as a segmentation failure.' -CommandTimeoutSeconds 60 -CheckDescription 'From C1-Client2, confirm tenant-local DNS is reachable while Company 2, management, and SAN paths remain blocked.' -Commands @(
        'nc -z -w 2 172.30.64.130 53 >/dev/null 2>&1 && echo C1_DNS_REACHABLE || echo C1_DNS_BLOCKED',
        'nc -z -w 2 172.30.64.146 53 >/dev/null 2>&1 && echo C2_DNS_REACHABLE || echo C2_DNS_BLOCKED',
        'nc -z -w 2 192.168.64.10 8006 >/dev/null 2>&1 && echo MGMT_REACHABLE || echo MGMT_BLOCKED',
        'nc -z -w 2 172.30.64.194 3260 >/dev/null 2>&1 && echo C2_SAN_REACHABLE || echo C2_SAN_BLOCKED'
    )

    Invoke-ToolkitSshTest -Name 'C2 tenant isolation from C2-Client1' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 3 / vRouter policy' -SuccessPatterns @('C2_DNS_REACHABLE', 'C1_DNS_BLOCKED', 'MGMT_BLOCKED', 'C1_SAN_BLOCKED') -MissingEvidenceStatus 'FAIL' -ReviewOnErrorPatterns @('timed out') -ReviewGuidance 'The SSH session timed out before all tenant-isolation probes returned. Re-run the test or verify C2-Client1 responsiveness before treating this as a segmentation failure.' -CommandTimeoutSeconds 60 -CheckDescription 'From C2-Client1, confirm tenant-local DNS is reachable while Company 1, management, and SAN paths remain blocked.' -Commands @(
        'nc -z -w 2 172.30.64.146 53 >/dev/null 2>&1 && echo C2_DNS_REACHABLE || echo C2_DNS_BLOCKED',
        'nc -z -w 2 172.30.64.130 53 >/dev/null 2>&1 && echo C1_DNS_REACHABLE || echo C1_DNS_BLOCKED',
        'nc -z -w 2 192.168.64.10 8006 >/dev/null 2>&1 && echo MGMT_REACHABLE || echo MGMT_BLOCKED',
        'nc -z -w 2 172.30.64.186 3260 >/dev/null 2>&1 && echo C1_SAN_REACHABLE || echo C1_SAN_BLOCKED'
    )
}

function Invoke-SB3-Hotseat2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 shared repository SMB path (Windows jumpbox)' -Address (Get-ToolkitHost 'Site2Repo').Address -Port 445 -Device 'Site 2 Offsite Shared Repository' -DocSection 'Service Block 3 / Site-to-Site VPN' -CheckDescription 'From Jumpbox Windows, confirm the Site 2 shared repository SMB path is reachable across the inter-site path.' -CommandLines @('Test-NetConnection -ComputerName 172.30.65.180 -Port 445')

    Invoke-ToolkitSshTest -Name 'Site 2 shared repository SMB path (Ubuntu jumpbox)' -Host (Get-ToolkitHost 'JumpboxUbuntu').Address -User (Get-ToolkitHost 'JumpboxUbuntu').LinuxUser -Device 'Jumpbox Ubuntu' -DocSection 'Service Block 3 / Site-to-Site VPN' -SuccessPatterns @('SITE2_REPO_SMB_REACHABLE') -CheckDescription 'From Jumpbox Ubuntu, confirm the same Site 2 shared repository SMB path is reachable and capture the route selection.' -Commands @(
        'ip route get 172.30.65.180',
        'nc -z -w 5 172.30.65.180 445 >/dev/null 2>&1 && echo SITE2_REPO_SMB_REACHABLE || echo SITE2_REPO_SMB_BLOCKED'
    )
}

function Invoke-SB4-Hotseat1Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'C1 DFS namespace and replication summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @('DFSN_ROOT_PRESENT', 'DFSR_GROUP_PRESENT', 'PUBLIC_REPLICATION_EVIDENCE_PRESENT', 'PRIVATE_REPLICATION_EVIDENCE_PRESENT', 'PUBLIC_REPL_FOLDER_PRESENT', 'PRIVATE_REPL_FOLDER_PRESENT', 'DFSR_SERVICE_RUNNING', 'C1FS_MEMBERSHIP_PRESENT') -CheckDescription 'On C1-DC1, confirm the Company 1 DFS namespace root plus public/private replication, DFSR service, replicated-folder, and C1FS membership evidence exist.' -CommandLines @(
        'Get-DfsnRoot'
        'Get-DfsnFolder -Path "\\c1.local\\namespace\\*"'
        'Get-DfsReplicationGroup'
        'Get-DfsReplicatedFolder -GroupName *'
        'Get-DfsrMembership'
        'Get-Service DFSR'
    ) -ScriptBlock {
        Import-Module Dfsn -ErrorAction SilentlyContinue
        Import-Module DFSR -ErrorAction SilentlyContinue

        $roots = @(Get-DfsnRoot -ErrorAction SilentlyContinue)
        $folders = @(Get-DfsnFolder -Path '\\c1.local\namespace\*' -ErrorAction SilentlyContinue)
        $groups = @(Get-DfsReplicationGroup -ErrorAction SilentlyContinue)
        $replicatedFolders = @(Get-DfsReplicatedFolder -GroupName * -ErrorAction SilentlyContinue)
        $memberships = @(Get-DfsrMembership -GroupName * -ErrorAction SilentlyContinue)
        $dfsrService = Get-Service DFSR -ErrorAction SilentlyContinue
        $publicMembership = @(
            $memberships |
                Where-Object {
                    ([string]$_.GroupName).ToLowerInvariant() -match 'public' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\public*' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\pub_s2*'
                }
        )
        $privateMembership = @(
            $memberships |
                Where-Object {
                    ([string]$_.GroupName).ToLowerInvariant() -match 'private' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\private*' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\priv_s2*'
                }
        )
        $c1fsMembership = @($memberships | Where-Object { $_.ComputerName -eq 'C1FS' -or $_.ContentPath -like 'F:\Pub_S2*' -or $_.ContentPath -like 'F:\Priv_S2*' })
        $publicReplicatedFolders = @(
            $replicatedFolders |
                Where-Object {
                    ([string]$_.FolderName).ToLowerInvariant() -match 'public' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\public*' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\pub_s2*'
                }
        )
        $privateReplicatedFolders = @(
            $replicatedFolders |
                Where-Object {
                    ([string]$_.FolderName).ToLowerInvariant() -match 'private' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\private*' -or
                    ([string]$_.ContentPath).ToLowerInvariant() -like '*\priv_s2*'
                }
        )

        if ($roots.Count -gt 0) { 'DFSN_ROOT_PRESENT' } else { 'DFSN_ROOT_MISSING' }
        if ($groups.Count -gt 0) { 'DFSR_GROUP_PRESENT' } else { 'DFSR_GROUP_MISSING' }
        if ($publicMembership.Count -gt 0) { 'PUBLIC_REPLICATION_EVIDENCE_PRESENT' } else { 'PUBLIC_REPLICATION_EVIDENCE_MISSING' }
        if ($privateMembership.Count -gt 0) { 'PRIVATE_REPLICATION_EVIDENCE_PRESENT' } else { 'PRIVATE_REPLICATION_EVIDENCE_MISSING' }
        if ($publicReplicatedFolders.Count -gt 0) { 'PUBLIC_REPL_FOLDER_PRESENT' } else { 'PUBLIC_REPL_FOLDER_MISSING' }
        if ($privateReplicatedFolders.Count -gt 0) { 'PRIVATE_REPL_FOLDER_PRESENT' } else { 'PRIVATE_REPL_FOLDER_MISSING' }
        if ($dfsrService -and $dfsrService.Status -eq 'Running') { 'DFSR_SERVICE_RUNNING' } else { 'DFSR_SERVICE_NOT_RUNNING' }
        if ($c1fsMembership.Count -gt 0) { 'C1FS_MEMBERSHIP_PRESENT' } else { 'C1FS_MEMBERSHIP_MISSING' }
        if ($folders.Count -gt 0) { 'DFSN_FOLDER_ENUMERATION_AVAILABLE' } else { 'DFSN_FOLDER_ENUMERATION_UNAVAILABLE' }

        $roots | Format-Table -HideTableHeaders Path, State
        $folders | Select-Object -First 10 Path, State | Format-Table -HideTableHeaders
        $groups | Format-Table -HideTableHeaders GroupName, DomainName
        $replicatedFolders | Select-Object -First 10 GroupName, FolderName, ContentPath | Format-Table -HideTableHeaders
        $memberships | Select-Object -First 10 GroupName, ComputerName, ContentPath | Format-Table -HideTableHeaders
        if ($dfsrService) {
            $dfsrService | Format-Table -HideTableHeaders Name, Status
        }
    }

    Invoke-ToolkitWinrmTest -Name 'C1 SMB share definitions' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @('PUB1_SHARE_PRESENT', 'PRIV1_SHARE_PRESENT') -CheckDescription 'On C1-DC1, confirm the published Company 1 SMB shares already exist.' -CommandLines @(
        'Get-SmbShare'
    ) -ScriptBlock {
        $shares = @(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @('Pub1', 'Priv1') })
        if ($shares.Name -contains 'Pub1') { 'PUB1_SHARE_PRESENT' } else { 'PUB1_SHARE_MISSING' }
        if ($shares.Name -contains 'Priv1') { 'PRIV1_SHARE_PRESENT' } else { 'PRIV1_SHARE_MISSING' }
        $shares | Format-Table -HideTableHeaders Name, Path, Description
    }

    Invoke-ToolkitWinrmTest -Name 'C1-DC1 iSCSI initiator summary' -ComputerName (Get-ToolkitHost 'C1DC1').Address -Device 'C1-DC1' -DocSection 'Service Block 4 / ISCSI' -SuccessPatterns @('ISCSI_SESSION_PRESENT', 'SAN_DISK_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-DC1, confirm the Company 1 SAN initiator has an active iSCSI session and attached disk.' -CommandLines @(
        'Get-IscsiSession'
        'Get-Disk'
    ) -ScriptBlock {
        $sessions = @(Get-IscsiSession -ErrorAction SilentlyContinue | Where-Object { $_.IsConnected })
        $disks = @(Get-Disk -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like 'MSFT Virtual HD*' })

        if ($sessions.Count -gt 0) { 'ISCSI_SESSION_PRESENT' } else { 'ISCSI_SESSION_MISSING' }
        if ($disks.Count -gt 0) { 'SAN_DISK_PRESENT' } else { 'SAN_DISK_MISSING' }

        $sessions | Format-Table -HideTableHeaders TargetNodeAddress, InitiatorPortalAddress, IsConnected
        $disks | Format-Table -HideTableHeaders Number, FriendlyName, OperationalStatus, Size
    }

    Invoke-ToolkitWinrmTest -Name 'C1-DC2 iSCSI initiator summary' -ComputerName (Get-ToolkitHost 'C1DC2').Address -Device 'C1-DC2' -DocSection 'Service Block 4 / ISCSI' -SuccessPatterns @('ISCSI_SESSION_PRESENT', 'SAN_DISK_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-DC2, confirm the Company 1 SAN initiator has an active iSCSI session and attached disk.' -CommandLines @(
        'Get-IscsiSession'
        'Get-Disk'
    ) -ScriptBlock {
        $sessions = @(Get-IscsiSession -ErrorAction SilentlyContinue | Where-Object { $_.IsConnected })
        $disks = @(Get-Disk -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like 'MSFT Virtual HD*' })

        if ($sessions.Count -gt 0) { 'ISCSI_SESSION_PRESENT' } else { 'ISCSI_SESSION_MISSING' }
        if ($disks.Count -gt 0) { 'SAN_DISK_PRESENT' } else { 'SAN_DISK_MISSING' }

        $sessions | Format-Table -HideTableHeaders TargetNodeAddress, InitiatorPortalAddress, IsConnected
        $disks | Format-Table -HideTableHeaders Number, FriendlyName, OperationalStatus, Size
    }

    Invoke-ToolkitWinrmTest -Name 'C1-Client1 iSCSI initiator summary' -ComputerName (Get-ToolkitHost 'C1Client1').Address -Device 'C1-Client1' -DocSection 'Service Block 4 / ISCSI' -SuccessPatterns @('ISCSI_SESSION_PRESENT', 'SAN_DISK_PRESENT', 'SAN_DRIVE_S_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client1, confirm the Company 1 SAN initiator has an active iSCSI session, attached disk, and S: volume.' -CommandLines @(
        'Get-IscsiSession'
        'Get-Disk'
        'Get-Volume -DriveLetter S'
    ) -ScriptBlock {
        $sessions = @(Get-IscsiSession -ErrorAction SilentlyContinue | Where-Object { $_.IsConnected })
        $disks = @(Get-Disk -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like 'MSFT Virtual HD*' -or "$($_.BusType)" -eq 'iSCSI' })
        $volumes = @(Get-Volume -DriveLetter S -ErrorAction SilentlyContinue)

        if ($sessions.Count -gt 0) { 'ISCSI_SESSION_PRESENT' } else { 'ISCSI_SESSION_MISSING' }
        if ($disks.Count -gt 0) { 'SAN_DISK_PRESENT' } else { 'SAN_DISK_MISSING' }
        if ($volumes.Count -gt 0) { 'SAN_DRIVE_S_PRESENT' } else { 'SAN_DRIVE_S_MISSING' }

        $sessions | Format-Table -HideTableHeaders TargetNodeAddress, InitiatorPortalAddress, IsConnected
        $disks | Format-Table -HideTableHeaders Number, FriendlyName, BusType, OperationalStatus, Size
        $volumes | Format-Table -HideTableHeaders DriveLetter, FileSystemLabel, FileSystem, SizeRemaining, Size
    }

    Invoke-ToolkitSshTest -Name 'C1-Client2 iSCSI initiator summary' -Host (Get-ToolkitHost 'C1Client2').Address -User (Get-ToolkitHost 'C1Client2').LinuxUser -Device 'C1-Client2' -DocSection 'Service Block 4 / ISCSI' -SuccessPatterns @('ISCSI_SESSION_PRESENT', 'ISCSI_DISK_PATH_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client2, confirm the Company 1 Linux client has an active iSCSI session and a live SAN disk path from the dedicated VLAN 40 workflow.' -DisplayCommands @(
        'iscsiadm -m session'
        'ls -l /dev/disk/by-path | grep iscsi'
        'lsblk -ndo NAME,TYPE,SIZE,MODEL,TRAN'
    ) -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session || true',
        'ls -l /dev/disk/by-path 2>/dev/null | grep iscsi || true',
        'lsblk -ndo NAME,TYPE,SIZE,MODEL,TRAN || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session 2>/dev/null | grep -qE "iqn\\.|tcp:" && echo ISCSI_SESSION_PRESENT || echo ISCSI_SESSION_MISSING',
        'ls -l /dev/disk/by-path 2>/dev/null | grep -q "iscsi" && echo ISCSI_DISK_PATH_PRESENT || echo ISCSI_DISK_PATH_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C1-Client2 mounted share summary' -Host (Get-ToolkitHost 'C1Client2').Address -User (Get-ToolkitHost 'C1Client2').LinuxUser -Device 'C1-Client2' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @('C1_PUBLIC_MOUNT_PRESENT', 'C1_PRIVATE_MOUNT_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client2, confirm the Company 1 public and private shares are mounted.' -Commands @(
        'mount | grep -E "C1_Public|C1_Private" || true',
        'findmnt -t cifs,nfs || true',
        'grep -E "C1_Public|C1_Private" /etc/fstab 2>/dev/null || true',
        'mount | grep -q "C1_Public" && echo C1_PUBLIC_MOUNT_PRESENT || echo C1_PUBLIC_MOUNT_MISSING',
        'mount | grep -q "C1_Private" && echo C1_PRIVATE_MOUNT_PRESENT || echo C1_PRIVATE_MOUNT_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C1-Client2 per-user share mount summary' -Host (Get-ToolkitHost 'C1Client2').Address -User (Get-ToolkitHost 'C1Client2').LinuxUser -Device 'C1-Client2' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @(
        'ADMIN_CRED_PRESENT',
        'EMPLOYEE1_CRED_PRESENT',
        'EMPLOYEE2_CRED_PRESENT',
        'ADMIN_PUBLIC_MOUNT_PRESENT', 'ADMIN_PUBLIC_USERNAME_OK', 'ADMIN_PUBLIC_DOMAIN_OK', 'ADMIN_PUBLIC_SELF_OK', 'ADMIN_PUBLIC_WRITE_OK',
        'ADMIN_PRIVATE_MOUNT_PRESENT', 'ADMIN_PRIVATE_USERNAME_OK', 'ADMIN_PRIVATE_DOMAIN_OK', 'ADMIN_PRIVATE_SELF_OK', 'ADMIN_PRIVATE_WRITE_OK',
        'EMPLOYEE1_PUBLIC_MOUNT_PRESENT', 'EMPLOYEE1_PUBLIC_USERNAME_OK', 'EMPLOYEE1_PUBLIC_DOMAIN_OK', 'EMPLOYEE1_PUBLIC_SELF_OK', 'EMPLOYEE1_PUBLIC_WRITE_OK',
        'EMPLOYEE1_PRIVATE_MOUNT_PRESENT', 'EMPLOYEE1_PRIVATE_USERNAME_OK', 'EMPLOYEE1_PRIVATE_DOMAIN_OK', 'EMPLOYEE1_PRIVATE_SELF_OK', 'EMPLOYEE1_PRIVATE_WRITE_OK',
        'EMPLOYEE2_PUBLIC_MOUNT_PRESENT', 'EMPLOYEE2_PUBLIC_USERNAME_OK', 'EMPLOYEE2_PUBLIC_DOMAIN_OK', 'EMPLOYEE2_PUBLIC_SELF_OK', 'EMPLOYEE2_PUBLIC_WRITE_OK',
        'EMPLOYEE2_PRIVATE_MOUNT_PRESENT', 'EMPLOYEE2_PRIVATE_USERNAME_OK', 'EMPLOYEE2_PRIVATE_DOMAIN_OK', 'EMPLOYEE2_PRIVATE_SELF_OK', 'EMPLOYEE2_PRIVATE_WRITE_OK'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client2, confirm admin plus the employee1@c1.local and employee2@c1.local workflows each have their own Company 1 public and private mounts with c1.local credentials in the mount options, can read them, and have write capability on the mounted directories.' -Commands @(
        (New-LinuxSessionWarmupCommands -Platform 'C1' -UserSpecs (Get-C1Client2LinuxUserSpecs))
        (New-LinuxPerUserMountCommands -SharePrefix 'C1' -DomainName 'c1.local' -UserSpecs (Get-C1Client2LinuxUserSpecs))
    )

    Invoke-ToolkitSshTest -Name 'C1-Client2 private share isolation' -Host (Get-ToolkitHost 'C1Client2').Address -User (Get-ToolkitHost 'C1Client2').LinuxUser -Device 'C1-Client2' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @(
        'EMPLOYEE1_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE2_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE1_SELF_PRIVATE_OK',
        'EMPLOYEE2_SELF_PRIVATE_OK',
        'EMPLOYEE1_BLOCKED_FROM_EMPLOYEE2_PRIVATE',
        'EMPLOYEE2_BLOCKED_FROM_EMPLOYEE1_PRIVATE'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-Client2, confirm employee1@c1.local and employee2@c1.local can each read their own Company 1 private mount but cannot read the other domain user''s private mount.' -Commands (New-LinuxPrivateIsolationCommands -LinuxPrefix 'C1' -Platform 'C1' -UserSpecs ((Get-C1Client2LinuxUserSpecs) | Where-Object { $_.Token -in @('EMPLOYEE1', 'EMPLOYEE2') }))

    Invoke-ToolkitWinrmTest -Name 'C1-Client1 mapped drive context summary' -ComputerName (Get-ToolkitHost 'C1Client1').Address -Device 'C1-Client1' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @(
        'CLIENT1_MAPPED_DRIVE_CONTEXT_PASS'
    ) -FailPatterns @(
        'CLIENT1_MAPPED_DRIVE_CONTEXT_FAIL'
    ) -ReviewPatterns @(
        'CLIENT1_MAPPED_DRIVE_CONTEXT_REVIEW'
    ) -MissingEvidenceStatus 'REVIEW' -ReviewGuidance 'The non-interactive WinRM validation context can confirm remembered mappings and live SMB backends, but it cannot safely impersonate the real admin, employee1, or employee2 DFS workflow on C1-Client1. Use the standard interactive C1-Client1 user-share walkthrough for final proof of Windows user access, isolation, and Public write behaviour.' -CheckDescription 'On C1-Client1, confirm the Company 1 mapped-drive definitions exist, capture the current DFS/SMB backend, and assess whether the DFS namespace is reachable from the current non-interactive validation context.' -CommandLines @(
        'Get-SmbMapping'
        'Get-SmbConnection'
        'cmd /c net use'
        'Get-ChildItem "\\c1.local\namespace\public"'
        'Get-ChildItem "\\c1.local\namespace\private"'
    ) -ScriptBlock {
        $mappings = @(Get-SmbMapping -ErrorAction SilentlyContinue)
        $connections = @(Get-SmbConnection -ErrorAction SilentlyContinue)
        $mappingText = ($mappings | Select-Object LocalPath, RemotePath, UserName, Status | Format-Table -HideTableHeaders | Out-String).Trim()
        $connectionText = ($connections | Select-Object ServerName, ShareName, UserName, Dialect | Format-Table -HideTableHeaders | Out-String).Trim()
        $netUse = (cmd /c 'net use') | Out-String
        $publicUnc = '\\c1.local\namespace\public'
        $privateUnc = '\\c1.local\namespace\private'

        $hasPublicRemote = ($mappings.RemotePath -contains '\\c1.local\namespace\public') -or ($netUse -match '\\\\c1\.local\\namespace\\public')
        $hasPrivateRemote = ($mappings.RemotePath -contains '\\c1.local\namespace\private') -or ($netUse -match '\\\\c1\.local\\namespace\\private')
        $hasPublicLetter = ($mappings.LocalPath -contains 'P:') -or ($netUse -match 'P:')
        $hasPrivateLetter = ($mappings.LocalPath -contains 'H:') -or ($netUse -match 'H:')
        $publicUncAccess = $false
        $privateUncAccess = $false
        $publicUncError = $null
        $privateUncError = $null
        $publicAccessDenied = $false
        $privateAccessDenied = $false
        $mappingUnavailable = @($mappings | Where-Object { "$($_.Status)" -eq 'Unavailable' }).Count -gt 0
        $mappingDefinitionsPresent = $hasPublicRemote -and $hasPrivateRemote -and $hasPublicLetter -and $hasPrivateLetter

        try {
            Get-ChildItem $publicUnc -ErrorAction Stop | Out-Null
            $publicUncAccess = $true
        }
        catch {
            $publicUncError = $_.Exception.Message
            if ($publicUncError -match 'Access is denied') {
                $publicAccessDenied = $true
            }
            $publicUncAccess = $false
        }

        try {
            Get-ChildItem $privateUnc -ErrorAction Stop | Out-Null
            $privateUncAccess = $true
        }
        catch {
            $privateUncError = $_.Exception.Message
            if ($privateUncError -match 'Access is denied') {
                $privateAccessDenied = $true
            }
            $privateUncAccess = $false
        }

        if ($hasPublicRemote) { 'PUBLIC_DRIVE_MAPPING_PRESENT' } else { 'PUBLIC_DRIVE_MAPPING_MISSING' }
        if ($hasPrivateRemote) { 'PRIVATE_DRIVE_MAPPING_PRESENT' } else { 'PRIVATE_DRIVE_MAPPING_MISSING' }
        if ($hasPublicLetter) { 'PUBLIC_DRIVE_LETTER_PRESENT' } else { 'PUBLIC_DRIVE_LETTER_MISSING' }
        if ($hasPrivateLetter) { 'PRIVATE_DRIVE_LETTER_PRESENT' } else { 'PRIVATE_DRIVE_LETTER_MISSING' }
        if ($publicUncAccess) { 'PUBLIC_UNC_ACCESS_OK' } elseif ($publicAccessDenied) { 'PUBLIC_UNC_ACCESS_DENIED' } else { 'PUBLIC_UNC_ACCESS_FAIL' }
        if ($privateUncAccess) { 'PRIVATE_UNC_ACCESS_OK' } elseif ($privateAccessDenied) { 'PRIVATE_UNC_ACCESS_DENIED' } else { 'PRIVATE_UNC_ACCESS_FAIL' }
        if ($mappingUnavailable) { 'MAPPED_DRIVE_STATUS_UNAVAILABLE' } else { 'MAPPED_DRIVE_STATUS_CONNECTED' }

        if ($mappingDefinitionsPresent -and $publicUncAccess -and $privateUncAccess) {
            'CLIENT1_MAPPED_DRIVE_CONTEXT_PASS'
        }
        elseif (-not $mappingDefinitionsPresent) {
            'CLIENT1_MAPPED_DRIVE_CONTEXT_FAIL'
        }
        else {
            'CLIENT1_MAPPED_DRIVE_CONTEXT_REVIEW'
        }

        if ($mappingText) {
            $mappingText
        }
        else {
            '[no Get-SmbMapping output returned]'
        }

        if ($connectionText) {
            $connectionText
        }
        else {
            '[no Get-SmbConnection output returned]'
        }

        $netUse.Trim()
        'PUBLIC_UNC=' + $publicUnc
        'PRIVATE_UNC=' + $privateUnc
        'PUBLIC_UNC_ERROR=' + ($(if ($publicUncError) { $publicUncError } else { '[none]' }))
        'PRIVATE_UNC_ERROR=' + ($(if ($privateUncError) { $privateUncError } else { '[none]' }))
    }
}

function Invoke-SB4-Hotseat2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitSshTest -Name 'C2 Gluster, Samba, and iSCSI primary summary' -Host (Get-ToolkitHost 'C2DC1').Address -User (Get-ToolkitHost 'C2DC1').LinuxUser -Device 'C2-DC1' -DocSection 'Service Block 4 / Replicated File Server and ISCSI' -SuccessPatterns @('C2_SAN_SESSION_PRESENT', 'GLUSTER_VOLUME_PRESENT', 'GLUSTER_BRICKS_ONLINE', 'BRICK_MOUNT_PRESENT', 'SYNC_DISK_MOUNT_PRESENT', 'C2_PUBLIC_SHARE_PRESENT', 'C2_PRIVATE_SHARE_PRESENT', 'C2_PRIVATE_PATH_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-DC1, confirm the Gluster replicate volume, Samba public/private share definitions, dedicated SAN session, and mounted storage paths are present.' -DisplayCommands @(
        'iscsiadm -m session'
        'gluster volume info gv0'
        'gluster volume status gv0'
        'findmnt /data/brick1'
        'mount | grep "/mnt/sync_disk"'
        'grep -n "\[C2_Public\]\|\[C2_Private\]\|/mnt/sync_disk/Private/%U" /etc/samba/smb.conf'
    ) -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume info gv0 || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume status gv0 || true',
        'findmnt /data/brick1 || true',
        'mount | grep "/mnt/sync_disk" || true',
        'grep -nE "\\[C2_Public\\]|\\[C2_Private\\]|/mnt/sync_disk/Private/%U" /etc/samba/smb.conf || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session 2>/dev/null | grep -q "172.30.64.194:3260" && echo C2_SAN_SESSION_PRESENT || echo C2_SAN_SESSION_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume info gv0 2>/dev/null | grep -q "Volume Name: gv0" && echo GLUSTER_VOLUME_PRESENT || echo GLUSTER_VOLUME_MISSING',
        'count="$(printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume status gv0 2>/dev/null | awk ''/^Brick / && $5 == "Y" { count++ } END { print count+0 }'')"; [ "$count" -ge 2 ] && echo GLUSTER_BRICKS_ONLINE || echo GLUSTER_BRICKS_OFFLINE',
        'findmnt /data/brick1 >/dev/null 2>&1 && echo BRICK_MOUNT_PRESENT || echo BRICK_MOUNT_MISSING',
        'mount | grep -q "/mnt/sync_disk" && echo SYNC_DISK_MOUNT_PRESENT || echo SYNC_DISK_MOUNT_MISSING',
        'grep -qE "^\\[C2_Public\\]" /etc/samba/smb.conf && echo C2_PUBLIC_SHARE_PRESENT || echo C2_PUBLIC_SHARE_MISSING',
        'grep -qE "^\\[C2_Private\\]" /etc/samba/smb.conf && echo C2_PRIVATE_SHARE_PRESENT || echo C2_PRIVATE_SHARE_MISSING',
        'grep -q "/mnt/sync_disk/Private/%U" /etc/samba/smb.conf && echo C2_PRIVATE_PATH_PRESENT || echo C2_PRIVATE_PATH_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C2 secondary storage node summary' -Host (Get-ToolkitHost 'C2DC2').Address -User (Get-ToolkitHost 'C2DC2').LinuxUser -Device 'C2-DC2' -DocSection 'Service Block 4 / Replicated File Server and ISCSI' -SuccessPatterns @('C2_SAN_SESSION_PRESENT', 'GLUSTER_BRICKS_ONLINE', 'BRICK_MOUNT_PRESENT', 'SYNC_DISK_MOUNT_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-DC2, confirm the secondary storage node participates in the same Gluster and iSCSI design.' -DisplayCommands @(
        'iscsiadm -m session'
        'gluster volume status gv0'
        'findmnt /data/brick1'
        'mount | grep "/mnt/sync_disk"'
    ) -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume status gv0 || true',
        'findmnt /data/brick1 || true',
        'mount | grep "/mnt/sync_disk" || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session 2>/dev/null | grep -q "172.30.64.194:3260" && echo C2_SAN_SESSION_PRESENT || echo C2_SAN_SESSION_MISSING',
        'count="$(printf "%s\n" "Cisco123!" | sudo -S -p "" gluster volume status gv0 2>/dev/null | awk ''/^Brick / && $5 == "Y" { count++ } END { print count+0 }'')"; [ "$count" -ge 2 ] && echo GLUSTER_BRICKS_ONLINE || echo GLUSTER_BRICKS_OFFLINE',
        'findmnt /data/brick1 >/dev/null 2>&1 && echo BRICK_MOUNT_PRESENT || echo BRICK_MOUNT_MISSING',
        'mount | grep -q "/mnt/sync_disk" && echo SYNC_DISK_MOUNT_PRESENT || echo SYNC_DISK_MOUNT_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C2-Client1 mounted share summary' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @('C2_PUBLIC_MOUNT_PRESENT', 'C2_PRIVATE_MOUNT_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-Client1, confirm the Company 2 public and private shares are mounted, including the domain-user home targets reached after successful employee1@c2.local and employee2@c2.local login sessions.' -Commands @(
        'mount | grep -E "C2_Public|C2_Private" || true',
        'findmnt -t cifs,nfs || true',
        'grep -E "C2_Public|C2_Private" /etc/fstab 2>/dev/null || true',
        'mount | grep -q "C2_Public" && echo C2_PUBLIC_MOUNT_PRESENT || echo C2_PUBLIC_MOUNT_MISSING',
        'mount | grep -q "C2_Private" && echo C2_PRIVATE_MOUNT_PRESENT || echo C2_PRIVATE_MOUNT_MISSING'
    )

    Invoke-ToolkitSshTest -Name 'C2-Client1 per-user share mount summary' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @(
        'ADMIN_CRED_PRESENT',
        'EMPLOYEE1_CRED_PRESENT',
        'EMPLOYEE2_CRED_PRESENT',
        'ADMIN_PUBLIC_MOUNT_PRESENT', 'ADMIN_PUBLIC_USERNAME_OK', 'ADMIN_PUBLIC_DOMAIN_OK', 'ADMIN_PUBLIC_SELF_OK', 'ADMIN_PUBLIC_WRITE_OK',
        'ADMIN_PRIVATE_MOUNT_PRESENT', 'ADMIN_PRIVATE_USERNAME_OK', 'ADMIN_PRIVATE_DOMAIN_OK', 'ADMIN_PRIVATE_SELF_OK', 'ADMIN_PRIVATE_WRITE_OK',
        'EMPLOYEE1_PUBLIC_MOUNT_PRESENT', 'EMPLOYEE1_PUBLIC_USERNAME_OK', 'EMPLOYEE1_PUBLIC_DOMAIN_OK', 'EMPLOYEE1_PUBLIC_SELF_OK', 'EMPLOYEE1_PUBLIC_WRITE_OK',
        'EMPLOYEE1_PRIVATE_MOUNT_PRESENT', 'EMPLOYEE1_PRIVATE_USERNAME_OK', 'EMPLOYEE1_PRIVATE_DOMAIN_OK', 'EMPLOYEE1_PRIVATE_SELF_OK', 'EMPLOYEE1_PRIVATE_WRITE_OK',
        'EMPLOYEE2_PUBLIC_MOUNT_PRESENT', 'EMPLOYEE2_PUBLIC_USERNAME_OK', 'EMPLOYEE2_PUBLIC_DOMAIN_OK', 'EMPLOYEE2_PUBLIC_SELF_OK', 'EMPLOYEE2_PUBLIC_WRITE_OK',
        'EMPLOYEE2_PRIVATE_MOUNT_PRESENT', 'EMPLOYEE2_PRIVATE_USERNAME_OK', 'EMPLOYEE2_PRIVATE_DOMAIN_OK', 'EMPLOYEE2_PRIVATE_SELF_OK', 'EMPLOYEE2_PRIVATE_WRITE_OK'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-Client1, confirm admin plus the employee1@c2.local and employee2@c2.local login workflows each reach their own Linux home directory, receive the correct Company 2 public and private mounts with c2.local credentials in the mount options, can read them, and have write capability on the mounted directories.' -Commands @(
        (New-LinuxSessionWarmupCommands -Platform 'C2' -UserSpecs (Get-C2Client1LinuxUserSpecs))
        (New-LinuxPerUserMountCommands -SharePrefix 'C2' -DomainName 'c2.local' -UserSpecs (Get-C2Client1LinuxUserSpecs))
    )

    Invoke-ToolkitSshTest -Name 'C2-Client1 private share isolation' -Host (Get-ToolkitHost 'C2Client1').Address -User (Get-ToolkitHost 'C2Client1').LinuxUser -Device 'C2-Client1' -DocSection 'Service Block 4 / Replicated File Server' -SuccessPatterns @(
        'EMPLOYEE1_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE2_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE1_SELF_PRIVATE_OK',
        'EMPLOYEE2_SELF_PRIVATE_OK',
        'EMPLOYEE1_BLOCKED_FROM_EMPLOYEE2_PRIVATE',
        'EMPLOYEE2_BLOCKED_FROM_EMPLOYEE1_PRIVATE'
    ) -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-Client1, confirm employee1@c2.local and employee2@c2.local can each read their own Company 2 private mount but cannot read the other domain user''s private mount.' -Commands (New-LinuxPrivateIsolationCommands -LinuxPrefix 'C2' -Platform 'C2' -UserSpecs ((Get-C2Client1LinuxUserSpecs) | Where-Object { $_.Token -in @('EMPLOYEE1', 'EMPLOYEE2') }))
}

function Invoke-SB5-Hotseat1Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitWinrmTest -Name 'Server2 Veeam services and repository drives' -ComputerName (Get-ToolkitHost 'Server2').Address -Device 'Server2' -DocSection 'Service Block 5 / VEEAM' -SuccessPatterns @('VEEAM_SERVICES_PRESENT', 'REPO_DRIVES_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On Server2, confirm Veeam services are running and the expected repository drives are mounted.' -CommandLines @(
        'Get-Service *Veeam*'
        'Get-PSDrive -PSProvider FileSystem'
    ) -ScriptBlock {
        $runningServices = @(Get-Service *Veeam* -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' })
        $runningCount = $runningServices.Count
        $repoDriveObjects = @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -in @('R', 'S', 'T', 'V') })
        $repoDrives = $repoDriveObjects.Name -join ','

        if ($runningCount -gt 0) { 'VEEAM_SERVICES_PRESENT' } else { 'VEEAM_SERVICES_MISSING' }
        if ((@('R', 'S', 'T', 'V') | Where-Object { $_ -in $repoDriveObjects.Name }).Count -eq 4) { 'REPO_DRIVES_PRESENT' } else { 'REPO_DRIVES_MISSING' }
        'RUNNING_VEEAM_SERVICES=' + $runningCount
        'REPO_DRIVES=' + $repoDrives
        $runningServices | Format-Table -HideTableHeaders Name, Status
    }

    Invoke-ToolkitWinrmTest -Name 'Server2 Veeam job and repository inventory' -ComputerName (Get-ToolkitHost 'Server2').Address -Device 'Server2' -DocSection 'Service Block 5 / VEEAM' -SuccessPatterns @('VEEAM_POWERSHELL_PRESENT', 'JOBS_PRESENT', 'REPOSITORIES_PRESENT', 'OFFSITE_SHARED_REPO_PRESENT', 'OFFSITE_SHARED_REPO_PATH_OK', 'SITE1_TO_SITE2_COPY_JOB_PRESENT', 'RECENT_SESSION_SUCCESS_PRESENT', 'RECENT_COPY_SESSION_SUCCESS_PRESENT') -CheckDescription 'On Server2, load the Veeam PowerShell interface and confirm the expected jobs, repositories, offsite copy target, and recent successful session evidence are present.' -CommandLines @(
        'Add-PSSnapin VeeamPSSnapIn or Import-Module Veeam.Backup.PowerShell -DisableNameChecking'
        'Get-VBRJob / Get-VBRComputerBackupJob / Get-VBRBackupCopyJob'
        'Get-VBRBackupRepository'
        'Get-VBRBackupSession'
    ) -ScriptBlock {
        function Get-VeeamJobInventory {
            $jobCollections = @()

            if (Get-Command Get-VBRJob -ErrorAction SilentlyContinue) {
                $jobCollections += @(Get-VBRJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
            }
            if (Get-Command Get-VBRComputerBackupJob -ErrorAction SilentlyContinue) {
                $jobCollections += @(Get-VBRComputerBackupJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
            }
            if (Get-Command Get-VBRBackupCopyJob -ErrorAction SilentlyContinue) {
                $jobCollections += @(Get-VBRBackupCopyJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
            }

            $jobCollections |
                Where-Object { $_ } |
                Select-Object Name, JobType, IsScheduleEnabled |
                Sort-Object Name, JobType -Unique
        }

        $loaded = $false
        $loadSource = $null
        try {
            Add-PSSnapin VeeamPSSnapIn -ErrorAction Stop
            $loaded = $true
            $loadSource = 'VeeamPSSnapIn'
        }
        catch {
            try {
                Import-Module Veeam.Backup.PowerShell -DisableNameChecking -ErrorAction Stop
                $loaded = $true
                $loadSource = 'Veeam.Backup.PowerShell'
            }
            catch {
                $loaded = $false
            }
        }

        if (-not $loaded) {
            $candidatePaths = @(
                'C:\Program Files\Veeam\Backup and Replication\Backup\Modules\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1',
                'C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1',
                'C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell',
                'C:\Program Files\Veeam\Backup and Replication\Backup\Veeam.Backup.PowerShell.dll',
                'C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell.dll'
            ) | Where-Object { Test-Path $_ }

            foreach ($candidatePath in $candidatePaths) {
                try {
                    Import-Module $candidatePath -DisableNameChecking -ErrorAction Stop
                    $loaded = $true
                    $loadSource = $candidatePath
                    break
                }
                catch {
                    $loaded = $false
                }
            }
        }

        if ($loaded) {
            'VEEAM_POWERSHELL_PRESENT'
            if ($loadSource) { 'VEEAM_POWERSHELL_SOURCE=' + $loadSource }
            $jobs = @(Get-VeeamJobInventory)
            $repositories = @(Get-VBRBackupRepository -ErrorAction SilentlyContinue)
            $sessions = @(Get-VBRBackupSession -ErrorAction SilentlyContinue | Sort-Object EndTime -Descending | Select-Object -First 10)
            $offsiteRepo = @($repositories | Where-Object { $_.Name -eq 'Site2-Offsite-SharedRepo' } | Select-Object -First 1)
            $copyJob = @($jobs | Where-Object { $_.Name -eq 'Site1-to-Site2 Backup Copy' } | Select-Object -First 1)
            $recentSuccess = @($sessions | Where-Object { "$($_.Result)" -eq 'Success' })
            $recentCopySuccess = @($sessions | Where-Object { $_.Name -like 'Site1-to-Site2 Backup Copy*' -and "$($_.Result)" -eq 'Success' })

            if ($jobs.Count -gt 0) { 'JOBS_PRESENT' } else { 'JOBS_MISSING' }
            'JOB_COUNT=' + $jobs.Count
            $jobs | Select-Object -First 10 Name, JobType, IsScheduleEnabled | Format-Table -HideTableHeaders

            if ($repositories.Count -gt 0) { 'REPOSITORIES_PRESENT' } else { 'REPOSITORIES_MISSING' }
            'REPOSITORY_COUNT=' + $repositories.Count
            $repositories | Select-Object -First 10 Name, Path, Type | Format-Table -HideTableHeaders

            if ($offsiteRepo.Count -gt 0) { 'OFFSITE_SHARED_REPO_PRESENT' } else { 'OFFSITE_SHARED_REPO_MISSING' }
            if ($offsiteRepo.Count -gt 0 -and $offsiteRepo[0].Path -like '\\172.30.65.180\Site1OffsiteFromServer2$\Repo*') {
                'OFFSITE_SHARED_REPO_PATH_OK'
            }
            else {
                'OFFSITE_SHARED_REPO_PATH_MISMATCH'
            }
            if ($offsiteRepo.Count -gt 0) {
                $offsiteRepo | Select-Object Name, Path, Type | Format-Table -HideTableHeaders
            }

            if ($copyJob.Count -gt 0) { 'SITE1_TO_SITE2_COPY_JOB_PRESENT' } else { 'SITE1_TO_SITE2_COPY_JOB_MISSING' }
            if ($copyJob.Count -gt 0) {
                $copyJob | Select-Object Name, JobType, IsScheduleEnabled | Format-Table -HideTableHeaders
            }

            if ($recentSuccess.Count -gt 0) { 'RECENT_SESSION_SUCCESS_PRESENT' } else { 'RECENT_SESSION_SUCCESS_MISSING' }
            if ($recentCopySuccess.Count -gt 0) { 'RECENT_COPY_SESSION_SUCCESS_PRESENT' } else { 'RECENT_COPY_SESSION_SUCCESS_MISSING' }
            'SESSION_COUNT=' + $sessions.Count
            $sessions | Select-Object -First 10 Name, Result, EndTime | Format-Table -HideTableHeaders
            return
        }

        $pwshPath = 'C:\Program Files\PowerShell\7\pwsh.exe'
        if (-not (Test-Path $pwshPath)) {
            'VEEAM_POWERSHELL_REQUIRES_PWSH7'
            return
        }

        $ps7ModulePath = 'C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell\Veeam.Backup.PowerShell.psd1'
        if (-not (Test-Path $ps7ModulePath)) {
            'VEEAM_POWERSHELL_MISSING'
            return
        }

        $ps7Script = @'
function Get-VeeamJobInventory {
    $jobCollections = @()

    if (Get-Command Get-VBRJob -ErrorAction SilentlyContinue) {
        $jobCollections += @(Get-VBRJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
    }
    if (Get-Command Get-VBRComputerBackupJob -ErrorAction SilentlyContinue) {
        $jobCollections += @(Get-VBRComputerBackupJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
    }
    if (Get-Command Get-VBRBackupCopyJob -ErrorAction SilentlyContinue) {
        $jobCollections += @(Get-VBRBackupCopyJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
    }

    $jobCollections |
        Where-Object { $_ } |
        Select-Object Name, JobType, IsScheduleEnabled |
        Sort-Object Name, JobType -Unique
}

Import-Module '__MODULE_PATH__' -DisableNameChecking -ErrorAction Stop
'VEEAM_POWERSHELL_PRESENT'
'VEEAM_POWERSHELL_SOURCE=__MODULE_PATH__'
$jobs = @(Get-VeeamJobInventory)
$repositories = @(Get-VBRBackupRepository -ErrorAction SilentlyContinue)
$sessions = @(Get-VBRBackupSession -ErrorAction SilentlyContinue | Sort-Object EndTime -Descending | Select-Object -First 10)
$offsiteRepo = @($repositories | Where-Object { $_.Name -eq 'Site2-Offsite-SharedRepo' } | Select-Object -First 1)
$copyJob = @($jobs | Where-Object { $_.Name -eq 'Site1-to-Site2 Backup Copy' } | Select-Object -First 1)
$recentSuccess = @($sessions | Where-Object { "$($_.Result)" -eq 'Success' })
$recentCopySuccess = @($sessions | Where-Object { $_.Name -like 'Site1-to-Site2 Backup Copy*' -and "$($_.Result)" -eq 'Success' })
if ($jobs.Count -gt 0) { 'JOBS_PRESENT' } else { 'JOBS_MISSING' }
'JOB_COUNT=' + $jobs.Count
$jobs | Select-Object -First 10 Name, JobType, IsScheduleEnabled | Format-Table -HideTableHeaders
if ($repositories.Count -gt 0) { 'REPOSITORIES_PRESENT' } else { 'REPOSITORIES_MISSING' }
'REPOSITORY_COUNT=' + $repositories.Count
$repositories | Select-Object -First 10 Name, Path, Type | Format-Table -HideTableHeaders
if ($offsiteRepo.Count -gt 0) { 'OFFSITE_SHARED_REPO_PRESENT' } else { 'OFFSITE_SHARED_REPO_MISSING' }
if ($offsiteRepo.Count -gt 0 -and $offsiteRepo[0].Path -like '\\172.30.65.180\Site1OffsiteFromServer2$\Repo*') {
    'OFFSITE_SHARED_REPO_PATH_OK'
}
else {
    'OFFSITE_SHARED_REPO_PATH_MISMATCH'
}
if ($offsiteRepo.Count -gt 0) {
    $offsiteRepo | Select-Object Name, Path, Type | Format-Table -HideTableHeaders
}
if ($copyJob.Count -gt 0) { 'SITE1_TO_SITE2_COPY_JOB_PRESENT' } else { 'SITE1_TO_SITE2_COPY_JOB_MISSING' }
if ($copyJob.Count -gt 0) {
    $copyJob | Select-Object Name, JobType, IsScheduleEnabled | Format-Table -HideTableHeaders
}
if ($recentSuccess.Count -gt 0) { 'RECENT_SESSION_SUCCESS_PRESENT' } else { 'RECENT_SESSION_SUCCESS_MISSING' }
if ($recentCopySuccess.Count -gt 0) { 'RECENT_COPY_SESSION_SUCCESS_PRESENT' } else { 'RECENT_COPY_SESSION_SUCCESS_MISSING' }
'SESSION_COUNT=' + $sessions.Count
$sessions | Select-Object -First 10 Name, Result, EndTime | Format-Table -HideTableHeaders
'@
        $ps7Script = $ps7Script.Replace('__MODULE_PATH__', $ps7ModulePath.Replace("'", "''"))

        & $pwshPath -NoProfile -Command $ps7Script
    }

    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 shared repository SMB endpoint (Windows jumpbox)' -Address (Get-ToolkitHost 'Site2Repo').Address -Port 445 -Device 'Site 2 Offsite Shared Repository' -DocSection 'Service Block 5 / VEEAM' -CheckDescription 'From Jumpbox Windows, confirm the Site 2 shared repository SMB endpoint remains reachable for backup copy operations.' -CommandLines @('Test-NetConnection -ComputerName 172.30.65.180 -Port 445')
    Invoke-ToolkitSshTest -Name 'Site 2 shared repository SMB endpoint (Ubuntu jumpbox)' -Host (Get-ToolkitHost 'JumpboxUbuntu').Address -User (Get-ToolkitHost 'JumpboxUbuntu').LinuxUser -Device 'Jumpbox Ubuntu' -DocSection 'Service Block 5 / VEEAM' -SuccessPatterns @('SITE2_REPO_SMB_REACHABLE') -CheckDescription 'From Jumpbox Ubuntu, confirm the same Site 2 SMB path works as supporting evidence for offsite backup copy.' -Commands @(
        'nc -z -w 5 172.30.65.180 445 >/dev/null 2>&1 && echo SITE2_REPO_SMB_REACHABLE || echo SITE2_REPO_SMB_BLOCKED'
    )
}

function Invoke-SB5-Hotseat2Tests {
    [CmdletBinding()]
    param()

    Invoke-ToolkitLocalEndpointTest -Name 'Server1 iLO HTTPS endpoint' -Address (Get-ToolkitHost 'Server1iLO').Address -Port 443 -Device 'Server1 / Proxmox host iLO' -DocSection 'Service Block 5 / Misc' -CheckDescription 'Confirm the out-of-band management endpoint for Server1 is reachable on TCP 443.' -CommandLines @('Test-NetConnection -ComputerName 192.168.64.11 -Port 443')
    Invoke-ToolkitLocalEndpointTest -Name 'Server2 iLO HTTPS endpoint' -Address (Get-ToolkitHost 'Server2iLO').Address -Port 443 -Device 'Server2 iLO' -DocSection 'Service Block 5 / Misc' -CheckDescription 'Confirm the out-of-band management endpoint for Server2 is reachable on TCP 443.' -CommandLines @('Test-NetConnection -ComputerName 192.168.64.21 -Port 443')
}

function Invoke-ServiceBlock1 { [CmdletBinding()] param() Invoke-SB1-Hotseat1Tests; Invoke-SB1-Hotseat2Tests }
function Invoke-ServiceBlock2 { [CmdletBinding()] param() Invoke-SB2-Hotseat1Tests; Invoke-SB2-Hotseat2Tests }
function Invoke-ServiceBlock3 { [CmdletBinding()] param() Invoke-SB3-Hotseat1Tests; Invoke-SB3-Hotseat2Tests }
function Invoke-ServiceBlock4 { [CmdletBinding()] param() Invoke-SB4-Hotseat1Tests; Invoke-SB4-Hotseat2Tests }
function Invoke-ServiceBlock5 { [CmdletBinding()] param() Invoke-SB5-Hotseat1Tests; Invoke-SB5-Hotseat2Tests }

Export-ModuleMember -Function @(
    'Get-ServiceBlockCoverage',
    'Test-ServiceBlockCoverage',
    'Show-ServiceBlockCoverage',
    'Show-ServiceBlock5PhysicalInspectionGuide',
    'Invoke-SB1-Hotseat1Tests',
    'Invoke-SB1-Hotseat2Tests',
    'Invoke-SB2-Hotseat1Tests',
    'Invoke-SB2-Hotseat2Tests',
    'Invoke-SB3-Hotseat1Tests',
    'Invoke-SB3-Hotseat2Tests',
    'Invoke-SB4-Hotseat1Tests',
    'Invoke-SB4-Hotseat2Tests',
    'Invoke-SB5-Hotseat1Tests',
    'Invoke-SB5-Hotseat2Tests',
    'Invoke-ServiceBlock1',
    'Invoke-ServiceBlock2',
    'Invoke-ServiceBlock3',
    'Invoke-ServiceBlock4',
    'Invoke-ServiceBlock5'
)
