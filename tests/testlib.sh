#!/usr/bin/env sh

CALM_VERSION=$(sed -n '1p' "$REPO_ROOT/VERSION")
CALM_TAG=v$CALM_VERSION
CALM_NEXT_VERSION=$(printf '%s\n' "$CALM_VERSION" | awk -F. '{ print $1 "." $2 "." ($3 + 1) }')
CALM_NEXT_TAG=v$CALM_NEXT_VERSION

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }
assert_file() { [ -f "$1" ] || fail "expected file: $1"; }
assert_dir() { [ -d "$1" ] || fail "expected directory: $1"; }
assert_not_file() { [ ! -f "$1" ] || fail "unexpected file: $1"; }
assert_contains() { grep -qF -- "$2" "$1" || fail "$1 does not contain: $2"; }
assert_not_contains() { if grep -qF -- "$2" "$1"; then fail "$1 unexpectedly contains: $2"; fi; }
assert_count() {
  actual=$(grep -cF -- "$2" "$1" 2>/dev/null || true)
  [ "$actual" -eq "$3" ] || fail "$1 contains '$2' $actual times, expected $3"
}
