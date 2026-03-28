import io
import sys
import textwrap
from datetime import datetime
from pathlib import Path

ROOT = Path(r"C:\Algonquin\Winter2026\Emerging_Tech\Project")
sys.path.insert(0, str(ROOT / "_pydeps"))

import paramiko
import winrm
from PIL import Image, ImageDraw, ImageFont


OUTDIR = ROOT / f"Site2_CLI_Evidence_{datetime.now().strftime('%Y-%m-%d_%H%M%S')}"
OUTDIR.mkdir(parents=True, exist_ok=True)


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


def tunneled_ssh(msp_client: paramiko.SSHClient, host: str, user: str, password: str):
    transport = msp_client.get_transport()
    channel = transport.open_channel("direct-tcpip", (host, 22), ("127.0.0.1", 0))
    return ssh_client(host, user, password, sock=channel)


def ssh_run(client, command: str) -> str:
    stdin, stdout, stderr = client.exec_command(command, timeout=90)
    stdout.channel.recv_exit_status()
    return stdout.read().decode("utf-8", errors="ignore").strip()


def ps_session():
    return winrm.Session(
        "http://100.97.37.83:5985/wsman",
        auth=("Administrator", "Cisco123!"),
        transport="ntlm",
        server_cert_validation="ignore",
    )


def run_ps(script: str) -> str:
    result = ps_session().run_ps(script)
    return result.std_out.decode("utf-8", errors="ignore").strip()


def wrap_line(line: str, width: int = 118):
    line = (
        line.replace("—", "-")
        .replace("–", "-")
        .replace("’", "'")
        .replace("“", '"')
        .replace("”", '"')
    )
    line = line.encode("ascii", "replace").decode("ascii")
    if not line:
        return [""]
    return textwrap.wrap(line, width=width, replace_whitespace=False, drop_whitespace=False) or [line]


def render_terminal_png(title: str, body: str, out_path: Path):
    font_path = r"C:\Windows\Fonts\consola.ttf"
    try:
        font = ImageFont.truetype(font_path, 24)
        title_font = ImageFont.truetype(font_path, 26)
    except Exception:
        font = ImageFont.load_default()
        title_font = ImageFont.load_default()

    lines = []
    for raw in body.splitlines():
        lines.extend(wrap_line(raw))

    dummy = Image.new("RGB", (10, 10))
    draw = ImageDraw.Draw(dummy)

    def text_w(line: str, use_font):
        if hasattr(draw, "textbbox"):
            try:
                return draw.textbbox((0, 0), line if line else " ", font=use_font)[2]
            except Exception:
                pass
        return draw.textsize(line if line else " ", font=use_font)[0]

    def text_h(line: str, use_font):
        if hasattr(draw, "textbbox"):
            try:
                return draw.textbbox((0, 0), line if line else " ", font=use_font)[3]
            except Exception:
                pass
        return draw.textsize(line if line else " ", font=use_font)[1]

    line_h = text_h("Ag", font) + 8
    max_w = 0
    for line in [title] + lines:
        max_w = max(max_w, text_w(line, font))
    width = min(max(1400, max_w + 80), 2200)
    height = 80 + line_h * (len(lines) + 2)

    img = Image.new("RGB", (width, height), "#0d1117")
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, width, 56), fill="#161b22")
    draw.text((20, 14), title, fill="#c9d1d9", font=title_font)
    y = 76
    for line in lines:
        fill = "#c9d1d9"
        if "$ " in line or line.startswith("PS "):
            fill = "#7ee787"
        elif line.startswith("HTTP/") or line.startswith("active") or line.startswith("C1") or line.startswith("c2") or line.startswith("C2") or line.startswith("msp"):
            fill = "#d2a8ff"
        draw.text((24, y), line, fill=fill, font=font)
        y += line_h
    img.save(str(out_path))


def build_linux_transcript(jump_prompt: str, ssh_target: str, target_prompt: str, commands):
    parts = [f"{jump_prompt}$ ssh {ssh_target}"]
    for cmd, out in commands:
        parts.append(f"{target_prompt}$ {cmd}")
        if out:
            parts.append(out.rstrip())
    return "\n".join(parts).strip() + "\n"


def build_jump64_transcript(commands):
    parts = []
    for cmd, out in commands:
        parts.append(f"PS C:\\Users\\Administrator> {cmd}")
        if out:
            parts.append(out.rstrip())
    return "\n".join(parts).strip() + "\n"


