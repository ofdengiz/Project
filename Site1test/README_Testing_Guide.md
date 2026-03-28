# Site 1 Central Test Toolkit

This toolkit is intended to be run from the Windows jumpbox at `172.30.64.179`.

It is aligned to:
- [Site1_Final_Documentation_V2.6.docx](/Users/Stephen/Desktop/Site1_Final_Documentation_V2.6.docx)
- The final discussion sections in Chapter 3
- Appendices A through E
- The project requirements for tenant isolation, management-network separation, firewall-controlled remote access, and iSCSI isolation

## Principles
- All scripted checks are read-only.
- No script changes any device configuration.
- `PASS` means the expected service or evidence pattern was observed.
- `FAIL` means the connection or command failed.
- `REVIEW` means the command ran, but the output still needs operator judgement.

## How to use
1. Open PowerShell on the Win10 jumpbox.
2. Change to `C:\Users\Stephen\Desktop\test`.
3. Run:

```powershell
.\00_Master_Menu.ps1
```

4. If you only want to verify the toolkit syntax, run:

```powershell
.\00_Master_Menu.ps1 -SelfTest
```

## Notes
- Windows remote checks use WinRM. If WinRM is not enabled on a target, the test will return `FAIL`.
- Linux remote checks use `ssh`. If OpenSSH is missing or the target cannot be reached, the test will return `FAIL`.
- GUI-heavy items are intentionally handled through checklist files in `03_Checklists`.
- A consolidated manual checklist is available at `00_Manual_GUI_Test_Checklist.md`.

## Most likely teacher workflow
- `1. Network and Addressing`
- `2. Identity, DNS, and DHCP`
- `3. Storage and SAN`
- `4. Backup and Recovery`
- `5. Value Added Features`
- `6. VPN and Administrative Access`

`VPN and Administrative Access` now also covers firewall and segmentation evidence:
- Company 1 client cannot reach Company 2 DNS or SAN endpoints
- Company 2 client cannot reach Company 1 DNS or SAN endpoints
- Tenant clients cannot reach management services such as Proxmox

## Output
- Session output is written to `04_Results\latest_session.log`
- Summary exports are written to timestamped files in `04_Results`
