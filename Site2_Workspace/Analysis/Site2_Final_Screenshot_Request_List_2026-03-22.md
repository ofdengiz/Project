# Site 2 Final Screenshot Request List

Date: 2026-03-22

The items below are the remaining screenshots that would most improve the final Site 2 documentation package. They are ordered by impact, not by difficulty.

## Highest Priority

1. `Jump64` final DNS settings
   Show the Windows adapter Advanced DNS order that was used for the final demo workflow.

2. `mspubuntujump` resolver configuration
   Show `/etc/netplan/01-netcfg.yaml` and, if possible, `resolvectl status`.

3. `C2IdM1` replication and DNS proof
   Capture:
   - `systemctl status samba-ad-dc`
   - `systemctl status isc-dhcp-server`
   - `samba-tool drs showrepl`
   - `samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P`
   - `samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P`

4. `C2IdM2` replication and DNS proof
   Capture the same screens or terminal outputs as `C2IdM1` to show the replicated final state.

5. `C2FS` storage and sync proof
   Capture:
   - `findmnt /mnt/c2_public`
   - `ls -ld /mnt/c2_public /mnt/c2_public/Public /mnt/c2_public/Private`
   - `tail -n 12 /var/log/c2_site1_sync.log`

6. `C2LinuxClient` interactive share proof
   Capture:
   - resolver test for `c1-webserver.c1.local`
   - resolver test for `c2-webserver.c2.local`
   - per-user mounted share view
   - one access-denied example showing private-share isolation between `employee1` and `employee2`

7. `S2Veeam` console proof
   Capture:
   - backup jobs
   - repositories
   - recent job success
   - offsite or copy history

## Medium Priority

1. `C2WebServer` Docker and web hardening proof
   Capture:
   - `docker ps`
   - `curl -k -I https://172.30.65.170` returning `404`
   - `curl -k -I --resolve c2-webserver.c2.local:443:172.30.65.170 https://c2-webserver.c2.local` returning `200`

2. Site 2 OPNsense internal management proof
   Capture:
   - interface summary or dashboard
   - OpenVPN status
   - NAT / port-forward screen

3. MSP Ubuntu jump final web tests
   Capture:
   - `curl -k -I https://c1-webserver.c1.local`
   - `curl -k -I https://c2-webserver.c2.local`
   - pinned `--resolve` tests if possible

## Nice to Have

1. Browser proof for the public AWS website
   Show `https://clearroots.omerdengiz.com` in a normal external browser session.

2. Route53 record screenshot
   Useful to support the public web appendix and explain why the jump-host resolver limitation does not equal a site outage.

3. Any final OPNsense policy screenshots used in the live demo
   Especially if you want the Site 2 report to visually match the depth of the Site 1 document.
