#!/usr/bin/env bash
set -euo pipefail

# Join a fresh Ubuntu VM as the first Site 2 Samba AD DC for the existing Company 2 domain.

: "${ADMIN_PASS:?Set ADMIN_PASS before running this script.}"

HOST_SHORT="${HOST_SHORT:-c2idm1}"
REALM="${REALM:-C2.LOCAL}"
DNS_DOMAIN="${DNS_DOMAIN:-c2.local}"
ADMIN_USER="${ADMIN_USER:-Administrator}"
SITE1_DC1_IP="${SITE1_DC1_IP:-172.30.64.146}"
SITE1_DC2_IP="${SITE1_DC2_IP:-172.30.64.147}"

backup_file() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    cp -a "$path" "${path}.pre-change.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
  fi
}

set_prejoin_resolver() {
  if [[ -L /etc/resolv.conf ]]; then
    rm -f /etc/resolv.conf
  fi

  cat >/etc/resolv.conf <<EOF
search ${DNS_DOMAIN}
nameserver ${SITE1_DC1_IP}
nameserver ${SITE1_DC2_IP}
EOF
}

set_postjoin_resolver() {
  if [[ -L /etc/resolv.conf ]]; then
    rm -f /etc/resolv.conf
  fi

  cat >/etc/resolv.conf <<EOF
search ${DNS_DOMAIN}
nameserver 127.0.0.1
nameserver ${SITE1_DC1_IP}
nameserver ${SITE1_DC2_IP}
EOF
}

echo "[1/9] Installing required packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y samba krb5-user winbind dnsutils chrony smbclient acl attr

echo "[2/9] Setting hostname"
hostnamectl set-hostname "${HOST_SHORT}"

echo "[3/9] Pointing DNS to Site 1 DCs for initial join"
set_prejoin_resolver

echo "[4/9] Stopping conflicting services"
systemctl stop smbd nmbd winbind systemd-resolved samba-ad-dc 2>/dev/null || true
systemctl disable smbd nmbd winbind systemd-resolved 2>/dev/null || true
systemctl mask systemd-resolved 2>/dev/null || true

echo "[5/9] Backing up existing config"
backup_file /etc/samba/smb.conf
backup_file /etc/krb5.conf

echo "[6/9] Preparing Kerberos"
cat >/etc/krb5.conf <<EOF
[libdefaults]
    default_realm = ${REALM}
    dns_lookup_realm = false
    dns_lookup_kdc = true
EOF

echo "[7/9] Joining the existing domain as an additional DC"
rm -f /etc/samba/smb.conf
samba-tool domain join "${REALM}" DC \
  --dns-backend=SAMBA_INTERNAL \
  --username="${ADMIN_USER}" \
  --password="${ADMIN_PASS}"

echo "[8/9] Installing generated Kerberos config"
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
set_postjoin_resolver

echo "[9/9] Starting Samba AD DC"
systemctl unmask samba-ad-dc 2>/dev/null || true
systemctl enable --now samba-ad-dc

echo
echo "Site 2 DC1 joined. Basic validation:"
samba-tool drs showrepl
host -t SRV _ldap._tcp."${DNS_DOMAIN}" 127.0.0.1
host -t SRV _kerberos._udp."${DNS_DOMAIN}" 127.0.0.1
echo
echo "Recommended next step:"
echo "  kinit ${ADMIN_USER}@${REALM}"
echo "  samba-tool user list | head"