def main():
    msp = ssh_client("100.82.97.92", "admin", "Cisco123!")

    # Figure 6
    c2idm1 = tunneled_ssh(msp, "172.30.65.66", "admin", "Cisco123!")
    cmds = []
    cmds.append(("hostname", ssh_run(c2idm1, "hostname")))
    cmds.append(("systemctl is-active samba-ad-dc", ssh_run(c2idm1, "systemctl is-active samba-ad-dc")))
    cmds.append(("systemctl is-active isc-dhcp-server", ssh_run(c2idm1, "systemctl is-active isc-dhcp-server")))
    cmds.append(("echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P", ssh_run(c2idm1, "echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P | sed '/password for admin/d'")))
    cmds.append(("echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P", ssh_run(c2idm1, "echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P | sed '/password for admin/d'")))
    render_terminal_png("Figure 6 - C2IdM1 AD / DNS / DHCP", build_linux_transcript("admin@mspubuntujump:~", "admin@172.30.65.66", "admin@c2idm1:~", cmds), OUTDIR / "Figure06_C2IdM1.png")
    c2idm1.close()

    # Figure 7
    c2idm2 = tunneled_ssh(msp, "172.30.65.67", "admin", "Cisco123!")
    cmds = []
    cmds.append(("hostname", ssh_run(c2idm2, "hostname")))
    cmds.append(("systemctl is-active samba-ad-dc", ssh_run(c2idm2, "systemctl is-active samba-ad-dc")))
    cmds.append(("systemctl is-active isc-dhcp-server", ssh_run(c2idm2, "systemctl is-active isc-dhcp-server")))
    cmds.append(("echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P", ssh_run(c2idm2, "echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P | sed '/password for admin/d'")))
    cmds.append(("echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P", ssh_run(c2idm2, "echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P | sed '/password for admin/d'")))
    render_terminal_png("Figure 7 - C2IdM2 AD / DNS / DHCP", build_linux_transcript("admin@mspubuntujump:~", "admin@172.30.65.67", "admin@c2idm2:~", cmds), OUTDIR / "Figure07_C2IdM2.png")
    c2idm2.close()

    # Figure 8
    c2idm1 = tunneled_ssh(msp, "172.30.65.66", "admin", "Cisco123!")
    cmds = []
    cmds.append(("hostname", ssh_run(c2idm1, "hostname")))
    cmds.append(("echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P", ssh_run(c2idm1, "echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P | sed '/password for admin/d'")))
    cmds.append(("echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P", ssh_run(c2idm1, "echo 'Cisco123!' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P | sed '/password for admin/d'")))
    render_terminal_png("Figure 8 - Shared-Forest Cross-Domain DNS", build_linux_transcript("admin@mspubuntujump:~", "admin@172.30.65.66", "admin@c2idm1:~", cmds), OUTDIR / "Figure08_CrossDomainDNS.png")
    c2idm1.close()

    # Figure 9
    c2fs = tunneled_ssh(msp, "172.30.65.68", "admin", "Cisco123!")
    cmds = []
    cmds.append(("hostname", ssh_run(c2fs, "hostname")))
    cmds.append(("echo 'Cisco123!' | sudo -S iscsiadm -m session", ssh_run(c2fs, "echo 'Cisco123!' | sudo -S iscsiadm -m session | sed '/password for admin/d'")))
    cmds.append(("findmnt /mnt/c2_public", ssh_run(c2fs, "findmnt /mnt/c2_public")))
    cmds.append(("lsblk -f", ssh_run(c2fs, "lsblk -f")))
    render_terminal_png("Figure 9 - C2FS iSCSI and Mounted Volume", build_linux_transcript("admin@mspubuntujump:~", "admin@172.30.65.68", "admin@c2fs:~", cmds), OUTDIR / "Figure09_C2FS_iSCSI_Mount.png")

    # Figure 10
    cmds = []
    cmds.append(("hostname", ssh_run(c2fs, "hostname")))
    cmds.append(("systemctl is-active smbd", ssh_run(c2fs, "systemctl is-active smbd")))
    cmds.append(("echo 'Cisco123!' | sudo -S bash -lc \"testparm -s 2>/dev/null | grep -A6 '^\\[C2_Public\\]'\"", ssh_run(c2fs, "echo 'Cisco123!' | sudo -S bash -lc \"testparm -s 2>/dev/null | grep -A6 '^\\[C2_Public\\]'\" | sed '/password for admin/d'")))
    cmds.append(("echo 'Cisco123!' | sudo -S bash -lc \"testparm -s 2>/dev/null | grep -A6 '^\\[C2_Private\\]'\"", ssh_run(c2fs, "echo 'Cisco123!' | sudo -S bash -lc \"testparm -s 2>/dev/null | grep -A6 '^\\[C2_Private\\]'\" | sed '/password for admin/d'")))
    cmds.append(("echo 'Cisco123!' | sudo -S tail -n 12 /var/log/c2_site1_sync.log", ssh_run(c2fs, "echo 'Cisco123!' | sudo -S tail -n 12 /var/log/c2_site1_sync.log | sed '/password for admin/d'")))
    render_terminal_png("Figure 10 - C2FS SMB Shares and Sync", build_linux_transcript("admin@mspubuntujump:~", "admin@172.30.65.68", "admin@c2fs:~", cmds), OUTDIR / "Figure10_C2FS_Shares_Sync.png")
    c2fs.close()

    # Figure 13
    c1ubuntu = tunneled_ssh(msp, "172.30.65.36", "Administrator", "Cisco123!")
    cmds = []
    cmds.append(("hostname", ssh_run(c1ubuntu, "hostname")))
    cmds.append(("whoami", ssh_run(c1ubuntu, "whoami")))
    cmds.append(("realm list", ssh_run(c1ubuntu, "realm list")))
    cmds.append(("curl -k -I https://c1-webserver.c1.local", ssh_run(c1ubuntu, "curl -k -I https://c1-webserver.c1.local")))
    cmds.append(("curl -k -I https://c2-webserver.c2.local", ssh_run(c1ubuntu, "curl -k -I https://c2-webserver.c2.local")))
    render_terminal_png("Figure 13 - C1UbuntuClient Dual-Web", build_linux_transcript("admin@mspubuntujump:~", "Administrator@172.30.65.36", "Administrator@C1UbuntuClient:~", cmds), OUTDIR / "Figure13_C1UbuntuClient_DualWeb.png")
    c1ubuntu.close()
    msp.close()

    # Jump64-based Company 1 and Veeam CLI evidence.
    def jump_ps(inner: str) -> str:
        return run_ps(inner)

    c1dc1 = jump_ps(r"""
$sec = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$sec)
Invoke-Command -ComputerName 172.30.65.2 -Credential $cred -ScriptBlock {
  hostname
  Get-Service NTDS,DNS,KDC,Netlogon | Select-Object Name,Status
} | Out-String -Width 220
""")
    render_terminal_png(
        "Jump64 - C1DC1 Service State",
        build_jump64_transcript([("Invoke-Command -ComputerName 172.30.65.2 -Credential Administrator@c1.local -ScriptBlock { hostname; Get-Service NTDS,DNS,KDC,Netlogon }", c1dc1)]),
        OUTDIR / "Jump64_C1DC1_ServiceState.png",
    )

    c1dc2 = jump_ps(r"""
$sec = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$sec)
Invoke-Command -ComputerName 172.30.65.3 -Credential $cred -ScriptBlock {
  hostname
  Get-Service NTDS,DNS,KDC,Netlogon | Select-Object Name,Status
} | Out-String -Width 220
""")
    render_terminal_png(
        "Jump64 - C1DC2 Service State",
        build_jump64_transcript([("Invoke-Command -ComputerName 172.30.65.3 -Credential Administrator@c1.local -ScriptBlock { hostname; Get-Service NTDS,DNS,KDC,Netlogon }", c1dc2)]),
        OUTDIR / "Jump64_C1DC2_ServiceState.png",
    )

    c1fs = jump_ps(r"""
$sec = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$sec)
Invoke-Command -ComputerName 172.30.65.4 -Credential $cred -ScriptBlock {
  hostname
  Get-Volume | Where-Object DriveLetter -eq 'F' | Select-Object DriveLetter,FileSystemLabel,SizeRemaining,Size
  Get-SmbShare | Where-Object Name -in 'PublicData','Pub_S2','Priv_S2' | Select-Object Name,Path
  Get-IscsiSession | Select-Object TargetNodeAddress,IsConnected
} | Out-String -Width 220
""")
    render_terminal_png(
        "Jump64 - C1FS Storage and Shares",
        build_jump64_transcript([("Invoke-Command -ComputerName 172.30.65.4 -Credential Administrator@c1.local -ScriptBlock { hostname; Get-Volume F; Get-SmbShare; Get-IscsiSession }", c1fs)]),
        OUTDIR / "Jump64_C1FS_StorageShares.png",
    )

    c1web = jump_ps(r"""
$sec = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('c1-webserver\Administrator',$sec)
Invoke-Command -ComputerName 172.30.65.162 -Credential $cred -ScriptBlock {
  hostname
  Get-WmiObject Win32_ComputerSystem | Select-Object Name,Domain,PartOfDomain
  Import-Module WebAdministration
  Get-WebBinding | Select-Object protocol,bindingInformation,HostHeader
} | Out-String -Width 220
""")
    render_terminal_png(
        "Jump64 - C1WebServer IIS Binding",
        build_jump64_transcript([("Invoke-Command -ComputerName 172.30.65.162 -Credential c1-webserver\\Administrator -ScriptBlock { hostname; Get-WmiObject Win32_ComputerSystem; Get-WebBinding }", c1web)]),
        OUTDIR / "Jump64_C1WebServer_IIS.png",
    )

    c1wmi = jump_ps(r"""
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$pw)
Get-WmiObject Win32_ComputerSystem -ComputerName 172.30.65.11 -Credential $cred | Select-Object Name,Domain,PartOfDomain,Model
Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName 172.30.65.11 -Credential $cred | Where-Object { $_.IPEnabled } | Select-Object IPAddress,DefaultIPGateway
""")
    render_terminal_png(
        "Jump64 - C1WindowsClient Baseline",
        build_jump64_transcript([("Get-WmiObject Win32_ComputerSystem / Win32_NetworkAdapterConfiguration -ComputerName 172.30.65.11 -Credential Administrator@c1.local", c1wmi)]),
        OUTDIR / "Jump64_C1WindowsClient_Baseline.png",
    )

    c1webprobe = jump_ps(r"""
$pw = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@c1.local',$pw)
$cmd = 'cmd.exe /c (echo HOSTNAME & hostname & echo DNS1 & nslookup c1-webserver.c1.local & echo DNS2 & nslookup c2-webserver.c2.local & echo CURL1 & curl.exe -k -I https://c1-webserver.c1.local & echo CURL2 & curl.exe -k -I https://c2-webserver.c2.local) > C:\Windows\Temp\site2_client_probe_terminal.txt 2>&1'
Invoke-WmiMethod -Class Win32_Process -Name Create -ComputerName 172.30.65.11 -Credential $cred -ArgumentList $cmd | Out-Null
Start-Sleep -Seconds 6
cmd /c "net use \\172.30.65.11\c$ /user:C1\Administrator Cisco123!"
cmd /c "type \\172.30.65.11\c$\Windows\Temp\site2_client_probe_terminal.txt"
cmd /c "del \\172.30.65.11\c$\Windows\Temp\site2_client_probe_terminal.txt"
cmd /c "net use \\172.30.65.11\c$ /delete /y"
""")
    render_terminal_png(
        "Jump64 - C1WindowsClient Web Probe",
        build_jump64_transcript([("Invoke-WmiMethod Win32_Process -> C1WindowsClient, then read probe output over \\\\172.30.65.11\\c$", c1webprobe)]),
        OUTDIR / "Jump64_C1WindowsClient_WebProbe.png",
    )

    veeam_cli = jump_ps(r"""
$sec = ConvertTo-SecureString 'Cisco123!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('.\Administrator',$sec)
Invoke-Command -ComputerName 172.30.65.180 -Credential $cred -ScriptBlock {
  hostname
  try { Add-PSSnapin VeeamPSSnapIn -ErrorAction Stop } catch {}
  Get-VBRBackupRepository | Select-Object Name,Path | Format-Table -AutoSize
  Get-VBRJob | Select-Object Name,JobType,LastResult | Format-Table -AutoSize
  Get-VBRBackupCopyJob | Select-Object Name,LastResult | Format-Table -AutoSize
} | Out-String -Width 220
""")
    render_terminal_png(
        "Jump64 - S2Veeam CLI Evidence",
        build_jump64_transcript([("Invoke-Command -ComputerName 172.30.65.180 -Credential .\\Administrator -ScriptBlock { Add-PSSnapin VeeamPSSnapIn; Get-VBRBackupRepository; Get-VBRJob; Get-VBRBackupCopyJob }", veeam_cli)]),
        OUTDIR / "Jump64_S2Veeam_CLI.png",
    )

    manifest = io.StringIO()
    manifest.write("Generated CLI evidence images\n")
    manifest.write(f"Output folder: {OUTDIR}\n\n")
    for path in sorted(OUTDIR.glob("*.png")):
        manifest.write(path.name + "\n")
    (OUTDIR / "README.txt").write_text(manifest.getvalue(), encoding="utf-8")
    print(str(OUTDIR))


if __name__ == "__main__":
    main()
