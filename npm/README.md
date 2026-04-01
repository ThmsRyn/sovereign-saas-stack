# npm Security

Node.js dependency chains are a major attack surface. This module covers how to lock them down.

---

## .npmrc

The `.npmrc` file controls npm's behavior. A hardened config prevents common supply chain risks.

See `.npmrc` in this folder. Copy it to your project root.

Key settings:
- `audit=true` - run `npm audit` on every install
- `fund=false` - disable funding prompts (noise reduction)
- `save-exact=true` - pin exact versions instead of ranges
- `package-lock=true` - always generate and commit the lockfile
- `ignore-scripts=false` - keep this off; set to `true` only if you know what you're doing

---

## npm audit

Run after every install and in your deployment process:

```bash
npm audit
npm audit --audit-level=high  # fail only on high/critical
```

Fix automatically where possible:

```bash
npm audit fix
```

For vulnerabilities with no automatic fix, review them manually and decide if they affect your use case.

---

## Lockfile

Always commit `package-lock.json`. It pins the exact version of every dependency and sub-dependency.

In production, install from the lockfile only:

```bash
npm ci
```

Never use `npm install` in production. `npm ci` is faster, stricter, and reproducible.

---

## Check for outdated packages

```bash
npm outdated
```

Update regularly. Outdated packages are often vulnerable packages.

---

## Minimal dependencies

Every dependency you add is a potential vulnerability. Ask before adding:
- Do I really need this package?
- Is it actively maintained?
- How many dependencies does it bring?

Check a package's dependency tree:

```bash
npm ls
```
