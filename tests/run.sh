#!/usr/bin/env bash
# self-check: подставной манифест с текущими версиями должен дать PASS/0
set -u
cd "$(dirname "$0")/.."
py="$(python3 -V 2>/dev/null | awk '{print $2}' | cut -d. -f1-2)"
node="$(node -v 2>/dev/null | tr -d v | cut -d. -f1)"
printf 'python=%s\nnode=%s\n' "$py" "$node" > /tmp/pf-test-manifest
out="$(bash preflight.sh /tmp/pf-test-manifest)"; rc=$?
echo "$out"
[ "$rc" = 0 ] || { echo "FAIL: ожидался rc=0"; exit 1; }
out2="$(bash preflight.sh /nonexistent)"; rc2=$?
[ "$rc2" = 2 ] || { echo "FAIL: ожидался rc=2 без манифеста"; exit 1; }
echo "tests: OK"
