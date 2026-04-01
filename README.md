# sovereign-saas-stack

A self-hosted, production-ready SaaS infrastructure stack.
No Vercel. No AWS. No managed secrets. You own everything.

Built for developers who already know their way around a Linux VM and want to ship a real SaaS without depending on third-party platforms.

---

## Philosophy

Most "deploy your SaaS" guides end with you locked into a cloud provider, paying per secret, per log line, per deployment minute. This stack is different. Every component runs on your own VPS, is open source, and is replaceable.

Sovereignty means: if a provider disappears tomorrow, your SaaS keeps running.

---

## Stack

| Layer | Tool |
|---|---|
| Reverse proxy | Nginx |
| Containers | Docker + Docker Compose |
| Secrets management | OpenBao |
| WAF | ModSecurity (Nginx module) |
| Intrusion prevention | fail2ban + CrowdSec |
| TLS certificates | Certbot (Let's Encrypt) |
| Database | PostgreSQL |
| Firewall | UFW |
| SSH hardening | OpenSSH configuration |
| Encrypted backups | restic + age |
| Container updates | diun |
| Log management | logrotate |
| Health monitoring | custom healthcheck scripts |
| Metrics | Prometheus + Grafana |
| Node.js security | npm audit + hardened .npmrc |

---

## Prerequisites

- A VPS running Ubuntu 22.04 or 24.04 (any provider)
- A domain name pointing to your server
- Basic Linux knowledge (you can navigate the filesystem, edit files, run commands)

---

## Structure

```
sovereign-saas-stack/
├── nginx/          # Reverse proxy config + SSL
├── docker/         # Docker Compose base + best practices
├── openbao/        # Secrets management setup
├── modsecurity/    # WAF rules and configuration
├── fail2ban/       # Intrusion prevention jails
├── crowdsec/       # Community threat intelligence
├── certbot/        # TLS certificate automation
├── postgresql/     # Database hardening
├── ufw/            # Firewall rules
├── ssh/            # SSH hardening
├── backups/        # Encrypted backup scripts
├── diun/           # Container image update notifications
├── logrotate/      # Log rotation config
├── healthchecks/   # Service health monitoring
├── monitoring/     # Prometheus + Grafana stack
└── npm/            # Node.js dependency security
```

---

## Getting started

**Read [TUTORIAL.md](./TUTORIAL.md) first.** It walks you through the full setup from a blank VPS to a running production stack, step by step. It also covers known issues and common pitfalls for each component.

Each folder also contains its own `README.md` with:
- What the tool does and why it is in this stack
- Configuration files ready to use or adapt
- How to verify it works

Recommended order:

1. SSH hardening
2. UFW
3. Docker
4. Nginx + Certbot
5. PostgreSQL
6. OpenBao
7. ModSecurity
8. fail2ban + CrowdSec
9. Backups
10. diun + logrotate
11. Healthchecks
12. Monitoring (Prometheus + Grafana)
13. npm hardening

---

## Going further

The `advanced/` folder covers optional tools for people who want to automate or extend the base stack:

| Module | What it does |
|---|---|
| [advanced/ansible/](./advanced/ansible/) | Automates the full setup with one command |
| [advanced/github-actions/](./advanced/github-actions/) | Deploys automatically on every push |
| [advanced/terraform/](./advanced/terraform/) | Provisions your VPS with code |
| [advanced/tests/](./advanced/tests/) | Validates that your stack works with `goss` |

None of this is required. The base stack is complete without it.

---

## Node.js

This stack is built around Node.js applications. A Python equivalent is planned.

---

## Author

Built and maintained by [Thomas Rayon](https://linkedin.com/in/thomas-rayon).

DevOps engineer in training. This stack is inspired by what runs in production on my own infrastructure.

Contributions, issues, and pull requests are welcome.

---

## License

MIT — see [LICENSE](./LICENSE)
