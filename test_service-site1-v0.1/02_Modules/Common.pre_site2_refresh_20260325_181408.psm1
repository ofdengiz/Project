$script:ToolkitContext = $null

function Initialize-TestToolkit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RootPath
    )

    $configPath = Join-Path $RootPath '01_Config\LabConfig.psd1'
    if (-not (Test-Path $configPath)) {
        throw "Toolkit config not found: $configPath"
    }

    $config = Import-PowerShellDataFile -Path $configPath
    $config.ResultsRoot = Join-Path $RootPath '04_Results'
    $config.ChecklistRoot = Join-Path $RootPath '03_Checklists'
    if (-not (Test-Path $config.ResultsRoot)) {
        New-Item -ItemType Directory -Force -Path $config.ResultsRoot | Out-Null
    }

    $script:ToolkitContext = @{
        RootPath          = $RootPath
        Config            = $config
        WindowsCredential = $null
        WindowsCredentials = @{}
        SessionResults    = [System.Collections.Generic.List[object]]::new()
        SessionStartedAt  = Get-Date
        SessionLogPath    = $null
    }

    $sessionLog = Join-Path $config.ResultsRoot 'latest_session.log'
    $sessionBanner = "=== Session started: $($script:ToolkitContext.SessionStartedAt.ToString('s')) ==="

    try {
        $sessionBanner | Set-Content -Path $sessionLog -ErrorAction Stop
        $script:ToolkitContext.SessionLogPath = $sessionLog
    }
    catch {
        $fallbackLog = Join-Path $config.ResultsRoot ("session_{0}.log" -f $script:ToolkitContext.SessionStartedAt.ToString('yyyyMMdd_HHmmss'))
        try {
            $sessionBanner | Set-Content -Path $fallbackLog -ErrorAction Stop
            $script:ToolkitContext.SessionLogPath = $fallbackLog
        }
        catch {
            Write-Verbose "Unable to initialize session log: $($_.Exception.Message)"
        }
    }

    Initialize-ToolkitConsoleSafety

    return $script:ToolkitContext
}

function Get-ToolkitConfig {
    [CmdletBinding()]
    param()

    if (-not $script:ToolkitContext) {
        throw 'Toolkit context has not been initialized.'
    }

    return $script:ToolkitContext.Config
}

function Get-ToolkitRoot {
    [CmdletBinding()]
    param()

    if (-not $script:ToolkitContext) {
        throw 'Toolkit context has not been initialized.'
    }

    return $script:ToolkitContext.RootPath
}

function Get-ToolkitHost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $config = Get-ToolkitConfig
    if (-not $config.Hosts.ContainsKey($Name)) {
        throw "Host '$Name' was not found in LabConfig.psd1."
    }

    return $config.Hosts[$Name]
}

function Get-ToolkitHostByAddress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Address
    )

    $config = Get-ToolkitConfig
    foreach ($entry in $config.Hosts.GetEnumerator()) {
        if ($entry.Value.Address -eq $Address) {
            return $entry.Value
        }
    }

    return $null
}

function Show-ToolkitHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    try {
        Clear-Host -ErrorAction Stop
    }
    catch {
        Write-Verbose "Clear-Host skipped: $($_.Exception.Message)"
    }
    Write-Host '=== Group 6 Cross-Site Self-Test Toolkit ===' -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Yellow
    Write-Host 'Read-only validation only. No configuration changes are performed.' -ForegroundColor DarkGray
    Write-Host ''
}

function Initialize-ToolkitConsoleSafety {
    [CmdletBinding()]
    param()

    if (-not $IsWindows) {
        return
    }

    try {
        if (-not ('ToolkitConsole.NativeMethods' -as [type])) {
            Add-Type -Namespace ToolkitConsole -Name NativeMethods -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern System.IntPtr GetStdHandle(int nStdHandle);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out int lpMode);

[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, int dwMode);
"@
            -ErrorAction Stop
        }

        $STD_INPUT_HANDLE = -10
        $ENABLE_QUICK_EDIT_MODE = 0x0040
        $ENABLE_EXTENDED_FLAGS = 0x0080

        $inputHandle = [ToolkitConsole.NativeMethods]::GetStdHandle($STD_INPUT_HANDLE)
        $mode = 0
        if ($inputHandle -ne [IntPtr]::Zero -and [ToolkitConsole.NativeMethods]::GetConsoleMode($inputHandle, [ref]$mode)) {
            $newMode = ($mode -bor $ENABLE_EXTENDED_FLAGS) -band (-bnot $ENABLE_QUICK_EDIT_MODE)
            [ToolkitConsole.NativeMethods]::SetConsoleMode($inputHandle, $newMode) | Out-Null
        }
    }
    catch {
        Write-Verbose "Console safety initialization skipped: $($_.Exception.Message)"
    }
}

function Get-ToolkitConsoleWidth {
    [CmdletBinding()]
    param()

    try {
        $width = [int]$Host.UI.RawUI.WindowSize.Width
        if ($width -lt 60) {
            return 120
        }

        return $width
    }
    catch {
        return 120
    }
}

function Write-ToolkitWrappedText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter(Mandatory)]
        [string]$Text
    )

    $indent = ' ' * $Prefix.Length
    $lines = $Text -split "(`r`n|`n)"

    foreach ($line in $lines) {
        $remaining = [string]$line
        $currentPrefix = $Prefix

        if ([string]::IsNullOrEmpty($remaining)) {
            Write-Host $currentPrefix
            $Prefix = $indent
            continue
        }

        while ($remaining.Length -gt 0) {
            $available = [Math]::Max(20, (Get-ToolkitConsoleWidth) - $currentPrefix.Length - 1)
            if ($remaining.Length -le $available) {
                Write-Host ($currentPrefix + $remaining)
                break
            }

            $breakIndex = $remaining.LastIndexOf(' ', $available)
            if ($breakIndex -lt 10) {
                $breakIndex = $available
            }

            $segment = $remaining.Substring(0, $breakIndex).TrimEnd()
            Write-Host ($currentPrefix + $segment)
            $remaining = $remaining.Substring($breakIndex).TrimStart()
            $currentPrefix = $indent
        }

        $Prefix = $indent
    }
}

