# SSH Hardening

The first thing you do after provisioning a VPS: lock down SSH.
Default SSH configuration is wide open. This fixes that.

---

## What this covers

- Disable root login
- Disable password authentication (keys only)
- Change default port
- Restrict allowed users
- Limit authentication attempts
- Disable unused features

---

## Configuration

Replace your `/etc/ssh/sshd_config` with the following (adapt to your setup):

```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
LoginGraceTime 20
X11Forwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers yourusername
```

---

## Steps

1. Generate a key pair on your local machine if you don't have one:

```bash
ssh-keygen -t ed25519 -C "your@email.com"
```

2. Copy your public key to the server:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-server-ip
```

3. Test that key authentication works before disabling passwords:

```bash
ssh -i ~/.ssh/id_ed25519 user@your-server-ip
```

4. Apply the hardened config:

```bash
sudo cp sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd
```

5. Open the new SSH port in UFW before disconnecting (see `../ufw/`):

```bash
sudo ufw allow 2222/tcp
```

---

## Verify

```bash
# Should be rejected
ssh root@your-server-ip

# Should work
ssh -p 2222 -i ~/.ssh/id_ed25519 yourusername@your-server-ip
```
