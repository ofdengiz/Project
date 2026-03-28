set -e
sshpass -p 'Cisco123!' ssh -o StrictHostKeyChecking=no administrator@172.30.65.36 'hostname; id; getent passwd administrator; groups'