# Certbot - TLS Certificates

Certbot automates obtaining and renewing TLS certificates from Let's Encrypt.
Free, automatic, trusted by all browsers.

---

## Installation

```bash
sudo apt update
sudo apt install -y certbot
```

---

## Obtain a certificate

Make sure your domain points to your server and that port 80 is open. Run this before starting Nginx:

```bash
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

> Note: This stack uses `--standalone` mode to obtain certificates before starting Nginx.
> Do not use `--nginx` mode as it will modify your Nginx config automatically, conflicting with this stack's manual configuration.

---

## Test auto-renewal

Certificates expire after 90 days. Certbot installs a systemd timer or cron job to renew automatically.

```bash
sudo certbot renew --dry-run
```

---

## Check renewal timer

```bash
systemctl status certbot.timer
```

---

## Manual renewal

```bash
sudo certbot renew
```

After renewal, Nginx is reloaded automatically via the deploy hook configured in TUTORIAL.md step 6.

---

## Verify

```bash
# Check certificate expiry
sudo certbot certificates

# Test HTTPS
curl -I https://yourdomain.com
```
