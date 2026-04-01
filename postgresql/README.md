# PostgreSQL

PostgreSQL runs inside Docker. It is never exposed to the internet.
Only your app container can reach it, over the internal Docker network.

---

## Configuration

The database is defined in `../docker/docker-compose.yml`. This stack uses **PostgreSQL 17** (17.9), the most battle-tested current major version. PostgreSQL 18 is available but still young for production.

Key points:
- No port mapping to the host (no `ports:` directive)
- Credentials passed via environment variables (set in `.env`, never committed)
- Data persisted in a named Docker volume

---

## .env file

Create a `.env` file at the root of your project (never commit it):

```
DB_PASSWORD=a-long-random-password
```

Generate a strong password:

```bash
openssl rand -base64 32
```

---

## Hardening

1. Use a dedicated user with limited privileges, not the superuser:

```sql
CREATE USER appuser WITH PASSWORD 'your-password';
CREATE DATABASE appdb OWNER appuser;
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
```

2. Revoke public schema access:

```sql
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO appuser;
```

3. Never use the `postgres` superuser in your application.

---

## Backups

See `../backups/` for automated encrypted backup scripts.

---

## Access the database

```bash
docker compose exec postgres psql -U appuser -d appdb
```

---

## Verify

```bash
docker compose logs postgres
docker compose exec postgres pg_isready -U appuser -d appdb
```
