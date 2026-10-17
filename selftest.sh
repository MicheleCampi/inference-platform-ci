#!/usr/bin/env bash
# Self-test of lib.sh, install.sh and install-python.sh: each must accept
# what it should accept and reject what it should reject, for the reason
# named. A check that cannot fail proves nothing. Needs bash, curl, git,
# python3 and network access for one pinned tool and PyYAML.
set -uo pipefail
cd "$(dirname "$0")"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fail=0
. ./lib.sh

echo "== lib.sh: each helper must set fail exactly when it should"
probe() { # name want-fail command...
  local n=$1 want=$2; shift 2
  ( fail=0; "$@" >/dev/null 2>&1; echo "$fail" ) > "$W/probe-$n.out"
  same "probe-$n" "$(cat "$W/probe-$n.out")" "$want"
}
probe check-passes          0 check c1 true
probe check-fails           1 check c2 false
probe reject-right-reason   0 expect_reject r1 boom sh -c 'echo boom; exit 1'
probe reject-accepted       1 expect_reject r2 boom true
probe reject-other-reason   1 expect_reject r3 boom sh -c 'echo other; exit 1'
probe same-equal            0 same s1 a a
probe same-different        1 same s2 a b
probe exit-code-match       0 exit_code e1 3 sh -c 'exit 3'
probe exit-code-mismatch    1 exit_code e2 3 true
G=(git -C "$W/repo" -c user.name=selftest -c user.email=selftest@invalid -c commit.gpgsign=false -c tag.gpgsign=false)
git init -q "$W/repo" && "${G[@]}" commit -q --allow-empty -m t && "${G[@]}" tag v1
c=$(git -C "$W/repo" rev-parse HEAD)
check tag-is-pinned tag_is "$W/repo" v1 "$c"
expect_reject tag-is-moved "resolves to $c, not the pinned" tag_is "$W/repo" v1 0000000000000000000000000000000000000000
expect_reject tag-is-missing "tag v9 not found" tag_is "$W/repo" v9 "$c"

echo "== install.sh and install-python.sh"
check install-yq bash install.sh "$W/bin" tools.lock yq
check yq-runs "$W/bin/yq" --version
awk '$1 == "yq" { $3 = "0" } 1' tools.lock > "$W/bad.lock"
expect_reject install-bad-checksum "checksum mismatch for yq" bash install.sh "$W/bad" "$W/bad.lock" yq
expect_reject install-unknown-name "nope is not in tools.lock" bash install.sh "$W/none" tools.lock nope
check install-python bash install-python.sh "$W/venv" requirements.lock
check pyyaml-imports "$W/venv/bin/python" -c 'import yaml'

if [ "$fail" = 0 ]; then echo "ALL PASS"; else echo "FAILED"; exit 1; fi
