#!/bin/bash
set -euo pipefail

LOG_FILE=/var/log/c2_site1_sync.log
SITE1_HOST=172.30.64.146
SITE1_USER=admindc
SITE1_PASS='Cisco123!'
SITE1_SUDO_PASS='Cisco123!'
SRC_BASE=/mnt/sync_disk
DEST_BASE=/mnt/c2_public
TMP_BASE=$(mktemp -d /tmp/c2_site1_sync.XXXXXX)

cleanup() {
  rm -rf "$TMP_BASE"
}
trap cleanup EXIT

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

pull_tree() {
  local name="$1"
  local src="$SRC_BASE/$name"
  local stage="$TMP_BASE/$name"
  local dest="$DEST_BASE/$name"

  mkdir -p "$stage" "$dest"
  log "Pulling $name from ${SITE1_HOST}:$src"
  sshpass -p "$SITE1_PASS" ssh -o StrictHostKeyChecking=no "${SITE1_USER}@${SITE1_HOST}" \
    "echo '$SITE1_SUDO_PASS' | sudo -S -p '' tar -C '$src' -cpf - ." | tar -C "$stage" -xpf -

  log "Mirroring staged $name into $dest"
  rsync -aH --delete "$stage"/ "$dest"/
}

log 'Starting Site1 -> Site2 C2 sync'
pull_tree Public
pull_tree Private

chgrp -R c2_file_users "$DEST_BASE/Public"
chmod -R g+rwX "$DEST_BASE/Public"
find "$DEST_BASE/Public" -type d -exec chmod g+s {} +
chgrp c2_file_users "$DEST_BASE/Private"
chmod 0711 "$DEST_BASE/Private"

for d in "$DEST_BASE/Private"/*; do
  [ -d "$d" ] || continue
  user_name="$(basename "$d")"
  if id "$user_name" >/dev/null 2>&1; then
    chown "$user_name":c2_file_users "$d"
    chmod 0700 "$d"
  else
    chown root:c2_file_users "$d"
    chmod 0711 "$d"
  fi
done

log 'Sync completed successfully'
