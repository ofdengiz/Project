import base64
import gzip
import json
import os
import socket
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

import paramiko


ROOT = Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project\Site2test_service")
RESULTS = ROOT / "04_Results"
RAW = RESULTS / "raw"

WINDOWS_JUMP = "100.97.37.83"
WINDOWS_USER = "Administrator"
WINDOWS_PASS = "Istanbul34!"

UBUNTU_JUMP = "100.82.97.92"
UBUNTU_USER = "mspadmin"
UBUNTU_PASS = "Istanbul34!"


def ensure_dirs():
    for path in [RESULTS, RAW]:
        path.mkdir(parents=True, exist_ok=True)


def timestamp():
    return datetime.now().strftime("%Y%m%d_%H%M%S")


RUN_ID = timestamp()
SUMMARY_PATH = RESULTS / f"{RUN_ID}_Summary.txt"
LOG_PATH = RESULTS / "latest_session.log"


def append_log(line: str):
    with LOG_PATH.open("a", encoding="utf-8") as fh:
        fh.write(line.rstrip() + "\n")


def write_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def run_local(cmd: str, timeout: int = 120):
    cp = subprocess.run(
        cmd,
        shell=True,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    return {
        "command": cmd,
        "returncode": cp.returncode,
        "stdout": cp.stdout,
        "stderr": cp.stderr,
    }


def test_tcp(host: str, port: int, timeout: float = 5.0):
    start = time.time()
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True, round((time.time() - start) * 1000, 1), ""
    except Exception as exc:
        return False, round((time.time() - start) * 1000, 1), str(exc)


def ssh_exec(host: str, user: str, password: str, command: str, timeout: int = 20):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(
            hostname=host,
            username=user,
            password=password,
            timeout=timeout,
            look_for_keys=False,
            allow_agent=False,
        )
        stdin, stdout, stderr = client.exec_command(command, timeout=timeout)
        exit_code = stdout.channel.recv_exit_status()
        return {
            "ok": True,
            "exit_code": exit_code,
            "stdout": stdout.read().decode("utf-8", errors="replace"),
            "stderr": stderr.read().decode("utf-8", errors="replace"),
            "command": command,
        }
    except Exception as exc:
        return {"ok": False, "error": str(exc), "command": command}
    finally:
        client.close()


def ps_escape_single(text: str) -> str:
    return text.replace("'", "''")


def run_wmi_process(ps_script: str):
    enc = base64.b64encode(ps_script.encode("utf-16le")).decode("ascii")
    local_script = (
        f"$remote='powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand {enc}'; "
        f"$sec=ConvertTo-SecureString '{WINDOWS_PASS}' -AsPlainText -Force; "
        f"$cred=New-Object System.Management.Automation.PSCredential('{WINDOWS_USER}',$sec); "
        f"Invoke-WmiMethod -Class Win32_Process -Name Create -ComputerName {WINDOWS_JUMP} "
        f"-Credential $cred -ArgumentList $remote | ConvertTo-Json -Compress"
    )
    return run_local(f'powershell -NoProfile -Command "{local_script}"', timeout=120)


def read_remote_registry_value(name: str):
    local_script = (
        f"$sec=ConvertTo-SecureString '{WINDOWS_PASS}' -AsPlainText -Force; "
        f"$cred=New-Object System.Management.Automation.PSCredential('{WINDOWS_USER}',$sec); "
        f"$reg=Get-WmiObject -List -Namespace root\\default -ComputerName {WINDOWS_JUMP} "
        f"-Credential $cred | Where-Object {{ $_.Name -eq 'StdRegProv' }}; "
        f"$r=Invoke-WmiMethod -InputObject $reg -Name GetStringValue "
        f"-ArgumentList 2147483650,'SOFTWARE\\Site2Test','{name}'; "
        f"$r | ConvertTo-Json -Compress"
    )
    result = run_local(f'powershell -NoProfile -Command "{local_script}"', timeout=120)
    if result["returncode"] != 0:
        return None, result
    try:
        payload = json.loads(result["stdout"])
        return payload.get("sValue"), result
    except Exception:
        return None, result


def clear_remote_registry_keys():
    script = r"""
New-Item -Path 'HKLM:\SOFTWARE\Site2Test' -Force | Out-Null
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Site2Test' -Name 'ResultB64' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Site2Test' -Name 'Status' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Site2Test' -Name 'Error' -ErrorAction SilentlyContinue
"""
    return run_wmi_process(script)


def build_windows_collector():
    return r"""
$ErrorActionPreference = 'Stop'
New-Item -Path 'HKLM:\SOFTWARE\Site2Test' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Site2Test' -Name 'Status' -Value 'RUNNING'

function Test-Port {
    param([string]$Host,[int]$Port)
    try {
        $r = Test-NetConnection -ComputerName $Host -Port $Port -WarningAction SilentlyContinue
        [pscustomobject]@{
            host = $Host
            port = $Port
            tcp = [bool]$r.TcpTestSucceeded
            ping = [bool]$r.PingSucceeded
            source = $env:COMPUTERNAME
        }
    } catch {
        [pscustomobject]@{
            host = $Host
            port = $Port
            tcp = $false
            ping = $false
            error = $_.Exception.Message
            source = $env:COMPUTERNAME
        }
    }
}

function Try-Web {
    param([string]$Name,[string]$Url)
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        [pscustomobject]@{
            name = $Name
            url = $Url
            ok = $true
            status_code = [int]$r.StatusCode
            length = if ($r.Content) { $r.Content.Length } else { 0 }
        }
    } catch {
        [pscustomobject]@{
            name = $Name
            url = $Url
            ok = $false
            error = $_.Exception.Message
        }
    }
}

function Try-WmiServiceSnapshot {
    param(
        [string]$Host,
        [string]$User,
        [string]$Password,
        [string[]]$ServiceNames
    )
    try {
        $sec = ConvertTo-SecureString $Password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($User,$sec)
        $os = Get-WmiObject Win32_OperatingSystem -ComputerName $Host -Credential $cred -ErrorAction Stop
        $cs = Get-WmiObject Win32_ComputerSystem -ComputerName $Host -Credential $cred -ErrorAction Stop
        $services = @(Get-WmiObject Win32_Service -ComputerName $Host -Credential $cred -ErrorAction Stop | Where-Object { $_.Name -in $ServiceNames })
        [pscustomobject]@{
            host = $Host
            ok = $true
            caption = $os.Caption
            version = $os.Version
            name = $cs.Name
            domain = $cs.Domain
            services = @($services | ForEach-Object {
                [pscustomobject]@{
                    name = $_.Name
                    state = $_.State
                    startmode = $_.StartMode
                }
            })
        }
    } catch {
        [pscustomobject]@{
            host = $Host
            ok = $false
            error = $_.Exception.Message
        }
    }
}

function Try-Command {
    param([string]$Name,[string]$Command)
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    [pscustomobject]@{
        name = $Name
        available = [bool]$cmd
        source = if ($cmd) { $cmd.Source } else { $null }
    }
}

function Try-Plink {
    param([string]$Host,[string]$User,[string]$Password,[string]$Command)
    $plink = Get-Command plink.exe -ErrorAction SilentlyContinue
    if (-not $plink) {
        return [pscustomobject]@{
            host = $Host
            ok = $false
            error = 'plink.exe not available'
        }
    }
    try {
        $out = & $plink.Source -batch -ssh "$User@$Host" -pw $Password $Command 2>&1
        [pscustomobject]@{
            host = $Host
            ok = $LASTEXITCODE -eq 0
            output = ($out | Out-String).Trim()
            exit_code = $LASTEXITCODE
        }
    } catch {
        [pscustomobject]@{
            host = $Host
            ok = $false
            error = $_.Exception.Message
        }
    }
}

$result = [ordered]@{}
$result.meta = [ordered]@{
    computername = $env:COMPUTERNAME
    when = (Get-Date).ToString('s')
    ips = @(
        Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } |
        ForEach-Object {
            [pscustomobject]@{
                description = $_.Description
                ip = @($_.IPAddress)
                gateway = @($_.DefaultIPGateway)
                dns = @($_.DNSServerSearchOrder)
            }
        }
    )
}
$result.tools = @(
    Try-Command -Name 'ssh' -Command 'ssh.exe'
    Try-Command -Name 'plink' -Command 'plink.exe'
)
$result.endpoints = @(
    Test-Port -Host '172.30.65.1' -Port 3389
    Test-Port -Host '172.30.65.65' -Port 3389
    Test-Port -Host '172.30.65.161' -Port 80
    Test-Port -Host '172.30.65.169' -Port 80
    Test-Port -Host '172.30.65.177' -Port 443
    Test-Port -Host '172.30.65.2' -Port 3389
    Test-Port -Host '172.30.65.2' -Port 5985
    Test-Port -Host '172.30.65.2' -Port 445
    Test-Port -Host '172.30.65.3' -Port 3389
    Test-Port -Host '172.30.65.3' -Port 5985
    Test-Port -Host '172.30.65.3' -Port 445
    Test-Port -Host '172.30.65.4' -Port 445
    Test-Port -Host '172.30.65.4' -Port 3389
    Test-Port -Host '172.30.65.162' -Port 80
    Test-Port -Host '172.30.65.162' -Port 3389
    Test-Port -Host '172.30.65.66' -Port 22
    Test-Port -Host '172.30.65.67' -Port 22
    Test-Port -Host '172.30.65.68' -Port 22
    Test-Port -Host '172.30.65.70' -Port 22
    Test-Port -Host '172.30.65.170' -Port 80
    Test-Port -Host '172.20.64.1' -Port 80
    Test-Port -Host '172.20.65.1' -Port 80
)
$result.web = @(
    Try-Web -Name 'C1Web' -Url 'http://172.30.65.162/'
    Try-Web -Name 'C2Web' -Url 'http://172.30.65.170/'
)
$result.windows = @(
    Try-WmiServiceSnapshot -Host '172.30.65.2' -User 'c1.local\Administrator' -Password 'Cisco123!' -ServiceNames @('NTDS','DNS','Netlogon','Kdc','W32Time','DHCPServer','TermService')
    Try-WmiServiceSnapshot -Host '172.30.65.3' -User 'c1.local\Administrator' -Password 'Cisco123!' -ServiceNames @('NTDS','DNS','Netlogon','Kdc','W32Time','DHCPServer','TermService')
    Try-WmiServiceSnapshot -Host '172.30.65.4' -User 'c1.local\Administrator' -Password 'Cisco123!' -ServiceNames @('Dfs','DFSR','WinTarget','LanmanServer','TermService')
    Try-WmiServiceSnapshot -Host '172.30.65.162' -User 'c1.local\Administrator' -Password 'Cisco123!' -ServiceNames @('W3SVC','TermService','LanmanServer')
)
$result.linux = @(
    Try-Plink -Host '172.30.65.66' -User 'ofdengiz' -Password 'admin' -Command 'hostname && systemctl is-active samba-ad-dc || true'
    Try-Plink -Host '172.30.65.67' -User 'ofdengiz' -Password 'admin' -Command 'hostname && systemctl is-active samba-ad-dc || true'
    Try-Plink -Host '172.30.65.68' -User 'odengiz' -Password 'admin' -Command 'hostname && systemctl is-active smbd && findmnt /mnt/c2_public || true'
    Try-Plink -Host '172.30.65.70' -User 'odengiz' -Password 'admin' -Command 'hostname && realm list && getent passwd employee1@c2.local || true'
)

$json = $result | ConvertTo-Json -Depth 8 -Compress
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
$ms = New-Object System.IO.MemoryStream
$gz = New-Object System.IO.Compression.GzipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
$gz.Write($bytes, 0, $bytes.Length)
$gz.Close()
$b64 = [Convert]::ToBase64String($ms.ToArray())
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Site2Test' -Name 'ResultB64' -Value $b64
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Site2Test' -Name 'Status' -Value 'DONE'
"""


class SummaryWriter:
    def __init__(self):
        self.lines = []
        self.results = []

    def add_result(self, status, section, device, name, method, commands, check, evidence):
        self.results.append(
            {
                "status": status,
                "section": section,
                "device": device,
                "name": name,
                "method": method,
                "commands": commands,
                "check": check,
                "evidence": evidence,
            }
        )
        append_log(
            f"{datetime.now().isoformat(timespec='seconds')} | {status} | {section} | {device} | {name}"
        )

    def render(self):
        out = []
        out.append("Site 2 Service Block Test Toolkit Summary")
        out.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        out.append("Toolkit Version: 1.0")
        out.append("")
        for item in self.results:
            out.append(f"[{item['status']}] {item['name']}")
            out.append(f"Device:  {item['device']}")
            out.append(f"Section: {item['section']}")
            out.append(f"Method:  {item['method']}")
            out.append("Commands:")
            for cmd in item["commands"]:
                out.append(f"  {cmd}")
            out.append(f"Check:   {item['check']}")
            out.append(item["evidence"])
            out.append("")
        return "\n".join(out)


def init_log():
    write_text(LOG_PATH, f"=== Session started: {datetime.now().isoformat(timespec='seconds')} ===\n")


def local_endpoint_result(writer, name, host, port, section, device, cmd_desc):
    ok, ms, err = test_tcp(host, port)
    status = "PASS" if ok else "FAIL"
    evidence = f"TCP {'reachable' if ok else 'failed'} to {host}:{port}. RTT(ms)={ms}."
    if err:
        evidence += f" Error: {err}"
    writer.add_result(
        status=status,
        section=section,
        device=device,
        name=name,
        method="Local TCP",
        commands=[cmd_desc],
        check=f"Verify {host}:{port} is reachable from the operator workstation.",
        evidence=evidence,
    )


def collect_ubuntu(writer):
    commands = {
        "identity": "hostname; whoami; ip -4 a; ip route",
        "cloud": "cloud-init status --long || true; ls /etc/cloud/cloud.cfg.d",
        "purple": "ping -c 2 172.30.65.177 || true; ip neigh show 172.30.65.177 || true; ping -c 2 172.30.65.66 || true; ping -c 2 172.30.65.67 || true; ping -c 2 172.30.65.68 || true",
        "blue": "ping -c 2 172.20.20.1 || true; ping -c 2 172.20.64.1 || true; ping -c 2 172.20.65.1 || true",
    }
    all_raw = {}
    for key, cmd in commands.items():
        result = ssh_exec(UBUNTU_JUMP, UBUNTU_USER, UBUNTU_PASS, cmd, timeout=40)
        all_raw[key] = result
        write_text(RAW / f"ubuntu_jump_{key}.txt", json.dumps(result, indent=2))
    identity_ok = all_raw["identity"].get("ok", False)
    writer.add_result(
        status="PASS" if identity_ok else "FAIL",
        section="Service Block 1 / Remote Access",
        device="MSPUbuntuJump",
        name="SSH to MSP Ubuntu Jump",
        method="Paramiko over Tailscale",
        commands=["ssh mspadmin@100.82.97.92"],
        check="Confirm direct SSH access to the MSP Ubuntu jump box.",
        evidence=(all_raw["identity"].get("stdout") or all_raw["identity"].get("error", "")).strip(),
    )
    purple_ok = "0 received" not in all_raw["purple"].get("stdout", "")
    writer.add_result(
        status="PASS" if purple_ok else "FAIL",
        section="Service Block 3 / vRouter policy",
        device="MSPUbuntuJump",
        name="MSP Ubuntu jump purple path health",
        method="SSH command",
        commands=[commands["purple"]],
        check="Confirm the Ubuntu jump can resolve and reach the MSP/purple gateway and routed Site 2 hosts.",
        evidence=(all_raw["purple"].get("stdout") or all_raw["purple"].get("error", "")).strip(),
    )
    blue_ok = "0 received" not in all_raw["blue"].get("stdout", "")
    writer.add_result(
        status="PASS" if blue_ok else "FAIL",
        section="Service Block 3 / Blue Network",
        device="MSPUbuntuJump",
        name="MSP Ubuntu jump blue path health",
        method="SSH command",
        commands=[commands["blue"]],
        check="Confirm the Ubuntu jump still reaches the blue network while Tailscale remains online.",
        evidence=(all_raw["blue"].get("stdout") or all_raw["blue"].get("error", "")).strip(),
    )


def decompress_b64_gzip(text: str):
    return gzip.decompress(base64.b64decode(text)).decode("utf-8")


def collect_windows(writer):
    clear_remote_registry_keys()
    launch = run_wmi_process(build_windows_collector())
    write_text(RAW / "windows_jump_launch.json", json.dumps(launch, indent=2))
    status = None
    result_b64 = None
    for _ in range(40):
        time.sleep(3)
        status, status_raw = read_remote_registry_value("Status")
        write_text(RAW / "windows_jump_registry_status.json", json.dumps(status_raw, indent=2))
        if status == "DONE":
            result_b64, result_raw = read_remote_registry_value("ResultB64")
            write_text(RAW / "windows_jump_registry_result.json", json.dumps(result_raw, indent=2))
            break
    if not result_b64:
        writer.add_result(
            status="FAIL",
            section="Service Block 1 / Remote Access",
            device="WindowsJump64",
            name="Windows jump remote collector",
            method="WMI registry return channel",
            commands=["Invoke-WmiMethod Win32_Process Create -> registry ResultB64"],
            check="Run the Site 2 collector on the Windows jump and retrieve JSON output.",
            evidence=f"Collector did not finish successfully. Final registry status: {status}",
        )
        return None
    payload = json.loads(decompress_b64_gzip(result_b64))
    write_text(RAW / "windows_jump_collector.json", json.dumps(payload, indent=2))

    writer.add_result(
        status="PASS",
        section="Service Block 1 / Remote Access",
        device="WindowsJump64",
        name="Windows jump control channel",
        method="WMI + registry",
        commands=["Win32_Process Create on 100.97.37.83", "StdRegProv GetStringValue ResultB64"],
        check="Confirm the Windows jump can run administrative collection commands.",
        evidence=json.dumps(payload["meta"], indent=2),
    )

    endpoint_map = {
        ("172.30.65.2", 3389): ("Service Block 1 / Remote Access", "C1DC1", "RDP to C1DC1"),
        ("172.30.65.3", 3389): ("Service Block 1 / Remote Access", "C1DC2", "RDP to C1DC2"),
        ("172.30.65.4", 445): ("Service Block 4 / Replicated File Server", "C1FS", "SMB to C1FS"),
        ("172.30.65.162", 80): ("Service Block 2 / HTTP", "C1Web", "HTTP to C1 Web"),
        ("172.30.65.162", 3389): ("Service Block 1 / Remote Access", "C1Web", "RDP to C1 Web"),
        ("172.30.65.66", 22): ("Service Block 1 / Remote Access", "C2IdM1", "SSH to C2IdM1"),
        ("172.30.65.67", 22): ("Service Block 1 / Remote Access", "C2IdM2", "SSH to C2IdM2"),
        ("172.30.65.68", 22): ("Service Block 1 / Remote Access", "C2FS", "SSH to C2FS"),
        ("172.30.65.70", 22): ("Service Block 1 / Remote Access", "C2LinuxClient", "SSH to C2LinuxClient"),
        ("172.30.65.170", 80): ("Service Block 2 / HTTP", "C2Web", "HTTP to C2 Web"),
        ("172.30.65.177", 443): ("Service Block 3 / vRouter", "OPNsense", "HTTPS to OPNsense MSP"),
        ("172.20.64.1", 80): ("Service Block 3 / vRouter", "OPNsense", "HTTP to WAN 172.20.64.1"),
        ("172.20.65.1", 80): ("Service Block 3 / vRouter", "OPNsense", "HTTP to WAN 172.20.65.1"),
    }
    for item in payload["endpoints"]:
        key = (item["host"], int(item["port"]))
        if key not in endpoint_map:
            continue
        section, device, name = endpoint_map[key]
        writer.add_result(
            status="PASS" if item.get("tcp") else "FAIL",
            section=section,
            device=device,
            name=name,
            method="Windows jump Test-NetConnection",
            commands=[f"Test-NetConnection {item['host']} -Port {item['port']}"],
            check=f"Confirm {item['host']}:{item['port']} is reachable from the Windows jump box.",
            evidence=json.dumps(item, indent=2),
        )

    for item in payload["web"]:
        writer.add_result(
            status="PASS" if item.get("ok") else "FAIL",
            section="Service Block 2 / HTTP",
            device=item["name"],
            name=f"{item['name']} web response",
            method="Windows jump Invoke-WebRequest",
            commands=[f"Invoke-WebRequest {item['url']} -UseBasicParsing"],
            check=f"Confirm {item['name']} responds to HTTP from the Windows jump box.",
            evidence=json.dumps(item, indent=2),
        )

    for item in payload["windows"]:
        host_map = {
            "172.30.65.2": ("Service Block 1 / Core Windows Services", "C1DC1", "C1DC1 service snapshot"),
            "172.30.65.3": ("Service Block 1 / Core Windows Services", "C1DC2", "C1DC2 service snapshot"),
            "172.30.65.4": ("Service Block 4 / Replicated File Server and ISCSI", "C1FS", "C1FS storage service snapshot"),
            "172.30.65.162": ("Service Block 2 / Web Services", "C1Web", "C1Web service snapshot"),
        }
        section, device, name = host_map[item["host"]]
        required_running = any(s.get("state") == "Running" for s in item.get("services", []))
        writer.add_result(
            status="PASS" if item.get("ok") and required_running else "FAIL",
            section=section,
            device=device,
            name=name,
            method="Remote WMI from Windows jump",
            commands=[f"Get-WmiObject Win32_OperatingSystem/Win32_Service -ComputerName {item['host']}"],
            check=f"Collect OS identity and key service states from {device}.",
            evidence=json.dumps(item, indent=2),
        )

    for item in payload["linux"]:
        host_map = {
            "172.30.65.66": ("Service Block 1 / Linux Identity", "C2IdM1", "C2IdM1 direct SSH command"),
            "172.30.65.67": ("Service Block 1 / Linux Identity", "C2IdM2", "C2IdM2 direct SSH command"),
            "172.30.65.68": ("Service Block 4 / Replicated File Server", "C2FS", "C2FS direct SSH command"),
            "172.30.65.70": ("Service Block 1 / Linux Identity", "C2LinuxClient", "C2LinuxClient direct SSH command"),
        }
        section, device, name = host_map[item["host"]]
        writer.add_result(
            status="PASS" if item.get("ok") else "FAIL",
            section=section,
            device=device,
            name=name,
            method="Windows jump plink",
            commands=[f"plink -ssh {item['host']}"],
            check=f"Attempt a direct SSH command from the Windows jump to {device}.",
            evidence=json.dumps(item, indent=2),
        )

    return payload


def main():
    ensure_dirs()
    init_log()
    writer = SummaryWriter()

    # Local / public-facing checks
    local_endpoint_result(writer, "RDP to Windows jump over Tailscale", WINDOWS_JUMP, 3389, "Service Block 1 / Remote Access", "WindowsJump64", "Test TCP 100.97.37.83:3389")
    local_endpoint_result(writer, "SSH to Ubuntu jump over Tailscale", UBUNTU_JUMP, 22, "Service Block 1 / Remote Access", "MSPUbuntuJump", "Test TCP 100.82.97.92:22")
    local_endpoint_result(writer, "Public RDP to Windows jump", "10.50.17.31", 33464, "Service Block 1 / Remote Access", "Teacher Edge -> WindowsJump64", "Test TCP 10.50.17.31:33464")
    local_endpoint_result(writer, "Public SSH to Ubuntu jump", "10.50.17.31", 33564, "Service Block 1 / Remote Access", "Teacher Edge -> MSPUbuntuJump", "Test TCP 10.50.17.31:33564")
    local_endpoint_result(writer, "Public HTTP to C1 Web", "10.50.17.31", 33465, "Service Block 2 / HTTP", "Teacher Edge -> C1Web", "Test TCP 10.50.17.31:33465")

    collect_ubuntu(writer)
    collect_windows(writer)

    summary = writer.render()
    write_text(SUMMARY_PATH, summary)
    print(str(SUMMARY_PATH))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
