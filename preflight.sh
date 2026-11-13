#!/usr/bin/env bash
# preflight — сверка окружения с манифестом сборки. Только чтение, без сети.
# usage: bash preflight.sh [manifest]
# коды: 0 совпало, 1 расхождение, 2 ошибка манифеста
set -u
MAN="${1:-.build-manifest}"
[ -e "$MAN" ] || { echo "preflight: манифест не найден: $MAN"; exit 2; }
[ -r "$MAN" ] || { echo "preflight: манифест не читается: $MAN"; exit 2; }

# нормализация: срезать комментарии и хвостовые пробелы, выкинуть пустые строки,
# последняя строка без перевода строки обрабатывается так же, как с ним
norm="$(awk '{sub(/#.*/,""); sub(/[ \t]+$/,""); if ($0!="") print}' "$MAN")"
[ -n "$norm" ] || { echo "preflight: пустой манифест: $MAN"; exit 2; }

while IFS= read -r line; do
  key="${line%%=*}"; val="${line#*=}"
  case "$key" in
    python|node) ;;
    *) echo "preflight: неизвестный ключ: $(printf '%s' "$key" | cut -c1-24)"; exit 2 ;;
  esac
  case "$val" in
    ''|*[!0-9.]*) echo "preflight: битое значение: $key=$(printf '%s' "$val" | cut -c1-24)"; exit 2 ;;
  esac
  if [ "${#val}" -gt 16 ]; then echo "preflight: длинное значение: $key=$(printf '%s' "$val" | cut -c1-16)..."; exit 2; fi
done <<EOF
$norm
EOF

dup="$(printf '%s\n' "$norm" | cut -d= -f1 | sort | uniq -d | tr '\n' ' ')"
[ -z "$dup" ] || { echo "preflight: дубли ключей: $dup"; exit 2; }

want_py="$(printf '%s\n' "$norm" | awk -F= '$1=="python"{print $2}')"
want_node="$(printf '%s\n' "$norm" | awk -F= '$1=="node"{print $2}')"
[ -n "$want_py" ] || { echo "preflight: пустой python в манифесте"; exit 2; }
[ -n "$want_node" ] || { echo "preflight: пустой node в манифесте"; exit 2; }

fail=0
chk() { # name want got
  if [ -z "$3" ]; then echo "FAIL $1 want=$2 got=missing"; fail=1
  elif [ "$2" = "$3" ]; then echo "PASS $1 $3"
  else echo "FAIL $1 want=$2 got=$3"; fail=1; fi
}

# версии: доверяем только нулевому коду возврата
py_raw="$(python3 -V 2>&1)"; py_rc=$?
node_raw="$(node -v 2>&1)"; node_rc=$?
py_minor="$([ "$py_rc" = 0 ] && printf '%s' "$py_raw" | awk '{print $2}' | cut -d. -f1-2 || echo error)"
node_major="$([ "$node_rc" = 0 ] && printf '%s' "$node_raw" | tr -d v | cut -d. -f1 || echo error)"
chk python "$want_py" "$py_minor"
chk node "$want_node" "$node_major"
echo "bash ${BASH_VERSION:-unknown}"
echo "os $(uname -s) $(uname -m)"
if [ "$fail" = 0 ]; then echo "preflight: OK"; else echo "preflight: MISMATCH"; fi
exit "$fail"
