# fail2ban

fail2ban watches your log files and temporarily bans IPs that show malicious behavior: too many failed SSH logins, too many 4xx errors, brute force attempts.

---

## Installation

```bash
sudo apt update
sudo apt install -y fail2ban
```

---

## Configuration

Copy the default config to a local override (never edit the original):

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

The `jail.local` file in this folder is a ready-to-use configuration covering:
- SSH brute force
- Nginx 4xx flood
- Nginx authentication failures

---

## Apply config

```bash
sudo cp jail.local /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

---

## Verify

```bash
# Check active jails
sudo fail2ban-client status

# Check a specific jail
sudo fail2ban-client status sshd
sudo fail2ban-client status nginx-http-auth

# Unban an IP manually
sudo fail2ban-client set sshd unbanip 1.2.3.4
```

---

## Integration with Docker

Nginx runs in Docker. For fail2ban to read Nginx logs, the nginx service mounts
`/var/log/nginx` from the host into the container (configured in docker-compose.yml).
Make sure this directory exists on the host:

    sudo mkdir -p /var/log/nginx

fail2ban reads logs from `/var/log/nginx/error.log` and `/var/log/nginx/access.log`
on the host — the same files written by the Nginx container.

---

## Notes

- fail2ban and CrowdSec work well together. fail2ban handles local rules, CrowdSec adds community threat intelligence.
- Ban time is set to 1 hour. Adjust `bantime` in `jail.local` to be more aggressive (e.g. `24h`) if needed.
