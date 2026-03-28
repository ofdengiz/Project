# Site 2 Recommended Additional Screenshots

Date: 2026-03-20

These screenshots are not blockers for the current documentation package, but they would make the Site 2 final documentation much closer to the depth and evidence density of the Site 1 final report.

## Highest priority

1. OPNsense dashboard or interface assignment screen
   - Show Site 2 interfaces for MSP, C1 DMZ, C1 LAN, C2 DMZ, and C2 LAN.
   - Best section match: Network Design and Site-to-Site VPN Security.

2. OPNsense OpenVPN status or tunnel configuration screen
   - Show the Site 1 to Site 2 routed trust path.
   - Best section match: Site-to-Site VPN Security and Administrative Access.

3. OPNsense NAT / port-forward rules page
   - Show the provisional WAN publication rules for Jump64, Ubuntu jump, and internal web.
   - Best section match: Network Design and Limitations/Risks.

4. DHCP scope or failover view for Company 2
   - Preferably from the actual GUI or management console used in the environment.
   - Best section match: Identity, DNS, and DHCP Services.

5. C2IdM1 or C2IdM2 replication / administration screenshot
   - Example: Samba AD replication, domain users, DNS zones, or host summary.
   - Best section match: Identity Infrastructure and Tenant Separation.

6. C2FS mount and sync proof
   - Example: terminal showing `/mnt/c2_public` mounted and recent lines from `/var/log/c2_site1_sync.log`.
   - Best section match: Storage and File Services.

7. Veeam repository or protection group screen
   - Show the Site 2 repository, the offsite SMB repository, or the Site2_All protection group.
   - Best section match: Backup and Recovery.

8. Lumora HTTPS browser proof
   - Preferably a browser view clearly showing the internal HTTPS page and trust state.
   - Best section match: Value Added Features.

## Medium priority

1. C2Web Apache service proof or local web page
2. Windows jump RDP session showing management success
3. Ubuntu jump terminal showing internal host validation
4. AWS Elastic IP screen
5. Docker Hub image screen for `ofdengiz/clearroots-web`

## Nice to have

1. Any topology or diagram board used during planning
2. Company 2 user/group administration screenshot
3. Client login proof for a Company 2 user
4. A restore or restore-point preview screen from Veeam

## Practical recommendation

If only a small number of additional screenshots can be collected, the best return comes from:

- OPNsense interfaces
- OPNsense OpenVPN/NAT
- C2FS mount and sync proof
- one C2 identity admin/replication screen
- one Veeam repository/protection-group screen

Those five additions would close a large part of the remaining evidence gap versus the Site 1 document.
