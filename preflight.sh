#!/usr/bin/env bash
# preflight — сверка окружения с манифестом сборки. Только чтение, без сети.
# usage: bash preflight.sh [manifest]
set -u
MAN="${1:-.build-manifest}"
[ -f "$MAN" ] || { echo "preflight: манифест не найден: $MAN"; exit 2; }

want_py="$(awk -F= '/^python=/{print $2}' "$MAN")"
want_node="$(awk -F= '/^node=/{print $2}' "$MAN")"
fail=0

chk() { # name want got_minor
  if [ "$2" = "$3" ]; then echo "PASS $1 $3"; else echo "FAIL $1 want=$2 got=$3"; fail=1; fi
}

py="$(python3 -V 2>/dev/null | awk '{print $2}')"
node="$(node -v 2>/dev/null | tr -d v)"
chk python "$want_py" "$(printf '%s' "$py" | cut -d. -f1-2)"
chk node "$want_node" "$(printf '%s' "$node" | cut -d. -f1)"
echo "bash ${BASH_VERSION:-unknown}"
echo "os $(uname -s) $(uname -m)"
if [ "$fail" = 0 ]; then echo "preflight: OK"; else echo "preflight: MISMATCH"; fi
exit "$fail"
