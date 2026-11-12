#!/usr/bin/env bash
# preflight — сверка окружения с манифестом сборки. Только чтение, без сети.
# usage: bash preflight.sh [manifest]
# коды: 0 совпало, 1 расхождение, 2 ошибка манифеста
set -u
MAN="${1:-.build-manifest}"
[ -e "$MAN" ] || { echo "preflight: манифест не найден: $MAN"; exit 2; }
[ -r "$MAN" ] || { echo "preflight: манифест не читается: $MAN"; exit 2; }

# манифест: только ключи python/node, без дублей и пустых значений
bad="$(printf '%s\n' "$(cat "$MAN")" | awk -F= 'NF && $1!="python" && $1!="node"')"
[ -z "$bad" ] || { echo "preflight: неизвестные ключи: $(printf '%s' "$bad" | tr '\n' ' ')"; exit 2; }
dup="$(printf '%s\n' "$(cat "$MAN")" | awk -F= 'NF{print $1}' | sort | uniq -d | tr '\n' ' ')"
[ -z "$dup" ] || { echo "preflight: дубли ключей: $dup"; exit 2; }

want_py="$(awk -F= '$1=="python"{print $2}' "$MAN")"
want_node="$(awk -F= '$1=="node"{print $2}' "$MAN")"
[ -n "$want_py" ] || { echo "preflight: пустой python в манифесте"; exit 2; }
[ -n "$want_node" ] || { echo "preflight: пустой node в манифесте"; exit 2; }

fail=0
chk() { # name want got
  if [ -z "$3" ]; then echo "FAIL $1 want=$2 got=missing"; fail=1
  elif [ "$2" = "$3" ]; then echo "PASS $1 $3"
  else echo "FAIL $1 want=$2 got=$3"; fail=1; fi
}

py="$(python3 -V 2>/dev/null | awk '{print $2}')"
node="$(node -v 2>/dev/null | tr -d v)"
chk python "$want_py" "$(printf '%s' "$py" | cut -d. -f1-2)"
chk node "$want_node" "$(printf '%s' "$node" | cut -d. -f1)"
echo "bash ${BASH_VERSION:-unknown}"
echo "os $(uname -s) $(uname -m)"
if [ "$fail" = 0 ]; then echo "preflight: OK"; else echo "preflight: MISMATCH"; fi
exit "$fail"
