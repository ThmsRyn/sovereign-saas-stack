# Nginx

Nginx acts as the reverse proxy: it receives all incoming traffic and forwards it to your app container.
It also handles TLS termination, HTTP to HTTPS redirect, and security headers.

---

## Installation (standalone, not in Docker)

For this stack, Nginx runs in Docker. See `../docker/docker-compose.yml`.

If you prefer to install it on the host:

```bash
sudo apt update
sudo apt install -y nginx
```

---

## Configuration files

- `nginx.conf` - global settings
- `conf.d/app.conf` - your app virtual host

---

## Security headers

The following headers are set in `conf.d/app.conf`:

- `Strict-Transport-Security` - forces HTTPS
- `X-Frame-Options` - prevents clickjacking
- `X-Content-Type-Options` - prevents MIME sniffing
- `Referrer-Policy` - limits referrer information
- `Content-Security-Policy` - restricts resource loading
- `Permissions-Policy` - disables unused browser features

---

## Rate limiting

The config includes rate limiting to slow down brute force and DDoS attempts:

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

Adjust `rate` and `burst` to your traffic profile.

---

## Verify

```bash
docker compose exec nginx nginx -t
docker compose logs nginx
```
