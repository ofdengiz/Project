# OPNsense Checklist

Related document sections:
- `3.2 Network Design and IP Addressing Rationale`
- `3.7 Storage and SAN Services`
- `3.10.1 Site-to-Site VPN Security`
- `3.10.2 Administrative Access`

Show these items in OPNsense:
- VLAN interfaces and gateway assignments
- Inter-VLAN routing and firewall policy structure
- Explicit deny or block rules between Company 1 and Company 2 user networks
- Rules that keep tenant clients away from the management network and Proxmox / switch / firewall admin services
- Rules or design evidence showing SAN / iSCSI traffic stays on dedicated storage paths instead of user VLANs
- DHCP relay configuration
- OpenVPN status page
- Port-forward entries for C1 and C2 web exposure
- Management access path for VLAN 99

Expected result:
- OPNsense is visibly the routing and policy enforcement point
- VLANs and gateways match `Appendix A`
- Cross-tenant traffic is blocked except for explicitly justified services
- Management and storage networks are separated from ordinary user access
- VPN status is consistent with `Table 27`
