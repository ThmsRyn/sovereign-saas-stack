# Advanced — Going further

This folder covers optional tools that automate or extend the base stack.

None of this is required to run a sovereign SaaS in production. The base stack in the root of this repo is already complete and production-ready without any of the tools below.

These modules are for people who want to go further: automate the setup, enforce infrastructure as code, or validate their deployment automatically.

---

## Modules

| Module | What it does | When to use it |
|---|---|---|
| [ansible/](./ansible/) | Automates the full server setup with one command | When you manage multiple servers or want a reproducible setup |
| [github-actions/](./github-actions/) | Deploys your app automatically on every push | When you want continuous deployment |
| [terraform/](./terraform/) | Provisions your VPS with code | When you want to create and destroy infrastructure programmatically |
| [tests/](./tests/) | Validates that your stack is correctly deployed | Always — even on a single server |

---

## Do I need this?

**You are deploying on a single VPS for the first time:** skip everything here. Follow the main `TUTORIAL.md`. Come back when the base stack is running.

**You manage more than one server:** Ansible will save you hours. A playbook runs all 17 tutorial steps automatically on any server.

**You push code frequently:** GitHub Actions will deploy for you. No more manual SSH sessions to pull and restart containers.

**You want to prove your infrastructure works:** add the tests. They run in 30 seconds and tell you immediately if something is broken.

**You want to spin up and tear down infrastructure on demand:** Terraform. Useful for staging environments or if you switch providers.
