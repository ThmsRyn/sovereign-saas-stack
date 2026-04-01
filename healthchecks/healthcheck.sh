#!/bin/bash
# Basic healthcheck script
# Checks containers, HTTP, database, and disk usage

set -uo pipefail

ALERT_EMAIL="you@youremail.com"
DOMAIN="yourdomain.com"
COMPOSE_DIR="/opt/myapp"
DISK_THRESHOLD=85
ERRORS=()

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
  echo -e "$MESSAGE" | mail -s "[ALERT] $DOMAIN healthcheck failed" "$ALERT_EMAIL"
else
  echo "[$(date)] All checks passed."
fi
