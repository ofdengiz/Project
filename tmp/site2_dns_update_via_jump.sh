set -e

update_dc() {
  host_ip="$1"
  sshpass -p admin ssh -o StrictHostKeyChecking=no "ofdengiz@${host_ip}" <<'INNER'
set -e
printf 'admin\n' | sudo -S cp /etc/samba/smb.conf /etc/samba/smb.conf.bak-20260320
printf 'admin\n' | sudo -S sed -i 's/^[[:space:]]*dns forwarder = .*/   dns forwarder = 172.30.64.130/' /etc/samba/smb.conf
printf 'admin\n' | sudo -S systemctl restart samba-ad-dc
printf 'admin\n' | sudo -S systemctl is-active samba-ad-dc
grep -n 'dns forwarder' /etc/samba/smb.conf
INNER
}

update_dc 172.30.65.66
update_dc 172.30.65.67

sshpass -p admin ssh -o StrictHostKeyChecking=no ofdengiz@172.30.65.66 <<'INNER'
set -e
printf 'admin\n' | sudo -S samba-tool dns add 127.0.0.1 c2.local c2-webserver A 172.30.65.170 -P || true
printf 'admin\n' | sudo -S samba-tool dns query 127.0.0.1 c2.local c2-webserver A -P
INNER
