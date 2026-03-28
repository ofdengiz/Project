set -e

echo '=== C2LINUXCLIENT STATUS ==='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 "hostname; nmcli -g ipv4.dns-search connection show netplan-ens18; resolvectl status | sed -n '1,20p'; echo '== NSLOOKUP_C1 =='; nslookup c1-webserver.c1.local; echo '== NSLOOKUP_C2 =='; nslookup c2-webserver.c2.local; echo '== GETENT_C1 =='; getent hosts c1-webserver.c1.local; echo '== GETENT_C2 =='; getent hosts c2-webserver.c2.local; echo '== CURL_C1 =='; curl -skI https://c1-webserver.c1.local; echo '== CURL_C2 =='; curl -skI https://c2-webserver.c2.local"

echo '=== C2WEBSERVER NGINX ==='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.170 "hostname; printf '%s\n' 'Cisco123!' | sudo -S -p '' systemctl is-active nginx; echo '== SERVER_NAME =='; printf '%s\n' 'Cisco123!' | sudo -S -p '' grep -R 'server_name' /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null || true; echo '== LOCAL_HOST_HEADER =='; curl -skI -H 'Host: c2-webserver.c2.local' https://127.0.0.1; echo '== LOCAL_RAW_IP =='; curl -skI https://127.0.0.1"