function Pause-Toolkit {
    [CmdletBinding()]
    param()

    Read-Host 'Press Enter to continue' | Out-Null
}

function Get-WindowsCredential {
    [CmdletBinding()]
    param()

    if (-not $script:ToolkitContext.WindowsCredential) {
        Write-Host 'Enter a Windows administrative credential for remote WinRM tests.' -ForegroundColor Yellow
        $script:ToolkitContext.WindowsCredential = Get-Credential
    }

    return $script:ToolkitContext.WindowsCredential
}

function Get-WindowsCredentialForComputer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $config = Get-ToolkitConfig
    $hostEntry = Get-ToolkitHostByAddress -Address $ComputerName

    if (-not $hostEntry) {
        throw "No host entry found for Windows credential lookup: $ComputerName"
    }

    if (-not $hostEntry.ContainsKey('WindowsUser') -or -not $hostEntry.WindowsUser) {
        throw "WindowsUser is not defined for host: $ComputerName"
    }

    $plainPassword = if ($hostEntry.ContainsKey('WindowsPassword') -and $hostEntry.WindowsPassword) {
        [string]$hostEntry.WindowsPassword
    }
    elseif ($config.ContainsKey('DefaultWindowsPassword') -and $config.DefaultWindowsPassword) {
        [string]$config.DefaultWindowsPassword
    }
    else {
        throw 'DefaultWindowsPassword is not defined in LabConfig.psd1.'
    }

    $cacheKey = '{0}|{1}' -f $ComputerName, $hostEntry.WindowsUser
    if ($script:ToolkitContext.WindowsCredentials.ContainsKey($cacheKey)) {
        return $script:ToolkitContext.WindowsCredentials[$cacheKey]
    }

    $securePassword = ConvertTo-SecureString -String $plainPassword -AsPlainText -Force
    $credential = [pscredential]::new([string]$hostEntry.WindowsUser, $securePassword)
    $script:ToolkitContext.WindowsCredentials[$cacheKey] = $credential
    return $credential
}

function Get-LinuxPassword {
    [CmdletBinding()]
    param(
        [string]$Host
    )

    $config = Get-ToolkitConfig
    if ($Host) {
        $hostEntry = Get-ToolkitHostByAddress -Address $Host
        if ($hostEntry -and $hostEntry.ContainsKey('LinuxPassword') -and $hostEntry.LinuxPassword) {
            return [string]$hostEntry.LinuxPassword
        }
    }

    if ($config.ContainsKey('DefaultLinuxPassword') -and $config.DefaultLinuxPassword) {
        return [string]$config.DefaultLinuxPassword
    }

    throw 'DefaultLinuxPassword is not defined in LabConfig.psd1.'
}

function Get-ToolkitSshNetAssemblyPath {
    [CmdletBinding()]
    param()

    $assemblyPath = Join-Path (Get-ToolkitRoot) '02_Modules\Renci.SshNet.dll'
    if (Test-Path $assemblyPath) {
        return $assemblyPath
    }

    return $null
}

function Initialize-ToolkitSshNet {
    [CmdletBinding()]
    param()

    $assemblyPath = Get-ToolkitSshNetAssemblyPath
    if (-not $assemblyPath) {
        throw 'Renci.SshNet.dll was not found in the toolkit package.'
    }

    $loaded = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
        $_.GetName().Name -eq 'Renci.SshNet'
    }

    if (-not $loaded) {
        Add-Type -Path $assemblyPath -ErrorAction Stop
    }
}

function New-ToolkitResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('PASS', 'FAIL', 'REVIEW')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Device,

        [Parameter(Mandatory)]
        [string]$DocSection,

        [Parameter(Mandatory)]
        [string]$Method,

        [string[]]$Commands = @(),

        [AllowEmptyString()]
        [string]$Check = '',

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Details
    )

    [pscustomobject]@{
        Timestamp = Get-Date
        Device    = $Device
        Section   = $DocSection
        Test      = $Name
        Method    = $Method
        Status    = $Status
        Commands  = @($Commands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Check     = $Check.Trim()
        Details   = $Details.Trim()
    }
}

function Get-ToolkitDeviceKey {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Device
    )

    $key = [string]$Device
    if ($key -match '^(?<Base>.+?)\s*->') {
        $key = $matches.Base
    }

    $key = $key -replace '^\s*Site\s+\d+\s+', ''
    return $key.Trim()
}

function Get-ToolkitImpactedSite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    $text = @(
        [string]$Result.Device,
        [string]$Result.Section,
        [string]$Result.Test,
        [string]$Result.Check,
        [string]$Result.Details
    ) -join "`n"

    $hasSite1 = $text -match '\bSite 1\b|172\.30\.64\.|192\.168\.64\.'
    $hasSite2 = $text -match '\bSite 2\b|172\.30\.65\.|192\.168\.65\.'

    if ($hasSite1 -and $hasSite2) {
        return 'Cross-site'
    }
    if ($hasSite2) {
        return 'Site 2'
    }
    if ($hasSite1) {
        return 'Site 1'
    }

    return 'Unspecified'
}

