set -e

sshpass -p admin ssh -o StrictHostKeyChecking=no ofdengiz@172.30.65.66 <<'INNER'
set -e
printf 'admin\n' | sudo -S samba-tool dns zonecreate 127.0.0.1 c1.local -P || true
printf 'admin\n' | sudo -S samba-tool dns add 127.0.0.1 c1.local c1-webserver A 172.30.64.162 -P || true
printf 'admin\n' | sudo -S samba-tool dns add 127.0.0.1 c1.local c1-webserver A 172.30.65.162 -P || true
printf 'admin\n' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P
INNER

sshpass -p admin ssh -o StrictHostKeyChecking=no ofdengiz@172.30.65.67 <<'INNER'
set -e
printf 'admin\n' | sudo -S samba-tool dns query 127.0.0.1 c1.local c1-webserver A -P
INNER
