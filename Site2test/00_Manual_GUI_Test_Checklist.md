# Site 2 Manual GUI Checklist

Use this short list if visual confirmation is needed after the scripted checks.

1. `OPNsense`
   - show interfaces, OpenVPN status, WAN NAT rules, MSP rules, and C1/C2 isolation rules

2. `Windows Jump`
   - show successful RDP login path and available admin tools

3. `Ubuntu Jump`
   - show SSH login and internal reachability to Site 2 hosts

4. `C1DC1 / C1DC2`
   - show DNS, AD DS, and DFSR service views if an RDP session is available

5. `C2IdM1 / C2IdM2`
   - show `samba-ad-dc` active state and replication output

6. `C2FS`
   - show mounted `/mnt/c2_public`, sync script, and sync log

7. `C2LinuxClient`
   - show `employee1@c2.local` identity resolution and share workflow if credentials are available

8. `C1 Web` and `C2 Web`
   - show the web pages in a browser if the HTTP paths are expected to be live
