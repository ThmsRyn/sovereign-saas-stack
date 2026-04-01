#!/bin/bash
# Encrypted PostgreSQL backup script
# Requires: restic, age, docker

set -euo pipefail

# Cleanup on exit (success or failure)
ENCRYPTED_FILE=""
cleanup() {
  [ -n "$ENCRYPTED_FILE" ] && rm -f "$ENCRYPTED_FILE"
}
trap cleanup EXIT

# Configuration - adapt to your setup
DB_CONTAINER="postgres"
DB_USER="postgres"
DB_NAME="appdb"
AGE_RECIPIENT="age1yourpublickey"  # Replace with your age public key
RESTIC_REPO="/backups/restic-repo"  # Or sftp://, s3://, etc.
RESTIC_PASSWORD_FILE="/root/.restic-password"
COMPOSE_DIR="/opt/myapp"
BACKUP_DIR="/tmp/backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup..."

# 1. Dump and encrypt in a single pipe — the plaintext SQL never touches disk
ENCRYPTED_FILE="$BACKUP_DIR/db_${DATE}.sql.age"
docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -T "$DB_CONTAINER" \
  pg_dump -U "$DB_USER" "$DB_NAME" | \
  age --encrypt -r "$AGE_RECIPIENT" -o "$ENCRYPTED_FILE"

echo "[$(date)] Database dumped and encrypted."

# 2. Verify restic repository is initialized
restic -r "$RESTIC_REPO" --password-file "$RESTIC_PASSWORD_FILE" snapshots > /dev/null 2>&1 || {
  echo "[$(date)] ERROR: Restic repository not initialized. Run: restic -r $RESTIC_REPO init"
  exit 1
}

# 3. Send to restic repository
restic -r "$RESTIC_REPO" --password-file "$RESTIC_PASSWORD_FILE" backup "$BACKUP_DIR"
restic -r "$RESTIC_REPO" --password-file "$RESTIC_PASSWORD_FILE" forget \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune

# 4. Cleanup local temp (handled by trap)

echo "[$(date)] Backup complete."
