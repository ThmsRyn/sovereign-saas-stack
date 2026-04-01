# Encrypted Backups

Backups use two tools:
- **restic** - incremental, deduplicated backup tool
- **age** - simple, modern file encryption

Your database dumps are encrypted before leaving your server.
Even if your backup destination is compromised, the data is unreadable.

---

## Install restic

```bash
sudo apt update
sudo apt install -y restic
```

---

## Install age

```bash
sudo apt install -y age
```

---

## Generate an age keypair

```bash
age-keygen -o ~/.age/key.txt
cat ~/.age/key.txt
```

Store the private key offline. The public key goes in your backup script.

---

## Backup script

See `backup.sh` in this folder. It:
1. Dumps the PostgreSQL database and pipes it directly through age encryption — the plaintext SQL dump never exists on disk
2. Sends the encrypted file to a restic repository (local, SFTP, or S3-compatible)
3. Removes the local encrypted file after the restic backup completes

---

## Set up a cron job

```bash
sudo crontab -e
```

Add:

```
0 3 * * * /opt/myapp/backups/backup.sh >> /var/log/backup.log 2>&1
```

This runs the backup every day at 3 AM.

---

## Restore

```bash
# Decrypt
age --decrypt -i ~/.age/key.txt backup.sql.age -o backup.sql

# Restore to PostgreSQL
docker compose exec -T postgres psql -U appuser -d appdb < backup.sql
```

---

## Verify

```bash
restic -r /path/to/repo snapshots
restic -r /path/to/repo check
```
