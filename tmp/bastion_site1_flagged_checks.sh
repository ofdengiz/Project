set -e

echo "== BASTION_IDENTITY =="
hostname
whoami
ip -4 addr show

echo "== C2_WEB_HOSTNAME_ONLY =="
curl -k -I https://c2-webserver.c2.local || true

echo "== SHARED_REPOSITORY_SMB_PATH =="
if command -v smbclient >/dev/null 2>&1; then
  smbclient -L //c2fs.c2.local -W C2 -U 'employee1%Cisco123!' || true
  smbclient //c2fs.c2.local/C2_Public -W C2 -U 'employee1%Cisco123!' -c 'ls' || true
else
  echo "smbclient not installed"
fi

echo "== OPNsense_MANAGEMENT_PLANE =="
curl -k -I https://172.30.65.177/ || true
nc -zvw4 172.30.65.177 443 || true

echo "== C2LINUXCLIENT_MOUNT_AND_PRIVATE =="
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 '
echo "-- REALM --"
realm list || true
echo "-- RESOLVER --"
resolvectl status | sed -n "1,25p" || true
echo "-- SMBCLIENT PUBLIC --"
smbclient //c2fs.c2.local/C2_Public -W C2 -U "employee1%Cisco123!" -c "ls" || true
echo "-- SMBCLIENT PRIVATE EMPLOYEE1 --"
smbclient //c2fs.c2.local/C2_Private -W C2 -U "employee1%Cisco123!" -c "ls" || true
echo "-- SMBCLIENT PRIVATE EMPLOYEE2 --"
smbclient //c2fs.c2.local/C2_Private -W C2 -U "employee2%Cisco123!" -c "ls" || true
'