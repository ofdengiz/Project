# Lab Switch Checklist

Related document sections:
- `3.4.2 Physical Switching and Uplink Baseline`

Show these items by SSH or local console:
- `Gi8/0/1` trunk to Proxmox with native VLAN `64`
- `Gi8/0/5` and `Gi8/0/6` storage-only trunks for VLANs `40` and `140`
- `Gi8/0/24` upstream teacher-switch trunk allowing only VLANs `1`, `64`, and `65`
- Access ports for Server2 management and both iLO interfaces on VLAN `64`
- Switch management IP `192.168.64.2`
- SSH enabled, HTTP disabled, rapid-PVST enabled

Expected result:
- The switch clearly enforces the physical separation described in the document
- SAN VLANs do not leak into the upstream lab network
