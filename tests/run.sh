#!/usr/bin/env bash
# self-check. прогонять интерпретатором, который проверяем: bash tests/run.sh
set -u
cd "$(dirname "$0")/.."
tmp="$(mktemp -d)" || { echo "FAIL: mktemp"; exit 1; }
trap 'rm -rf "$tmp"' EXIT
self="${BASH:-/bin/bash}"   # тот же интерпретатор, что запустил тесты
echo "interp $self $BASH_VERSION"

py="$(python3 -V 2>/dev/null | awk '{print $2}' | cut -d. -f1-2)"
node="$(node -v 2>/dev/null | tr -d v | cut -d. -f1)"

try() { # expect-rc manifest-name manifest-body
  printf '%s\n' "$3" > "$tmp/$2"
  out="$("$self" preflight.sh "$tmp/$2" 2>&1)"; rc=$?
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
out="$("$self" preflight.sh "$tmp/nofile-missing" 2>&1)"; [ "$?" = 2 ] || { echo "FAIL case missing-file"; fails=1; }

try 2 eq-in-value "python=3.12=INVALID
node=$node" || fails=1

# инструмент печатает версию, но падает с ненулевым кодом → FAIL
mkdir -p "$tmp/stub"
printf '#!/bin/sh\necho "Python 3.12.7"\nexit 7\n' > "$tmp/stub/python3"
printf '#!/bin/sh\necho v22.1.0\nexit 0\n' > "$tmp/stub/node"
chmod +x "$tmp/stub/python3" "$tmp/stub/node"
printf 'python=3.12\nnode=22\n' > "$tmp/badexit"
out="$(PATH="$tmp/stub:$PATH" "$self" preflight.sh "$tmp/badexit" 2>&1)"; rc=$?
case "$out" in *"got=error"*) echo "PASS case bad-exit rc=$rc";; *) echo "FAIL case bad-exit rc=$rc"; echo "$out"; fails=1;; esac

# отсутствующие инструменты не должны давать PASS
mkdir -p "$tmp/bin"
for t in awk cut sort uniq tr cat uname grep; do ln -s "$(command -v "$t")" "$tmp/bin/$t" 2>/dev/null; done
out="$(PATH="$tmp/bin" "$self" preflight.sh "$tmp/match" 2>&1)"; rc=$?
case "$out" in *got=missing*|*got=error*) echo "PASS case missing-tools";; *) echo "FAIL case missing-tools rc=$rc"; echo "$out"; fails=1;; esac

[ "$fails" = 0 ] && echo "tests: OK" || { echo "tests: FAILED"; exit 1; }
