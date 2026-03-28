function Get-Group6Coverage {
    [CmdletBinding()]
    param()

    @(
        [pscustomobject]@{ Block = '1'; Hotseat = '1'; Area = 'Company 1 + MSP'; Coverage = 'Site 1 Company 1 core plus Site 2 Company 1 service-path validation.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '1'; Hotseat = '2'; Area = 'Company 2 + MSP'; Coverage = 'Site 1 Company 2 core plus Site 2 Company 2 identity and client validation.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '1'; Area = 'Company 1 + MSP'; Coverage = 'Company 1 DNS redundancy plus hostname-only HTTPS across both sites, including client-side enforcement.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '2'; Hotseat = '2'; Area = 'Company 2 + MSP'; Coverage = 'Company 2 DNS redundancy plus hostname-only HTTPS across both sites, including client-side enforcement.'; Mode = 'Automated' }
        [pscustomobject]@{ Block = '3'; Hotseat = '1'; Area = 'MSP control plane'; Coverage = 'Site 1 Proxmox/OPNsense proof plus Site 2 OPNsense management-plane validation.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '3'; Hotseat = '2'; Area = 'MSP inter-site policy'; Coverage = 'Inter-site SMB path plus Site 2 edge and OpenVPN policy walkthrough.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '4'; Hotseat = '1'; Area = 'Company 1 file services'; Coverage = 'Site 1 DFS/iSCSI/share proof with active Public/Private write verification, plus Site 2 Company 1 file-path / SAN validation; Site 2 client-side share proof remains a manual adjunct.'; Mode = 'Automated + manual adjunct' }
        [pscustomobject]@{ Block = '4'; Hotseat = '2'; Area = 'Company 2 file services'; Coverage = 'Site 1 mounted-share proof plus Site 2 Company 2 storage-chain, hostname-based SMB access, and active Public/Private write and isolation verification.'; Mode = 'Automated' }
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
    Write-Host '2. Site 2 C1WindowsClient interactive Public / Private walkthrough: create username_timestamp files in Public, confirm the other Company 1 users can see them, then create username_timestamp files in Private and confirm the other users do not see them before cleanup.' -ForegroundColor Yellow
    Write-Host '3. Site 2 OPNsense NAT, aliases, OpenVPN, and bounded inter-site policy walkthrough.' -ForegroundColor Yellow
    Write-Host '4. Site 2 Veeam design interpretation when deeper backup proof is needed.' -ForegroundColor Yellow
    Write-Host '5. Site 1 rack and switch baseline walkthrough.' -ForegroundColor Yellow
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

function New-Group6Site2C2SmbBrowseCommands {
    @(
        'command -v smbclient >/dev/null 2>&1 && echo SMBCLIENT_PRESENT || echo SMBCLIENT_MISSING',
        'getent hosts c2fs.c2.local',
        'getent hosts c2fs.c2.local >/dev/null 2>&1 && echo C2FS_HOST_OK || echo C2FS_HOST_FAIL',
        'browse_out=$(smbclient -g -L //c2fs.c2.local -W C2 -U employee1%Cisco123! 2>&1 || true); echo "$browse_out"; echo "$browse_out" | grep -Fq "Disk|C2_Public|" && echo C2FS_BROWSE_PUBLIC_OK || echo C2FS_BROWSE_PUBLIC_FAIL; if echo "$browse_out" | grep -Fq "Disk|C2_Private|"; then echo C2FS_BROWSE_PRIVATE_LISTED; else echo C2FS_BROWSE_PRIVATE_NOT_LISTED; fi'
    )
}

function New-Group6Site2C2SmbShareCommands {
    param(
        [object[]]$UserSpecs,
        [string[]]$ShareTypes = @('Public', 'Private')
    )

    $commands = @()
    foreach ($spec in Resolve-Group6LinuxUserSpecs -UserSpecs $UserSpecs) {
        $token = $spec.Token
        foreach ($shareType in $ShareTypes) {
            $shareToken = $shareType.ToUpperInvariant()
            $shareName = "C2_{0}" -f $shareType
            $commands += ('status=FAIL; for attempt in 1 2 3; do out=$(smbclient //c2fs.c2.local/{0} -W C2 -U {1}%Cisco123! -c ''ls'' 2>&1 || true); echo "$out"; if echo "$out" | grep -q ''blocks of size''; then status=OK; break; fi; if ! echo "$out" | grep -q ''NT_STATUS_IO_TIMEOUT''; then break; fi; sleep 2; done; [ "$status" = OK ] && echo {2}_{3}_ACCESS_OK || echo {2}_{3}_ACCESS_FAIL' -f $shareName, $spec.MountUsername, $token, $shareToken)
        }
    }

    return $commands
}

function New-Group6Site2C2SmbPublicWriteWorkflowPlan {
    param(
        [object[]]$UserSpecs
    )

    $specs = Resolve-Group6LinuxUserSpecs -UserSpecs $UserSpecs
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $commands = @('mkdir -p /tmp/codex-share-tests')
    $successPatterns = [System.Collections.Generic.List[string]]::new()

    foreach ($spec in $specs) {
        $token = $spec.Token
        $localFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_public.txt" -f $spec.MountUsername, $stamp
        $remoteFile = "toolkit_c2_{0}_{1}_public.txt" -f $spec.MountUsername, $stamp
        $resultFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_public.create.out" -f $spec.MountUsername, $stamp
        $content = "creator=$($spec.MountUsername) scope=public stamp=$stamp"

        $commands += (@"
printf "%s\n" "$content" > '$localFile' && smbclient //c2fs.c2.local/C2_Public -W C2 -U $($spec.MountUsername)%Cisco123! -c "put $localFile $remoteFile; ls $remoteFile" > '$resultFile' 2>&1; rc=`$?; cat '$resultFile'; [ `$rc -eq 0 ] && grep -Fq '$remoteFile' '$resultFile' && echo ${token}_PUBLIC_CREATE_OK || echo ${token}_PUBLIC_CREATE_FAIL
"@).Trim()
        $successPatterns.Add("${token}_PUBLIC_CREATE_OK")
    }

    foreach ($owner in $specs) {
        $ownerToken = $owner.Token
        $remoteFile = "toolkit_c2_{0}_{1}_public.txt" -f $owner.MountUsername, $stamp

        foreach ($viewer in $specs | Where-Object { $_.Token -ne $ownerToken }) {
            $viewerToken = $viewer.Token
            $resultFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_public.check_{2}.out" -f $owner.MountUsername, $stamp, $viewer.MountUsername
            $visibleMarker = "${ownerToken}_PUBLIC_VISIBLE_TO_${viewerToken}"
            $hiddenMarker = "${ownerToken}_PUBLIC_HIDDEN_FROM_${viewerToken}"

            $commands += (@"
smbclient //c2fs.c2.local/C2_Public -W C2 -U $($viewer.MountUsername)%Cisco123! -c "ls $remoteFile" > '$resultFile' 2>&1 || true; cat '$resultFile'; grep -Fq '$remoteFile' '$resultFile' && ! grep -Fq 'NT_STATUS_' '$resultFile' && echo $visibleMarker || echo $hiddenMarker; rm -f '$resultFile'
"@).Trim()
            $successPatterns.Add($visibleMarker)
        }
    }

    foreach ($spec in $specs) {
        $token = $spec.Token
        $localFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_public.txt" -f $spec.MountUsername, $stamp
        $remoteFile = "toolkit_c2_{0}_{1}_public.txt" -f $spec.MountUsername, $stamp
        $resultFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_public.delete.out" -f $spec.MountUsername, $stamp

        $commands += (@"
smbclient //c2fs.c2.local/C2_Public -W C2 -U $($spec.MountUsername)%Cisco123! -c "del $remoteFile" > '$resultFile' 2>&1; rc=`$?; cat '$resultFile'; rm -f '$localFile' '$resultFile'; [ `$rc -eq 0 ] && echo ${token}_PUBLIC_CLEANUP_OK || echo ${token}_PUBLIC_CLEANUP_FAIL
"@).Trim()
        $successPatterns.Add("${token}_PUBLIC_CLEANUP_OK")
    }

    return [pscustomobject]@{
        Commands        = $commands
        SuccessPatterns = @($successPatterns)
        DisplayCommands = @(
            'Create a temporary local source file for each Company 2 user'
            'Upload each file into C2_Public over hostname-based SMB'
            'Confirm the other users can see those Public files through their own SMB view'
            'Delete the temporary Public test files after verification'
        )
    }
}

function New-Group6Site2C2SmbPrivateWriteWorkflowPlan {
    param(
        [object[]]$UserSpecs
    )

    $specs = Resolve-Group6LinuxUserSpecs -UserSpecs $UserSpecs
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $commands = @('mkdir -p /tmp/codex-share-tests')
    $successPatterns = [System.Collections.Generic.List[string]]::new()

    foreach ($spec in $specs) {
        $token = $spec.Token
        $localFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_private.txt" -f $spec.MountUsername, $stamp
        $remoteFile = "toolkit_c2_{0}_{1}_private.txt" -f $spec.MountUsername, $stamp
        $resultFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_private.create.out" -f $spec.MountUsername, $stamp
        $content = "creator=$($spec.MountUsername) scope=private stamp=$stamp"

        $commands += (@"
printf "%s\n" "$content" > '$localFile' && smbclient //c2fs.c2.local/C2_Private -W C2 -U $($spec.MountUsername)%Cisco123! -c "put $localFile $remoteFile; ls $remoteFile" > '$resultFile' 2>&1; rc=`$?; cat '$resultFile'; [ `$rc -eq 0 ] && grep -Fq '$remoteFile' '$resultFile' && echo ${token}_PRIVATE_CREATE_OK || echo ${token}_PRIVATE_CREATE_FAIL
"@).Trim()
        $successPatterns.Add("${token}_PRIVATE_CREATE_OK")
    }

    foreach ($owner in $specs) {
        $ownerToken = $owner.Token
        $remoteFile = "toolkit_c2_{0}_{1}_private.txt" -f $owner.MountUsername, $stamp

        foreach ($viewer in $specs | Where-Object { $_.Token -ne $ownerToken }) {
            $viewerToken = $viewer.Token
            $resultFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_private.check_{2}.out" -f $owner.MountUsername, $stamp, $viewer.MountUsername
            $hiddenMarker = "${ownerToken}_PRIVATE_HIDDEN_FROM_${viewerToken}"
            $visibleMarker = "${ownerToken}_PRIVATE_VISIBLE_TO_${viewerToken}"

            $commands += (@"
smbclient //c2fs.c2.local/C2_Private -W C2 -U $($viewer.MountUsername)%Cisco123! -c "ls $remoteFile" > '$resultFile' 2>&1 || true; cat '$resultFile'; grep -Fq '$remoteFile' '$resultFile' && ! grep -Fq 'NT_STATUS_' '$resultFile' && echo $visibleMarker || echo $hiddenMarker; rm -f '$resultFile'
"@).Trim()
            $successPatterns.Add($hiddenMarker)
        }
    }

    foreach ($spec in $specs) {
        $token = $spec.Token
        $localFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_private.txt" -f $spec.MountUsername, $stamp
        $remoteFile = "toolkit_c2_{0}_{1}_private.txt" -f $spec.MountUsername, $stamp
        $resultFile = "/tmp/codex-share-tests/toolkit_c2_{0}_{1}_private.delete.out" -f $spec.MountUsername, $stamp

        $commands += (@"
smbclient //c2fs.c2.local/C2_Private -W C2 -U $($spec.MountUsername)%Cisco123! -c "del $remoteFile" > '$resultFile' 2>&1; rc=`$?; cat '$resultFile'; rm -f '$localFile' '$resultFile'; [ `$rc -eq 0 ] && echo ${token}_PRIVATE_CLEANUP_OK || echo ${token}_PRIVATE_CLEANUP_FAIL
"@).Trim()
        $successPatterns.Add("${token}_PRIVATE_CLEANUP_OK")
    }

    return [pscustomobject]@{
        Commands        = $commands
        SuccessPatterns = @($successPatterns)
        DisplayCommands = @(
            'Create a temporary local source file for each Company 2 user'
            'Upload each file into the authenticated C2_Private view over hostname-based SMB'
            'Confirm the other users do not see those Private files through their own SMB view'
            'Delete the temporary Private test files after verification'
        )
    }
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
}

function Invoke-Group6SB1Hotseat2Site2Tests {
    [CmdletBinding()]
    param()

    $idm1 = Get-ToolkitHost 'S2C2IdM1'
    $idm2 = Get-ToolkitHost 'S2C2IdM2'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'
    $c2Specs = Get-Group6C2DomainUserSpecs

    foreach ($idm in @($idm1, $idm2)) {
        $failoverNeedle = if ($idm.Address -eq $idm1.Address) { 'primary;' } else { 'secondary;' }
        $failoverMarker = if ($idm.Address -eq $idm1.Address) { 'PRIMARY_FAILOVER_OK' } else { 'SECONDARY_FAILOVER_OK' }
        Invoke-ToolkitSshTest -Name ("{0} identity and DHCP summary" -f $idm.DisplayName) -Host $idm.Address -User $idm.LinuxUser -Device $idm.DisplayName -DocSection 'Service Block 1 / Hotseat 2 / Site 2 Company 2 path' -Commands @(
            'printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active samba-ad-dc | grep -qx "active" && echo SAMBA_ACTIVE || echo SAMBA_INACTIVE',
            'printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active isc-dhcp-server | grep -qx "active" && echo DHCP_ACTIVE || echo DHCP_INACTIVE',
            ("printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" grep -nE `"failover peer|{0}|subnet 172\\.30\\.65\\.64`" /etc/dhcp/dhcpd.conf 2>/dev/null" -f $failoverNeedle),
            ("printf `"%s\n`" `"Cisco123!`" | sudo -S -p `"`" grep -q `"{0}`" /etc/dhcp/dhcpd.conf 2>/dev/null && echo {1} || echo {1}_FAIL" -f $failoverNeedle, $failoverMarker),
            'user_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool user list 2>/dev/null); echo "$user_out"; echo "$user_out" | grep -qx "Administrator" && echo "$user_out" | grep -qx "admin" && echo "$user_out" | grep -qx "employee1" && echo "$user_out" | grep -qx "employee2" && echo USERS_OK || echo USERS_FAIL',
            'group_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool group list 2>/dev/null); echo "$group_out"; echo "$group_out" | grep -qx "c2_file_users" && echo GROUPS_OK || echo GROUPS_FAIL',
            'zone_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool dns zonelist 127.0.0.1 -P 2>/dev/null); echo "$zone_out"; echo "$zone_out" | grep -q "c2.local" && echo "$zone_out" | grep -q "c1.local" && echo "$zone_out" | grep -q "_msdcs.c2.local" && echo DNS_ZONES_OK || echo DNS_ZONES_FAIL',
            'c1_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P 2>/dev/null); echo "$c1_out"; echo "$c1_out" | grep -q "172.30.64.162" && echo "$c1_out" | grep -q "172.30.65.162" && echo C1_WEB_RECORDS_OK || echo C1_WEB_RECORDS_FAIL',
            'c2_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P 2>/dev/null); echo "$c2_out"; echo "$c2_out" | grep -q "172.30.64.170" && echo "$c2_out" | grep -q "172.30.65.170" && echo C2_WEB_RECORDS_OK || echo C2_WEB_RECORDS_FAIL'
        ) -SuccessPatterns @('SAMBA_ACTIVE', 'DHCP_ACTIVE', $failoverMarker, 'USERS_OK', 'GROUPS_OK', 'DNS_ZONES_OK', 'C1_WEB_RECORDS_OK', 'C2_WEB_RECORDS_OK') -CheckDescription ("On {0}, confirm Samba AD, DHCP failover, required users/groups, and authoritative DNS/web-record state remain healthy." -f $idm.DisplayName)
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
        'resolvectl status',
        'nmcli dev show | grep -q "172.30.65.70/26" && echo CLIENT_IP_OK || echo CLIENT_IP_FAIL',
        'nmcli dev show | grep -q "172.30.65.65" && echo GATEWAY_OK || echo GATEWAY_FAIL',
        'nmcli dev show | grep -q "172.30.65.66" && echo DNS1_OK || echo DNS1_FAIL',
        'nmcli dev show | grep -q "172.30.65.67" && echo DNS2_OK || echo DNS2_FAIL',
        'resolvectl status | grep -q "c1.local" && resolvectl status | grep -q "c2.local" && echo DNS_SEARCH_OK || echo DNS_SEARCH_FAIL',
        'realm list',
        'realm list | grep -qi "^c2\\.local" && echo C2_REALM_OK || echo C2_REALM_FAIL',
        'c1_out=$(nslookup c1-webserver.c1.local 2>/dev/null); echo "$c1_out"; echo "$c1_out" | grep -q "172.30.64.162" && echo "$c1_out" | grep -q "172.30.65.162" && echo C1WEB_RESOLVE_OK || echo C1WEB_RESOLVE_FAIL',
        'c2_out=$(nslookup c2-webserver.c2.local 2>/dev/null); echo "$c2_out"; echo "$c2_out" | grep -q "172.30.64.170" && echo "$c2_out" | grep -q "172.30.65.170" && echo C2WEB_RESOLVE_OK || echo C2WEB_RESOLVE_FAIL'
    ) -SuccessPatterns @('CLIENT_IP_OK', 'GATEWAY_OK', 'DNS1_OK', 'DNS2_OK', 'DNS_SEARCH_OK', 'C2_REALM_OK', 'C1WEB_RESOLVE_OK', 'C2WEB_RESOLVE_OK') -CheckDescription 'On Site 2 C2LinuxClient, confirm the live address, gateway, DNS settings, resolver domains, realm membership, and dual-company hostname resolution match the documented Company 2 design.'
}

function Invoke-Group6SB1Hotseat1AdditionalTests {
    [CmdletBinding()]
    param()

    foreach ($dcKey in 'S2C1DC1', 'S2C1DC2') {
        $dc = Get-ToolkitHost $dcKey
        Invoke-ToolkitWinrmTest -Name ("{0} directory and DNS role summary" -f $dc.DisplayName) -ComputerName $dc.Address -Device $dc.DisplayName -DocSection 'Service Block 1 / Hotseat 1 / Site 2 Company 1 path' -CommandLines @(
            'Get-Service NTDS,DNS',
            'Get-ADDomain',
            'Get-DnsServerZone'
        ) -ScriptBlock {
            $services = @(Get-Service NTDS, DNS)
            $services
            if (($services | Where-Object { $_.Status -eq 'Running' }).Count -eq 2) {
                'S2_C1_ROLE_SERVICES_OK'
            }
            else {
                'S2_C1_ROLE_SERVICES_FAIL'
            }

            $domain = Get-ADDomain
            $domain
            if ($domain.DNSRoot -eq 'c1.local') {
                'S2_C1_DOMAIN_OK'
            }
            else {
                'S2_C1_DOMAIN_FAIL'
            }

            $zones = @(Get-DnsServerZone | Select-Object -ExpandProperty ZoneName)
            $zones
            if ($zones -contains 'c1.local') {
                'S2_C1_ZONE_OK'
            }
            else {
                'S2_C1_ZONE_FAIL'
            }
        } -SuccessPatterns @('S2_C1_ROLE_SERVICES_OK', 'S2_C1_DOMAIN_OK', 'S2_C1_ZONE_OK') -CheckDescription ("On {0}, confirm AD DS and DNS services are running and the c1.local namespace is present." -f $dc.DisplayName)
    }
}

function Invoke-Group6SB2Hotseat1AdditionalTests {
    [CmdletBinding()]
    param()

    $c1dc2 = Get-ToolkitHost 'C1DC2'
    $c1Client2 = Get-ToolkitHost 'C1Client2'

    Invoke-ToolkitWinrmTest -Name 'C1 secondary DNS resolution summary' -ComputerName $c1dc2.Address -Device $c1dc2.DisplayName -DocSection 'Service Block 2 / DNS' -CommandLines @(
        'Get-DnsServerZone',
        'Get-DnsServerForwarder',
        'Resolve-DnsName -Name c1-webserver.c1.local -Server 172.30.64.131',
        'Resolve-DnsName -Name microsoft.com -Server 172.30.64.131'
    ) -ScriptBlock {
        Import-Module DnsServer -ErrorAction Stop

        $zones = @(Get-DnsServerZone | Select-Object -ExpandProperty ZoneName)
        if ($zones -contains 'c1.local' -and $zones -contains '64.30.172.in-addr.arpa') {
            'SECONDARY_ZONES_PRESENT'
        }
        else {
            'SECONDARY_ZONES_MISSING'
        }

        $forwarders = @(
            Get-DnsServerForwarder | ForEach-Object {
                if ($_.PSObject.Properties.Name -contains 'IPAddress') {
                    [string]$_.IPAddress
                }
                elseif ($_.PSObject.Properties.Name -contains 'IPAddressToString') {
                    [string]$_.IPAddressToString
                }
                else {
                    [string]$_
                }
            }
        )
        if ($forwarders -contains '8.8.8.8') {
            'SECONDARY_FORWARDERS_PRESENT'
        }
        else {
            'SECONDARY_FORWARDERS_MISSING'
        }

        $web = Resolve-DnsName -Name c1-webserver.c1.local -Server 172.30.64.131 -ErrorAction Stop
        if ($web.IPAddress -contains '172.30.64.162') {
            'SECONDARY_WEB_RECORD_OK'
        }
        else {
            'SECONDARY_WEB_RECORD_FAIL'
        }

        $public = Resolve-DnsName -Name microsoft.com -Server 172.30.64.131 -ErrorAction Stop
        if ($public) {
            'SECONDARY_PUBLIC_RECURSION_OK'
        }
        else {
            'SECONDARY_PUBLIC_RECURSION_FAIL'
        }

        $web
        $public | Select-Object -First 3
    } -SuccessPatterns @('SECONDARY_ZONES_PRESENT', 'SECONDARY_FORWARDERS_PRESENT', 'SECONDARY_WEB_RECORD_OK', 'SECONDARY_PUBLIC_RECURSION_OK') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-DC2, confirm the secondary Company 1 DNS node can resolve the web record, perform recursive lookups, and still carries the expected zone / forwarder state for failover readiness.'

    Invoke-ToolkitSshTest -Name 'C1-Client2 hostname-only company-web validation' -Host $c1Client2.Address -User $c1Client2.LinuxUser -Device $c1Client2.DisplayName -DocSection 'Service Block 2 / HTTPS' -Commands @(
        'code=$(curl -sk --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://c1-webserver.c1.local/ 2>/dev/null || true); if [ "$code" = "200" ]; then echo C1CLIENT_HTTPS_FQDN_OK; else echo C1CLIENT_HTTPS_FQDN_FAIL:$code; fi',
        'code=$(curl -sk --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://172.30.64.162/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo C1CLIENT_HTTPS_IP_HARDENED; else echo C1CLIENT_HTTPS_IP_ALLOWED:$code; fi',
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.64.162/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo C1CLIENT_HTTP_IP_HARDENED; else echo C1CLIENT_HTTP_IP_ALLOWED:$code; fi',
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://c1-webserver.c1.local/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo C1CLIENT_HTTP_FQDN_HARDENED; else echo C1CLIENT_HTTP_FQDN_ALLOWED:$code; fi'
    ) -DisplayCommands @(
        'curl -sk --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://c1-webserver.c1.local/',
        'curl -sk --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://172.30.64.162/',
        'curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.64.162/',
        'curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://c1-webserver.c1.local/'
    ) -SuccessPatterns @('C1CLIENT_HTTPS_FQDN_OK', 'C1CLIENT_HTTPS_IP_HARDENED', 'C1CLIENT_HTTP_IP_HARDENED', 'C1CLIENT_HTTP_FQDN_HARDENED') -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 60 -CheckDescription 'From C1-Client2, confirm the Company 1 website is consumed only through https://c1-webserver.c1.local while HTTP and direct-IP paths do not return the tenant page with HTTP 200.'
}

function Invoke-Group6SB2Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $c1UbuntuClient = Get-ToolkitHost 'S2C1UbuntuClient'

    Invoke-ToolkitSshTest -Name 'Site 2 C1UbuntuClient company-web hostname-only enforcement' -Host $c1UbuntuClient.Address -User $c1UbuntuClient.LinuxUser -Device $c1UbuntuClient.DisplayName -DocSection 'Service Block 2 / Hotseat 1 / Site 2 Company 1 client' -Commands @(
        'code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://c1-webserver.c1.local/ 2>/dev/null || true); if [ "$code" = "200" ]; then echo S2_C1CLIENT_C1WEB_HTTPS_FQDN_OK; else echo S2_C1CLIENT_C1WEB_HTTPS_FQDN_FAIL:$code; fi',
        'code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://172.30.65.162/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo S2_C1CLIENT_C1WEB_HTTPS_IP_HARDENED; else echo S2_C1CLIENT_C1WEB_HTTPS_IP_ALLOWED:$code; fi',
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.65.162/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo S2_C1CLIENT_C1WEB_HTTP_IP_HARDENED; else echo S2_C1CLIENT_C1WEB_HTTP_IP_ALLOWED:$code; fi',
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://c1-webserver.c1.local/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo S2_C1CLIENT_C1WEB_HTTP_FQDN_HARDENED; else echo S2_C1CLIENT_C1WEB_HTTP_FQDN_ALLOWED:$code; fi'
    ) -DisplayCommands @(
        'curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://c1-webserver.c1.local/',
        'curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://172.30.65.162/',
        'curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.65.162/',
        'curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://c1-webserver.c1.local/'
    ) -SuccessPatterns @('S2_C1CLIENT_C1WEB_HTTPS_FQDN_OK', 'S2_C1CLIENT_C1WEB_HTTPS_IP_HARDENED', 'S2_C1CLIENT_C1WEB_HTTP_IP_HARDENED', 'S2_C1CLIENT_C1WEB_HTTP_FQDN_HARDENED') -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 60 -CheckDescription 'From Site 2 C1UbuntuClient, confirm the Company 1 website is consumed only through https://c1-webserver.c1.local while HTTP and direct-IP paths do not return the tenant page with HTTP 200.'
}

function Invoke-Group6SB2Hotseat2AdditionalTests {
    [CmdletBinding()]
    param()

    $c2dc2 = Get-ToolkitHost 'C2DC2'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'

    Invoke-ToolkitSshTest -Name 'C2 secondary DNS internal and external resolution summary' -Host $c2dc2.Address -User $c2dc2.LinuxUser -Device $c2dc2.DisplayName -DocSection 'Service Block 2 / DNS' -Commands @(
        'host c2-dc1.c2.local 127.0.0.1',
        'host c2-dc2.c2.local 127.0.0.1',
        'host c1-webserver.c1.local 127.0.0.1',
        'host c2-webserver.c2.local 127.0.0.1',
        'host microsoft.com 127.0.0.1',
        'host c2-dc1.c2.local 127.0.0.1 >/dev/null 2>&1 && echo SECONDARY_C2DC1_OK || echo SECONDARY_C2DC1_FAIL',
        'host c2-dc2.c2.local 127.0.0.1 >/dev/null 2>&1 && echo SECONDARY_C2DC2_OK || echo SECONDARY_C2DC2_FAIL',
        'host c1-webserver.c1.local 127.0.0.1 >/dev/null 2>&1 && echo SECONDARY_C1WEB_OK || echo SECONDARY_C1WEB_FAIL',
        'host c2-webserver.c2.local 127.0.0.1 >/dev/null 2>&1 && echo SECONDARY_C2WEB_OK || echo SECONDARY_C2WEB_FAIL',
        'host microsoft.com 127.0.0.1 >/dev/null 2>&1 && echo SECONDARY_EXTERNAL_LOOKUP_OK || echo SECONDARY_EXTERNAL_LOOKUP_FAIL'
    ) -SuccessPatterns @('SECONDARY_C2DC1_OK', 'SECONDARY_C2DC2_OK', 'SECONDARY_C1WEB_OK', 'SECONDARY_C2WEB_OK', 'SECONDARY_EXTERNAL_LOOKUP_OK') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C2-DC2, confirm the secondary Company 2 DNS node can still resolve controller records, both tenant web names, and recursive external lookups for failover readiness.'

    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient company-web hostname-only enforcement' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 2 / Hotseat 2 / Site 2 Company 2 client' -Commands @(
        'code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://c2-webserver.c2.local/ 2>/dev/null || true); if [ "$code" = "200" ]; then echo S2_C2CLIENT_C2WEB_HTTPS_FQDN_OK; else echo S2_C2CLIENT_C2WEB_HTTPS_FQDN_FAIL:$code; fi',
        'code=$(curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://172.30.65.170/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo S2_C2CLIENT_C2WEB_HTTPS_IP_HARDENED; else echo S2_C2CLIENT_C2WEB_HTTPS_IP_ALLOWED:$code; fi',
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.65.170/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo S2_C2CLIENT_C2WEB_HTTP_IP_HARDENED; else echo S2_C2CLIENT_C2WEB_HTTP_IP_ALLOWED:$code; fi',
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://c2-webserver.c2.local/ 2>/dev/null || true); if [ "$code" != "200" ]; then echo S2_C2CLIENT_C2WEB_HTTP_FQDN_HARDENED; else echo S2_C2CLIENT_C2WEB_HTTP_FQDN_ALLOWED:$code; fi'
    ) -DisplayCommands @(
        'curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://c2-webserver.c2.local/',
        'curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" https://172.30.65.170/',
        'curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.65.170/',
        'curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://c2-webserver.c2.local/'
    ) -SuccessPatterns @('S2_C2CLIENT_C2WEB_HTTPS_FQDN_OK', 'S2_C2CLIENT_C2WEB_HTTPS_IP_HARDENED', 'S2_C2CLIENT_C2WEB_HTTP_IP_HARDENED', 'S2_C2CLIENT_C2WEB_HTTP_FQDN_HARDENED') -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 60 -CheckDescription 'From Site 2 C2LinuxClient, confirm the Company 2 website is consumed only through https://c2-webserver.c2.local while HTTP and direct-IP paths do not return the tenant page with HTTP 200.'
}

function Invoke-Group6SB2Hotseat2Site2Tests {
    [CmdletBinding()]
    param()

    $idm1 = Get-ToolkitHost 'S2C2IdM1'
    $idm2 = Get-ToolkitHost 'S2C2IdM2'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'

    foreach ($idm in @($idm1, $idm2)) {
        Invoke-ToolkitSshTest -Name ("{0} dual-web namespace visibility" -f $idm.DisplayName) -Host $idm.Address -User $idm.LinuxUser -Device $idm.DisplayName -DocSection 'Service Block 2 / Hotseat 2 / Site 2 namespace visibility' -Commands @(
            'c1_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P 2>/dev/null); echo "$c1_out"; echo "$c1_out" | grep -q "172.30.64.162" && echo "$c1_out" | grep -q "172.30.65.162" && echo C1WEB_OK || echo C1WEB_FAIL',
            'c2_out=$(printf "%s\n" "Cisco123!" | sudo -S -p "" samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P 2>/dev/null); echo "$c2_out"; echo "$c2_out" | grep -q "172.30.64.170" && echo "$c2_out" | grep -q "172.30.65.170" && echo C2WEB_OK || echo C2WEB_FAIL'
        ) -SuccessPatterns @('C1WEB_OK', 'C2WEB_OK') -CheckDescription ("On {0}, confirm both tenant web records remain visible in the Site 2 namespace." -f $idm.DisplayName)
    }

    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient dual-web validation' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 2 / Hotseat 2 / Site 2 Company 2 client' -Commands @(
        'curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "S2_C2CLIENT_C1WEB_STATUS=%{http_code}\n" https://c1-webserver.c1.local/',
        'curl -k -s --connect-timeout 5 --max-time 10 https://c1-webserver.c1.local/ >/dev/null 2>&1 && echo S2_C2CLIENT_C1WEB_OK || echo S2_C2CLIENT_C1WEB_FAIL',
        'curl -k -s --connect-timeout 5 --max-time 10 -o /dev/null -w "S2_C2CLIENT_C2WEB_STATUS=%{http_code}\n" https://c2-webserver.c2.local/',
        'curl -k -s --connect-timeout 5 --max-time 10 https://c2-webserver.c2.local/ >/dev/null 2>&1 && echo S2_C2CLIENT_C2WEB_OK || echo S2_C2CLIENT_C2WEB_FAIL'
    ) -SuccessPatterns @('S2_C2CLIENT_C1WEB_OK', 'S2_C2CLIENT_C2WEB_OK') -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 60 -CheckDescription 'From the Site 2 Company 2 Linux client, confirm both tenant web hostnames resolve and return valid HTTPS responses.'
}

function Invoke-Group6SB3Hotseat1Site2Tests {
    [CmdletBinding()]
    param()

    $site2Opn = Get-ToolkitHost 'Site2OPNsense'
    $mspJump = Get-ToolkitHost 'Site2MSPUbuntuJump'

    Invoke-ToolkitLocalEndpointTest -Name 'Site 2 OPNsense GUI endpoint' -Address $site2Opn.Address -Port 80 -Device $site2Opn.DisplayName -DocSection 'Service Block 3 / Hotseat 1 / Site 2 control plane' -CheckDescription 'Confirm the Site 2 OPNsense management endpoint is reachable from the current jumpbox.'

    Invoke-ToolkitSshTest -Name 'Site 2 OPNsense management-plane evidence' -Host $mspJump.Address -User $mspJump.LinuxUser -Device 'MSPUbuntuJump -> Site 2 OPNsense' -DocSection 'Service Block 3 / Hotseat 1 / Site 2 control plane' -Commands @(
        'code=$(curl -s --connect-timeout 5 --max-time 10 -o /dev/null -w "%{http_code}" http://172.30.65.177/ 2>/dev/null || true); case "$code" in 200|401|403) echo S2_OPN_HTTP_PORTAL_OK:$code ;; *) echo S2_OPN_HTTP_UNEXPECTED:$code ;; esac',
        'nc -z -w 3 172.30.65.177 53 >/dev/null 2>&1 && echo S2_OPN_DNS_PORT_OK || echo S2_OPN_DNS_PORT_FAIL'
    ) -DisplayCommands @(
        'curl -I http://172.30.65.177',
        'nc -z -w 3 172.30.65.177 53'
    ) -SuccessPatterns @('S2_OPN_HTTP_PORTAL_OK', 'S2_OPN_DNS_PORT_OK') -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 30 -CheckDescription 'From Site 2 MSPUbuntuJump, confirm the OPNsense management plane responds on the approved path and still exposes the expected GUI and DNS listeners.'
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

function Invoke-Group6SB4Hotseat1AdditionalTests {
    [CmdletBinding()]
    param()

    $c1dc1 = Get-ToolkitHost 'C1DC1'
    $s2c1WindowsClient = Get-ToolkitHost 'S2C1WindowsClient'
    $s2c1fs = Get-ToolkitHost 'S2C1FS'

    Invoke-ToolkitWinrmTest -Name 'C1 DFS namespace target-set summary' -ComputerName $c1dc1.Address -Device $c1dc1.DisplayName -DocSection 'Service Block 4 / Replicated File Server' -CommandLines @(
        "Get-DfsnFolder -Path '\\c1.local\\namespace\\*'",
        'Get-DfsrMembership'
    ) -ScriptBlock {
        Import-Module Dfsn -ErrorAction SilentlyContinue
        Import-Module DFSR -ErrorAction SilentlyContinue

        $folders = @(Get-DfsnFolder -Path '\\c1.local\namespace\*' -ErrorAction SilentlyContinue)
        $memberships = @(Get-DfsrMembership -GroupName * -ErrorAction SilentlyContinue)
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
        $expectedNodes = @('C1-DC1', 'C1-DC2', 'C1FS')
        $publicNodes = @($publicMembership | Select-Object -ExpandProperty ComputerName -Unique)
        $privateNodes = @($privateMembership | Select-Object -ExpandProperty ComputerName -Unique)
        $missingPublicNodes = @($expectedNodes | Where-Object { $publicNodes -notcontains $_ })
        $missingPrivateNodes = @($expectedNodes | Where-Object { $privateNodes -notcontains $_ })

        if ($missingPublicNodes.Count -eq 0) {
            'PUBLIC_TARGET_SET_OK'
        }
        else {
            'PUBLIC_TARGET_SET_FAIL'
        }

        if ($missingPrivateNodes.Count -eq 0) {
            'PRIVATE_TARGET_SET_OK'
        }
        else {
            'PRIVATE_TARGET_SET_FAIL'
        }

        if ($folders.Count -gt 0) {
            'DFS_NAMESPACE_FOLDERS_VISIBLE'
        }
        else {
            'DFS_NAMESPACE_FOLDERS_UNAVAILABLE'
        }

        $folders | Select-Object Path, State | Format-Table -HideTableHeaders
        $publicMembership | Select-Object GroupName, ComputerName, ContentPath | Format-Table -HideTableHeaders
        $privateMembership | Select-Object GroupName, ComputerName, ContentPath | Format-Table -HideTableHeaders
    } -SuccessPatterns @('PUBLIC_TARGET_SET_OK', 'PRIVATE_TARGET_SET_OK') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On C1-DC1, confirm the DFS namespace still presents redundant public and private content membership across C1-DC1, C1-DC2, and C1FS so namespace failover remains available.'

    Invoke-ToolkitWinrmTest -Name 'Site 2 C1FS server role and storage summary' -ComputerName $s2c1fs.Address -Device $s2c1fs.DisplayName -DocSection 'Service Block 4 / Hotseat 1 / Site 2 Company 1 file path' -CommandLines @(
        'Get-SmbShare',
        'Get-IscsiSession',
        'Get-Disk'
    ) -ScriptBlock {
        $shares = @(Get-SmbShare | Where-Object { $_.Name -notin @('ADMIN$', 'C$', 'IPC$', 'print$') })
        $sessions = @(Get-IscsiSession)
        $dataDisks = @(Get-Disk | Where-Object { $_.Number -gt 0 -and $_.OperationalStatus -eq 'Online' })

        $shares | Select-Object Name, Path
        $sessions
        $dataDisks | Select-Object Number, FriendlyName, BusType, OperationalStatus, Size

        if ($shares.Count -gt 0) {
            'S2_C1FS_SHARES_OK'
        }
        else {
            'S2_C1FS_SHARES_FAIL'
        }

        if ($sessions.Count -gt 0) {
            'S2_C1FS_ISCSI_OK'
        }
        else {
            'S2_C1FS_ISCSI_FAIL'
        }

        if ($dataDisks.Count -gt 0) {
            'S2_C1FS_STORAGE_OK'
        }
        else {
            'S2_C1FS_STORAGE_FAIL'
        }
    } -SuccessPatterns @('S2_C1FS_SHARES_OK', 'S2_C1FS_ISCSI_OK', 'S2_C1FS_STORAGE_OK') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On Site 2 C1FS, confirm the file server is publishing SMB shares from attached storage rather than existing only as a reachable endpoint.'

    $site2C1ManualResult = New-ToolkitResult -Name 'Site 2 C1WindowsClient interactive share workflow (manual)' -Status 'REVIEW' -Device $s2c1WindowsClient.DisplayName -DocSection 'Service Block 4 / Hotseat 1 / Site 2 Company 1 client' -Method 'Manual adjunct' -Commands @(
        'RDP to Site 2 C1WindowsClient as c1\admin, c1\employee1, and c1\employee2'
        'In the Company 1 Public path, create username_timestamp.txt and confirm the other Company 1 users can see it'
        'In each user''s Company 1 Private path, create username_timestamp.txt and confirm the other Company 1 users do not see it'
        'Delete the temporary Public / Private test files after verification'
    ) -Check 'On Site 2 C1WindowsClient, complete an interactive Company 1 Public / Private workflow because the available Site 2 C1 Ubuntu client does not expose a reliable non-interactive SMB write path for automated proof.' -Details @'
MANUAL_REQUIRED
Why this remains manual:
- Site 2 C1UbuntuClient currently does not provide smbclient, mount.cifs, or another reliable non-interactive SMB write path in the live environment.
- The Group 6 toolkit therefore keeps the Site 2 Company 1 server-path and storage checks automated, and moves the final client-side Public / Private create-and-isolation proof to this explicit manual walkthrough.

Expected interactive proof:
- Public: each Company 1 user can create username_timestamp.txt and the other Company 1 users can see that file.
- Private: each Company 1 user can create username_timestamp.txt in their own Private view and the other Company 1 users do not see it.
- Cleanup: remove the temporary files after the walkthrough.
'@
    Add-ToolkitResult -Result $site2C1ManualResult
    Write-ToolkitResult -Result $site2C1ManualResult
}

function Invoke-Group6SB4Hotseat2Site2Tests {
    [CmdletBinding()]
    param()

    $c2fs = Get-ToolkitHost 'S2C2FS'
    $c2LinuxClient = Get-ToolkitHost 'S2C2LinuxClient'
    $c2Specs = Get-Group6C2DomainUserSpecs

    Invoke-ToolkitSshTest -Name 'Site 2 C2FS storage chain summary' -Host $c2fs.Address -User $c2fs.LinuxUser -Device $c2fs.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 file path' -Commands @(
        'printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active smbd | grep -qx "active" && echo SMBD_ACTIVE || echo SMBD_INACTIVE',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" systemctl is-active iscsid | grep -qx "active" && echo ISCSID_ACTIVE || echo ISCSID_INACTIVE',
        'findmnt /mnt/c2_public >/dev/null 2>&1 && echo SYNC_DISK_MOUNT_PRESENT || echo SYNC_DISK_MOUNT_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session | grep -q "172.30.65.194:3260" && echo C2_SAN_SESSION_PRESENT || echo C2_SAN_SESSION_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" testparm -s | egrep "C2_Public|C2_Private|/mnt/c2_public/Private/%U" || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" testparm -s | grep -q "\\[C2_Public\\]" && echo C2_PUBLIC_SHARE_PRESENT || echo C2_PUBLIC_SHARE_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" testparm -s | grep -q "\\[C2_Private\\]" && echo C2_PRIVATE_SHARE_PRESENT || echo C2_PRIVATE_SHARE_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" testparm -s | grep -q "/mnt/c2_public/Private/%U" && echo C2_PRIVATE_PATH_PRESENT || echo C2_PRIVATE_PATH_MISSING',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" tail -n 20 /var/log/c2_site1_sync.log >/dev/null 2>&1 && echo SYNC_LOG_PRESENT || echo SYNC_LOG_MISSING',
        'findmnt /mnt/c2_public || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" iscsiadm -m session || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" find /mnt/c2_public -maxdepth 2 -type d | sort || true',
        'printf "%s\n" "Cisco123!" | sudo -S -p "" tail -n 20 /var/log/c2_site1_sync.log || true'
    ) -SuccessPatterns @('SMBD_ACTIVE', 'ISCSID_ACTIVE', 'SYNC_DISK_MOUNT_PRESENT', 'C2_SAN_SESSION_PRESENT', 'C2_PUBLIC_SHARE_PRESENT', 'C2_PRIVATE_SHARE_PRESENT', 'C2_PRIVATE_PATH_PRESENT', 'SYNC_LOG_PRESENT') -MissingEvidenceStatus 'FAIL' -CheckDescription 'On Site 2 C2FS, confirm Company 2 file services still sit on an iSCSI-backed mounted volume with published public/private shares and recent synchronization evidence.'

    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient hostname-based SMB browse summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands (New-Group6Site2C2SmbBrowseCommands) -SuccessPatterns @(
        'SMBCLIENT_PRESENT','C2FS_HOST_OK','C2FS_BROWSE_PUBLIC_OK'
    ) -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 60 -CheckDescription 'On Site 2 C2LinuxClient, confirm smbclient is available, c2fs.c2.local resolves by name, and authenticated hostname-based SMB browse reaches the C2FS server; direct C2_Private access is validated in the per-user share checks below.'

    $perUserCommands = New-Group6Site2C2SmbShareCommands -UserSpecs $c2Specs -ShareTypes @('Public', 'Private')
    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient per-user share access summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands $perUserCommands -SuccessPatterns @(
        'ADMIN_PUBLIC_ACCESS_OK','ADMIN_PRIVATE_ACCESS_OK',
        'EMPLOYEE1_PUBLIC_ACCESS_OK','EMPLOYEE1_PRIVATE_ACCESS_OK',
        'EMPLOYEE2_PUBLIC_ACCESS_OK','EMPLOYEE2_PRIVATE_ACCESS_OK'
    ) -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 60 -CheckDescription 'On Site 2 C2LinuxClient, confirm admin plus employee1@c2.local and employee2@c2.local can open Company 2 Public and their authenticated C2_Private view through hostname-based SMB.'

    $site2C2PublicWritePlan = New-Group6Site2C2SmbPublicWriteWorkflowPlan -UserSpecs $c2Specs
    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient public share create-and-visibility summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands $site2C2PublicWritePlan.Commands -DisplayCommands $site2C2PublicWritePlan.DisplayCommands -SuccessPatterns $site2C2PublicWritePlan.SuccessPatterns -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 120 -CheckDescription 'On Site 2 C2LinuxClient, upload a temporary file into C2_Public for each user, confirm the other users can see it through their own hostname-based SMB view, and then remove the temporary files.'

    $site2C2PrivateWritePlan = New-Group6Site2C2SmbPrivateWriteWorkflowPlan -UserSpecs $c2Specs
    Invoke-ToolkitSshTest -Name 'Site 2 C2LinuxClient private share create-and-isolation summary' -Host $c2LinuxClient.Address -User $c2LinuxClient.LinuxUser -Device $c2LinuxClient.DisplayName -DocSection 'Service Block 4 / Hotseat 2 / Site 2 Company 2 client' -Commands $site2C2PrivateWritePlan.Commands -DisplayCommands $site2C2PrivateWritePlan.DisplayCommands -SuccessPatterns $site2C2PrivateWritePlan.SuccessPatterns -MissingEvidenceStatus 'FAIL' -CommandTimeoutSeconds 120 -CheckDescription 'On Site 2 C2LinuxClient, upload a temporary file into each user''s authenticated C2_Private view, confirm the other users do not see it through their own Private view, and then remove the temporary files.'
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
    Invoke-Group6SB1Hotseat1AdditionalTests
    Invoke-Group6SB1Hotseat1Site2Tests
    Invoke-SB2-Hotseat1Tests
    Invoke-Group6SB2Hotseat1AdditionalTests
    Invoke-Group6SB2Hotseat1Site2Tests
    Invoke-SB3-Hotseat1Tests
    Invoke-Group6SB3Hotseat1Site2Tests
    Invoke-SB4-Hotseat1Tests
    Invoke-Group6SB4Hotseat1AdditionalTests
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
    Invoke-Group6SB2Hotseat2AdditionalTests
    Invoke-Group6SB2Hotseat2Site2Tests
    Invoke-SB3-Hotseat2Tests
    Invoke-SB4-Hotseat2Tests
    Invoke-Group6SB4Hotseat2Site2Tests
    Invoke-SB5-Hotseat2Tests
}

function Invoke-Group6ServiceBlock1 { [CmdletBinding()] param() Invoke-SB1-Hotseat1Tests; Invoke-SB1-Hotseat2Tests; Invoke-Group6SB1Hotseat1AdditionalTests; Invoke-Group6SB1Hotseat1Site2Tests; Invoke-Group6SB1Hotseat2Site2Tests }
function Invoke-Group6ServiceBlock2 { [CmdletBinding()] param() Invoke-SB2-Hotseat1Tests; Invoke-SB2-Hotseat2Tests; Invoke-Group6SB2Hotseat1AdditionalTests; Invoke-Group6SB2Hotseat1Site2Tests; Invoke-Group6SB2Hotseat2AdditionalTests; Invoke-Group6SB2Hotseat2Site2Tests }
function Invoke-Group6ServiceBlock3 { [CmdletBinding()] param() Invoke-SB3-Hotseat1Tests; Invoke-SB3-Hotseat2Tests; Invoke-Group6SB3Hotseat1Site2Tests }
function Invoke-Group6ServiceBlock4 { [CmdletBinding()] param() Invoke-SB4-Hotseat1Tests; Invoke-Group6SB4Hotseat1AdditionalTests; Invoke-SB4-Hotseat2Tests; Invoke-Group6SB4Hotseat1Site2Tests; Invoke-Group6SB4Hotseat2Site2Tests }
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
