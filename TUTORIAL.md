# Tutorial — Deploy a sovereign SaaS from scratch

This tutorial walks you through deploying a complete, production-ready SaaS stack on a single VPS. No managed services. No vendor lock-in. You own everything.

By the end, you will have:
- A Node.js application running in Docker
- HTTPS with automatic certificate renewal
- A WAF blocking common web attacks
- Secrets stored securely in OpenBao, not in `.env` files
- A PostgreSQL database that is never exposed to the internet
- Intrusion prevention with fail2ban and CrowdSec
- Encrypted automated backups
- Full monitoring with Prometheus and Grafana

Estimated time: 2 to 4 hours depending on your experience.

---

## Prerequisites

- A VPS with Ubuntu 22.04 or 24.04 (any provider: Hetzner, OVH, Scaleway, Infomaniak, etc.) or other if you prefer an other OS
- A domain name with an A record pointing to your server IP
- SSH access to your server
- Basic Linux knowledge: you can navigate the filesystem, edit files with nano or vim, and run commands as root

---

## Important: read this before starting

This stack has been tested on Ubuntu 24.04. If you are on another distribution, package names and paths may differ.

A few components have known quirks covered in this tutorial:

- **ModSecurity** can produce false positives on your app. Start in detection mode, not blocking mode.
- **OpenBao** has two modes: dev (no persistence, for testing) and production (requires unseal). This tutorial uses production mode.
- **diun** notifies you of image updates but does not apply them automatically. You decide when to update.
- **Grafana**: use the image `grafana/grafana`, not `grafana/grafana-oss` (the OSS image is no longer updated as of version 12.4.0).
- **PostgreSQL 17** is used. If you migrate from version 16, the data directory format changed — do not mount an old volume directly.

---

## Step 1 — Initial server setup

Connect to your server:

```bash
ssh root@your-server-ip
```

Update the system:

```bash
apt update && apt upgrade -y
```

Create a non-root user:

```bash
adduser thomas
usermod -aG sudo thomas
```

Copy your SSH key to the new user:

```bash
rsync --archive --chown=thomas:thomas ~/.ssh /home/thomas
```

From this point, work as your user, not root.

---

## Step 2 — SSH hardening

See `ssh/README.md` for the full explanation.

Apply the hardened SSH config:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo nano /etc/ssh/sshd_config
```

Set at minimum:

```
Port 2222
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
```

**Do not restart sshd yet.** Open the new port in UFW first (next step), or you will lock yourself out.

---

## Step 3 — Firewall (UFW)

```bash
sudo apt install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

Now restart SSH:

```bash
sudo systemctl restart sshd
```

Open a new terminal and test that you can connect on port 2222 before closing the current session:

```bash
ssh -p 2222 thomas@your-server-ip
```

---

## Step 4 — Docker

```bash
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
newgrp docker
```

Verify:

```bash
docker run hello-world
```

---

## Step 5 — Clone this repository

```bash
sudo mkdir -p /opt/myapp
sudo chown $USER:$USER /opt/myapp
cd /opt/myapp
git clone https://github.com/YOUR_USERNAME/sovereign-saas-stack.git .
```

Copy and fill your environment file:

```bash
cp .env.example .env
nano .env
```

Generate strong passwords for each variable:

```bash
openssl rand -base64 32
```

Never commit `.env`. It is already in `.gitignore`.

---

## Step 6 — Nginx and Certbot

Install Certbot on the host (it needs to write to `/etc/letsencrypt`, which will be mounted into the Nginx container):

```bash
sudo apt install -y certbot
```

Make sure your domain points to your server IP, then obtain a certificate in standalone mode (before starting Nginx):

```bash
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

Edit `nginx/conf.d/app.conf` and replace `yourdomain.com` with your actual domain.

Set up automatic renewal:

```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
sudo certbot renew --dry-run
```

After a successful renewal, reload Nginx:

```bash
# The certbot systemd timer handles renewal automatically.
# After renewal, reload Nginx with a post-renewal hook:
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << 'EOF'
#!/bin/bash
docker compose -f /opt/myapp/docker-compose.yml exec -T nginx nginx -s reload
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

---

## Step 7 — PostgreSQL

The database runs in Docker and is never exposed to the internet. No `ports:` directive in the Compose file means it is only reachable from other containers on the same internal network.

Set your database password in `.env`:

```
DB_PASSWORD=a-very-long-random-password
```

After the stack starts (step 10), create restricted users:

