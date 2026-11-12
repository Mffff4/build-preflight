#!/usr/bin/env bash
# self-check. прогонять интерпретатором, который проверяем: bash tests/run.sh
set -u
cd "$(dirname "$0")/.."
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
say="$(bash -c 'echo ${BASH_VERSION}')"
echo "bash $say"

py="$(python3 -V 2>/dev/null | awk '{print $2}' | cut -d. -f1-2)"
node="$(node -v 2>/dev/null | tr -d v | cut -d. -f1)"

try() { # expect-rc manifest-name manifest-body
  printf '%s\n' "$3" > "$tmp/$2"
  out="$(bash preflight.sh "$tmp/$2" 2>&1)"; rc=$?
  if [ "$rc" = "$1" ]; then echo "PASS case $2 rc=$rc"; else echo "FAIL case $2 rc=$rc want=$1"; echo "$out"; return 1; fi
}
fails=0
try 0 match "python=$py
node=$node" || fails=1
try 1 mismatch "python=1.0
node=2" || fails=1
try 2 unknown-key "python=$py
node=$node
ruby=3" || fails=1
try 2 duplicate "python=$py
python=$py
node=$node" || fails=1
try 2 empty-value "python=
node=$node" || fails=1
try 2 nofile-missing "python=$py" ; rm -f "$tmp/nofile-missing"
out="$(bash preflight.sh "$tmp/nofile-missing" 2>&1)"; [ "$?" = 2 ] || { echo "FAIL case missing-file"; fails=1; }

# отсутствующие инструменты не должны давать PASS
mkdir -p "$tmp/bin"
for t in awk cut sort uniq tr cat uname; do ln -s "$(command -v "$t")" "$tmp/bin/$t" 2>/dev/null; done
out="$(PATH="$tmp/bin" /bin/bash preflight.sh "$tmp/match" 2>&1)"; rc=$?
case "$out" in *got=missing*) echo "PASS case missing-tools";; *) echo "FAIL case missing-tools rc=$rc"; echo "$out"; fails=1;; esac

[ "$fails" = 0 ] && echo "tests: OK" || { echo "tests: FAILED"; exit 1; }