function Get-ToolkitResultAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    if ($Result.Status -eq 'PASS') {
        return 'Expected evidence observed'
    }

    $combined = @(
        [string]$Result.Test,
        [string]$Result.Device,
        [string]$Result.Section,
        [string]$Result.Method,
        [string]$Result.Details
    ) -join "`n"

    if ($Result.Status -eq 'REVIEW') {
        if ($combined -match 'non-interactive WinRM validation context|MAPPED_DRIVE_STATUS_UNAVAILABLE|Review guidance :') {
            return 'Interactive-context limitation'
        }

        return 'Manual follow-up recommended'
    }

    if ($Result.Test -eq 'Site 2 C2LinuxClient hostname-based SMB browse summary' -and $combined -match 'C2FS_BROWSE_PUBLIC_OK' -and $combined -match 'C2FS_BROWSE_PRIVATE_FAIL') {
        return 'Script expectation issue'
    }

    if ($Result.Test -eq 'C1 DFS namespace target-set summary' -and $combined -match 'Cannot get DFS folder properties') {
        return 'Script or cmdlet-context issue'
    }

    if ($combined -match 'Authentication hint :|Permission denied|Authentication failed|No suitable authentication|Logon failure|The user name or password is incorrect') {
        return 'Credential or permission issue'
    }

    if ($Result.Method -eq 'Local port probe' -and $combined -match 'TcpTestSucceeded\s*:\s*False') {
        return 'Connectivity or management-plane issue'
    }

    if ($combined -match 'WinRM cannot complete the operation|Connection refused|actively refused|No route to host|Unable to connect|A connection attempt failed|Connection timed out|timed out') {
        return 'Connectivity or management-plane issue'
    }

    if ($combined -match 'HTTP_FQDN_ALLOWED|HTTPS_IP_ALLOWED|HTTP_IP_ALLOWED|SECONDARY_EXTERNAL_LOOKUP_FAIL|PUBLIC_RECURSION_FAIL|NXDOMAIN|_MISSING\b|_FAIL\b') {
        return 'Actual environment failure'
    }

    return 'Failure needs inspection'
}

function Get-ToolkitResultLikelyCause {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    if ($Result.Status -eq 'PASS') {
        return ''
    }

    $combined = @(
        [string]$Result.Test,
        [string]$Result.Device,
        [string]$Result.Section,
        [string]$Result.Method,
        [string]$Result.Details
    ) -join "`n"

    if ($Result.Status -eq 'REVIEW' -and $combined -match 'non-interactive WinRM validation context|MAPPED_DRIVE_STATUS_UNAVAILABLE|Review guidance :') {
        return 'This proof depends on an interactive Windows user session, but the toolkit is intentionally running through a non-interactive read-only WinRM context.'
    }

    if ($Result.Test -eq 'Site 2 C2LinuxClient hostname-based SMB browse summary' -and $combined -match 'C2FS_BROWSE_PUBLIC_OK' -and $combined -match 'C2FS_BROWSE_PRIVATE_FAIL') {
        return 'Authenticated smbclient browsing exposed C2_Public, but Samba did not advertise C2_Private in the browse list even though direct per-share access can still succeed.'
    }

    if ($Result.Test -eq 'C1 DFS namespace target-set summary' -and $combined -match 'Cannot get DFS folder properties') {
        return 'The DFS cmdlet could not enumerate folder-target properties through this namespace path in the current context, even though other DFS evidence was collected elsewhere in the run.'
    }

    if ($combined -match 'Authentication hint :|Permission denied|Authentication failed|No suitable authentication|Logon failure|The user name or password is incorrect') {
        return 'The script could not authenticate to the target with the configured account, or the target refused that account for the requested remote-management path.'
    }

    if ($combined -match 'WinRM cannot complete the operation') {
        return 'The runner could not open a WinRM session to this host. This usually means WinRM is disabled, blocked by firewall, or not exposed from the current path.'
    }

    if ($Result.Method -eq 'Local port probe' -and $combined -match 'TcpTestSucceeded\s*:\s*False') {
        return 'The required TCP port did not answer from the current runner, which points to routing, firewall, listener, or service-exposure issues.'
    }

    if ($combined -match 'SECONDARY_EXTERNAL_LOOKUP_FAIL|NXDOMAIN') {
        return 'This DNS node resolved the internal records but failed the external recursive lookup, which points to recursion or forwarder behavior on that specific secondary DNS server.'
    }

    if ($combined -match 'HTTP_FQDN_ALLOWED:\d+') {
        return 'HTTP by FQDN is still allowed from this path, so HTTPS-only hostname enforcement is not in place on the tested web path.'
    }

    if ($combined -match 'HTTPS_IP_ALLOWED:\d+') {
        return 'Direct HTTPS access by IP is still allowed, so the site is not fully constrained to the approved hostname-only access pattern.'
    }

    if ($combined -match 'HTTP_IP_ALLOWED:\d+') {
        return 'Direct HTTP access by IP is still allowed, so the site is not fully constrained to the approved hostname-only access pattern.'
    }

    if ($combined -match '_MISSING\b') {
        return 'One or more required evidence markers were missing from the command output, so the observed state does not yet match the documented design.'
    }

    if ($combined -match '_FAIL\b') {
        return 'The target returned explicit failure markers for one or more required checks, so the observed state does not yet match the documented design.'
    }

    if ($Result.Status -eq 'REVIEW') {
        return 'The toolkit captured useful evidence, but this item still needs a manual or context-specific follow-up to reach a final conclusion.'
    }

    return 'Expected evidence was not fully observed. Review the command output above for the missing or contradictory markers.'
}

function Get-ToolkitPassReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    return ('{0} ({1})' -f $Result.Test, $Result.Device)
}

function Get-ToolkitRelatedPasses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    if (-not $script:ToolkitContext -or -not $script:ToolkitContext.SessionResults) {
        return @()
    }

    $related = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $deviceKey = Get-ToolkitDeviceKey -Device $Result.Device
    $sectionRoot = (([string]$Result.Section) -split '/' | Select-Object -First 1).Trim()

    $candidateGroups = @(
        @(
            $script:ToolkitContext.SessionResults |
                Where-Object {
                    $_.Status -eq 'PASS' -and
                    $_.Test -ne $Result.Test -and
                    (Get-ToolkitDeviceKey -Device $_.Device) -eq $deviceKey
                }
        ),
        @(
            $script:ToolkitContext.SessionResults |
                Where-Object {
                    $_.Status -eq 'PASS' -and
                    $_.Test -ne $Result.Test -and
                    $_.Section -eq $Result.Section
                }
        ),
        @(
            $script:ToolkitContext.SessionResults |
                Where-Object {
                    $_.Status -eq 'PASS' -and
                    $_.Test -ne $Result.Test -and
                    $_.Section -like "$sectionRoot*"
                }
        )
    )

    foreach ($group in $candidateGroups) {
        foreach ($candidate in $group) {
            $reference = Get-ToolkitPassReference -Result $candidate
            if ($seen.Add($reference)) {
                $related.Add($reference)
            }

            if ($related.Count -ge 3) {
                return @($related)
            }
        }
    }

    return @($related)
}

