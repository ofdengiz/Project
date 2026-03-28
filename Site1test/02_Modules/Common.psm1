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
    }

    $sessionLog = Join-Path $config.ResultsRoot 'latest_session.log'
    "=== Session started: $($script:ToolkitContext.SessionStartedAt.ToString('s')) ===" | Set-Content -Path $sessionLog

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

function Show-ToolkitHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Clear-Host
    Write-Host '=== Site 1 Central Test Toolkit ===' -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Yellow
    Write-Host 'Read-only validation only. No configuration changes are performed.' -ForegroundColor DarkGray
    Write-Host ''
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
    $hostEntry = $null
    foreach ($entry in $config.Hosts.GetEnumerator()) {
        if ($entry.Value.Address -eq $ComputerName) {
            $hostEntry = $entry.Value
            break
        }
    }

    if (-not $hostEntry) {
        throw "No host entry found for Windows credential lookup: $ComputerName"
    }

    if (-not $hostEntry.ContainsKey('WindowsUser') -or -not $hostEntry.WindowsUser) {
        throw "WindowsUser is not defined for host: $ComputerName"
    }

    if (-not ($config.ContainsKey('DefaultWindowsPassword') -and $config.DefaultWindowsPassword)) {
        throw 'DefaultWindowsPassword is not defined in LabConfig.psd1.'
    }

    $cacheKey = '{0}|{1}' -f $ComputerName, $hostEntry.WindowsUser
    if ($script:ToolkitContext.WindowsCredentials.ContainsKey($cacheKey)) {
        return $script:ToolkitContext.WindowsCredentials[$cacheKey]
    }

    $securePassword = ConvertTo-SecureString -String ([string]$config.DefaultWindowsPassword) -AsPlainText -Force
    $credential = [pscredential]::new([string]$hostEntry.WindowsUser, $securePassword)
    $script:ToolkitContext.WindowsCredentials[$cacheKey] = $credential
    return $credential
}

function Get-LinuxPassword {
    [CmdletBinding()]
    param()

    $config = Get-ToolkitConfig
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
        Details   = $Details.Trim()
    }
}

function Add-ToolkitResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    $script:ToolkitContext.SessionResults.Add($Result)

    $sessionLog = Join-Path (Get-ToolkitConfig).ResultsRoot 'latest_session.log'
    $line = '{0} | {1} | {2} | {3} | {4}' -f `
        $Result.Timestamp.ToString('s'),
        $Result.Status,
        $Result.Section,
        $Result.Device,
        $Result.Test

    try {
        Add-Content -Path $sessionLog -Value $line -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to write session log: $($_.Exception.Message)"
    }
}

function Write-ToolkitResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

    $color = switch ($Result.Status) {
        'PASS'  { 'Green' }
        'FAIL'  { 'Red' }
        default { 'Yellow' }
    }

    Write-Host "[$($Result.Status)] $($Result.Test)" -ForegroundColor $color
    Write-Host "Device:  $($Result.Device)"
    Write-Host "Section: $($Result.Section)"
    Write-Host "Method:  $($Result.Method)"
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
            Write-Host "- [$($item.Status)] $($item.Test) ($($item.Device))"
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

        [string[]]$SuccessPatterns = @()
    )

    if (-not $Succeeded) {
        return 'FAIL'
    }

    if (-not $SuccessPatterns -or $SuccessPatterns.Count -eq 0) {
        return 'REVIEW'
    }

    foreach ($pattern in $SuccessPatterns) {
        if ($Output -notmatch $pattern) {
            return 'REVIEW'
        }
    }

    return 'PASS'
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
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'Local port probe' -Details $details
    }
    catch {
        $result = New-ToolkitResult -Name $Name -Status 'FAIL' -Device $Device -DocSection $DocSection -Method 'Local port probe' -Details $_.Exception.Message
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

        [string[]]$ReviewOnErrorPatterns = @(),

        [string]$ReviewGuidance = '',

        [switch]$UseCurrentCredential
    )

    try {
        $params = @{
            ComputerName = $ComputerName
            ScriptBlock  = $ScriptBlock
            ErrorAction  = 'Stop'
        }

        if (-not $UseCurrentCredential) {
            $params.Credential = Get-WindowsCredentialForComputer -ComputerName $ComputerName
        }

        $output = Invoke-Command @params 2>&1 | Out-String
        if ([string]::IsNullOrWhiteSpace($output)) {
            $output = '[no command output returned]'
        }
        $status = Get-ToolkitStatus -Succeeded $true -Output $output -SuccessPatterns $SuccessPatterns
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'WinRM' -Details $output
    }
    catch {
        $errorText = $_.Exception.Message
        $status = 'FAIL'

        foreach ($pattern in $ReviewOnErrorPatterns) {
            if ($errorText -match $pattern) {
                $status = 'REVIEW'
                break
            }
        }

        if ($status -eq 'REVIEW' -and $ReviewGuidance) {
            $errorText = "$errorText`nReview guidance : $ReviewGuidance"
        }

        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'WinRM' -Details $errorText
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

        [string[]]$SuccessPatterns = @()
    )

    try {
        Initialize-ToolkitSshNet
        $commandText = ($Commands | Where-Object { $_ }) -join '; '
        $connectionInfo = [Renci.SshNet.PasswordConnectionInfo]::new($Host, $User, (Get-LinuxPassword))
        $connectionInfo.Timeout = [TimeSpan]::FromSeconds(10)

        $client = [Renci.SshNet.SshClient]::new($connectionInfo)
        $client.Connect()

        $command = $client.CreateCommand($commandText)
        $command.CommandTimeout = [TimeSpan]::FromSeconds(20)
        $stdout = $command.Execute()
        $stderr = $command.Error

        $output = @($stdout, $stderr) -join [Environment]::NewLine
        $output = $output.Trim()
        if (-not $output) {
            $output = '[no command output returned]'
        }

        $status = Get-ToolkitStatus -Succeeded ($client.IsConnected -and ($command.ExitStatus -eq 0)) -Output $output -SuccessPatterns $SuccessPatterns
        $result = New-ToolkitResult -Name $Name -Status $status -Device $Device -DocSection $DocSection -Method 'SSH' -Details $output
    }
    catch {
        $result = New-ToolkitResult -Name $Name -Status 'FAIL' -Device $Device -DocSection $DocSection -Method 'SSH' -Details $_.Exception.Message
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

function Export-ToolkitSummary {
    [CmdletBinding()]
    param()

    $resultsRoot = (Get-ToolkitConfig).ResultsRoot
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $summaryPath = Join-Path $resultsRoot "${timestamp}_Summary.txt"
    $results = $script:ToolkitContext.SessionResults

    $header = @(
        'Site 1 Central Test Toolkit Summary',
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Toolkit Version: $((Get-ToolkitConfig).ToolkitVersion)",
        ''
    )

    $body = foreach ($result in $results) {
        @(
            "[{0}] {1}" -f $result.Status, $result.Test,
            "Device:  $($result.Device)",
            "Section: $($result.Section)",
            "Method:  $($result.Method)",
            $result.Details,
            ''
        ) -join [Environment]::NewLine
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
    'Export-ToolkitSummary',
    'Show-ChecklistIndex',
    'Test-ToolkitIntegrity'
)
