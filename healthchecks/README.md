# Healthchecks

A simple script that checks whether your critical services are up and alerts you if something is down.

No external dependency. Runs as a cron job.

---

## What it checks

- Docker containers are running
- Nginx responds on HTTPS
- PostgreSQL accepts connections
- Disk usage is below threshold

---

## Script

See `healthcheck.sh` in this folder.

---

## Set up as a cron job

```bash
sudo crontab -e
```

Add:

```
*/5 * * * * /opt/scripts/healthcheck.sh >> /var/log/healthcheck.log 2>&1
```

Runs every 5 minutes.

---

## Alerting

The script sends an email when a check fails. Configure the `ALERT_EMAIL` variable and make sure `mailutils` is installed:

```bash
sudo apt install -y mailutils
```

For a more robust solution, pair this with Grafana alerts (see `../monitoring/`).
