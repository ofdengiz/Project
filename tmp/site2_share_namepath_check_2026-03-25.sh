set -e

echo '===== C2IdM1 NAME CHECK ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.66 'printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool dns query 127.0.0.1 c2.local c2fs A -P || true; printf "%s\n" "Cisco123!" | sudo -S -p "" /usr/bin/samba-tool dns query 127.0.0.1 c2.local c2idm1 A -P || true'

echo
echo '===== C2LinuxClient NAME CHECK ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 'echo "== HOSTS =="; getent hosts c2fs.c2.local || true; getent hosts c2idm1.c2.local || true; echo "== SMBCLIENT =="; smbclient -L //c2fs.c2.local -W C2 -U employee1%Cisco123! 2>/dev/null | sed -n "1,30p" || true'