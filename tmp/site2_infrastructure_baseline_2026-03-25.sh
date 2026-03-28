set -e

echo '===== C2IdM1 ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.66 'hostname; hostnamectl 2>/dev/null || true; echo "== CPU =="; nproc; lscpu | sed -n "1,12p"; echo "== MEMORY =="; free -h; echo "== DISK =="; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT; echo "== ROOTFS =="; df -h /; echo "== IP =="; ip -4 addr show; echo "== SERVICES =="; systemctl list-units --type=service --state=running --no-pager | grep -E "samba|dhcp|nginx|smbd|iscsid|sssd|NetworkManager" || true'
echo
echo '===== C2IdM2 ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.67 'hostname; hostnamectl 2>/dev/null || true; echo "== CPU =="; nproc; lscpu | sed -n "1,12p"; echo "== MEMORY =="; free -h; echo "== DISK =="; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT; echo "== ROOTFS =="; df -h /; echo "== IP =="; ip -4 addr show; echo "== SERVICES =="; systemctl list-units --type=service --state=running --no-pager | grep -E "samba|dhcp|nginx|smbd|iscsid|sssd|NetworkManager" || true'
echo
echo '===== C2FS ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.68 'hostname; hostnamectl 2>/dev/null || true; echo "== CPU =="; nproc; lscpu | sed -n "1,12p"; echo "== MEMORY =="; free -h; echo "== DISK =="; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT; echo "== ROOTFS =="; df -h /; echo "== IP =="; ip -4 addr show; echo "== SERVICES =="; systemctl list-units --type=service --state=running --no-pager | grep -E "samba|dhcp|nginx|smbd|iscsid|sssd|NetworkManager" || true'
echo
echo '===== C2LinuxClient ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 'hostname; hostnamectl 2>/dev/null || true; echo "== CPU =="; nproc; lscpu | sed -n "1,12p"; echo "== MEMORY =="; free -h; echo "== DISK =="; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT; echo "== ROOTFS =="; df -h /; echo "== IP =="; ip -4 addr show; echo "== SERVICES =="; systemctl list-units --type=service --state=running --no-pager | grep -E "samba|dhcp|nginx|smbd|iscsid|sssd|NetworkManager" || true'
echo
echo '===== C2WebServer ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.170 'hostname; hostnamectl 2>/dev/null || true; echo "== CPU =="; nproc; lscpu | sed -n "1,12p"; echo "== MEMORY =="; free -h; echo "== DISK =="; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT; echo "== ROOTFS =="; df -h /; echo "== IP =="; ip -4 addr show; echo "== SERVICES =="; systemctl list-units --type=service --state=running --no-pager | grep -E "samba|dhcp|nginx|smbd|iscsid|sssd|NetworkManager" || true'