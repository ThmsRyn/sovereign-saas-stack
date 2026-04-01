# Monitoring - Prometheus + Grafana

Prometheus scrapes metrics from your services. Grafana displays them in dashboards.
Together they give you visibility on what your stack is doing in real time.

---

## Architecture

- Prometheus runs in Docker on the internal network
- Grafana runs in Docker, proxied through Nginx (never exposed directly)
- Node Exporter runs on the host to expose system metrics (CPU, RAM, disk, network)

---

## Node Exporter (host metrics)

Install on the host:

```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz
tar xvf node_exporter-1.10.2.linux-amd64.tar.gz
sudo mv node_exporter-1.10.2.linux-amd64/node_exporter /usr/local/bin/
```

Create a dedicated user for node_exporter:

```bash
# Create a dedicated user for node_exporter
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

Create a systemd service:

```bash
sudo cp node_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

---

## Prometheus config

See `prometheus.yml`. It scrapes:
- Node Exporter (host metrics)
- cAdvisor (container metrics)
- PostgreSQL Exporter
- Your app (if you expose a `/metrics` endpoint)

---

## Grafana

Access Grafana through your domain at `/grafana` (configure the Nginx location block).

Default login: `admin` / password set in `GRAFANA_PASSWORD` env var.

Recommended dashboards to import (use the dashboard ID in Grafana's import UI):
- Node Exporter Full: `1860`
- Docker containers: `893`
- PostgreSQL: `9628`

---

## Expose /metrics in your Node.js app

```bash
npm install prom-client
```

```javascript
const promClient = require('prom-client')
const register = promClient.register
promClient.collectDefaultMetrics()

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType)
  res.end(await register.metrics())
})
```

Restrict the `/metrics` endpoint to localhost or the internal Docker network only.

---

## Verify

```bash
# Prometheus
curl http://localhost:9090/api/v1/targets

# Grafana
curl -I https://yourdomain.com/grafana
```
