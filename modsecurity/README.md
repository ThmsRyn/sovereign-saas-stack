# ModSecurity - Web Application Firewall

> **Activation:** To activate ModSecurity, replace the `nginx` service image in `docker-compose.yml` with the ModSecurity image below, and add the modsecurity volume mount.

ModSecurity is a WAF (Web Application Firewall). It inspects HTTP requests and blocks known attack patterns: SQL injection, XSS, path traversal, and more.

It runs as an Nginx module, sitting between the internet and your app.

---

## Why a WAF

Your app code may have vulnerabilities. ModSecurity adds a layer that blocks common attack patterns before they even reach your application.

---

## Installation with Nginx

ModSecurity with Nginx requires the `modsecurity-nginx` connector. The easiest way is to use a pre-built image:

Replace the Nginx image in your `docker-compose.yml`:

```yaml
nginx:
  image: owasp/modsecurity-crs:4-nginx-202602250702
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    - ./nginx/conf.d:/etc/nginx/conf.d:ro
    - /etc/letsencrypt:/etc/letsencrypt:ro
    - /var/log/nginx:/var/log/nginx
    - ./modsecurity/modsecurity-override.conf:/etc/modsecurity.d/modsecurity-override.conf:ro
  environment:
    - MODSEC_RULE_ENGINE=On
    - BLOCKING_PARANOIA=1
  networks:
    - app_network
```

---

## OWASP Core Rule Set

The `owasp/modsecurity-crs` image includes the OWASP Core Rule Set (CRS), a set of generic rules maintained by the security community.

Paranoia level 1 (default) blocks obvious attacks with very few false positives.
Paranoia level 2-4 adds more rules but may block legitimate traffic. Start at 1.

---

## Override config

The `modsecurity-override.conf` file lets you:
- Switch between Detection and Blocking mode
- Whitelist false positives
- Tune rules for your specific app

---

## Detection vs Blocking mode

Start in detection mode (`SecRuleEngine DetectionOnly`) to see what would be blocked without actually blocking it. Check logs, tune rules, then switch to `On`.

---

## Verify

```bash
docker compose logs nginx | grep -i modsecurity

# Test a basic SQL injection attempt (should be blocked)
curl -I "https://yourdomain.com/?id=1' OR '1'='1"
```
