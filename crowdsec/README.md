# CrowdSec

CrowdSec is a community-driven intrusion prevention system.
It does what fail2ban does, but smarter: it shares threat intelligence across all CrowdSec users.
When one server gets attacked by an IP, that IP gets added to a shared blocklist.

---

## How it works

1. CrowdSec agent reads your logs and detects attacks
2. Detected IPs are reported to the CrowdSec community hub
3. You receive the community blocklist in return
4. A bouncer (plugin) enforces the ban at the Nginx or firewall level

---

## Installation

```bash
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt install -y crowdsec
```

---

## Install the Nginx bouncer

```bash
sudo apt install -y crowdsec-nginx-bouncer
```

---

## Add log sources

Tell CrowdSec where your logs are:

```bash
sudo cscli collections install crowdsecurity/nginx
sudo cscli collections install crowdsecurity/linux
sudo systemctl restart crowdsec
```

---

## Check the community blocklist

```bash
# Enroll your instance (optional but recommended)
sudo cscli hub update

# See active decisions
sudo cscli decisions list

# See detected alerts
sudo cscli alerts list
```

---

## Coexistence with fail2ban

CrowdSec and fail2ban can run together:
- fail2ban handles your local rules (too many 4xx, SSH brute force on your own logs)
- CrowdSec adds the community blocklist and its own detection engine

They do not conflict as long as both are not managing the same iptables rules simultaneously. The CrowdSec bouncer handles its own iptables chains.

---

## Verify

```bash
sudo systemctl status crowdsec
sudo cscli metrics
```
