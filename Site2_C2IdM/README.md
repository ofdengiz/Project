# Site 2 Company 2 Identity Runbook

This folder is the starting package for bringing the Site 2 Company 2 identity hosts into the already-running Company 2 domain from Site 1.

It is based on two local sources that were available in the workspace:

- `Site1_Final_Documentation_V1.7.docx`
- `Dokumantasyon_icin_gerekli.docx`

## Stable Design Taken From Site 1

The Site 1 handover document is consistent on these points:

- Company 2 uses `Samba AD on Ubuntu Server`
- Core services are `authentication, DNS, DHCP, SMB`
- The Company 2 directory domain is `c2.local`
- The Company 2 controller pattern is dual-controller
- Existing Site 1 Company 2 DCs are documented as `172.30.64.146` and `172.30.64.147`

## Site 2 Assumptions Used Here

These scripts keep the Site 2 addressing assumption from the newer local notes, but they no longer create a new domain.

- `C2IdM1` hostname: `c2idm1`
- `C2IdM2` hostname: `c2idm2`
- Existing shared domain: `c2.local`
- Kerberos realm: `C2.LOCAL`
- NetBIOS domain: `C2`
- Company 2 gateway at Site 2: `172.30.65.65`
- `C2IdM1` local Site 2 IP: `172.30.65.66/26`
- `C2IdM2` local Site 2 IP: `172.30.65.67/26`
- Existing Site 1 C2 DCs: `172.30.64.146`, `172.30.64.147`

If the final shared notes use different Site 2 IPs or different Site 1 DC IPs, update the variables before execution.

## What Is In This Folder

- `c2idm1-bootstrap.sh`
  Joins the first Site 2 identity VM as an additional DC in the existing `c2.local` domain.
- `c2idm2-join.sh`
  Joins the second Site 2 identity VM as another additional DC after `C2IdM1` is in place.

## Recommended Build Order

1. Confirm VPN routing and DNS reachability from Site 2 to the existing Site 1 C2 DCs.
2. Set static networking on `C2IdM1`.
3. Point `C2IdM1` DNS to the Site 1 C2 DC IPs for the initial join.
4. Run `c2idm1-bootstrap.sh` on `C2IdM1`.
5. Validate Kerberos, DNS, and replication on `C2IdM1`.
6. Set static networking on `C2IdM2`.
7. Point `C2IdM2` DNS first to `C2IdM1`, then to a Site 1 C2 DC.
8. Run `c2idm2-join.sh` on `C2IdM2`.
9. Validate multi-site replication, DNS, and logon behavior.

## Static Network Examples

Example netplan for `C2IdM1` before the domain join:

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 172.30.65.66/26
      routes:
        - to: default
          via: 172.30.65.65
      nameservers:
        addresses:
          - 172.30.64.146
          - 172.30.64.147
        search:
          - c2.local
```

Example netplan for `C2IdM2` before the domain join:

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 172.30.65.67/26
      routes:
        - to: default
          via: 172.30.65.65
      nameservers:
        addresses:
          - 172.30.65.66
          - 172.30.64.146
        search:
          - c2.local
```

After the join is complete, a sensible DNS order is:

- `C2IdM1`: `172.30.65.66`, `172.30.64.146`, `172.30.64.147`
- `C2IdM2`: `172.30.65.67`, `172.30.65.66`, `172.30.64.146`

## Execution Notes

Run each script as `root` or with `sudo -i`.

The scripts expect:

- Ubuntu Server 22.04 LTS or newer
- a fresh machine, or at minimum no existing Samba AD DC state
- working VPN routing between Site 2 and Site 1
- working time sync before the join
- successful DNS lookup of the existing `c2.local` domain from Site 2

Set the administrator password in the shell before running:

```bash
export ADMIN_PASS='ChangeThisImmediately!'
```

If your join account is not the default domain administrator, also set:

```bash
export ADMIN_USER='Administrator'
```

## Post-Build Validation

Run these on `C2IdM1` after it joins:

```bash
kinit administrator@C2.LOCAL
klist
samba-tool drs showrepl
host -t SRV _ldap._tcp.c2.local 127.0.0.1
host -t SRV _kerberos._udp.c2.local 127.0.0.1
```

Run these on `C2IdM2` after it joins:

```bash
samba-tool drs kcc
samba-tool drs showrepl
host -t SRV _ldap._tcp.c2.local 127.0.0.1
```

Run this from either Site 2 DC to confirm the joined environment is healthy:

```bash
samba-tool user list | head
samba-tool computer list
samba-tool dns query 127.0.0.1 c2.local @ ALL
```

## DHCP Follow-Up

The Site 1 handover says Company 2 DHCP is provided from the Samba domain controller layer with ISC DHCP.

I have still left DHCP out of the scripts because it should only be enabled after:

- the Site 2 DC joins complete successfully
- replication is healthy
- you confirm whether DHCP stays active at Site 1 only, becomes split between sites, or uses a failover design

## Important Assumption

The shared links could not be fully extracted in this environment. If those links specify:

- different hostnames
- a different domain than `c2.local`
- different Site 1 DC IPs
- a different Site 2 IP plan

then adjust the variables and rerun with that model. The current package now follows the existing-domain model instead of a new-domain model.