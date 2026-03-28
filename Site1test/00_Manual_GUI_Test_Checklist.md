# Manual GUI Test Checklist

Use this file when the teacher asks for visual proof instead of command output.

This is the short list of items that should be shown manually from GUI, browser, SSH, or console views.

## Manual-only or primarily manual checks

1. `C1-Client1` user experience
   - Show domain logon, DNS settings, branding, mapped shares, private/public access behavior, and Veeam Agent presence.
   - Checklist: `03_Checklists\Client_Experience_Checklist.md`
   - Document sections: `3.3`, `3.6`, `3.7`, `3.8.2`, `3.9.1`, `3.10.2`

2. `C1-Client2` Linux client experience
   - Show mounted shares, private/public access behavior, and Linux client administration path.
   - Checklist: `03_Checklists\Client_Experience_Checklist.md`
   - Document sections: `3.7`, `3.10.2`

3. `C2-Client1` Linux client experience
   - Show mounted shares, private/public access behavior, and SSH administration path.
   - Checklist: `03_Checklists\Client_Experience_Checklist.md`
   - Document sections: `3.7`, `3.10.2`

4. `Lab Switch`
   - Show trunks, uplinks, access ports, and physical switching baseline.
   - Checklist: `03_Checklists\Lab_Switch_Checklist.md`
   - Document sections: `3.4.2`, `Appendix A`

5. `Proxmox VE`
   - Show VM inventory, templates, storage views, and management console.
   - Checklist: `03_Checklists\Proxmox_Server1_Checklist.md`
   - Document sections: `3.5`, `3.10.2`

6. `C1 Web` and `C2 Web`
   - Show both web applications in a browser and verify the expected page content.
   - Checklist: `03_Checklists\Web_Applications_Checklist.md`
   - Document sections: `3.2`, `3.10`

## Manual checks that supplement scripted evidence

7. `OPNsense`
   - Show VLAN interfaces, routing, firewall rules, VPN status, tenant isolation, management-network separation, and SAN/iSCSI isolation evidence.
   - Checklist: `03_Checklists\OPNsense_Checklist.md`
   - Document sections: `3.2`, `3.7`, `3.10.1`, `3.10.2`

8. `Server2`
   - Show Disk Management, iSCSI Target views, repository drives, and Veeam console screens.
   - Checklist: `03_Checklists\Server2_Storage_Backup_Checklist.md`
   - Document sections: `3.7`, `3.8`

9. `Grafana`, `Cockpit`, and `Windows Admin Center`
   - Show dashboards or admin pages after the scripted health checks pass.
   - Checklist: `03_Checklists\Value_Added_GUI_Checklist.md`
   - Document sections: `3.9.2`, `3.9.3`, `3.9.4`

## Fast teacher demo order

1. `OPNsense`
2. `Proxmox VE`
3. `Server2`
4. `C1-Client1`
5. `C1 Web` and `C2 Web`
6. `Grafana`, `Cockpit`, and `Windows Admin Center`
7. `Lab Switch` if physical switching proof is requested

## Quick note

The automated toolkit covers the command-driven parts.

This file exists for the remaining evidence that is better shown visually:
- user experience
- branding
- web pages
- dashboards
- firewall rule views
- switch and hypervisor management screens
