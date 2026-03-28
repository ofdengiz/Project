import json
import sys
from pathlib import Path

ROOT = Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project")
sys.path.insert(0, str(ROOT / "pydeps"))

import paramiko
import winrm


def latest_outdir() -> Path:
    return sorted(ROOT.glob("site2_v42_live_2026-03-27_*"))[-1]


OUTDIR = latest_outdir()


def write_text(name: str, text: str) -> None:
    (OUTDIR / name).write_text(text, encoding="utf-8", errors="ignore")


def ssh_client(host: str, user: str, password: str):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(hostname=host, username=user, password=password, timeout=15, look_for_keys=False, allow_agent=False)
    return client


def ssh_exec(client, command: str) -> str:
    stdin, stdout, stderr = client.exec_command(command, timeout=60)
    stdout.channel.recv_exit_status()
    return stdout.read().decode("utf-8", errors="ignore") + "\n" + stderr.read().decode("utf-8", errors="ignore")


def ps_session():
    return winrm.Session(
        "http://100.97.37.83:5985/wsman",
        auth=("Administrator", "Cisco123!"),
        transport="ntlm",
        server_cert_validation="ignore",
    )


def run_ps(script: str) -> str:
    result = ps_session().run_ps(script)
    return result.std_out.decode("utf-8", errors="ignore") + "\n" + result.std_err.decode("utf-8", errors="ignore")


def main():
    msp = ssh_client("100.82.97.92", "admin", "Cisco123!")
    write_text(
        "msp_opnsense_and_c1san_ports_2026-03-27.txt",
        ssh_exec(
            msp,
            "for t in '172.30.65.177 80' '172.30.65.177 443' '172.30.65.177 53' '172.30.65.186 3260' '172.30.65.186 22' '172.30.65.186 3389' '172.30.65.180 445' '172.30.65.180 9392'; do set -- $t; echo TARGET=$1:$2; nc -zvw4 $1 $2; done",
        ),
    )
    msp.close()

    write_text(
        "jump64_testwsman_2026-03-27.txt",
        run_ps(
            "$targets='172.30.65.2','172.30.65.3','172.30.65.4','172.30.65.11','172.30.65.162','172.30.65.180'; foreach($t in $targets){ Write-Output ('TARGET=' + $t); try { Test-WSMan -ComputerName $t -ErrorAction Stop | Out-String } catch { 'ERROR: ' + $_.Exception.Message } }"
        ),
    )
    write_text(
        "c1fs_focused_2026-03-27.txt",
        run_ps(
            """
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$pw)
Invoke-Command -ComputerName 172.30.65.4 -Credential $cred -ScriptBlock {
  hostname
  [System.Environment]::OSVersion.VersionString
  Get-Disk | Select-Object Number,FriendlyName,Size,PartitionStyle
  Get-Volume | Select-Object DriveLetter,FileSystemLabel,FileSystem,Size,SizeRemaining
  Get-SmbShare | Select-Object Name,Path,Description
  Get-SmbSession | Select-Object ClientComputerName,ClientUserName,NumOpens
  Get-IscsiSession
  Get-IscsiTarget
  Get-Service LanmanServer,LanmanWorkstation | Select-Object Name,Status
}
"""
        ),
    )
    write_text(
        "c1webserver_focused_2026-03-27.txt",
        run_ps(
            """
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('C1WEBSERVER\\administrator',$pw)
Invoke-Command -ComputerName 172.30.65.162 -Credential $cred -ScriptBlock {
  hostname
  whoami
  [System.Environment]::OSVersion.VersionString
  Get-Service W3SVC,WAS | Select-Object Name,Status,StartType
  Import-Module WebAdministration
  Get-Website | Select-Object Name,State,PhysicalPath,Id
  Get-WebBinding | Select-Object protocol,bindingInformation,sslFlags
  Get-ChildItem IIS:SSLBindings | Select-Object IPAddress,Port,Store,Thumbprint
  netstat -an | Select-String ':443|:80'
}
"""
        ),
    )
    write_text(
        "c1windowsclient_wmi_2026-03-27.txt",
        run_ps(
            """
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$pw)
Get-WmiObject Win32_ComputerSystem -ComputerName 172.30.65.11 -Credential $cred | Select-Object Name,Domain,PartOfDomain,UserName,Model
Get-WmiObject Win32_OperatingSystem -ComputerName 172.30.65.11 -Credential $cred | Select-Object CSName,Caption,Version,LastBootUpTime
Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName 172.30.65.11 -Credential $cred | Where-Object { $_.IPEnabled } | Select-Object Description,IPAddress,DefaultIPGateway
"""
        ),
    )
    write_text(
        "c1windowsclient_webprobe_2026-03-27.txt",
        run_ps(
            r"""
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$pw)
$cmd = 'cmd.exe /c (echo HOSTNAME & hostname & echo WHOAMI & whoami & echo DNS1 & nslookup c1-webserver.c1.local & echo DNS2 & nslookup c2-webserver.c2.local & echo CURL1 & curl.exe -k -I https://c1-webserver.c1.local & echo CURL2 & curl.exe -k -I https://c2-webserver.c2.local) > C:\Windows\Temp\site2_client_probe_final.txt 2>&1'
Invoke-WmiMethod -Class Win32_Process -Name Create -ComputerName 172.30.65.11 -Credential $cred -ArgumentList $cmd | Out-Null
Start-Sleep -Seconds 6
cmd /c "net use \\172.30.65.11\c$ /user:C1\Administrator Cisco123!"
cmd /c "type \\172.30.65.11\c$\Windows\Temp\site2_client_probe_final.txt"
cmd /c "del \\172.30.65.11\c$\Windows\Temp\site2_client_probe_final.txt"
cmd /c "net use \\172.30.65.11\c$ /delete /y"
"""
        ),
    )
    write_text(
        "s2veeam_focused_2026-03-27.txt",
        run_ps(
            """
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('.\\Administrator',$pw)
Invoke-Command -ComputerName 172.30.65.180 -Credential $cred -ScriptBlock {
  hostname
  [System.Environment]::OSVersion.VersionString
  Get-ComputerInfo | Select-Object CsName,OsName,OsVersion,CsNumberOfProcessors,CsPhysicallyInstalledMemory
  Get-Service | Where-Object { $_.Name -like 'Veeam*' -or $_.DisplayName -like 'Veeam*' } | Select-Object Name,Status,StartType
  Get-NetTCPConnection -LocalPort 445,9392,5985,10005,10006 -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State
}
"""
        ),
    )
    print(str(OUTDIR))


if __name__ == "__main__":
    main()