```bash
docker compose exec postgres psql -U postgres
```

```sql
-- appuser is created by the init script, not as a superuser
-- Connect as postgres admin:
\c appdb postgres
-- Revoke public schema from public
REVOKE ALL ON SCHEMA public FROM PUBLIC;
-- Create restricted app user
CREATE USER appuser WITH PASSWORD 'your-db-password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE appdb TO appuser;
GRANT ALL ON SCHEMA public TO appuser;

-- Create monitoring user for postgres-exporter (read-only)
CREATE USER monitoring WITH PASSWORD 'your-monitoring-password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
GRANT pg_monitor TO monitoring;
\q
```

---

## Step 8 — OpenBao (secrets management)

OpenBao replaces plaintext environment variables for your secrets.

**Why this matters:** if your server is ever compromised and an attacker reads your process environment or your `.env` file, they get all your secrets instantly. With OpenBao, secrets are encrypted at rest and your app fetches them at runtime using a token with limited permissions.

Add OpenBao to your `docker-compose.yml` (see `openbao/README.md` for the full service definition).

Start OpenBao:

```bash
docker compose up -d openbao
```

Initialize it (production mode):

```bash
docker compose exec openbao bao operator init
```

This outputs 5 unseal keys and a root token. **Save these somewhere safe and offline.** Losing them means losing all your secrets permanently.

Unseal (you need 3 of the 5 keys):

```bash
docker compose exec openbao bao operator unseal
# Run this 3 times with 3 different keys
```

Store your first secret:

```bash
docker compose exec openbao bao login  # use root token
docker compose exec openbao bao kv put secret/myapp \
  db_password="your-db-password" \
  api_key="your-api-key"
```

Create an app token with read-only access:

```bash
docker compose exec openbao bao token create -policy=default -ttl=720h
```

Put this token in `.env` as `BAO_TOKEN`. Your app uses it to fetch secrets.

---

## Step 9 — ModSecurity (WAF)

**Start in detection mode.** This is the most important advice in this tutorial.

ModSecurity with the OWASP Core Rule Set will block legitimate requests from your app if you enable blocking mode without tuning first. A single false positive can take your app offline.

In `modsecurity/modsecurity-override.conf`:

```
SecRuleEngine DetectionOnly
```

Run the stack for a few days, watch the logs:

```bash
docker compose logs nginx | grep -i modsec
```

For each false positive, add an exception in `modsecurity-override.conf`:

```
SecRuleRemoveById 942100
```

Once you are satisfied with the results, switch to blocking mode:

```
SecRuleEngine On
```

The image to use in `docker-compose.yml`:

```yaml
image: owasp/modsecurity-crs:4-nginx-202602250702
```

Always use a fixed tag, never the rolling `nginx` tag in production.

---

## Step 10 — Start the stack

```bash
cd /opt/myapp
docker compose up -d
```

Check that all containers are running:

```bash
docker compose ps
```

All services should show `running`. If a container exits immediately, check its logs:

```bash
docker compose logs service-name
```

Common issues at first start:

- **nginx exits**: your SSL certificate path is wrong or the cert does not exist yet. Check that `/etc/letsencrypt/live/yourdomain.com/` exists on the host.
- **postgres exits**: a volume from a previous PostgreSQL version is mounted. Delete the volume and let it initialize fresh: `docker volume rm myapp_postgres_data`.
- **openbao exits**: it is sealed. Run the unseal commands from step 8.
- **app exits**: check for missing environment variables or a database connection error. Make sure the database is initialized.

---

## Step 11 — fail2ban

```bash
sudo apt install -y fail2ban
sudo cp fail2ban/jail.local /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

Verify active jails:

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

The config in `fail2ban/jail.local` covers SSH and Nginx. Ban time is set to 1 hour with 5 retries. Adjust to your preference.

---

## Step 12 — CrowdSec

```bash
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt install -y crowdsec crowdsec-nginx-bouncer

sudo cscli collections install crowdsecurity/nginx
sudo cscli collections install crowdsecurity/linux
sudo systemctl restart crowdsec
```

CrowdSec and fail2ban run side by side without conflict. CrowdSec manages its own iptables chains.

Check active decisions:

```bash
sudo cscli decisions list
sudo cscli alerts list
```

---

## Step 13 — Encrypted backups

Install the tools:

```bash
sudo apt install -y restic age
```

Generate an age keypair:

```bash
mkdir -p ~/.age
age-keygen -o ~/.age/key.txt
```

The public key is in `~/.age/key.txt` (line starting with `# public key:`). Copy it.

