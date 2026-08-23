#!/usr/bin/env sh

set -e
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/testlib.sh"

"$REPO_ROOT/scripts/quick_validate.sh" >"${TMPDIR:-/tmp}/calm-quick-validate.$$"
assert_contains "${TMPDIR:-/tmp}/calm-quick-validate.$$" 'quick_validate calm-gtm: ok'
rm -f "${TMPDIR:-/tmp}/calm-quick-validate.$$"
pass "calm-gtm owns a deterministic quick validator"

"$REPO_ROOT/scripts/validate-skills.sh" >"${TMPDIR:-/tmp}/calm-validate-skills.$$"
assert_contains "${TMPDIR:-/tmp}/calm-validate-skills.$$" 'validate-skills: ok'
rm -f "${TMPDIR:-/tmp}/calm-validate-skills.$$"
pass "the registry validator checks every registered skill"

assert_contains "$REPO_ROOT/docs/multi-skill-foundation.md" 'Only `calm-gtm` is installed by default.'
assert_contains "$REPO_ROOT/docs/multi-skill-foundation.md" 'Large runtimes and brand packs are separate'
pass "the foundation documents default and optional-package boundaries"