function Update-ToolkitResultAnnotations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    $Result | Add-Member -NotePropertyName ImpactedSite -NotePropertyValue (Get-ToolkitImpactedSite -Result $Result) -Force
    $Result | Add-Member -NotePropertyName Assessment -NotePropertyValue (Get-ToolkitResultAssessment -Result $Result) -Force
    $Result | Add-Member -NotePropertyName LikelyCause -NotePropertyValue (Get-ToolkitResultLikelyCause -Result $Result) -Force
    $Result | Add-Member -NotePropertyName RelatedPasses -NotePropertyValue @(Get-ToolkitRelatedPasses -Result $Result) -Force

    return $Result
}

function Add-ToolkitResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    Update-ToolkitResultAnnotations -Result $Result | Out-Null
    $script:ToolkitContext.SessionResults.Add($Result)

    if ($script:ToolkitContext.SessionLogPath) {
        $line = '{0} | {1} | {2} | {3} | {4}' -f `
            $Result.Timestamp.ToString('s'),
            $Result.Status,
            $Result.Section,
            $Result.Device,
            $Result.Test

        try {
            Add-Content -Path $script:ToolkitContext.SessionLogPath -Value $line -ErrorAction Stop
        }
        catch {
            Write-Verbose "Unable to write session log: $($_.Exception.Message)"
        }
    }
}

function Write-ToolkitResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    Update-ToolkitResultAnnotations -Result $Result | Out-Null

    $color = switch ($Result.Status) {
        'PASS'  { 'Green' }
        'FAIL'  { 'Red' }
        default { 'Yellow' }
    }

    Write-Host "[$($Result.Status)] $($Result.Test)" -ForegroundColor $color
    Write-ToolkitWrappedText -Prefix 'Device:  ' -Text $Result.Device
    Write-ToolkitWrappedText -Prefix 'Section: ' -Text $Result.Section
    Write-ToolkitWrappedText -Prefix 'Method:  ' -Text $Result.Method
    if ($Result.Commands -and $Result.Commands.Count -gt 0) {
        if ($Result.Commands.Count -eq 1) {
            Write-ToolkitWrappedText -Prefix 'Command: ' -Text $Result.Commands[0]
        }
        else {
            Write-Host 'Commands:'
            foreach ($command in $Result.Commands) {
                Write-ToolkitWrappedText -Prefix '  ' -Text $command
            }
        }
    }
    if ($Result.Check) {
        Write-ToolkitWrappedText -Prefix 'Check:   ' -Text $Result.Check
    }
    if ($Result.Status -ne 'PASS') {
        if ($Result.ImpactedSite -and $Result.ImpactedSite -ne 'Unspecified') {
            Write-ToolkitWrappedText -Prefix 'Site:    ' -Text $Result.ImpactedSite
        }
        if ($Result.Assessment) {
            Write-ToolkitWrappedText -Prefix 'Assessment: ' -Text $Result.Assessment
        }
        if ($Result.LikelyCause) {
            Write-ToolkitWrappedText -Prefix 'Likely:  ' -Text $Result.LikelyCause
        }
        if ($Result.RelatedPasses -and $Result.RelatedPasses.Count -gt 0) {
            Write-ToolkitWrappedText -Prefix 'Related: ' -Text ($Result.RelatedPasses -join '; ')
        }
    }
    if ($Result.Details) {
        Write-Host $Result.Details.Trim()
    }
    Write-Host ''
}

function Write-ToolkitBatchSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [int]$StartIndex
    )

    $results = @($script:ToolkitContext.SessionResults | Select-Object -Skip $StartIndex)
    $passCount = @($results | Where-Object { $_.Status -eq 'PASS' }).Count
    $failCount = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
    $reviewCount = @($results | Where-Object { $_.Status -eq 'REVIEW' }).Count

    Write-Host "=== Summary: $Label ===" -ForegroundColor Cyan
    Write-Host "PASS   : $passCount" -ForegroundColor Green
    Write-Host "FAIL   : $failCount" -ForegroundColor Red
    Write-Host "REVIEW : $reviewCount" -ForegroundColor Yellow
    Write-Host 'Meaning: PASS = expected evidence observed; FAIL = expected evidence missing or test execution blocked; REVIEW = manual follow-up recommended.' -ForegroundColor DarkGray

    $flagged = @($results | Where-Object { $_.Status -ne 'PASS' })
    if ($flagged.Count -gt 0) {
        Write-Host ''
        Write-Host 'Flagged items:' -ForegroundColor Yellow
        foreach ($item in $flagged) {
            Update-ToolkitResultAnnotations -Result $item | Out-Null
            Write-Host "- [$($item.Status)] $($item.Test) ($($item.Device))"
            if ($item.ImpactedSite -and $item.ImpactedSite -ne 'Unspecified') {
                Write-ToolkitWrappedText -Prefix '  Site:        ' -Text $item.ImpactedSite
            }
            if ($item.Assessment) {
                Write-ToolkitWrappedText -Prefix '  Assessment:  ' -Text $item.Assessment
            }
            if ($item.LikelyCause) {
                Write-ToolkitWrappedText -Prefix '  Likely cause: ' -Text $item.LikelyCause
            }
            if ($item.RelatedPasses -and $item.RelatedPasses.Count -gt 0) {
                Write-ToolkitWrappedText -Prefix '  Related PASS: ' -Text ($item.RelatedPasses -join '; ')
            }
        }
    }

    Write-Host ''
}

function Invoke-ToolkitBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    $startIndex = $script:ToolkitContext.SessionResults.Count
    & $ScriptBlock
    Write-ToolkitBatchSummary -Label $Label -StartIndex $startIndex
}

function Get-ToolkitStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$Succeeded,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Output,

        [string[]]$SuccessPatterns = @(),

        [string[]]$FailPatterns = @(),

        [string[]]$ReviewPatterns = @(),

        [ValidateSet('REVIEW', 'FAIL')]
        [string]$MissingEvidenceStatus = 'REVIEW'
    )

    if (-not $Succeeded) {
        return 'FAIL'
    }

    foreach ($pattern in $FailPatterns) {
        if ($Output -match $pattern) {
            return 'FAIL'
        }
    }

    $hasSuccessPatterns = $SuccessPatterns -and $SuccessPatterns.Count -gt 0
    if ($hasSuccessPatterns) {
        $allSuccessPatternsMatched = $true
        foreach ($pattern in $SuccessPatterns) {
            if ($Output -notmatch $pattern) {
                $allSuccessPatternsMatched = $false
                break
            }
        }

        if ($allSuccessPatternsMatched) {
            return 'PASS'
        }
    }
    else {
        return 'REVIEW'
    }

    foreach ($pattern in $ReviewPatterns) {
        if ($Output -match $pattern) {
            return 'REVIEW'
        }
    }

    return $MissingEvidenceStatus
}

function Invoke-ToolkitLocalEndpointTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Address,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [string]$Device,

        [Parameter(Mandatory)]
        [string]$DocSection,

        [string[]]$CommandLines = @(),

        [string]$CheckDescription = '',

        [string]$Notes = ''
    )

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $iar = $client.BeginConnect($Address, $Port, $null, $null)
        $connected = $iar.AsyncWaitHandle.WaitOne(5000, $false)
        if ($connected) {
            $client.EndConnect($iar)
        }
        else {
            $client.Close()
        }

        $details = @"
ComputerName     : $Address
RemotePort       : $Port
TcpTestSucceeded : $connected
ICMP note        : Ping reply not required for this test; TCP reachability is the pass/fail condition.
"@
        if ($Notes) {
            $details += "`nNotes: $Notes"
        }

        $status = if ($connected) { 'PASS' } else { 'FAIL' }
        if (-not $CheckDescription) {
            $CheckDescription = "Confirm TCP reachability to $Address`:$Port from the jumpbox."
        }
        if (-not $CommandLines -or $CommandLines.Count -eq 0) {
            $CommandLines = @("Test-NetConnection -ComputerName $Address -Port $Port")
        }
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'Local port probe' -Commands $CommandLines -Check $CheckDescription -Details $details
    }
    catch {
        if (-not $CheckDescription) {
            $CheckDescription = "Confirm TCP reachability to $Address`:$Port from the jumpbox."
        }
        if (-not $CommandLines -or $CommandLines.Count -eq 0) {
            $CommandLines = @("Test-NetConnection -ComputerName $Address -Port $Port")
        }
        $result = New-ToolkitResult -Name $Name -Status 'FAIL' -Device $Device -DocSection $DocSection -Method 'Local port probe' -Commands $CommandLines -Check $CheckDescription -Details $_.Exception.Message
    }
    finally {
        if ($iar -and $iar.AsyncWaitHandle) {
            $iar.AsyncWaitHandle.Close()
        }
        if ($client) {
            $client.Dispose()
        }
    }

    Add-ToolkitResult -Result $result
    Write-ToolkitResult -Result $result
}

