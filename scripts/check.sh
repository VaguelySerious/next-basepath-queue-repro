#!/usr/bin/env bash
# Usage: scripts/check.sh <deployment-url> [--scope <team>]
# Enqueues one job, waits for the queue-triggered consumer, and reports
# whether it ran. Uses `vercel curl` so Deployment Protection is handled.
set -euo pipefail
url=${1:?deployment url}
shift
ids=$(vercel curl /docs/api/send --deployment "$url" "$@" -- -s -X POST)
echo "sent:     $ids"
for _ in $(seq 1 12); do
  sleep 5
  result=$(vercel curl /docs/api/result --deployment "$url" "$@" -- -s)
  if [[ $result == *'"ok":true'* ]]; then
    echo "consumed: $result"
    echo "PASS: the queue consumer ran"
    exit 0
  fi
done
echo "FAIL: nothing consumed after 60s. Runtime logs for the consumer:"
vercel logs "$url" "$@" --since 5m --no-follow 2>/dev/null | grep -a -A2 '/docs/api/consume' || true
exit 1
