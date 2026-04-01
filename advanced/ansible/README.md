# Ansible — Automated server setup

Ansible lets you run all 17 steps of the tutorial automatically on any fresh Ubuntu server with a single command.

Instead of connecting to your server and running commands one by one, you write a playbook (a YAML file describing what to do) and Ansible executes it remotely over SSH.

---

## When to use it

- You manage more than one server
- You want to rebuild your server quickly after a failure
- You want a written, versioned record of exactly what is installed and configured

## When to skip it

- You have one server and you are doing this for the first time
- You want to understand what each step does before automating it

Automating something you do not understand yet is a bad idea. Do the tutorial manually first.

---

## How Ansible works

You run Ansible from your local machine (or a CI runner). It connects to your server over SSH and executes the tasks in your playbook. Nothing is installed on the server itself — only SSH access is required.

```
Your machine  ──SSH──▶  Your VPS
   ansible               runs tasks
```

---

## Install Ansible

On your local machine:

```bash
pip install ansible
```

Or on Ubuntu/Debian:

```bash
sudo apt install -y ansible
```

---

## Inventory file

The inventory file tells Ansible which servers to manage.

Create `inventory.ini`:

```ini
[vps]
your-server-ip ansible_user=thomas ansible_port=2222 ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

Test connectivity:

```bash
ansible -i inventory.ini vps -m ping
```

Expected output: `your-server-ip | SUCCESS`

---

## What a playbook looks like

A playbook is a list of tasks. Each task uses an Ansible module to do something on the remote server.

```yaml
- name: Install UFW
  hosts: vps
  become: true
  tasks:
    - name: Install ufw package
      apt:
        name: ufw
        state: present

    - name: Allow SSH port
      ufw:
        rule: allow
        port: "2222"
        proto: tcp

    - name: Enable UFW
      ufw:
        state: enabled
        policy: deny
```

This is the equivalent of:

```bash
sudo apt install -y ufw
sudo ufw allow 2222/tcp
sudo ufw enable
```

Except it is idempotent: you can run it 10 times and the result is always the same.

---

## Writing a playbook for this stack

To automate the full setup of this stack, you would write one playbook per module (or group related modules into roles). A complete playbook for this stack would cover:

1. System update and user creation
2. SSH hardening
3. UFW rules
4. Docker installation
5. Certbot and certificate issuance
6. Docker Compose deployment
7. fail2ban configuration
8. CrowdSec installation
9. Backup script and cron job
10. Node Exporter and logrotate

Each step maps directly to a section in `TUTORIAL.md`.

---

## Key Ansible modules for this stack

| Module | What it does |
|---|---|
| `apt` | Install packages |
| `copy` | Copy files to the server |
| `template` | Copy files with variable substitution |
| `ufw` | Manage firewall rules |
| `systemd` | Enable and start services |
| `cron` | Create cron jobs |
| `docker_compose_v2` | Deploy a Compose stack (requires `community.docker` collection: `ansible-galaxy collection install community.docker`) |
| `command` / `shell` | Run arbitrary commands (use sparingly) |

---

## Run a playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

With a vault-encrypted secrets file:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

---

## Ansible Vault

Never put passwords or tokens in plaintext in your playbooks. Use Ansible Vault to encrypt sensitive variables:

```bash
ansible-vault encrypt_string 'your-db-password' --name 'db_password'
```

Paste the output into your variables file. Ansible decrypts it at runtime.

---

## Further reading

- [Ansible documentation](https://docs.ansible.com/)
- [Ansible for DevOps (free book)](https://www.ansiblefordevops.com/)
