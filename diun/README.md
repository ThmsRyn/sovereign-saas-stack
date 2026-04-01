# diun - Docker Image Update Notifier

diun watches your running containers and notifies you when a new image version is available on the registry.

> **Note:** Watchtower (containrrr/watchtower) was archived in December 2025 and is broken with Docker 29.x. This stack uses diun as a replacement.

---

## Difference with Watchtower

Watchtower pulled and restarted containers automatically. diun notifies you instead and lets you decide when to update. This is safer in production: you review what changed before applying it.

---

## Add to docker-compose.yml

Already included in `../docker/docker-compose.yml`. The relevant service:

```yaml
diun:
  image: crazymax/diun:4.28.0
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - diun_data:/data
  environment:
    - DIUN_WATCH_SCHEDULE=0 0 4 * * *
    - DIUN_PROVIDERS_DOCKER=true
```

---

## Notifications

diun supports email, Slack, Telegram, Gotify, and more. Add environment variables to configure your preferred channel. Example for email:

```yaml
environment:
  - DIUN_NOTIF_MAIL_HOST=smtp.yourdomain.com
  - DIUN_NOTIF_MAIL_PORT=587
  - DIUN_NOTIF_MAIL_USERNAME=${SMTP_USER}
  - DIUN_NOTIF_MAIL_PASSWORD=${SMTP_PASSWORD}
  - DIUN_NOTIF_MAIL_FROM=diun@yourdomain.com
  - DIUN_NOTIF_MAIL_TO=you@youremail.com
```

---

## Update a container manually

When diun notifies you that a new image is available:

```bash
docker compose pull app
docker compose up -d app
```

---

## Verify

```bash
docker compose logs diun
```
