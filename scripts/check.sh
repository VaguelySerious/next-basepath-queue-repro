#!/usr/bin/env bash
# Usage: scripts/check.sh <deployment-url> [--scope <team>]
# Enqueues one job, waits for the queue-triggered consumer, and reports
# whether it ran. Uses `vercel curl` so Deployment Protection is handled.
# Exits 0 on PASS, 1 on FAIL, 2 if the deployment can't be reached.
set -euo pipefail
url=${1:?deployment url}
shift

call() {
  local path=$1 method=$2
  shift 2
  vercel curl "$path" --deployment "$url" "$@" -- -s -X "$method" 2>/dev/null || true
}

# The first `vercel curl` against a protected deployment creates a bypass
# token, which takes a few seconds to take effect, so retry until the send
# route answers with JSON.
sent=''
for _ in $(seq 1 10); do
  sent=$(call /docs/api/send POST "$@")
  [[ $sent == '{"id":'* ]] && break
  sleep 3
done
if [[ $sent != '{"id":'* ]]; then
  echo "Could not reach POST /docs/api/send. Last response:"
  echo "$sent" | head -5
  exit 2
fi
echo "sent:     $sent"
id=$(sed -E 's/.*"id":"([^"]+)".*/\1/' <<<"$sent")

for _ in $(seq 1 12); do
  sleep 5
  result=$(call /docs/api/result GET "$@")
  if [[ $result == *"$id"* ]]; then
    echo "consumed: $result"
    echo "PASS: the queue consumer ran"
    exit 0
  fi
done

echo "FAIL: job $id not consumed after 60s. Runtime logs for the consumer:"
vercel logs "$url" "$@" --since 10m --no-follow --json 2>/dev/null | node -e '
  let found = false;
  for (const line of require("fs").readFileSync(0, "utf8").split("\n")) {
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    if (entry.requestPath !== "/docs/api/consume") continue;
    found = true;
    const message = (entry.message || "").split("\n").slice(0, 2).join(" | ");
    console.log(`  ${entry.requestMethod} ${entry.requestPath} ${entry.responseStatusCode} ${message}`);
  }
  if (!found) console.log("  (no consumer log lines found)");
'
exit 1
