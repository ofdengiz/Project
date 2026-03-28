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

function Add-ToolkitResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Result
    )

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
        $connectionInfo = [Renci.SshNet.PasswordConnectionInfo]::new($Host, $User, (Get-LinuxPassword))
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
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add(("[{0}] {1}" -f $result.Status, $result.Test))
        $lines.Add("Device:  $($result.Device)")
        $lines.Add("Section: $($result.Section)")
        $lines.Add("Method:  $($result.Method)")
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
