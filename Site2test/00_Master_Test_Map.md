# Site 2 Master Test Map

This map adapts the Site 1 testing model to the current Site 2 topology.

| Feature | Primary Device | Verification Method |
| --- | --- | --- |
| MSP management path | Windows Jump, Ubuntu Jump | Public path port checks + Ubuntu jump shell access |
| Site 2 addressing baseline | Ubuntu Jump, C2IdM1, C2IdM2, C2FS, C2LinuxClient | Raw network outputs in `04_Results/raw` |
| Company 1 Windows server reachability | C1DC1, C1DC2, C1FS | Port matrix from Ubuntu jump |
| Company 2 identity layer | C2IdM1, C2IdM2 | `samba-ad-dc` state + resolver output |
| Company 2 storage and sync | C2FS | Mount, disk, script, and sync log checks |
| Company 2 Linux client identity | C2LinuxClient | `getent`, `id`, and resolver status |
| Inter-site connectivity to Site 1 | Site 1 DCs and backup/storage host paths | Port matrix from Ubuntu jump |
| Public web publishing | C1 Web | Public path probe + internal HTTP probe |
| Site 2 backup host reachability | Veeam host `172.30.65.180` | Port checks from Ubuntu jump |
