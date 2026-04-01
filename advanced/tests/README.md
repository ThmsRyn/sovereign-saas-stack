# Infrastructure Tests

Tests verify that your stack is correctly deployed and working. Not that it will work — that it works right now.

This module provides ready-to-use tests with `goss`, a tool designed for infrastructure testing. It also explains how to write your own.

---

## Why test your infrastructure

You finish the tutorial. Everything looks fine. Two weeks later you update a package and something silently breaks. Without tests, you find out when a user reports it. With tests, you find out in 30 seconds.

Infrastructure tests answer: is everything that should be running, actually running?

---

## The tool: goss

`goss` is a YAML-based tool for validating server state. You describe what should be true (this port is open, this service is running, this file exists) and goss checks it.

It is simpler than testinfra (Python), faster than Ansible ad-hoc commands, and requires no external dependencies.

---

## Install goss

```bash
curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 -o /usr/local/bin/goss
chmod +x /usr/local/bin/goss
```

---

## Run the default tests

```bash
goss -g advanced/tests/goss.yaml validate
```

Expected output:

```
..............

Total Duration: 0.512s
Count: 14, Failed: 0, Skipped: 0
```

If a test fails, goss tells you exactly which check failed and why.

---

## Default test file

See `goss.yaml` in this folder. It covers the base stack:

- SSH is listening on port 2222
- UFW is active
- Docker is running
- Nginx container is running and responding on port 443
- PostgreSQL container is running
- Prometheus is running
- Grafana is running
- Ports 80 and 443 are reachable
- Port 5432 (PostgreSQL) is NOT reachable from outside
- Port 3000 (Grafana) is NOT reachable from outside
- Disk usage is below 85%
- The backup log exists and was modified in the last 25 hours

---

## How to write your own tests

A goss test file is a YAML file. Each key is a resource type, each entry is a check.

### Check that a service is running

```yaml
service:
  docker:
    enabled: true
    running: true
  fail2ban:
    enabled: true
    running: true
```

### Check that a port is listening

```yaml
port:
  tcp:2222:
    listening: true
    ip: ["0.0.0.0"]
  tcp:5432:
    listening: false  # should NOT be exposed
```

### Check that a file exists and has the right content

```yaml
file:
  /etc/fail2ban/jail.local:
    exists: true
    contains:
      - "bantime = 1h"
  /opt/myapp/.env:
    exists: true
    mode: "0600"  # only owner can read it
```

### Check that a command returns the expected output

```yaml
command:
  "docker compose -f /opt/myapp/docker-compose.yml ps --format json":
    exit-status: 0
    stdout:
      - "running"
  "curl -s -o /dev/null -w '%{http_code}' https://yourdomain.com":
    exit-status: 0
    stdout:
      - "200"
```

### Check that a process is running

```yaml
process:
  node_exporter:
    running: true
  crowdsec:
    running: true
```

### Check disk and memory

```yaml
command:
  "df / --output=pcent | tail -1 | tr -d ' %'":
    exit-status: 0
    # Custom check: combine with a shell condition if needed
```

---

## Running tests automatically

Add tests to your cron or your GitHub Actions workflow:

```yaml
- name: Run infrastructure tests
  uses: appleboy/ssh-action@v1.0.3
  with:
    script: goss -g /opt/myapp/advanced/tests/goss.yaml validate
```

If any test fails, the deployment step is not reached.

---

## Adding tests progressively

Start with the defaults. Each time you add a new component to your stack, add a test for it. Good habits:

- Every open port should have a test that it is open
- Every port that should NOT be open should have a test that it is closed
- Every critical service should have a running check
- Every backup should have a freshness check

---

## Further reading

- [goss documentation](https://github.com/goss-org/goss)
- [goss syntax reference](https://github.com/goss-org/goss/blob/master/docs/manual.md)
