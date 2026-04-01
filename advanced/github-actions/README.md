# GitHub Actions — Continuous Deployment

GitHub Actions runs a workflow automatically every time you push code to your repository. For a SaaS, the typical use case is: push to `main` → deploy to production.

Without this, deploying means: SSH into the server, pull the new image, restart the container. With GitHub Actions, that happens automatically.

---

## When to use it

- You push new versions of your app regularly
- You want to stop doing manual deployments
- You want to add automated checks before deploying (tests, lint, security scan)

## When to skip it

- Your app does not change often
- You are not comfortable with the security implications yet (see below)

---

## How it works

GitHub Actions runs a YAML workflow file stored in `.github/workflows/`. When you push to `main`, GitHub runs the workflow on a runner (a temporary VM), which connects to your server and deploys.

```
git push main
     │
     ▼
GitHub Actions runner
     │
     ├── runs tests
     ├── builds Docker image
     ├── pushes image to registry
     │
     └──SSH──▶ your VPS
                  docker compose pull
                  docker compose up -d
```

---

## Security considerations

GitHub Actions needs SSH access to your server to deploy. This means storing your private SSH key as a GitHub secret. A few rules:

- Create a dedicated deployment key with minimal permissions (read-only access to the repo, write access to nothing else on the server)
- Use a dedicated deploy user on your server with limited sudo rights (only `docker compose` commands)
- Never use your personal SSH key as a deployment key
- Restrict the deploy user to run only the necessary commands via `sudoers`

---

## GitHub Secrets

Store sensitive values in your repository settings under **Settings > Secrets and variables > Actions**:

| Secret name | Value |
|---|---|
| `SSH_PRIVATE_KEY` | Your deployment private key |
| `SSH_HOST` | Your server IP |
| `SSH_USER` | Your deploy user (e.g. `deploy`) |
| `SSH_PORT` | Your SSH port (e.g. `2222`) |

---

## Example workflow

Create `.github/workflows/deploy.yml` in your app repository:

```yaml
name: Deploy to production

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Security audit
        run: npm audit --audit-level=high

      - name: Run tests
        run: npm ci && npm test

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          port: ${{ secrets.SSH_PORT }}
          script: |
            cd /opt/myapp
            docker compose pull app
            docker compose up -d app
            docker image prune -f
```

This workflow:
1. Runs on every push to `main`
2. Runs your test suite first — if tests fail, deployment is cancelled
3. SSHes into your server and updates only the `app` container

---

## Zero-downtime deployment

The basic workflow above has a brief downtime while the container restarts. For zero-downtime, use a rolling update strategy or a health check:

```yaml
script: |
  cd /opt/myapp
  docker compose pull app
  docker compose up -d --no-deps --wait app
  docker image prune -f
```

`--wait` tells Compose to wait until the container passes its health check before returning. Define a health check in your `docker-compose.yml`:

```yaml
app:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval: 10s
    timeout: 5s
    retries: 3
```

---

> **Security note:** For stronger supply chain security, pin GitHub Actions to a specific commit SHA rather than a version tag:
> `uses: appleboy/ssh-action@<commit-sha>  # v1.x.x`
> See [GitHub's security hardening guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions).

---

## Further reading

- [GitHub Actions documentation](https://docs.github.com/en/actions)
- [appleboy/ssh-action](https://github.com/appleboy/ssh-action)
