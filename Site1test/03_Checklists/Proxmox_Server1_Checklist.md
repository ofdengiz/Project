# Proxmox Server1 Checklist

Related document sections:
- `3.5 Compute and Virtualization`
- `3.10.2 Administrative Access`

Show these items in the Proxmox GUI:
- Host reachable at `https://192.168.64.10:8006`
- VM inventory matches the systems described in `Tables 7, 8, and 9`
- Template VMs exist for Windows Server 2022, Windows 10, and Linux clients
- Network and storage views are consistent with the platform role described in `3.5`

Expected result:
- Proxmox is the single compute host for Site 1
- The VM inventory is consistent with the final document
- Templates support repeatable provisioning
