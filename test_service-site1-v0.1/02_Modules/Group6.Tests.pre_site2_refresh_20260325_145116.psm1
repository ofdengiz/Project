function Get-Group6Coverage {
    [CmdletBinding()]
    param()

    @(
        [pscustomobject]@{ Block = '1'; Hotseat = '1'; Area = 'Company 1 + MSP'; Coverage = 'Site 1 Company 1 core plus Site 2 Company 1 service-path validation.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '1'; Hotseat = '2'; Area = 'Company 2 + MSP'; Coverage = 'Site 1 Company 2 core plus Site 2 Company 2 identity and client validation.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '1'; Area = 'Company 1 + MSP'; Coverage = 'Company 1 DNS and hostname-only HTTPS across both sites.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '2'; Area = 'Company 2 + MSP'; Coverage = 'Company 2 DNS and hostname-only HTTPS across both sites.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '3'; Hotseat = '1'; Area = 'MSP control plane'; Coverage = 'Site 1 Proxmox/OPNsense proof plus Site 2 OPNsense management-plane validation.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '3'; Hotseat = '2'; Area = 'MSP inter-site policy'; Coverage = 'Inter-site SMB path plus Site 2 edge and OpenVPN policy walkthrough.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '4'; Hotseat = '1'; Area = 'Company 1 file services'; Coverage = 'Site 1 DFS/iSCSI/share proof plus Site 2 Company 1 file-path and SAN isolation validation.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '4'; Hotseat = '2'; Area = 'Company 2 file services'; Coverage = 'Site 1 and Site 2 Company 2 storage chain, mounted share, and private-isolation proof.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '5'; Hotseat = '1'; Area = 'MSP backup platform'; Coverage = 'Site 1 Veeam plus Site 2 S2Veeam control-path validation and offsite-copy policy walkthrough.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '5'; Hotseat = '2'; Area = 'Physical / miscellaneous'; Coverage = 'Site 1 iLO and rack/switch walkthrough plus Site 2 backup design interpretation.'; Mode = 'Automated + manual adjunct' }
    )
}

function Test-Group6Coverage {
    [CmdletBinding()]
    param()

    $coverage = Get-Group6Coverage
    $missingBlocks = 1..5 | Where-Object { $_.ToString() -notin $coverage.Block }
    if ($missingBlocks.Count -gt 0) {
        throw "Group 6 coverage is missing service block definitions for: $($missingBlocks -join ', ')"
    }

    foreach ($block in 1..5) {
        $hotseats = @($coverage | Where-Object { $_.Block -eq $block.ToString() } | Select-Object -ExpandProperty Hotseat -Unique)
        if ('1' -notin $hotseats -or '2' -notin $hotseats) {
            throw "Group 6 coverage for Service Block $block is missing one or more hotseat mappings."
        }
    }

    Write-Host 'Coverage check passed: Group 6 maps Service Blocks 1-5 across both hotseats with cross-site scope.' -ForegroundColor Green
}

function Show-Group6Coverage {
    [CmdletBinding()]
    param()

    Show-ToolkitHeader -Title 'Group 6 Coverage Review'
    foreach ($block in Get-Group6Coverage | Group-Object Block | Sort-Object Name) {
        Write-Host ("Service Block {0}" -f $block.Name) -ForegroundColor Cyan
        foreach ($item in $block.Group) {
            Write-Host ("  Hotseat {0} | {1} | {2}" -f $item.Hotseat, $item.Area, $item.Mode)
            Write-Host ("    {0}" -f $item.Coverage)
        }
        Write-Host ''
    }
}

function Show-Group6ManualGuide {
    [CmdletBinding()]
    param()

    Show-ToolkitHeader -Title 'Group 6 Manual Follow-Up Guide'
    Write-Host '1. Site 1 C1-Client1 interactive Public / Private walkthrough.' -ForegroundColor Yellow
    Write-Host '2. Site 2 OPNsense NAT, aliases, OpenVPN, and bounded inter-site policy walkthrough.' -ForegroundColor Yellow
    Write-Host '3. Site 2 Veeam design interpretation when deeper backup proof is needed.' -ForegroundColor Yellow
    Write-Host '4. Site 1 rack and switch baseline walkthrough.' -ForegroundColor Yellow
    Write-Host ''
}

function Resolve-Group6LinuxUserSpecs {
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

function Get-Group6C2DomainUserSpecs {
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

function New-Group6LinuxSessionWarmupCommands {
    param(
        [string[]]$Users,
        [object[]]$UserSpecs,

        [Parameter(Mandatory)]
        [ValidateSet('C2')]
        [string]$Platform
    )

    $commands = @()
    $specs = Resolve-Group6LinuxUserSpecs -Users $Users -UserSpecs $UserSpecs
    foreach ($spec in $specs) {
        $token = $spec.Token
        $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" test -f /etc/c2-share-creds/$($spec.CredentialKey).cred && echo ${token}_CRED_PRESENT || echo ${token}_CRED_MISSING"
        $commands += "printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" /usr/local/sbin/c2-share-session --mount-now `"$($spec.WarmupUser)`" || true"
    }

    return $commands
}

function New-Group6LinuxUserContextCommands {
    param(
        [string[]]$Users,
        [object[]]$UserSpecs
    )

    $commands = @()
    foreach ($spec in Resolve-Group6LinuxUserSpecs -Users $Users -UserSpecs $UserSpecs) {
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

function New-Group6LinuxPerUserMountCommands {
    param(
        [object[]]$UserSpecs,

        [Parameter(Mandatory)]
        [string]$SharePrefix,

        [Parameter(Mandatory)]
        [string]$DomainName
    )

    $commands = @()
    foreach ($spec in Resolve-Group6LinuxUserSpecs -UserSpecs $UserSpecs) {
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

function New-Group6LinuxPrivateIsolationCommands {
    param(
        [Parameter(Mandatory)]
        [string]$LinuxPrefix,

        [object[]]$UserSpecs
    )

    $commands = @()
    $specs = Resolve-Group6LinuxUserSpecs -UserSpecs $UserSpecs
    $employee1Spec = $specs | Where-Object { $_.Token -eq 'EMPLOYEE1' } | Select-Object -First 1
    $employee2Spec = $specs | Where-Object { $_.Token -eq 'EMPLOYEE2' } | Select-Object -First 1
    if (-not $employee1Spec -or -not $employee2Spec) {
        throw 'Private isolation checks require EMPLOYEE1 and EMPLOYEE2 user specs.'
    }

    $employee1Path = "$($employee1Spec.HomePath)/${LinuxPrefix}_Private"
    $employee2Path = "$($employee2Spec.HomePath)/${LinuxPrefix}_Private"
    $commands += New-Group6LinuxSessionWarmupCommands -Platform 'C2' -UserSpecs $specs
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

function Invoke-Group6Site2EntryTests {
    [CmdletBinding()]
    param()

    $jump64 = Get-ToolkitHost 'Site2Jump64'
    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'

    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 Jump64 RDP endpoint' -Address $jump64.Address -Port 3389 -Device $jump64.DisplayName -DocSection 'Group 6 / Site 2 entry path' -CheckDescription 'Confirm the Site 2 Windows bastion host is reachable over RDP from the current jumpbox.'
    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 MSPUbuntuJump SSH endpoint' -Address $mspJump.Address -Port 22 -Device $mspJump.DisplayName -DocSection 'Group 6 / Site 2 entry path' -CheckDescription 'Confirm the Site 2 MSP Ubuntu bastion host is reachable over SSH from the current jumpbox.'
}

function Invoke-Group6SB1Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'
    $c1WindowsClient = Get-ToolkitHost 'S2C1WindowsClient'
    $c1UbuntuClient = Get-ToolkitHost 'S2C1UbuntuClient'

    Invoke-Group6Site2EntryTests

    $mgmtCommands = @(
        "nc -z -w 3 172.30.65.2 53 >/dev/null 2>&1 && echo S2_C1DC1_DNS_OK || echo S2_C1DC1_DNS_FAIL",
        "nc -z -w 3 172.30.65.2 88 >/dev/null 2>&1 && echo S2_C1DC1_KERBEROS_OK || echo S2_C1DC1_KERBEROS_FAIL",
        "nc -z -w 3 172.30.65.2 389 >/dev/null 2>&1 && echo S2_C1DC1_LDAP_OK || echo S2_C1DC1_LDAP_FAIL",
        "nc -z -w 3 172.30.65.2 445 >/dev/null 2>&1 && echo S2_C1DC1_SMB_OK || echo S2_C1DC1_SMB_FAIL",
        "nc -z -w 3 172.30.65.2 3389 >/dev/null 2>&1 && echo S2_C1DC1_RDP_OK || echo S2_C1DC1_RDP_FAIL",
        "nc -z -w 3 172.30.65.2 5985 >/dev/null 2>&1 && echo S2_C1DC1_WINRM_OK || echo S2_C1DC1_WINRM_FAIL",
        "nc -z -w 3 172.30.65.3 53 >/dev/null 2>&1 && echo S2_C1DC2_DNS_OK || echo S2_C1DC2_DNS_FAIL",
        "nc -z -w 3 172.30.65.3 88 >/dev/null 2>&1 && echo S2_C1DC2_KERBEROS_OK || echo S2_C1DC2_KERBEROS_FAIL",
        "nc -z -w 3 172.30.65.3 389 >/dev/null 2>&1 && echo S2_C1DC2_LDAP_OK || echo S2_C1DC2_LDAP_FAIL",
        "nc -z -w 3 172.30.65.3 445 >/dev/null 2>&1 && echo S2_C1DC2_SMB_OK || echo S2_C1DC2_SMB_FAIL",
        "nc -z -w 3 172.30.65.3 3389 >/dev/null 2>&1 && echo S2_C1DC2_RDP_OK || echo S2_C1DC2_RDP_FAIL",
        "nc -z -w 3 172.30.65.3 5985 >/dev/null 2>&1 && echo S2_C1DC2_WINRM_OK || echo S2_C1DC2_WINRM_FAIL",
        "nc -z -w 3 172.30.65.4 445 >/dev/null 2>&1 && echo S2_C1FS_SMB_OK || echo S2_C1FS_SMB_FAIL",
        "nc -z -w 3 172.30.65.4 3389 >/dev/null 2>&1 && echo S2_C1FS_RDP_OK || echo S2_C1FS_RDP_FAIL",
        "nc -z -w 3 172.30.65.36 22 >/dev/null 2>&1 && echo S2_C1UBUNTU_SSH_OK || echo S2_C1UBUNTU_SSH_FAIL",
        "nc -z -w 3 172.30.65.162 443 >/dev/null 2>&1 && echo S2_C1WEB_HTTPS_OK || echo S2_C1WEB_HTTPS_FAIL",
        "nc -z -w 3 172.30.65.162 3389 >/dev/null 2>&1 && echo S2_C1WEB_RDP_OK || echo S2_C1WEB_RDP_FAIL",
        "nc -z -w 3 172.30.65.162 5985 >/dev/null 2>&1 && echo S2_C1WEB_WINRM_OK || echo S2_C1WEB_WINRM_FAIL"
    )
    $mgmtDisplay = @(
        'nc -z -w 3 172.30.65.2 53',
        'nc -z -w 3 172.30.65.2 88',
        'nc -z -w 3 172.30.65.2 389',
        'nc -z -w 3 172.30.65.2 445',
        'nc -z -w 3 172.30.65.2 3389',
        'nc -z -w 3 172.30.65.2 5985',
        'nc -z -w 3 172.30.65.3 53',
        'nc -z -w 3 172.30.65.3 88',
        'nc -z -w 3 172.30.65.3 389',
        'nc -z -w 3 172.30.65.3 445',
        'nc -z -w 3 172.30.65.3 3389',
        'nc -z -w 3 172.30.65.3 5985',
        'nc -z -w 3 172.30.65.4 445',
        'nc -z -w 3 172.30.65.4 3389',
        'nc -z -w 3 172.30.65.36 22',
        'nc -z -w 3 172.30.65.162 443',
        'nc -z -w 3 172.30.65.162 3389',
        'nc -z -w 3 172.30.65.162 5985'
    )
    Invoke-ToolkitSshTest -Name 'Site 2 Company 1 management-path reachability summary' -Host $mspJump.Address -User $mspJump.LinuxUser -Commands $mgmtCommands -DisplayCommands $mgmtDisplay -Device 'MSPUbuntuJump -> Site 2 C1 stack' -DocSection 'Service Block 1 / Hotseat 1 / Site 2 Company 1 path' -SuccessPatterns @(
        'S2_C1DC1_DNS_OK','S2_C1DC1_KERBEROS_OK','S2_C1DC1_LDAP_OK','S2_C1DC1_SMB_OK','S2_C1DC1_RDP_OK','S2_C1DC1_WINRM_OK',
        'S2_C1DC2_DNS_OK','S2_C1DC2_KERBEROS_OK','S2_C1DC2_LDAP_OK','S2_C1DC2_SMB_OK','S2_C1DC2_RDP_OK','S2_C1DC2_WINRM_OK',
        'S2_C1FS_SMB_OK','S2_C1FS_RDP_OK','S2_C1UBUNTU_SSH_OK','S2_C1WEB_HTTPS_OK','S2_C1WEB_RDP_OK','S2_C1WEB_WINRM_OK'
    ) -CheckDescription 'From Site 2 MSPUbuntuJump, confirm the approved Company 1 administrative path can reach directory, file, client, and web roles.'

    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 C1WindowsClient RDP endpoint' -Address $c1WindowsClient.Address -Port 3389 -Device $c1WindowsClient.DisplayName -DocSection 'Service Block 1 / Hotseat 1 / Site 2 Company 1 path' -CheckDescription 'Confirm the Site 2 Company 1 Windows client remains reachable over RDP from the current jumpbox.'

    Invoke-ToolkitWinrmTest -Name 'Site 2 C1WindowsClient domain-workstation summary' -ComputerName $c1WindowsClient.Address -Device $c1WindowsClient.DisplayName -DocSection 'Service Block 1 / Hotseat 1 / Site 2 Company 1 path' -ScriptBlock {
        $cs = Get-CimInstance Win32_ComputerSystem
        if ($cs.PartOfDomain -and $cs.Domain -eq 'c1.local') { 'DOMAIN_JOIN_OK' } else { 'DOMAIN_JOIN_FAIL' }
        $profiles = Get-CimInstance Win32_UserProfile | Select-Object LocalPath
        if ($profiles.LocalPath -contains 'C:\Users\admin') { 'ADMIN_PROFILE_PRESENT' } else { 'ADMIN_PROFILE_MISSING' }
        if ($profiles.LocalPath -contains 'C:\Users\employee1') { 'EMPLOYEE1_PROFILE_PRESENT' } else { 'EMPLOYEE1_PROFILE_MISSING' }
        if ($profiles.LocalPath -contains 'C:\Users\employee2') { 'EMPLOYEE2_PROFILE_PRESENT' } else { 'EMPLOYEE2_PROFILE_MISSING' }
        $cs | Format-List Name,Domain,PartOfDomain
        $profiles | Format-Table LocalPath -AutoSize
    } -CommandLines @(
        'Get-CimInstance Win32_ComputerSystem',
        'Get-CimInstance Win32_UserProfile'
    ) -SuccessPatterns @('DOMAIN_JOIN_OK', 'ADMIN_PROFILE_PRESENT', 'EMPLOYEE1_PROFILE_PRESENT', 'EMPLOYEE2_PROFILE_PRESENT') -CheckDescription 'On the Site 2 Company 1 Windows client, confirm the workstation is joined to c1.local and already contains the expected user profiles.'

    Invoke-ToolkitSshTest -Name 'Site 2 C1UbuntuClient realm-member summary' -Host $c1UbuntuClient.Address -User $c1UbuntuClient.LinuxUser -Device $c1UbuntuClient.DisplayName -DocSection 'Service Block 1 / Hotseat 1 / Site 2 Company 1 path' -Commands @(
        'host=$(hostnamectl --static); echo "HOSTNAME=$host"; echo "$host" | grep -Eiq "^c1" && echo HOSTNAME_OK || echo HOSTNAME_FAIL',
        'realm list',
        'realm list | grep -qi "^c1\\.local" && echo C1_REALM_OK || echo C1_REALM_FAIL',
        'realm list | grep -qi "configured: kerberos-member" && echo C1_KERBEROS_MEMBER_OK || echo C1_KERBEROS_MEMBER_FAIL',
        'whoami'
    ) -SuccessPatterns @('HOSTNAME_OK', 'C1_REALM_OK', 'C1_KERBEROS_MEMBER_OK') -CheckDescription 'On the Site 2 Company 1 Ubuntu client, confirm the host remains joined to the Company 1 realm.'
}

function Invoke-Group6SB1Hotseat2Site2Tests {
    [CmdletBinding()]
    param()

    $idm1 = Get-ToolkitHost 'S2C2IdM1'
    $idm2 = Get-ToolkitHost 'S2C2IdM2'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'
    $c2Specs = Get-Group6C2DomainUserSpecs

    foreach ($idm in @($idm1, $idm2)) {
        Invoke-ToolkitSshTest -Name ("{0} identity and DHCP summary" -f $idm.DisplayName) -Host $idm.Address -User $idm.LinuxUser -Device $idm.DisplayName -DocSection 'Service Block 1 / Hotseat 2 / Site 2 Company 2 path' -Commands @(
            'systemctl is-active samba-ad-dc | grep -qx "active" && echo SAMBA_ACTIVE || echo SAMBA_INACTIVE',
            'systemctl is-active isc-dhcp-server | grep -qx "active" && echo DHCP_ACTIVE || echo DHCP_INACTIVE',
            'host c1-webserver.c1.local 127.0.0.1 >/dev/null 2>&1 && echo C1WEB_OK || echo C1WEB_FAIL',
            'host c2-webserver.c2.local 127.0.0.1 >/dev/null 2>&1 && echo C2WEB_OK || echo C2WEB_FAIL',
            'host microsoft.com 127.0.0.1 >/dev/null 2>&1 && echo EXTERNAL_LOOKUP_OK || echo EXTERNAL_LOOKUP_FAIL',
            'host c1-webserver.c1.local 127.0.0.1',
            'host c2-webserver.c2.local 127.0.0.1',
            'host microsoft.com 127.0.0.1'
        ) -SuccessPatterns @('SAMBA_ACTIVE', 'DHCP_ACTIVE', 'C1WEB_OK', 'C2WEB_OK', 'EXTERNAL_LOOKUP_OK') -CheckDescription ("On {0}, confirm Samba AD, DHCP, internal namespace visibility, and recursive DNS remain healthy." -f $idm.DisplayName)
    }

    $userCommands = @('realm list')
    $userCommands += New-Group6LinuxUserContextCommands -UserSpecs $c2Specs
    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient user identity contexts' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 1 / Hotseat 2 / Site 2 Company 2 client' -Commands $userCommands -SuccessPatterns @(
        'ADMIN_ACCOUNT_PRESENT','ADMIN_HOME_PRESENT','ADMIN_IDENTITY_OK',
        'EMPLOYEE1_ACCOUNT_PRESENT','EMPLOYEE1_HOME_PRESENT','EMPLOYEE1_IDENTITY_OK','EMPLOYEE1_SESSION_OK','EMPLOYEE1_SESSION_HOME_OK',
        'EMPLOYEE2_ACCOUNT_PRESENT','EMPLOYEE2_HOME_PRESENT','EMPLOYEE2_IDENTITY_OK','EMPLOYEE2_SESSION_OK','EMPLOYEE2_SESSION_HOME_OK'
    ) -CheckDescription 'On the Site 2 Company 2 Linux client, confirm admin remains local and employee1@c2.local plus employee2@c2.local can complete real domain-user sessions.'

    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient lease and resolver summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 1 / Hotseat 2 / Site 2 Company 2 client' -Commands @(
        'hostnamectl --static',
        'nmcli dev show | egrep "IP4.ADDRESS|IP4.GATEWAY|IP4.DNS"',
        'nmcli dev show | grep -q "172.30.65.70/26" && echo CLIENT_IP_OK || echo CLIENT_IP_FAIL',
        'nmcli dev show | grep -q "172.30.65.65" && echo GATEWAY_OK || echo GATEWAY_FAIL',
        'nmcli dev show | grep -q "172.30.65.66" && echo DNS1_OK || echo DNS1_FAIL',
        'nmcli dev show | grep -q "172.30.65.67" && echo DNS2_OK || echo DNS2_FAIL',
        'realm list',
        'realm list | grep -qi "^c2\\.local" && echo C2_REALM_OK || echo C2_REALM_FAIL'
    ) -SuccessPatterns @('CLIENT_IP_OK', 'GATEWAY_OK', 'DNS1_OK', 'DNS2_OK', 'C2_REALM_OK') -CheckDescription 'On Site 2 C2LinuxClient, confirm the live address, gateway, DNS settings, and realm membership match the documented Company 2 design.'
}

function Invoke-Group6SB2Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'
    $c1UbuntuClient = Get-ToolkitHost 'S2C1UbuntuClient'

    Invoke-ToolkitSshTest -Name 'Site 2 Company 1 web hostname-only access summary' -Host $mspJump.Address -User $mspJump.LinuxUser -Device 'MSPUbuntuJump -> Site 2 C1 web' -DocSection 'Service Block 2 / Hotseat 1 / Site 2 Company 1 web' -Commands @(
        'code=$(curl -k -s -o /dev/null -w "%{http_code}" https://c1-webserver.c1.local/ || true); if [ "$code" = "200" ]; then echo S2_C1WEB_FQDN_OK; else echo S2_C1WEB_FQDN_FAIL:$code; fi',
        'code=$(curl -k -s -o /dev/null -w "%{http_code}" https://172.30.65.162/ || true); if [ "$code" = "403" ] || [ "$code" = "404" ] || [ "$code" = "000" ]; then echo S2_C1WEB_IP_HARDENED; else echo S2_C1WEB_IP_ALLOWED:$code; fi'
    ) -DisplayCommands @(
        'curl -k -s -o /dev/null -w "%{http_code}" https://c1-webserver.c1.local/',
        'curl -k -s -o /dev/null -w "%{http_code}" https://172.30.65.162/'
    ) -SuccessPatterns @('S2_C1WEB_FQDN_OK', 'S2_C1WEB_IP_HARDENED') -CheckDescription 'From Site 2 MSPUbuntuJump, confirm Company 1 web access succeeds via FQDN and direct-IP HTTPS is hardened.'

    Invoke-ToolkitSshTest -Name 'Site 2 C1UbuntuClient dual-web validation' -Host $c1UbuntuClient.Address -User $c1UbuntuClient.LinuxUser -Device $c1UbuntuClient.DisplayName -DocSection 'Service Block 2 / Hotseat 1 / Site 2 Company 1 client' -Commands @(
        'curl -k -s -o /dev/null -w "S2_C1CLIENT_C1WEB_STATUS=%{http_code}\n" https://c1-webserver.c1.local/',
        'curl -k -s https://c1-webserver.c1.local/ >/dev/null 2>&1 && echo S2_C1CLIENT_C1WEB_OK || echo S2_C1CLIENT_C1WEB_FAIL',
        'curl -k -s -o /dev/null -w "S2_C1CLIENT_C2WEB_STATUS=%{http_code}\n" https://c2-webserver.c2.local/',
        'curl -k -s https://c2-webserver.c2.local/ >/dev/null 2>&1 && echo S2_C1CLIENT_C2WEB_OK || echo S2_C1CLIENT_C2WEB_FAIL'
    ) -SuccessPatterns @('S2_C1CLIENT_C1WEB_OK', 'S2_C1CLIENT_C2WEB_OK') -CheckDescription 'From the Site 2 Company 1 Ubuntu client, confirm both tenant web hostnames resolve and return valid HTTPS responses.'
}

function Invoke-Group6SB2Hotseat2Site2Tests {
    [CmdletBinding()]
    param()

    $idm1 = Get-ToolkitHost 'S2C2IdM1'
    $idm2 = Get-ToolkitHost 'S2C2IdM2'
    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'

    foreach ($idm in @($idm1, $idm2)) {
        Invoke-ToolkitSshTest -Name ("{0} dual-web namespace visibility" -f $idm.DisplayName) -Host $idm.Address -User $idm.LinuxUser -Device $idm.DisplayName -DocSection 'Service Block 2 / Hotseat 2 / Site 2 namespace visibility' -Commands @(
            'host c1-webserver.c1.local 127.0.0.1 >/dev/null 2>&1 && echo C1WEB_OK || echo C1WEB_FAIL',
            'host c2-webserver.c2.local 127.0.0.1 >/dev/null 2>&1 && echo C2WEB_OK || echo C2WEB_FAIL',
            'host c1-webserver.c1.local 127.0.0.1',
            'host c2-webserver.c2.local 127.0.0.1'
        ) -SuccessPatterns @('C1WEB_OK', 'C2WEB_OK') -CheckDescription ("On {0}, confirm both tenant web records remain visible in the Site 2 namespace." -f $idm.DisplayName)
    }

    Invoke-ToolkitSshTest -Name 'Site 2 Company 2 web hostname-only access summary' -Host $mspJump.Address -User $mspJump.LinuxUser -Device 'MSPUbuntuJump -> Site 2 C2 web' -DocSection 'Service Block 2 / Hotseat 2 / Site 2 Company 2 web' -Commands @(
        'code=$(curl -k -s -o /dev/null -w "%{http_code}" https://c2-webserver.c2.local/ || true); if [ "$code" = "200" ]; then echo S2_C2WEB_FQDN_OK; else echo S2_C2WEB_FQDN_FAIL:$code; fi',
        'code=$(curl -k -s -o /dev/null -w "%{http_code}" https://172.30.65.170/ || true); if [ "$code" = "403" ] || [ "$code" = "404" ] || [ "$code" = "000" ]; then echo S2_C2WEB_HTTPS_IP_HARDENED; else echo S2_C2WEB_HTTPS_IP_ALLOWED:$code; fi',
        'code=$(curl -s -o /dev/null -w "%{http_code}" http://172.30.65.170/ || true); if [ "$code" = "403" ] || [ "$code" = "404" ] || [ "$code" = "000" ]; then echo S2_C2WEB_HTTP_IP_HARDENED; else echo S2_C2WEB_HTTP_IP_ALLOWED:$code; fi',
        'code=$(curl -s -o /dev/null -w "%{http_code}" http://c2-webserver.c2.local/ || true); if [ "$code" = "403" ] || [ "$code" = "404" ] || [ "$code" = "000" ]; then echo S2_C2WEB_HTTP_FQDN_HARDENED; else echo S2_C2WEB_HTTP_FQDN_ALLOWED:$code; fi'
    ) -DisplayCommands @(
        'curl -k -s -o /dev/null -w "%{http_code}" https://c2-webserver.c2.local/',
        'curl -k -s -o /dev/null -w "%{http_code}" https://172.30.65.170/',
        'curl -s -o /dev/null -w "%{http_code}" http://172.30.65.170/',
        'curl -s -o /dev/null -w "%{http_code}" http://c2-webserver.c2.local/'
    ) -SuccessPatterns @('S2_C2WEB_FQDN_OK', 'S2_C2WEB_HTTPS_IP_HARDENED', 'S2_C2WEB_HTTP_IP_HARDENED', 'S2_C2WEB_HTTP_FQDN_HARDENED') -CheckDescription 'From Site 2 MSPUbuntuJump, confirm Company 2 web access succeeds via FQDN and direct-IP or HTTP access remains hardened.'

    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient dual-web validation' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 2 / Hotseat 2 / Site 2 Company 2 client' -Commands @(
        'curl -k -s -o /dev/null -w "S2_C2CLIENT_C1WEB_STATUS=%{http_code}\n" https://c1-webserver.c1.local/',
        'curl -k -s https://c1-webserver.c1.local/ >/dev/null 2>&1 && echo S2_C2CLIENT_C1WEB_OK || echo S2_C2CLIENT_C1WEB_FAIL',
        'curl -k -s -o /dev/null -w "S2_C2CLIENT_C2WEB_STATUS=%{http_code}\n" https://c2-webserver.c2.local/',
        'curl -k -s https://c2-webserver.c2.local/ >/dev/null 2>&1 && echo S2_C2CLIENT_C2WEB_OK || echo S2_C2CLIENT_C2WEB_FAIL'
    ) -SuccessPatterns @('S2_C2CLIENT_C1WEB_OK', 'S2_C2CLIENT_C2WEB_OK') -CheckDescription 'From the Site 2 Company 2 Linux client, confirm both tenant web hostnames resolve and return valid HTTPS responses.'
}

function Invoke-Group6SB3Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $site2Opn = Get-ToolkitHost 'Site2OPNsense'
    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'

    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 OPNsense GUI endpoint' -Address $site2Opn.Address -Port 80 -Device $site2Opn.DisplayName -DocSection 'Service Block 3 / Hotseat 1 / Site 2 control plane' -CheckDescription 'Confirm the Site 2 OPNsense management endpoint is reachable from the current jumpbox.'

    Invoke-ToolkitSshTest -Name 'Site 2 OPNsense management-plane evidence' -Host $mspJump.Address -User $mspJump.LinuxUser -Device 'MSPUbuntuJump -> Site 2 OPNsense' -DocSection 'Service Block 3 / Hotseat 1 / Site 2 control plane' -Commands @(
        'code=$(curl -s -o /dev/null -w "%{http_code}" http://172.30.65.177/ || true); if [ "$code" = "403" ]; then echo S2_OPN_HTTP_403_OK; else echo S2_OPN_HTTP_UNEXPECTED:$code; fi',
        'nc -z -w 3 172.30.65.177 53 >/dev/null 2>&1 && echo S2_OPN_DNS_PORT_OK || echo S2_OPN_DNS_PORT_FAIL'
    ) -DisplayCommands @(
        'curl -I http://172.30.65.177',
        'nc -z -w 3 172.30.65.177 53'
    ) -SuccessPatterns @('S2_OPN_HTTP_403_OK', 'S2_OPN_DNS_PORT_OK') -CheckDescription 'From Site 2 MSPUbuntuJump, confirm the OPNsense management plane exists on the approved path and is not anonymously published.'
}

function Invoke-Group6SB4Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'

    Invoke-ToolkitSshTest -Name 'Site 2 Company 1 file-path and SAN-isolation summary' -Host $mspJump.Address -User $mspJump.LinuxUser -Device 'MSPUbuntuJump -> Site 2 C1 file path' -DocSection 'Service Block 4 / Hotseat 1 / Site 2 Company 1 file path' -Commands @(
        'nc -z -w 3 172.30.65.4 445 >/dev/null 2>&1 && echo S2_C1FS_SMB_OK || echo S2_C1FS_SMB_FAIL',
        'nc -z -w 3 172.30.65.4 3389 >/dev/null 2>&1 && echo S2_C1FS_RDP_OK || echo S2_C1FS_RDP_FAIL',
        'nc -z -w 3 172.30.65.186 3260 >/dev/null 2>&1 && echo S2_C1SAN_REACHABLE || echo S2_C1SAN_ISOLATED'
    ) -DisplayCommands @(
        'nc -z -w 3 172.30.65.4 445',
        'nc -z -w 3 172.30.65.4 3389',
        'nc -z -w 3 172.30.65.186 3260'
    ) -SuccessPatterns @('S2_C1FS_SMB_OK', 'S2_C1FS_RDP_OK', 'S2_C1SAN_ISOLATED') -CheckDescription 'From Site 2 MSPUbuntuJump, confirm the Company 1 file-server admin path remains reachable while the Company 1 SAN target stays isolated from the MSP bastion path.'
}

function Invoke-Group6SB4Hotseat2Site2Tests {
    [CmdletBinding()]
    param()

    $c2fs = Get-ToolkitHost 'S2C2FS'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'
    $c2Specs = Get-Group6C2DomainUserSpecs

    Invoke-ToolkitSshTest -Name 'Site 2 C2FS storage chain summary' -Host $c2fs.Address -User $c2fs.LinuxUser -Device $c2fs.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 file path' -Commands @(
        'systemctl is-active smbd | grep -qx "active" && echo SMBD_ACTIVE || echo SMBD_INACTIVE',
        'findmnt /mnt/c2_public >/dev/null 2>&1 && echo SYNC_DISK_MOUNT_PRESENT || echo SYNC_DISK_MOUNT_MISSING',
        'iscsiadm -m session | grep -q "172.30.65.194:3260" && echo C2_SAN_SESSION_PRESENT || echo C2_SAN_SESSION_MISSING',
        'testparm -s | egrep "C2_Public|C2_Private|/mnt/c2_public/Private" || true',
        'testparm -s | grep -q "\\[C2_Public\\]" && echo C2_PUBLIC_SHARE_PRESENT || echo C2_PUBLIC_SHARE_MISSING',
        'testparm -s | grep -q "\\[C2_Private\\]" && echo C2_PRIVATE_SHARE_PRESENT || echo C2_PRIVATE_SHARE_MISSING',
        'testparm -s | grep -q "/mnt/c2_public/Private" && echo C2_PRIVATE_PATH_PRESENT || echo C2_PRIVATE_PATH_MISSING',
        'tail -n 20 /var/log/c2_site1_sync.log >/dev/null 2>&1 && echo SYNC_LOG_PRESENT || echo SYNC_LOG_MISSING',
        'findmnt /mnt/c2_public || true',
        'iscsiadm -m session || true',
        'tail -n 20 /var/log/c2_site1_sync.log || true'
    ) -SuccessPatterns @('SMBD_ACTIVE', 'SYNC_DISK_MOUNT_PRESENT', 'C2_SAN_SESSION_PRESENT', 'C2_PUBLIC_SHARE_PRESENT', 'C2_PRIVATE_SHARE_PRESENT', 'C2_PRIVATE_PATH_PRESENT', 'SYNC_LOG_PRESENT') -CheckDescription 'On Site 2 C2FS, confirm Company 2 file services still sit on an iSCSI-backed mounted volume with published public/private shares and recent synchronization evidence.'

    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient mounted share summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands @(
        "findmnt -t cifs,nfs | grep -E 'C2_Public|C2_Private' || true",
        "findmnt /home/admin/C2_Public >/dev/null 2>&1 && echo ADMIN_PUBLIC_MOUNT_PRESENT || echo ADMIN_PUBLIC_MOUNT_MISSING",
        "findmnt /home/admin/C2_Private >/dev/null 2>&1 && echo ADMIN_PRIVATE_MOUNT_PRESENT || echo ADMIN_PRIVATE_MOUNT_MISSING",
        "findmnt '/home/employee1@c2.local/C2_Public' >/dev/null 2>&1 && echo EMPLOYEE1_PUBLIC_MOUNT_PRESENT || echo EMPLOYEE1_PUBLIC_MOUNT_MISSING",
        "findmnt '/home/employee1@c2.local/C2_Private' >/dev/null 2>&1 && echo EMPLOYEE1_PRIVATE_MOUNT_PRESENT || echo EMPLOYEE1_PRIVATE_MOUNT_MISSING",
        "findmnt '/home/employee2@c2.local/C2_Public' >/dev/null 2>&1 && echo EMPLOYEE2_PUBLIC_MOUNT_PRESENT || echo EMPLOYEE2_PUBLIC_MOUNT_MISSING",
        "findmnt '/home/employee2@c2.local/C2_Private' >/dev/null 2>&1 && echo EMPLOYEE2_PRIVATE_MOUNT_PRESENT || echo EMPLOYEE2_PRIVATE_MOUNT_MISSING"
    ) -SuccessPatterns @(
        'ADMIN_PUBLIC_MOUNT_PRESENT','ADMIN_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE1_PUBLIC_MOUNT_PRESENT','EMPLOYEE1_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE2_PUBLIC_MOUNT_PRESENT','EMPLOYEE2_PRIVATE_MOUNT_PRESENT'
    ) -CheckDescription 'On Site 2 C2LinuxClient, confirm the expected Public and Private CIFS mounts remain present for the local admin and both domain-user homes.'

    $perUserCommands = @()
    $perUserCommands += New-Group6LinuxSessionWarmupCommands -Platform 'C2' -UserSpecs $c2Specs
    $perUserCommands += New-Group6LinuxPerUserMountCommands -UserSpecs $c2Specs -SharePrefix 'C2' -DomainName 'c2.local'
    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient per-user share mount summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands $perUserCommands -SuccessPatterns @(
        'ADMIN_CRED_PRESENT','EMPLOYEE1_CRED_PRESENT','EMPLOYEE2_CRED_PRESENT',
        'ADMIN_PUBLIC_MOUNT_PRESENT','ADMIN_PUBLIC_USERNAME_OK','ADMIN_PUBLIC_DOMAIN_OK','ADMIN_PUBLIC_SELF_OK','ADMIN_PUBLIC_WRITE_OK',
        'ADMIN_PRIVATE_MOUNT_PRESENT','ADMIN_PRIVATE_USERNAME_OK','ADMIN_PRIVATE_DOMAIN_OK','ADMIN_PRIVATE_SELF_OK','ADMIN_PRIVATE_WRITE_OK',
        'EMPLOYEE1_PUBLIC_MOUNT_PRESENT','EMPLOYEE1_PUBLIC_USERNAME_OK','EMPLOYEE1_PUBLIC_DOMAIN_OK','EMPLOYEE1_PUBLIC_SELF_OK','EMPLOYEE1_PUBLIC_WRITE_OK',
        'EMPLOYEE1_PRIVATE_MOUNT_PRESENT','EMPLOYEE1_PRIVATE_USERNAME_OK','EMPLOYEE1_PRIVATE_DOMAIN_OK','EMPLOYEE1_PRIVATE_SELF_OK','EMPLOYEE1_PRIVATE_WRITE_OK',
        'EMPLOYEE2_PUBLIC_MOUNT_PRESENT','EMPLOYEE2_PUBLIC_USERNAME_OK','EMPLOYEE2_PUBLIC_DOMAIN_OK','EMPLOYEE2_PUBLIC_SELF_OK','EMPLOYEE2_PUBLIC_WRITE_OK',
        'EMPLOYEE2_PRIVATE_MOUNT_PRESENT','EMPLOYEE2_PRIVATE_USERNAME_OK','EMPLOYEE2_PRIVATE_DOMAIN_OK','EMPLOYEE2_PRIVATE_SELF_OK','EMPLOYEE2_PRIVATE_WRITE_OK'
    ) -CheckDescription 'On Site 2 C2LinuxClient, confirm admin plus employee1@c2.local and employee2@c2.local each have the correct Public and Private mounts, c2.local credentials, and write capability.'

    $isolationCommands = New-Group6LinuxPrivateIsolationCommands -LinuxPrefix 'C2' -UserSpecs $c2Specs
    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient private share isolation' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands $isolationCommands -SuccessPatterns @(
        'EMPLOYEE1_CRED_PRESENT','EMPLOYEE2_CRED_PRESENT',
        'EMPLOYEE1_PRIVATE_MOUNT_PRESENT','EMPLOYEE2_PRIVATE_MOUNT_PRESENT',
        'EMPLOYEE1_SELF_PRIVATE_OK','EMPLOYEE2_SELF_PRIVATE_OK',
        'EMPLOYEE1_BLOCKED_FROM_EMPLOYEE2_PRIVATE','EMPLOYEE2_BLOCKED_FROM_EMPLOYEE1_PRIVATE'
    ) -CheckDescription 'On Site 2 C2LinuxClient, confirm each employee can read their own Private mount but cannot read the other employee private data.'
}

function Invoke-Group6SB5Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $s2Veeam = Get-ToolkitHost 'S2Veeam'

    foreach ($port in 135, 445, 6160, 6162) {
        Invoke-ToolkitLocalEndpointTest -Name ("Site 2 S2Veeam control endpoint TCP {0}" -f $port) -Address $s2Veeam.Address -Port $port -Device $s2Veeam.DisplayName -DocSection 'Service Block 5 / Hotseat 1 / Site 2 backup' -CheckDescription ("Confirm S2Veeam remains reachable on TCP {0} from the current jumpbox." -f $port)
    }
}

