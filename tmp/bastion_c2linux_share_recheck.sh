set -e
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 <<'EOF'
echo "-- REALM --"
realm list || true
echo "-- PUBLIC --"
smbclient //c2fs.c2.local/C2_Public -W C2 -U 'employee1%Cisco123!' -c 'ls' || true
echo "-- PRIVATE1 --"
smbclient //c2fs.c2.local/C2_Private -W C2 -U 'employee1%Cisco123!' -c 'ls' || true
echo "-- PRIVATE2 --"
smbclient //c2fs.c2.local/C2_Private -W C2 -U 'employee2%Cisco123!' -c 'ls' || true
EOF