function Invoke-ToolkitWinrmTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [string]$Device,

        [Parameter(Mandatory)]
        [string]$DocSection,

        [string[]]$SuccessPatterns = @(),

        [string[]]$FailPatterns = @(),

        [string[]]$ReviewPatterns = @(),

        [ValidateSet('REVIEW', 'FAIL')]
        [string]$MissingEvidenceStatus = 'REVIEW',

        [string[]]$ReviewOnErrorPatterns = @(),

        [string]$ReviewGuidance = '',

        [string[]]$CommandLines = @(),

        [string]$CheckDescription = '',

        [switch]$UseCurrentCredential
    )

    try {
        $params = @{
            ComputerName = $ComputerName
            ScriptBlock  = $ScriptBlock
            ErrorAction  = 'Stop'
            SessionOption = (New-PSSessionOption -OpenTimeout 15000 -OperationTimeout 15000 -CancelTimeout 5000)
        }

        if (-not $UseCurrentCredential) {
            $params.Credential = Get-WindowsCredentialForComputer -ComputerName $ComputerName
        }

        $output = Invoke-Command @params 2>&1 | Out-String
        if ([string]::IsNullOrWhiteSpace($output)) {
            $output = '[no command output returned]'
        }
        $status = Get-ToolkitStatus -Succeeded $true -Output $output -SuccessPatterns $SuccessPatterns -FailPatterns $FailPatterns -ReviewPatterns $ReviewPatterns -MissingEvidenceStatus $MissingEvidenceStatus
        if ($status -eq 'REVIEW' -and $ReviewGuidance -and $output -notmatch 'Review guidance :') {
            $output = "$($output.TrimEnd())`nReview guidance : $ReviewGuidance"
        }
        if (-not $CheckDescription) {
            $CheckDescription = "Run a remote PowerShell check on $ComputerName and validate the expected evidence."
        }
        if (-not $CommandLines -or $CommandLines.Count -eq 0) {
            $CommandText = $ScriptBlock.ToString().Trim()
            if ($CommandText) {
                $CommandLines = @($CommandText -split "(`r`n|`n)" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }
            else {
                $CommandLines = @("Invoke-Command -ComputerName $ComputerName -ScriptBlock { ... }")
            }
        }
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'WinRM' -Commands $CommandLines -Check $CheckDescription -Details $output
    }
    catch {
        $errorText = $_.Exception.Message
        $status = 'FAIL'

        if ($errorText -match 'Access is denied|Logon failure|The user name or password is incorrect') {
            $errorText = "$errorText`nAuthentication hint : Verify WindowsUser/WindowsPassword for this host in LabConfig.psd1."
        }

        foreach ($pattern in $ReviewOnErrorPatterns) {
            if ($errorText -match $pattern) {
                $status = 'REVIEW'
                break
            }
        }

        if ($status -eq 'REVIEW' -and $ReviewGuidance) {
            $errorText = "$errorText`nReview guidance : $ReviewGuidance"
        }

        if (-not $CheckDescription) {
            $CheckDescription = "Run a remote PowerShell check on $ComputerName and validate the expected evidence."
        }
        if (-not $CommandLines -or $CommandLines.Count -eq 0) {
            $CommandText = $ScriptBlock.ToString().Trim()
            if ($CommandText) {
                $CommandLines = @($CommandText -split "(`r`n|`n)" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }
            else {
                $CommandLines = @("Invoke-Command -ComputerName $ComputerName -ScriptBlock { ... }")
            }
        }
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'WinRM' -Commands $CommandLines -Check $CheckDescription -Details $errorText
    }

    Add-ToolkitResult -Result $result
    Write-ToolkitResult -Result $result
}

function Invoke-ToolkitSshTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Host,

        [Parameter(Mandatory)]
        [string]$User,

        [Parameter(Mandatory)]
        [string[]]$Commands,

        [Parameter(Mandatory)]
        [string]$Device,

        [Parameter(Mandatory)]
        [string]$DocSection,

        [string[]]$SuccessPatterns = @(),

        [string[]]$FailPatterns = @(),

        [string[]]$ReviewPatterns = @(),

        [ValidateSet('REVIEW', 'FAIL')]
        [string]$MissingEvidenceStatus = 'REVIEW',

        [string[]]$ReviewOnErrorPatterns = @(),

        [string]$ReviewGuidance = '',

        [string[]]$DisplayCommands = @(),

        [int]$CommandTimeoutSeconds = 45,

        [string]$CheckDescription = ''
    )

    try {
        Initialize-ToolkitSshNet
        $commandText = ($Commands | Where-Object { $_ }) -join '; '
        $connectionInfo = [Renci.SshNet.PasswordConnectionInfo]::new($Host, $User, (Get-LinuxPassword -Host $Host))
        $connectionInfo.Timeout = [TimeSpan]::FromSeconds(10)

        $client = [Renci.SshNet.SshClient]::new($connectionInfo)
        $client.Connect()

        $command = $client.CreateCommand($commandText)
        $command.CommandTimeout = [TimeSpan]::FromSeconds($CommandTimeoutSeconds)
        $stdout = $command.Execute()
        $stderr = $command.Error

        $output = @($stdout, $stderr) -join [Environment]::NewLine
        $output = $output.Trim()
        if (-not $output) {
            $output = '[no command output returned]'
        }

        $status = Get-ToolkitStatus -Succeeded ($client.IsConnected -and ($command.ExitStatus -eq 0)) -Output $output -SuccessPatterns $SuccessPatterns -FailPatterns $FailPatterns -ReviewPatterns $ReviewPatterns -MissingEvidenceStatus $MissingEvidenceStatus
        if ($status -eq 'REVIEW' -and $ReviewGuidance -and $output -notmatch 'Review guidance :') {
            $output = "$($output.TrimEnd())`nReview guidance : $ReviewGuidance"
        }
        if (-not $CheckDescription) {
            $CheckDescription = "Run remote shell checks on $Host and validate the expected evidence."
        }
        if (-not $DisplayCommands -or $DisplayCommands.Count -eq 0) {
            $DisplayCommands = $Commands
        }
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'SSH' -Commands $DisplayCommands -Check $CheckDescription -Details $output
    }
    catch {
        $errorText = $_.Exception.Message
        $status = 'FAIL'

        if ($errorText -match 'Permission denied|Authentication failed|No suitable authentication') {
            $errorText = "$errorText`nAuthentication hint : Verify LinuxUser/LinuxPassword for this host in LabConfig.psd1."
        }

        foreach ($pattern in $ReviewOnErrorPatterns) {
            if ($errorText -match $pattern) {
                $status = 'REVIEW'
                break
            }
        }

        if ($status -eq 'REVIEW' -and $ReviewGuidance) {
            $errorText = "$errorText`nReview guidance : $ReviewGuidance"
        }

        if (-not $CheckDescription) {
            $CheckDescription = "Run remote shell checks on $Host and validate the expected evidence."
        }
        if (-not $DisplayCommands -or $DisplayCommands.Count -eq 0) {
            $DisplayCommands = $Commands
        }
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'SSH' -Commands $DisplayCommands -Check $CheckDescription -Details $errorText
    }
    finally {
        if ($command) {
            $command.Dispose()
        }
        if ($client) {
            if ($client.IsConnected) {
                $client.Disconnect()
            }
            $client.Dispose()
        }
    }

    Add-ToolkitResult -Result $result
    Write-ToolkitResult -Result $result
}