function Invoke-Group6Hotseat1Tests {
    [CmdletBinding()]
    param()

    Invoke-SB1-Hotseat1Tests
    Invoke-Group6SB1Hotseat1Site2Tests
    Invoke-SB2-Hotseat1Tests
    Invoke-Group6SB2Hotseat1Site2Tests
    Invoke-SB3-Hotseat1Tests
    Invoke-Group6SB3Hotseat1Site2Tests
    Invoke-SB4-Hotseat1Tests
    Invoke-Group6SB4Hotseat1Site2Tests
    Invoke-SB5-Hotseat1Tests
    Invoke-Group6SB5Hotseat1Site2Tests
}

function Invoke-Group6Hotseat2Tests {
    [CmdletBinding()]
    param()

    Invoke-SB1-Hotseat2Tests
    Invoke-Group6SB1Hotseat2Site2Tests
    Invoke-SB2-Hotseat2Tests
    Invoke-Group6SB2Hotseat2Site2Tests
    Invoke-SB3-Hotseat2Tests
    Invoke-SB4-Hotseat2Tests
    Invoke-Group6SB4Hotseat2Site2Tests
    Invoke-SB5-Hotseat2Tests
}

function Invoke-Group6ServiceBlock1 { [CmdletBinding()] param() Invoke-SB1-Hotseat1Tests; Invoke-SB1-Hotseat2Tests; Invoke-Group6SB1Hotseat1Site2Tests; Invoke-Group6SB1Hotseat2Site2Tests }
function Invoke-Group6ServiceBlock2 { [CmdletBinding()] param() Invoke-SB2-Hotseat1Tests; Invoke-SB2-Hotseat2Tests; Invoke-Group6SB2Hotseat1Site2Tests; Invoke-Group6SB2Hotseat2Site2Tests }
function Invoke-Group6ServiceBlock3 { [CmdletBinding()] param() Invoke-SB3-Hotseat1Tests; Invoke-SB3-Hotseat2Tests; Invoke-Group6SB3Hotseat1Site2Tests }
function Invoke-Group6ServiceBlock4 { [CmdletBinding()] param() Invoke-SB4-Hotseat1Tests; Invoke-SB4-Hotseat2Tests; Invoke-Group6SB4Hotseat1Site2Tests; Invoke-Group6SB4Hotseat2Site2Tests }
function Invoke-Group6ServiceBlock5 { [CmdletBinding()] param() Invoke-SB5-Hotseat1Tests; Invoke-SB5-Hotseat2Tests; Invoke-Group6SB5Hotseat1Site2Tests }

function Invoke-Group6AllTests {
    [CmdletBinding()]
    param()

    Invoke-Group6ServiceBlock1
    Invoke-Group6ServiceBlock2
    Invoke-Group6ServiceBlock3
    Invoke-Group6ServiceBlock4
    Invoke-Group6ServiceBlock5
}

Export-ModuleMember -Function @(
    'Get-Group6Coverage',
    'Test-Group6Coverage',
    'Show-Group6Coverage',
    'Show-Group6ManualGuide',
    'Invoke-Group6Hotseat1Tests',
    'Invoke-Group6Hotseat2Tests',
    'Invoke-Group6ServiceBlock1',
    'Invoke-Group6ServiceBlock2',
    'Invoke-Group6ServiceBlock3',
    'Invoke-Group6ServiceBlock4',
    'Invoke-Group6ServiceBlock5',
    'Invoke-Group6AllTests'
)
