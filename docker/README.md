# Docker

Docker lets you run your application and its dependencies in isolated containers.
This module covers installation, best practices, and a base Compose structure.

---

## Installation

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

## Add your user to the docker group

```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

## Base docker-compose.yml

The `docker-compose.yml` file is located at the **root of the repository**, not in this `docker/` folder. Run all Compose commands from the repository root:

```bash
cd /opt/myapp
docker compose up -d
```

The root `docker-compose.yml` includes:

- A Node.js app service
- PostgreSQL
- Nginx
- Prometheus + Grafana
- OpenBao

All services communicate over a private internal network. Only Nginx is exposed to the host.

---

## Security best practices

- Never run containers as root. Use `user: "1000:1000"` or create a dedicated user.
- Always pin image versions. Never use `latest` in production.
- Use Docker secrets or OpenBao for sensitive environment variables. Never hardcode them.
- Limit container capabilities with `cap_drop: [ALL]` and add back only what is needed.
- Set `read_only: true` on containers that don't need to write to their filesystem.
- Use `--no-new-privileges` (via `security_opt: no-new-privileges:true`).

---

## Verify

```bash
docker compose ps
docker compose logs -f
```