function Invoke-ToolkitHttpTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string]$Device,

        [Parameter(Mandatory)]
        [string]$DocSection,

        [string[]]$SuccessPatterns = @(),

        [ValidateSet('REVIEW', 'FAIL')]
        [string]$MissingEvidenceStatus = 'REVIEW',

        [string[]]$CommandLines = @(),

        [string]$CheckDescription = '',

        [string]$Method = 'HTTP GET'
    )

    $response = $null
    $stream = $null
    $reader = $null
    $uriObject = [System.Uri]$Uri
    $restoreCallback = $false
    $previousCallback = $null

    try {
        if ($uriObject.Scheme -eq 'https') {
            $previousCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            $restoreCallback = $true
        }

        $request = [System.Net.HttpWebRequest]::Create($uriObject)
        $request.Method = 'GET'
        $request.Timeout = 15000
        $request.ReadWriteTimeout = 15000
        $request.UserAgent = 'Site1Toolkit/1.0'

        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $stream = $response.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $body = $reader.ReadToEnd()
        $sample = ($body -replace '\s+', ' ').Trim()
        if ($sample.Length -gt 240) {
            $sample = $sample.Substring(0, 240) + '...'
        }

        $details = @"
StatusCode      : $([int]$response.StatusCode)
StatusDescription: $($response.StatusDescription)
ContentLength   : $($body.Length)
BodySample      : $sample
"@

        $statusOkay = ([int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 400)
        if ($SuccessPatterns.Count -gt 0) {
              $status = Get-ToolkitStatus -Succeeded $statusOkay -Output $details -SuccessPatterns $SuccessPatterns -MissingEvidenceStatus $MissingEvidenceStatus
        }
        else {
            $status = if ($statusOkay) { 'PASS' } else { 'FAIL' }
        }

        if (-not $CheckDescription) {
            $CheckDescription = "Request $Uri and confirm the web application returns a valid web response."
        }
        if (-not $CommandLines -or $CommandLines.Count -eq 0) {
            if ($uriObject.Scheme -eq 'https') {
                $CommandLines = @("Invoke-WebRequest -Uri '$Uri' -SkipCertificateCheck")
            }
            else {
                $CommandLines = @("Invoke-WebRequest -Uri '$Uri'")
            }
        }
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method $Method -Commands $CommandLines -Check $CheckDescription -Details $details
    }
    catch {
        if (-not $CheckDescription) {
            $CheckDescription = "Request $Uri and confirm the web application returns a valid web response."
        }
        if (-not $CommandLines -or $CommandLines.Count -eq 0) {
            if ($uriObject.Scheme -eq 'https') {
                $CommandLines = @("Invoke-WebRequest -Uri '$Uri' -SkipCertificateCheck")
            }
            else {
                $CommandLines = @("Invoke-WebRequest -Uri '$Uri'")
            }
        }
        $result = New-ToolkitResult -Name $Name -Status 'FAIL' -Device $Device -DocSection $DocSection -Method $Method -Commands $CommandLines -Check $CheckDescription -Details $_.Exception.Message
    }
    finally {
        if ($reader) { $reader.Dispose() }
        if ($stream) { $stream.Dispose() }
        if ($response) { $response.Dispose() }
        if ($restoreCallback) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $previousCallback
        }
    }

    Add-ToolkitResult -Result $result
    Write-ToolkitResult -Result $result
}

function Invoke-ToolkitHttpRejectionTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string[]]$Uris,

        [Parameter(Mandatory)]
        [string]$Device,

        [Parameter(Mandatory)]
        [string]$DocSection,

        [string[]]$CommandLines = @(),

        [string]$CheckDescription = '',

        [string]$Method = 'HTTP/HTTPS rejection'
    )

    $detailsLines = New-Object System.Collections.Generic.List[string]
    $allRejected = $true

    foreach ($Uri in $Uris) {
        $response = $null
        $stream = $null
        $reader = $null
        $uriObject = [System.Uri]$Uri
        $restoreCallback = $false
        $previousCallback = $null

        try {
            if ($uriObject.Scheme -eq 'https') {
                $previousCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                $restoreCallback = $true
            }

            $request = [System.Net.HttpWebRequest]::Create($uriObject)
            $request.Method = 'GET'
            $request.Timeout = 15000
            $request.ReadWriteTimeout = 15000
            $request.UserAgent = 'Site1Toolkit/1.0'

            $response = [System.Net.HttpWebResponse]$request.GetResponse()
            $stream = $response.GetResponseStream()
            $reader = [System.IO.StreamReader]::new($stream)
            $body = $reader.ReadToEnd()
            $sample = ($body -replace '\s+', ' ').Trim()
            if ($sample.Length -gt 160) {
                $sample = $sample.Substring(0, 160) + '...'
            }

            $statusCode = [int]$response.StatusCode
            if ($statusCode -ge 400 -and $statusCode -lt 500) {
                $detailsLines.Add("URI                 : $Uri")
                $detailsLines.Add("Observed            : HTTP $statusCode $($response.StatusDescription)")
                $detailsLines.Add('Outcome             : REJECTED_EXPECTED')
                $detailsLines.Add('')
            }
            else {
                $allRejected = $false
                $detailsLines.Add("URI                 : $Uri")
                $detailsLines.Add("Observed            : HTTP $statusCode $($response.StatusDescription)")
                $detailsLines.Add('Outcome             : ALLOWED_UNEXPECTED')
                if ($sample) {
                    $detailsLines.Add("BodySample          : $sample")
                }
                $detailsLines.Add('')
            }
        }
        catch [System.Net.WebException] {
            $webException = $_.Exception
            $httpResponse = $webException.Response -as [System.Net.HttpWebResponse]
            if ($httpResponse) {
                $statusCode = [int]$httpResponse.StatusCode
                if ($statusCode -ge 400 -and $statusCode -lt 500) {
                    $detailsLines.Add("URI                 : $Uri")
                    $detailsLines.Add("Observed            : HTTP $statusCode $($httpResponse.StatusDescription)")
                    $detailsLines.Add('Outcome             : REJECTED_EXPECTED')
                    $detailsLines.Add('')
                }
                else {
                    $allRejected = $false
                    $detailsLines.Add("URI                 : $Uri")
                    $detailsLines.Add("Observed            : HTTP $statusCode $($httpResponse.StatusDescription)")
                    $detailsLines.Add('Outcome             : ALLOWED_UNEXPECTED')
                    $detailsLines.Add('')
                }
            }
            else {
                $detailsLines.Add("URI                 : $Uri")
                $detailsLines.Add("Observed            : $($webException.Status)")
                $detailsLines.Add('Outcome             : CONNECTION_BLOCKED_EXPECTED')
                $detailsLines.Add('')
            }
        }
        catch {
            $detailsLines.Add("URI                 : $Uri")
            $detailsLines.Add("Observed            : $($_.Exception.Message)")
            $detailsLines.Add('Outcome             : CONNECTION_BLOCKED_EXPECTED')
            $detailsLines.Add('')
        }
        finally {
            if ($reader) { $reader.Dispose() }
            if ($stream) { $stream.Dispose() }
            if ($response) { $response.Dispose() }
            if ($restoreCallback) {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $previousCallback
            }
        }
    }

    if (-not $CheckDescription) {
        $CheckDescription = "Request the listed URIs and confirm direct IP or non-approved host access is rejected."
    }
    if (-not $CommandLines -or $CommandLines.Count -eq 0) {
        $CommandLines = foreach ($Uri in $Uris) {
            if ($Uri.StartsWith('https://')) {
                "Invoke-WebRequest -Uri '$Uri' -SkipCertificateCheck"
            }
            else {
                "Invoke-WebRequest -Uri '$Uri'"
            }
        }
    }

    $details = ($detailsLines | Where-Object { $_ -ne $null }) -join "`n"
    $status = if ($allRejected) { 'PASS' } else { 'FAIL' }
    $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method $Method -Commands $CommandLines -Check $CheckDescription -Details $details
    Add-ToolkitResult -Result $result
    Write-ToolkitResult -Result $result
}

