# UFW - Firewall

UFW (Uncomplicated Firewall) is a frontend for iptables.
Default policy: deny everything, allow only what you need.

---

## Base rules

```bash
# Reset to defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (use your custom port if you changed it)
sudo ufw allow 2222/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable
sudo ufw enable
```

---

## Verify

```bash
sudo ufw status verbose
```

Expected output:

```
Status: active

To                         Action      From
--                         ------      ----
2222/tcp                   ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
```

---

## Notes

- Never enable UFW before allowing your SSH port. You will lock yourself out.
- PostgreSQL (port 5432) should NOT be open to the internet. Access it only from localhost or through a private network interface.
- Grafana (port 3000) should be proxied through Nginx, not exposed directly.
