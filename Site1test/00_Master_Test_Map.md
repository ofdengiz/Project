# Master Test Map

This map keeps the toolkit aligned to `Site1_Final_Documentation_V2.6.docx`.

| Document Section | Feature | Primary Device | Verification Method |
| --- | --- | --- | --- |
| `3.2` | VLAN and addressing baseline | Jumpbox Win10, C1-DC1, C2-DC1, C2-DC2, Jumpbox Ubuntu | `00_Master_Menu.ps1` -> Network and Addressing |
| `3.2 / 3.10.2` | Company 1 and Company 2 tenant isolation, plus management-network restriction | C1-Client2, C2-Client1, OPNsense | `00_Master_Menu.ps1` -> VPN, Segmentation, and Administrative Access + `OPNsense_Checklist.md` |
| `3.3` | Tenant identity separation | C1-DC1, C1-DC2, C2-DC1, C2-DC2 | `00_Master_Menu.ps1` -> Identity, DNS, and DHCP |
| `3.3 / 3.6` | Company 1 client domain logon and resolver view | C1-Client1 | `Client_Experience_Checklist.md` |
| `3.6` | DNS and DHCP | C1-DC1, C1-DC2, C2-DC1, C2-DC2, C2-Client1 | `00_Master_Menu.ps1` -> Identity, DNS, and DHCP |
| `3.7` | iSCSI, SAN, Gluster, and file services | Server2, C1-DC1, C1-DC2, C2-DC1, C2-DC2 | `00_Master_Menu.ps1` -> Storage and SAN |
| `3.7` | iSCSI traffic isolation from user networks | C1-Client2, C2-Client1, Server2, OPNsense | `00_Master_Menu.ps1` -> VPN, Segmentation, and Administrative Access + `OPNsense_Checklist.md` |
| `3.7` | Client share experience and access control | C1-Client1, C1-Client2, C2-Client1 | `Client_Experience_Checklist.md` |
| `3.8` | Backup platform, repositories, and offsite path | Server2, Site2Repo | `00_Master_Menu.ps1` -> Backup and Recovery |
| `3.8.2` | C1 client backup agent evidence | C1-Client1 | `Client_Experience_Checklist.md` |
| `3.9.1` | Company 1 branding | C1-Client1 | Manual GUI check |
| `3.9.2` | Grafana and InfluxDB | Jumpbox Ubuntu | Scripted health test + GUI checklist |
| `3.9.3` | Cockpit | C2-DC1 | Scripted endpoint and service test + GUI checklist |
| `3.9.4` | Windows Admin Center | Jumpbox Win10 | Scripted service test + GUI checklist |
| `3.10.1` | Site-to-site VPN | Site2Repo, OPNsense | Scripted control-port test + GUI checklist |
| `3.10.2` | Administrative access | Jumpbox Win10, Jumpbox Ubuntu, C2-DC1, C1-DC1, Server2, Proxmox, Lab Switch, C1-Client2, C2-Client1 | Scripted endpoint probes + GUI checklists |
| `3.4.2` | Physical switching baseline | Lab Switch | Manual SSH or console checklist |
| `Appendix A` | VLAN addressing reference | Multiple | Network submenu + OPNsense / Lab Switch checklists |
| `Appendix B` | DHCP reference | C1-DC1, C2-DC1, C2-DC2, clients | Identity submenu |
| `Appendix C` | Storage reference | Server2, C1-DC1, C1-DC2, C2-DC1, C2-DC2 | Storage submenu |
| `Appendix D` | Backup reference | Server2, Site2Repo | Backup submenu + Server2 checklist |
| `Appendix E` | Requirement coverage and demonstration notes | All | Use this toolkit in the same sequence as the final demonstration |
