# OpenBao - Secrets Management

**Production mode:** The configuration in this stack runs OpenBao in production mode with file storage. Data is persisted in the `openbao_data` Docker volume. After the first start, you must initialize and unseal OpenBao (see instructions below). In development mode (`BAO_DEV_ROOT_TOKEN_ID`), data is stored in memory only — never use dev mode in production.

OpenBao is an open source fork of HashiCorp Vault (before the license change).
It stores and manages your secrets: API keys, database passwords, tokens.

Instead of putting secrets in `.env` files or environment variables, your app fetches them from OpenBao at runtime. If your server is compromised, secrets are not sitting in plaintext on disk.

---

## Why OpenBao and not Vault

HashiCorp changed Vault's license to BUSL in 2023. OpenBao is the community-maintained, truly open source fork. Same API, same behavior.

---

## Run OpenBao in Docker

The OpenBao service is already configured in `docker-compose.yml` at the root of the repository. It uses the `config.hcl` file in this folder and runs in production mode with file storage.

---

## Initialize and unseal (production mode)

```bash
docker compose exec openbao bao operator init
docker compose exec openbao bao operator unseal
# Run the unseal command 3 times with 3 different unseal keys
```

Store your unseal keys and root token securely. Losing them means losing access to all secrets.

---

## Enable the KV secrets engine

```bash
# Enable the KV v2 secrets engine (required in production mode, auto-enabled in dev mode)
docker compose exec openbao bao secrets enable -path=secret kv-v2
```

---

## Store a secret

```bash
docker compose exec openbao bao kv put secret/myapp db_password="your-db-password" api_key="your-api-key"
```

---

## Read a secret from your Node.js app

```javascript
// Native fetch (Node.js 18+) — no external dependency needed
async function getSecret(path) {
  const response = await fetch(`http://openbao:8200/v1/${path}`, {
    headers: { 'X-Vault-Token': process.env.BAO_TOKEN }
  })
  if (!response.ok) throw new Error(`OpenBao error: ${response.status}`)
  const data = await response.json()
  return data.data.data
}

// Usage
const secrets = await getSecret('secret/data/myapp')
const dbPassword = secrets.db_password
```

---

## Verify

```bash
docker compose exec openbao bao status
docker compose exec openbao bao kv list secret/
```
