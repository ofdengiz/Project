import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Tuple

ROOT = Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project")
PYDEPS = ROOT / "pydeps"
for candidate in [
    PYDEPS,
    PYDEPS / "Lib" / "site-packages",
    ROOT / "pydeps_test" / "Lib" / "site-packages",
]:
    if candidate.exists():
        sys.path.insert(0, str(candidate))

import paramiko
import winrm


STAMP = datetime.now().strftime("%Y-%m-%d_%H%M%S")
OUTDIR = ROOT / f"site2_v42_live_2026-03-27_{STAMP}"
OUTDIR.mkdir(parents=True, exist_ok=True)


def write_text(name: str, text: str) -> None:
    (OUTDIR / name).write_text(text, encoding="utf-8", errors="ignore")


def write_json(name: str, data) -> None:
    (OUTDIR / name).write_text(json.dumps(data, indent=2), encoding="utf-8")


def ssh_client(host: str, user: str, password: str, port: int = 22, sock=None):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        hostname=host,
        port=port,
        username=user,
        password=password,
        timeout=15,
        banner_timeout=15,
        auth_timeout=15,
        sock=sock,
        look_for_keys=False,
        allow_agent=False,
    )
    return client


def ssh_exec(client: paramiko.SSHClient, command: str) -> dict:
    stdin, stdout, stderr = client.exec_command(command, timeout=60)
    code = stdout.channel.recv_exit_status()
    return {
        "command": command,
        "exit_code": code,
        "stdout": stdout.read().decode("utf-8", errors="ignore"),
        "stderr": stderr.read().decode("utf-8", errors="ignore"),
    }


def tunneled_ssh(msp_client: paramiko.SSHClient, host: str, user: str, password: str):
    transport = msp_client.get_transport()
    channel = transport.open_channel("direct-tcpip", (host, 22), ("127.0.0.1", 0))
    return ssh_client(host, user, password, sock=channel)


def ps_session():
    return winrm.Session(
        "http://100.97.37.83:5985/wsman",
        auth=("Administrator", "Cisco123!"),
        transport="ntlm",
        server_cert_validation="ignore",
    )


def run_ps(session, script: str) -> dict:
    result = session.run_ps(script)
    return {
        "status_code": result.status_code,
        "stdout": result.std_out.decode("utf-8", errors="ignore"),
        "stderr": result.std_err.decode("utf-8", errors="ignore"),
        "script": script,
    }


def build_invoke(ip: str, username: str, password: str, inner_script: str) -> str:
    escaped_user = username.replace("'", "''")
    escaped_pass = password.replace("'", "''")
    return f"""
$pw = ConvertTo-SecureString '{escaped_pass}' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('{escaped_user}', $pw)
try {{
  Invoke-Command -ComputerName {ip} -Credential $cred -ScriptBlock {{
{inner_script}
  }} -ErrorAction Stop
}} catch {{
  Write-Output ('REMOTE_ERROR: ' + $_.Exception.Message)
  if ($_.FullyQualifiedErrorId) {{ Write-Output ('FQID: ' + $_.FullyQualifiedErrorId) }}
  exit 1
}}
"""


def try_remote(session, ip: str, creds: List[Tuple[str, str]], inner_script: str) -> dict:
    attempts = []
    for username, password in creds:
        ps = build_invoke(ip, username, password, inner_script)
        res = run_ps(session, ps)
        attempts.append(
            {
                "username": username,
                "status_code": res["status_code"],
                "stdout": res["stdout"],
                "stderr": res["stderr"],
            }
        )
        if res["status_code"] == 0 and "REMOTE_ERROR:" not in res["stdout"]:
            return {"success": True, "attempts": attempts}
    return {"success": False, "attempts": attempts}


