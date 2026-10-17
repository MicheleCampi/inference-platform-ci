# Shared helpers for the validate scripts of the platform. Source this file
# after setting W (a scratch directory) and fail=0. Each helper logs to
# $W/<name>.log and sets fail=1 instead of exiting, so one run reports every
# failure; tag_is returns non-zero instead, for use inside check or
# expect_reject.
pass() { echo "PASS $1"; }
check() { local n=$1; shift; if "$@" >"$W/$n.log" 2>&1; then pass "$n"; else echo "FAIL $n"; tail -20 "$W/$n.log"; fail=1; fi; }
expect_reject() {
  local n=$1 reason=$2; shift 2
  if "$@" >"$W/$n.log" 2>&1; then echo "FAIL $n: accepted, should have been rejected"; fail=1
  elif grep -q -E "$reason" "$W/$n.log"; then echo "PASS $n: rejected ($(grep -m1 -o -E ".{0,40}$reason.{0,40}" "$W/$n.log"))"
  else echo "FAIL $n: rejected for another reason"; tail -5 "$W/$n.log"; fail=1; fi
}
same() { if [ "$2" = "$3" ]; then pass "$1 ($2)"; else echo "FAIL $1: $2 != $3"; fail=1; fi; }
exit_code() {
  local n=$1 want=$2; shift 2
  "$@" >"$W/$n.log" 2>&1; local got=$?
  if [ "$got" = "$want" ]; then pass "$n (exit $got)"; else echo "FAIL $n: exit $got, want $want"; tail -5 "$W/$n.log"; fail=1; fi
}
tag_is() { # repo tag commit
  local got; got=$(git -C "$1" rev-parse --verify -q "refs/tags/$2^{commit}") || { echo "tag $2 not found"; return 1; }
  [ "$got" = "$3" ] || { echo "tag $2 resolves to $got, not the pinned $3"; return 1; }
}
