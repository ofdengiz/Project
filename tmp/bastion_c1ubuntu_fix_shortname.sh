set -e

sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no 'Administrator@c1.local@172.30.65.36' '
echo "== BEFORE =="
getent passwd Administrator || true
getent passwd administrator || true
getent passwd "Administrator@c1.local" || true
echo "Cisco123!" | sudo -S cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.bak_2026-03-25
echo "Cisco123!" | sudo -S python3 - <<'"'"'PY'"'"'
from pathlib import Path
p = Path("/etc/sssd/sssd.conf")
text = p.read_text()
if "use_fully_qualified_names = False" not in text:
    if "use_fully_qualified_names = True" in text:
        text = text.replace("use_fully_qualified_names = True", "use_fully_qualified_names = False")
    elif "use_fully_qualified_names = true" in text:
        text = text.replace("use_fully_qualified_names = true", "use_fully_qualified_names = False")
    else:
        lines = text.splitlines()
        out = []
        inserted = False
        for line in lines:
            out.append(line)
            if line.strip().startswith("[domain/") and not inserted:
                out.append("use_fully_qualified_names = False")
                inserted = True
        text = "\n".join(out) + "\n"
p.write_text(text)
PY
echo "Cisco123!" | sudo -S systemctl restart sssd
sleep 2
echo "== AFTER =="
getent passwd Administrator || true
getent passwd administrator || true
getent passwd "Administrator@c1.local" || true
'