def main():
    results = {"started": datetime.now().isoformat(), "outdir": str(OUTDIR)}
    msp = ssh_client("100.82.97.92", "admin", "Cisco123!")
    results["msp_baseline"] = ssh_exec(
        msp,
        "hostname && whoami && uname -a && uptime && ip -4 addr show | sed -n '1,120p'",
    )
    results["msp_ports"] = ssh_exec(
        msp,
        "for t in '172.30.65.177 80' '172.30.65.177 443' '172.30.65.177 53' '172.30.65.186 3260' '172.30.65.186 22' '172.30.65.186 3389' '172.30.65.180 445' '172.30.65.180 9392' ; do set -- $t; echo TARGET=$1:$2; nc -zvw4 $1 $2; done",
    )
    results["msp_c1_web"] = ssh_exec(
        msp,
        "echo '== HOSTNAME ==' && curl -k -I --resolve c1-webserver.c1.local:443:172.30.65.162 https://c1-webserver.c1.local && echo '== RAW_IP ==' && curl -k -I https://172.30.65.162 || true",
    )

    c1ubuntu = tunneled_ssh(msp, "172.30.65.36", "Administrator", "Cisco123!")
    results["c1ubuntu_baseline"] = ssh_exec(
        c1ubuntu,
        "hostname; whoami; uname -a; lsb_release -a; realm list; id administrator@c1.local; nproc; free -h; df -h; ip -4 addr show; resolvectl status 2>/dev/null || systemd-resolve --status 2>/dev/null; curl -k -I https://c1-webserver.c1.local; curl -k -I https://c2-webserver.c2.local",
    )
    c1ubuntu.close()

    c2idm1 = tunneled_ssh(msp, "172.30.65.66", "admin", "Cisco123!")
    results["c2idm1_state"] = ssh_exec(
        c2idm1,
        "hostname; printf '%s\n' 'Cisco123!' | sudo -S -p '' systemctl is-active samba-ad-dc; printf '%s\n' 'Cisco123!' | sudo -S -p '' systemctl is-active isc-dhcp-server; printf '%s\n' 'Cisco123!' | sudo -S -p '' samba-tool dns zonelist 127.0.0.1 -P; printf '%s\n' 'Cisco123!' | sudo -S -p '' samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P; printf '%s\n' 'Cisco123!' | sudo -S -p '' samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P",
    )
    c2idm1.close()

    c2idm2 = tunneled_ssh(msp, "172.30.65.67", "admin", "Cisco123!")
    results["c2idm2_state"] = ssh_exec(
        c2idm2,
        "hostname; printf '%s\n' 'Cisco123!' | sudo -S -p '' systemctl is-active samba-ad-dc; printf '%s\n' 'Cisco123!' | sudo -S -p '' systemctl is-active isc-dhcp-server; printf '%s\n' 'Cisco123!' | sudo -S -p '' samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P; printf '%s\n' 'Cisco123!' | sudo -S -p '' samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P",
    )
    c2idm2.close()

    c2fs = tunneled_ssh(msp, "172.30.65.68", "admin", "Cisco123!")
    results["c2fs_state"] = ssh_exec(
        c2fs,
        "hostname; printf '%s\n' 'Cisco123!' | sudo -S -p '' systemctl is-active smbd; printf '%s\n' 'Cisco123!' | sudo -S -p '' findmnt /mnt/c2_public; printf '%s\n' 'Cisco123!' | sudo -S -p '' iscsiadm -m session || true; printf '%s\n' 'Cisco123!' | sudo -S -p '' lsblk -f; printf '%s\n' 'Cisco123!' | sudo -S -p '' testparm -s 2>/dev/null | tail -n 60; printf '%s\n' 'Cisco123!' | sudo -S -p '' tail -n 20 /var/log/c2_site1_sync.log",
    )
    c2fs.close()

    c2linux = tunneled_ssh(msp, "172.30.65.70", "admin", "Cisco123!")
    results["c2linux_state"] = ssh_exec(
        c2linux,
        "hostname; whoami; realm list; resolvectl status; getent passwd employee1@c2.local; getent passwd employee2@c2.local; ls -ld /home/employee1@c2.local /home/employee2@c2.local; mount | grep -E 'C2_Public|C2_Private|cifs' || true; nslookup c1-webserver.c1.local || true; nslookup c2-webserver.c2.local || true; curl -k -I https://c1-webserver.c1.local || true; curl -k -I https://c2-webserver.c2.local || true",
    )
    c2linux.close()

    c2web = tunneled_ssh(msp, "172.30.65.170", "admin", "Cisco123!")
    results["c2web_state"] = ssh_exec(
        c2web,
        "hostname; whoami; systemctl is-active nginx; grep -Rin 'server_name' /etc/nginx/sites-enabled /etc/nginx/sites-available 2>/dev/null || true; curl -k -I -H 'Host: c2-webserver.c2.local' https://127.0.0.1; curl -k -I https://127.0.0.1 || true",
    )
    c2web.close()

    session = ps_session()
    results["jump64_baseline"] = run_ps(
        session,
        "hostname; $env:COMPUTERNAME; [System.Environment]::OSVersion.Version; whoami; Get-Date; Get-ComputerInfo | Select-Object CsName,OsName,OsVersion,CsNumberOfProcessors,CsPhysicallyInstalledMemory; Get-NetIPAddress | Select-Object InterfaceAlias,IPAddress,PrefixLength; Get-NetRoute | Where-Object { $_.DestinationPrefix -ne '0.0.0.0/0' } | Select-Object DestinationPrefix,NextHop,InterfaceAlias",
    )
    results["jump64_trustedhosts"] = run_ps(
        session,
        "Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value '172.30.65.2,172.30.65.3,172.30.65.4,172.30.65.11,172.30.65.162,172.30.65.180' -Force; Get-Item WSMan:\\localhost\\Client\\TrustedHosts | Select-Object -ExpandProperty Value",
    )
    results["jump64_testwsman"] = run_ps(
        session,
        "$targets='172.30.65.2','172.30.65.3','172.30.65.4','172.30.65.11','172.30.65.162','172.30.65.180'; foreach($t in $targets){ Write-Output ('TARGET=' + $t); try { Test-WSMan -ComputerName $t -ErrorAction Stop | Out-String } catch { 'ERROR: ' + $_.Exception.Message } }",
    )
    results["jump64_c1san"] = run_ps(
        session,
        "foreach($p in 3260,22){ Test-NetConnection -ComputerName 172.30.65.186 -Port $p | Select-Object ComputerName,RemotePort,TcpTestSucceeded,InterfaceAlias,SourceAddress | Format-List }",
    )

    c1_dc_script = """
hostname
$env:COMPUTERNAME
[System.Environment]::OSVersion.VersionString
Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, CsNumberOfProcessors, CsPhysicallyInstalledMemory
Get-ADDomain | Select-Object DNSRoot, DomainMode, PDCEmulator, RIDMaster, InfrastructureMaster
Get-ADForest | Select-Object Name, ForestMode, RootDomain, Domains
Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, IsGlobalCatalog, OperationMasterRoles
Get-Service ADWS, DNS, KDC, Netlogon, NTDS | Select-Object Name, Status, StartType
repadmin /showrepl
dcdiag /test:replications /test:services /test:dns /q
"""
    c1_host_creds = [("Administrator@c1.local", "Cisco123!"), ("C1\\Administrator", "Cisco123!")]
    results["c1dc1"] = try_remote(session, "172.30.65.2", c1_host_creds, c1_dc_script)
    results["c1dc2"] = try_remote(session, "172.30.65.3", c1_host_creds, c1_dc_script)

    c1fs_script = """
hostname
[System.Environment]::OSVersion.VersionString
Get-ComputerInfo | Select-Object CsName, OsName, CsNumberOfProcessors, CsPhysicallyInstalledMemory
Get-Disk | Select-Object Number, FriendlyName, Size, PartitionStyle
Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining
Get-SmbShare | Select-Object Name, Path, Description
Get-IscsiSession
Get-IscsiTarget
Get-Service LanmanServer, LanmanWorkstation | Select-Object Name, Status
"""
    results["c1fs"] = try_remote(session, "172.30.65.4", c1_host_creds, c1fs_script)

    c1web_script = """
hostname
[System.Environment]::OSVersion.VersionString
Get-ComputerInfo | Select-Object CsName, OsName, CsNumberOfProcessors, CsPhysicallyInstalledMemory
Get-Service W3SVC, WAS | Select-Object Name, Status, StartType
Import-Module WebAdministration
Get-Website | Select-Object Name, State, PhysicalPath, Id
Get-WebBinding | Select-Object protocol, bindingInformation, sslFlags
Get-ChildItem IIS:SSLBindings | Select-Object IPAddress, Port, Store, Thumbprint
netstat -an | Select-String ':443|:80'
"""
    results["c1webserver"] = try_remote(
        session,
        "172.30.65.162",
        [("Administrator@c1.local", "Cisco123!"), ("administrator", "Cisco123!")],
        c1web_script,
    )

    c1client_script = """
hostname
whoami
[System.Environment]::OSVersion.VersionString
Get-ComputerInfo | Select-Object CsName, OsName, CsDomain, CsDomainRole
(Get-WmiObject Win32_ComputerSystem).Domain
(Get-WmiObject Win32_ComputerSystem).PartOfDomain
query user
Resolve-DnsName c1-webserver.c1.local
Resolve-DnsName c2-webserver.c2.local
(Invoke-WebRequest -Uri https://c1-webserver.c1.local -UseBasicParsing -SkipCertificateCheck).StatusCode
(Invoke-WebRequest -Uri https://c2-webserver.c2.local -UseBasicParsing -SkipCertificateCheck).StatusCode
"""
    results["c1windowsclient"] = try_remote(
        session,
        "172.30.65.11",
        [
            ("Administrator@c1.local", "Cisco123!"),
            ("C1\\Administrator", "Cisco123!"),
            ("administrator", "Cisco123!"),
        ],
        c1client_script,
    )

    veeam_script = """
hostname
[System.Environment]::OSVersion.VersionString
Get-ComputerInfo | Select-Object CsName, OsName, CsNumberOfProcessors, CsPhysicallyInstalledMemory
Get-Service | Where-Object { $_.Name -like 'Veeam*' -or $_.DisplayName -like 'Veeam*' } | Select-Object Name, Status, StartType
Get-NetTCPConnection -LocalPort 445,9392,5985,10005,10006 -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State
"""
    results["s2veeam"] = try_remote(
        session,
        "172.30.65.180",
        [
            ("Administrator", "Cisco123!"),
            (".\\Administrator", "Cisco123!"),
            ("172.30.65.180\\Administrator", "Cisco123!"),
        ],
        veeam_script,
    )

    write_json("site2_v42_live_collect_results.json", results)
    lines = []
    for key, value in results.items():
        lines.append(f"== {key} ==")
        if isinstance(value, dict):
            lines.append(json.dumps(value, indent=2))
        else:
            lines.append(str(value))
        lines.append("")
    write_text("site2_v42_live_collect_results.txt", "\n".join(lines))
    print(str(OUTDIR))


if __name__ == "__main__":
    main()
