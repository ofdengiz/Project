set -e
echo "-- OPNsense 443 --"
nc -zvw5 172.30.65.177 443 || true
echo "-- OPNsense 53 --"
nc -zvw5 172.30.65.177 53 || true