Edit `backups/backup.sh`:
- Set `AGE_RECIPIENT` to your public key
- Set `RESTIC_REPO` to your backup destination (local path, SFTP, or S3-compatible)
- Set `COMPOSE_DIR` to `/opt/myapp`

Initialize the restic repository:

```bash
restic -r /path/to/your/repo init
```

Test the backup script:

```bash
sudo bash backups/backup.sh
```

Set up the cron job:

```bash
sudo crontab -e
```

Add:

```
0 3 * * * /opt/myapp/backups/backup.sh >> /var/log/backup.log 2>&1
```

**Store your age private key (`~/.age/key.txt`) offline.** Without it, your encrypted backups are unreadable.

---

## Step 14 — Monitoring (Prometheus + Grafana)

Install Node Exporter on the host:

```bash
# Always check the latest release before downloading:
# https://github.com/prometheus/node_exporter/releases
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xvf node_exporter-1.10.2.linux-amd64.tar.gz
sudo mv node_exporter-1.10.2.linux-amd64/node_exporter /usr/local/bin/
sudo cp monitoring/node_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# Block port 9100 from the internet
sudo ufw deny 9100/tcp
```

Prometheus and Grafana are already in `docker-compose.yml` and will start with the stack.

Access Grafana through your domain. Add the Nginx location block:

```nginx
location /grafana/ {
    proxy_pass http://grafana:3000/;
    proxy_set_header Host $host;
}
```

Log in with `admin` and the password from `GRAFANA_PASSWORD` in your `.env`.

Import these dashboards (Dashboards > Import > enter the ID):
- `1860` — Node Exporter Full (host metrics)
- `893` — Docker containers
- `9628` — PostgreSQL

---

## Step 15 — Healthchecks

```bash
sudo apt install -y mailutils
sudo cp healthchecks/healthcheck.sh /opt/scripts/healthcheck.sh
sudo chmod +x /opt/scripts/healthcheck.sh
```

Edit the script: set `ALERT_EMAIL` and `DOMAIN`.

Set up the cron job:

```bash
sudo crontab -e
```

Add:

```
*/5 * * * * /opt/scripts/healthcheck.sh >> /var/log/healthcheck.log 2>&1
```

---

## Step 16 — npm hardening

In your Node.js project root:

```bash
cp sovereign-saas-stack/npm/.npmrc .npmrc
```

Run the first audit:

```bash
npm audit
```

Fix what can be fixed automatically:

```bash
npm audit fix
```

For remaining vulnerabilities, read each one and decide if it affects your use case. Not every vulnerability in a dev dependency is a real risk.

In production, always install from the lockfile:

```bash
npm ci
```

---

## Step 17 — logrotate

```bash
sudo cp /opt/myapp/logrotate/nginx-logrotate /etc/logrotate.d/nginx
sudo logrotate -d /etc/logrotate.d/nginx
```

---

## Maintenance

### Check container image updates

diun logs will tell you when a new image version is available:

```bash
docker compose logs diun
```

To update a specific service:

```bash
docker compose pull service-name
docker compose up -d service-name
```

### Renew OpenBao token

App tokens have a TTL (set to 720 hours in step 8). Rotate them before they expire:

```bash
docker compose exec openbao bao token renew
```

### Check backup integrity

```bash
restic -r /path/to/your/repo check
restic -r /path/to/your/repo snapshots
```

### Monitor disk usage

```bash
df -h
docker system df
```

Clean up unused Docker images periodically:

```bash
docker image prune -a
```

---

## Security checklist

Before going live:

- [ ] SSH: root login disabled, password auth disabled, custom port
- [ ] UFW: only ports 80, 443, and your SSH port are open
- [ ] PostgreSQL: not exposed on any public port
- [ ] Grafana: behind Nginx, not exposed directly on port 3000
- [ ] OpenBao: initialized in production mode, not dev mode
- [ ] ModSecurity: tested in detection mode before enabling blocking
- [ ] `.env` file: not committed to git
- [ ] Backups: tested and restorable (test the restore, not just the backup)
- [ ] age private key: stored offline
- [ ] Node Exporter: not exposed publicly (firewall rule or Nginx auth if needed)

---

## Author

Built and maintained by [Thomas Rayon](https://linkedin.com/in/thomas-rayon).

DevOps engineer in training. This stack is inspired by what runs in production on my own infrastructure.

Contributions, issues, and pull requests are welcome.
