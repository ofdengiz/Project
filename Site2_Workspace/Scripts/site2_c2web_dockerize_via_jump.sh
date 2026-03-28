set -e

sshpass -p admin ssh -o StrictHostKeyChecking=no odengiz@172.30.65.170 <<'INNER'
set -e

printf 'admin\n' | sudo -S mkdir -p /opt/c2web/html /opt/c2web/certs

curl -k -s https://172.30.64.170/ -o /tmp/site1_c2_index.html
curl -k -s https://172.30.64.170/c2.png -o /tmp/c2.png

printf 'admin\n' | sudo -S cp /tmp/site1_c2_index.html /opt/c2web/html/index.html
printf 'admin\n' | sudo -S cp /tmp/c2.png /opt/c2web/html/c2.png

cat >/tmp/c2web-nginx.conf <<'NGINX'
events {}

http {
    server {
        listen 80;
        server_name c2-webserver.c2.local;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name c2-webserver.c2.local;

        ssl_certificate     /etc/nginx/certs/c2-webserver.crt;
        ssl_certificate_key /etc/nginx/certs/c2-webserver.key;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
NGINX

printf 'admin\n' | sudo -S cp /tmp/c2web-nginx.conf /opt/c2web/nginx.conf

cat >/tmp/c2web-openssl.cnf <<'OPENSSL'
[req]
default_bits = 2048
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn

[dn]
CN = c2-webserver.c2.local

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = c2-webserver.c2.local
OPENSSL

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/c2-webserver.key \
  -out /tmp/c2-webserver.crt \
  -config /tmp/c2web-openssl.cnf

printf 'admin\n' | sudo -S cp /tmp/c2-webserver.key /opt/c2web/certs/c2-webserver.key
printf 'admin\n' | sudo -S cp /tmp/c2-webserver.crt /opt/c2web/certs/c2-webserver.crt

printf 'admin\n' | sudo -S systemctl stop apache2 || true
printf 'admin\n' | sudo -S systemctl disable apache2 || true

printf 'admin\n' | sudo -S docker rm -f c2web || true
printf 'admin\n' | sudo -S docker pull nginx:alpine
printf 'admin\n' | sudo -S docker run -d --name c2web \
  --restart unless-stopped \
  -p 80:80 -p 443:443 \
  -v /opt/c2web/html:/usr/share/nginx/html:ro \
  -v /opt/c2web/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /opt/c2web/certs:/etc/nginx/certs:ro \
  nginx:alpine

sleep 5
printf 'admin\n' | sudo -S docker ps --filter name=c2web
curl -I http://127.0.0.1
curl -k -I https://127.0.0.1
INNER
