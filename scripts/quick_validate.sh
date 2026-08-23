#!/usr/bin/env sh

set -e
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

fail() { echo "quick_validate calm-gtm: $*" >&2; exit 1; }

[ -f "$REPO_ROOT/SKILL.md" ] || fail "missing SKILL.md"
[ -d "$REPO_ROOT/references" ] || fail "missing references directory"

frontmatter_name=$(awk '
  NR == 1 && $0 == "---" { frontmatter=1; next }
  frontmatter && $0 == "---" { exit }
  frontmatter && /^name:[[:space:]]*/ {
    sub(/^name:[[:space:]]*/, "")
    print
    exit
  }
' "$REPO_ROOT/SKILL.md")
[ "$frontmatter_name" = calm-gtm ] || fail "SKILL.md frontmatter name must be calm-gtm"

for required in \
  apop-questions.csv \
  apop-strategy.md \
  action-plan.md \
  assets.md \
  weekly-update.md \
  local-tracker.md
do
  [ -f "$REPO_ROOT/references/$required" ] || fail "missing references/$required"
done

if [ -f "$REPO_ROOT/bin/calm" ] && [ -d "$REPO_ROOT/lib/calm" ]; then
  for shell_file in "$REPO_ROOT/bin/calm" "$REPO_ROOT"/lib/calm/*.sh; do
    sh -n "$shell_file" || fail "invalid POSIX shell: $shell_file"
  done
elif [ -e "$REPO_ROOT/bin/calm" ] || [ -e "$REPO_ROOT/lib/calm" ]; then
  fail "partial CLI runtime beside the skill"
fi

echo "quick_validate calm-gtm: ok"
