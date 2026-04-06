#!/usr/bin/env bash
# healthcheck.sh - checks containers, HTTP, database, and disk usage

set -euo pipefail

ALERT_EMAIL="${ALERT_EMAIL:-}"
DOMAIN="${DOMAIN:-yourdomain.com}"
COMPOSE_DIR="${COMPOSE_DIR:-/opt/myapp}"
DISK_THRESHOLD=85
ERRORS=()
SEND_MAIL=true

usage() {
  cat <<'EOF'
Usage:
  ./healthcheck.sh [--domain example.com] [--compose-dir /opt/app]
                   [--alert-email ops@example.com] [--disk-threshold 85]
                   [--no-mail]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      DOMAIN="${2:?--domain requires a value}"
      shift 2
      ;;
    --compose-dir)
      COMPOSE_DIR="${2:?--compose-dir requires a value}"
      shift 2
      ;;
    --alert-email)
      ALERT_EMAIL="${2:?--alert-email requires a value}"
      shift 2
      ;;
    --disk-threshold)
      DISK_THRESHOLD="${2:?--disk-threshold requires a value}"
      shift 2
      ;;
    --no-mail)
      SEND_MAIL=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# 1. Check Docker containers
CONTAINERS=("app" "postgres" "nginx" "prometheus" "grafana")
for container in "${CONTAINERS[@]}"; do
  if ! docker compose -f "$COMPOSE_DIR/docker-compose.yml" ps --status running "$container" 2>/dev/null | grep -q "$container"; then
    ERRORS+=("Container $container is not running")
  fi
done

# 2. Check HTTPS response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN" || echo "000")
if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "301" ] && [ "$HTTP_CODE" != "302" ]; then
  ERRORS+=("HTTPS check failed: got HTTP $HTTP_CODE for https://$DOMAIN")
fi

# 3. Check PostgreSQL
PG_CHECK=$(docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -T postgres pg_isready -U postgres -d appdb 2>&1 || echo "failed")
if echo "$PG_CHECK" | grep -q "failed\|no response"; then
  ERRORS+=("PostgreSQL is not accepting connections")
fi

# 4. Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
  ERRORS+=("Disk usage is at ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)")
fi

# 5. Report
if [ ${#ERRORS[@]} -gt 0 ]; then
  MESSAGE="[$(date)] Healthcheck FAILED on $DOMAIN:\n"
  for error in "${ERRORS[@]}"; do
    MESSAGE+="- $error\n"
  done
  echo -e "$MESSAGE"
  if [[ "$SEND_MAIL" == true && -n "$ALERT_EMAIL" ]] && command -v mail >/dev/null 2>&1; then
    echo -e "$MESSAGE" | mail -s "[ALERT] $DOMAIN healthcheck failed" "$ALERT_EMAIL"
  fi
else
  echo "[$(date)] All checks passed."
fi