function Export-ToolkitSummary {
    [CmdletBinding()]
    param()

    $resultsRoot = (Get-ToolkitConfig).ResultsRoot
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $summaryPath = Join-Path $resultsRoot "${timestamp}_Summary.txt"
    $results = $script:ToolkitContext.SessionResults

    $header = @(
        'Site 1 Service Block Test Toolkit Summary',
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Toolkit Version: $((Get-ToolkitConfig).ToolkitVersion)",
        ''
    )

    $body = foreach ($result in $results) {
        Update-ToolkitResultAnnotations -Result $result | Out-Null
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add(("[{0}] {1}" -f $result.Status, $result.Test))
        $lines.Add("Device:  $($result.Device)")
        $lines.Add("Section: $($result.Section)")
        $lines.Add("Method:  $($result.Method)")
        if ($result.Status -ne 'PASS' -and $result.ImpactedSite -and $result.ImpactedSite -ne 'Unspecified') {
            $lines.Add("Site:    $($result.ImpactedSite)")
        }
        if ($result.Status -ne 'PASS' -and $result.Assessment) {
            $lines.Add("Assessment: $($result.Assessment)")
        }
        if ($result.Status -ne 'PASS' -and $result.LikelyCause) {
            $lines.Add("Likely:  $($result.LikelyCause)")
        }
        if ($result.Status -ne 'PASS' -and $result.RelatedPasses -and $result.RelatedPasses.Count -gt 0) {
            $lines.Add("Related PASS: $($result.RelatedPasses -join '; ')")
        }
        if ($result.Commands -and $result.Commands.Count -gt 0) {
            if ($result.Commands.Count -eq 1) {
                $lines.Add("Command: $($result.Commands[0])")
            }
            else {
                $lines.Add('Commands:')
                foreach ($command in $result.Commands) {
                    $lines.Add("  $command")
                }
            }
        }
        if ($result.Check) {
            $lines.Add("Check:   $($result.Check)")
        }
        if ($result.Details) {
            $lines.Add($result.Details)
        }
        $lines.Add('')
        $lines -join [Environment]::NewLine
    }

    ($header + $body) | Set-Content -Path $summaryPath
    Write-Host "Summary exported to: $summaryPath" -ForegroundColor Green
    return $summaryPath
}

function Show-ChecklistIndex {
    [CmdletBinding()]
    param()

    Show-ToolkitHeader -Title 'Manual GUI Checklists'
    $config = Get-ToolkitConfig
    if (-not ($config.ContainsKey('Checklists')) -or -not $config.Checklists) {
        Write-Host 'No checklist index is defined for this toolkit.' -ForegroundColor Yellow
        return
    }

    foreach ($entry in $config.Checklists.GetEnumerator() | Sort-Object Name) {
        $path = Join-Path $config.ChecklistRoot $entry.Value.File
        Write-Host "$($entry.Name)" -ForegroundColor Cyan
        Write-Host "  File: $path"
        Write-Host "  Doc:  $($entry.Value.DocSections -join ', ')"
        Write-Host "  Use:  $($entry.Value.Description)"
        Write-Host ''
    }
}

function Test-ToolkitIntegrity {
    [CmdletBinding()]
    param()

    $root = Get-ToolkitRoot
    $files = Get-ChildItem -Path $root -Recurse -Include *.ps1, *.psm1
    $errors = @()

    foreach ($file in $files) {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
        foreach ($parseError in $parseErrors) {
            $errors += '{0} ({1},{2}): {3}' -f $file.FullName, $parseError.Extent.StartLineNumber, $parseError.Extent.StartColumnNumber, $parseError.Message
        }
    }

    if ($errors.Count -gt 0) {
        throw ($errors -join [Environment]::NewLine)
    }

    $sshNetAssembly = Join-Path $root '02_Modules\Renci.SshNet.dll'
    if (-not (Test-Path $sshNetAssembly)) {
        throw "SSH.NET assembly is missing from the toolkit package: $sshNetAssembly"
    }

    try {
        Initialize-ToolkitSshNet
    }
    catch {
        throw "SSH.NET assembly could not be loaded: $sshNetAssembly"
    }

    Write-Host 'Self-test passed: PowerShell syntax is valid for all toolkit scripts, and the bundled SSH library loaded successfully.' -ForegroundColor Green
}

Export-ModuleMember -Function @(
    'Initialize-TestToolkit',
    'Get-ToolkitConfig',
    'Get-ToolkitRoot',
    'Get-ToolkitHost',
    'Show-ToolkitHeader',
    'Pause-Toolkit',
    'Get-WindowsCredential',
    'Get-ToolkitSshNetAssemblyPath',
    'Initialize-ToolkitSshNet',
    'New-ToolkitResult',
    'Add-ToolkitResult',
    'Write-ToolkitResult',
    'Write-ToolkitBatchSummary',
    'Invoke-ToolkitBatch',
    'Get-ToolkitStatus',
    'Invoke-ToolkitLocalEndpointTest',
    'Invoke-ToolkitWinrmTest',
    'Invoke-ToolkitSshTest',
    'Invoke-ToolkitHttpTest',
    'Invoke-ToolkitHttpRejectionTest',
    'Export-ToolkitSummary',
    'Show-ChecklistIndex',
    'Test-ToolkitIntegrity'
)
