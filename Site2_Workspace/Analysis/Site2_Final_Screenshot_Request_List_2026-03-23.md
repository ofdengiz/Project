# Site 2 Final Screenshot Request List

Date: 2026-03-23

The earlier March 22 list is now partially closed. The items below are the remaining screenshots that would add the most value to the revised Site 2 final package after the March 23 Veeam and OPNsense troubleshooting pass.

## Highest Priority

1. `Jump64` final DNS settings
   Show the Windows adapter Advanced DNS order used for the final demo workflow.

2. `mspubuntujump` resolver configuration
   Show `/etc/netplan/01-netcfg.yaml` and, if possible, `resolvectl status`.

3. `S2Veeam` final troubleshooting proof
   Capture:
   - the job list showing the current Windows/Linux/file job set
   - the repository list showing the IP-based repository object
   - the `Get-NetTCPConnection` proof for `10005` and `10006`
   - the Windows Firewall rule showing the inbound allow for `10005-10006`
   - one representative failed-session detail showing `172.30.65.180:10006` timeout or `veeam` resolution dependence

4. Site 2 OPNsense Veeam rule proof
   Capture:
   - alias list showing `S2_VEEAM`
   - alias list showing `VEEAM_COPY_PORTS`
   - `C1LAN` rules
   - `C2LAN` rules
   - `OpenVPN` rules

5. `C2LinuxClient` live connectivity proof for Veeam
   Capture:
   - `nc -zvw5 172.30.65.180 10005`
   - `nc -zvw5 172.30.65.180 10006`
   This is useful even if it still fails, because it supports the firewall-path section of the report.

## Already Collected and Ready to Use

1. `C2IdM1` replication and DNS proof
2. `C2IdM2` replication and DNS proof
3. `C2FS` storage and sync proof
4. `C2LinuxClient` SSSD and domain-identity proof
5. `C2WebServer` Docker and hostname-only hardening proof
6. MSP Ubuntu jump HTTPS validation for `c1-webserver.c1.local` and `c2-webserver.c2.local`

## Still Useful If Time Permits

1. Browser proof for the public AWS website
   Show `https://clearroots.omerdengiz.com` in a normal external browser session.

2. Route53 record screenshot
   Useful to support the public web appendix and explain why the jump-host resolver limitation does not equal a site outage.

3. `C2LinuxClient` interactive private-share isolation
   If you can show `employee1` and `employee2` contexts cleanly, this would still strengthen the file-service appendix.
