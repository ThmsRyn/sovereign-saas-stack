# logrotate

logrotate prevents your log files from filling up the disk.
It compresses, rotates, and deletes old log files automatically.

---

## Installation

logrotate is installed by default on Ubuntu. Check:

```bash
which logrotate
logrotate --version
```

---

## Nginx logs

Create `/etc/logrotate.d/nginx`:

```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

---

## Application logs

If your Node.js app writes to a log file, add a config for it:

```
/var/log/myapp/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
```

---

## Apply config

```bash
sudo cp nginx-logrotate /etc/logrotate.d/nginx
sudo logrotate -d /etc/logrotate.d/nginx  # dry run
sudo logrotate -f /etc/logrotate.d/nginx  # force run
```

---

## Verify

```bash
sudo logrotate -v /etc/logrotate.conf
ls -lh /var/log/nginx/
```
