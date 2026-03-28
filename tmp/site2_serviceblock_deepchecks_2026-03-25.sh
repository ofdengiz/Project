set -e

echo '===== C2IdM1 ACCOUNT AND DHCP SUMMARY ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.66 'echo "== HOST =="; hostname; echo "== USERS =="; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool user list | sed -n "1,20p"; echo "== GROUPS =="; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool group list | sed -n "1,25p"; echo "== DHCP FAILOVER =="; grep -n "failover peer\|primary;\|secondary;\|subnet 172.30.65.64" /etc/dhcp/dhcpd.conf || true; echo "== DNS ZONES =="; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool dns zonelist 127.0.0.1 -P | egrep "pszZoneName|ZoneType" || true'

echo
echo '===== C2IdM2 ACCOUNT AND DHCP SUMMARY ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.67 'echo "== HOST =="; hostname; echo "== USERS =="; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool user list | sed -n "1,20p"; echo "== GROUPS =="; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool group list | sed -n "1,25p"; echo "== DHCP FAILOVER =="; grep -n "failover peer\|primary;\|secondary;\|subnet 172.30.65.64" /etc/dhcp/dhcpd.conf || true; echo "== DNS ZONES =="; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool dns zonelist 127.0.0.1 -P | egrep "pszZoneName|ZoneType" || true'

echo
echo '===== C2LinuxClient IDENTITY AND SHARE MODEL ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 'echo "== HOST =="; hostname; echo "== REALM =="; realm list; echo "== USERS =="; getent passwd admin || true; getent passwd "employee1@c2.local" || true; getent passwd "employee2@c2.local" || true; echo "== WHOAMI AS USERS =="; printf "%s\n" "Cisco123!" | sudo -S -p "" -u "employee1@c2.local" whoami || true; printf "%s\n" "Cisco123!" | sudo -S -p "" -u "employee2@c2.local" whoami || true; echo "== RESOLVER =="; nmcli dev show ens18 | egrep "IP4.ADDRESS|IP4.GATEWAY|IP4.DNS|IP4.DOMAIN" || true; echo "== HOST RESOLUTION =="; nslookup c1-webserver.c1.local; nslookup c2-webserver.c2.local; echo "== SHARE PRESENTATION =="; findmnt -t cifs,nfs || true; grep -E "C2_Public|C2_Private" /etc/fstab || true; ls -ld /home/* 2>/dev/null | sed -n "1,20p"; echo "== SESSION SCRIPT =="; ls -l /usr/local/sbin/c2-share-session 2>/dev/null || echo missing; echo "== WEB =="; curl -skI https://c1-webserver.c1.local; curl -skI https://c2-webserver.c2.local'

echo
echo '===== C2FS SHARE AND PRIVATE TREE ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.68 'echo "== HOST =="; hostname; echo "== SHARES =="; printf "%s\n" "Cisco123!" | sudo -S -p "" testparm -s 2>/dev/null | grep -A6 "^\[C2_Public\]"; printf "%s\n" "Cisco123!" | sudo -S -p "" testparm -s 2>/dev/null | grep -A6 "^\[C2_Private\]"; echo "== TREE =="; printf "%s\n" "Cisco123!" | sudo -S -p "" find /mnt/c2_public -maxdepth 2 -type d | sort | sed -n "1,40p"'