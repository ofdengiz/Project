set -e

echo '===== C2LinuxClient SMB ACCESS ====='
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no admin@172.30.65.70 '
  echo "== PUBLIC_EMPLOYEE1 =="
  smbclient //c2fs.c2.local/C2_Public -W C2 -U employee1%Cisco123! -c ls
  echo
  echo "== PRIVATE_EMPLOYEE1 =="
  smbclient //c2fs.c2.local/C2_Private -W C2 -U employee1%Cisco123! -c ls
  echo
  echo "== PRIVATE_EMPLOYEE2 =="
  smbclient //c2fs.c2.local/C2_Private -W C2 -U employee2%Cisco123! -c ls
  echo
  echo "== WRITECHECK_PUBLIC_EMPLOYEE1 =="
  tmpf=$(mktemp /tmp/c2pub.XXXXXX)
  echo employee1-public-test > "$tmpf"
  smbclient //c2fs.c2.local/C2_Public -W C2 -U employee1%Cisco123! -c "put $tmpf employee1-public-test.txt; ls employee1-public-test.txt; del employee1-public-test.txt"
  rm -f "$tmpf"
'