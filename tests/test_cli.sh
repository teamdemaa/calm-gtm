#!/usr/bin/env sh

set -e
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/calm-cli-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/testlib.sh"
CALM=$REPO_ROOT/bin/calm

"$CALM" help >"$TEST_DIR/help.txt"
assert_contains "$TEST_DIR/help.txt" 'asks the first question in the terminal'
assert_contains "$TEST_DIR/help.txt" 'portable handoff'
pass "CLI help states the universal terminal and coding-agent handoff contract"

broken_package=$TEST_DIR/broken-package
mkdir -p "$broken_package"
cp -R "$REPO_ROOT/VERSION" "$REPO_ROOT/bin" "$REPO_ROOT/lib" "$broken_package/"
rm -f "$broken_package/lib/calm/weekly_overview.awk"
if "$broken_package/bin/calm" help >"$TEST_DIR/broken-package.log" 2>&1; then
  fail "CLI with a missing runtime renderer unexpectedly started"
fi
assert_contains "$TEST_DIR/broken-package.log" 'calm: installation incomplete; lib/calm/weekly_overview.awk is missing.'
pass "CLI reports an incomplete runtime package before sourcing or rendering"

project=$TEST_DIR/project\ with\ spaces
mkdir -p "$project"
printf '%s\n' 'Je construis un SaaS vertical. Tout est encore désordonné.' | "$CALM" init --project "$project" --intake - --agent none --no-start >/dev/null
assert_file "$project/.calm/intake.md"
assert_file "$project/.calm/overview.md"
assert_file "$project/.calm/sources.md"
assert_dir "$project/.calm/assets"
assert_contains "$project/.calm/intake.md" 'Je construis un SaaS vertical.'
assert_contains "$project/.calm/intake.md" 'Language: French'
assert_contains "$project/.calm/overview.md" "# Vue d'ensemble Calm GTM"
assert_not_file "$project/.calm/strategy.md"
assert_not_file "$project/.calm/action-plan.csv"

mkdir -p "$project/nested/deeper"
(cd "$project/nested/deeper" && "$CALM" status >/dev/null)
assert_file "$project/.calm/overview.md"
pass "non-TTY init, stdin intake, spaces, and ancestor root resolution"

pending_word_project=$TEST_DIR/pending-word-project
mkdir -p "$pending_word_project"
printf '%s\n' 'Je construis un SaaS.' 'Pending.' 'Nous avons trois pilotes.' | \
  "$CALM" init --project "$pending_word_project" --intake - --agent none --no-start >/dev/null
assert_contains "$pending_word_project/.calm/intake.md" 'Language: French'
assert_contains "$pending_word_project/.calm/intake.md" 'Pending.'
assert_contains "$pending_word_project/.calm/overview.md" 'Phase du projet : Intake complet'
assert_not_contains "$pending_word_project/.calm/overview.md" 'Intake en attente'
pass "founder text cannot reactivate the structural pending marker"

golden=$TEST_DIR/golden
mkdir -p "$golden"
cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/06-weekly/.calm" "$golden/.calm"
"$CALM" status --project "$golden" >/dev/null
assert_contains "$golden/.calm/overview.md" "# Vue d'ensemble Calm GTM"
assert_contains "$golden/.calm/overview.md" 'Phase du projet : Exécution active'
assert_contains "$golden/.calm/overview.md" "| Interroger 10 dirigeants correspondant à l'ICP | 2026-09-05 | In progress |"
assert_contains "$golden/.calm/overview.md" 'ASSET-001'
assert_contains "$golden/.calm/overview.md" '12 messages, 4 réponses, 2 appels'
assert_contains "$golden/.calm/overview.md" '### APOP Changes'
assert_contains "$golden/.calm/overview.md" 'Réécrire le site autour'
assert_not_contains "$golden/.calm/overview.md" 'What do you want this company to bring you?'

awk '{ if (!changed && /Interroger 10 dirigeants/ && /In progress/) { sub(/In progress/, "Done"); changed=1 } print }' \
  "$golden/.calm/action-plan.csv" >"$golden/.calm/action-plan.csv.tmp"
mv "$golden/.calm/action-plan.csv.tmp" "$golden/.calm/action-plan.csv"
printf '%s\n' 'ACT-010,Now,Security check,<script>alert(1)</script> & follow up,Escaping test,PR1,Founder,2026-09-06,None,Escaped safely,Not started' >>"$golden/.calm/action-plan.csv"
"$CALM" status --project "$golden" --html >/dev/null
assert_contains "$golden/.calm/overview.md" "| Interroger 10 dirigeants correspondant à l'ICP | 2026-09-05 | Done |"
assert_file "$golden/.calm/dashboard.html"
assert_contains "$golden/.calm/dashboard.html" "Content-Security-Policy"
assert_not_contains "$golden/.calm/dashboard.html" '<script'
assert_not_contains "$golden/.calm/dashboard.html" 'https://'
assert_contains "$golden/.calm/dashboard.html" '&lt;script&gt;alert(1)&lt;/script&gt; &amp; follow up'
assert_contains "$golden/.calm/dashboard.html" '<html lang="fr">'
assert_contains "$golden/.calm/dashboard.html" 'ASSET-001'
assert_contains "$golden/.calm/dashboard.html" '### APOP Changes'
pass "status regeneration, authoritative CSV status, French rendering, and opt-in HTML"

asset_history=$TEST_DIR/asset-history
mkdir -p "$asset_history"
cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/05-plan-and-asset/.calm" "$asset_history/.calm"
awk '{ if (/^ASSET-001,/) sub(/,Final$/, ",Superseded"); print }' \
  "$asset_history/.calm/assets.csv" >"$asset_history/.calm/assets.csv.tmp"
mv "$asset_history/.calm/assets.csv.tmp" "$asset_history/.calm/assets.csv"
printf '%s\n' 'ASSET-002,Message de prospection v2,Messaging,Tester la version révisée du message,ACT-003,.calm/assets/outreach-owner-v2.md,Final' >>"$asset_history/.calm/assets.csv"
"$CALM" status --project "$asset_history" >/dev/null
assert_contains "$asset_history/.calm/overview.md" '## Assets actifs'
assert_contains "$asset_history/.calm/overview.md" '## Historique des assets'
assert_contains "$asset_history/.calm/overview.md" 'ASSET-002'
assert_contains "$asset_history/.calm/overview.md" 'ASSET-001'
if awk '
  /^## Assets actifs$/ { active=1; next }
  /^## Historique des assets$/ { active=0 }
  active && /ASSET-001/ { bad=1 }
  END { exit bad }
' "$asset_history/.calm/overview.md"; then :; else fail "superseded asset remained in the active section"; fi
pass "asset revisions separate current deliverables from preserved history"

proposed=$TEST_DIR/plan-proposed
mkdir -p "$proposed"
cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/04a-plan-proposed/.calm" "$proposed/.calm"
"$CALM" status --project "$proposed" >/dev/null
assert_contains "$proposed/.calm/overview.md" 'Phase du projet : Plan proposé'
assert_contains "$proposed/.calm/overview.md" 'Statut du plan : Proposé — en attente'
assert_contains "$proposed/.calm/overview.md" '## Maintenant — proposé'
assert_contains "$proposed/.calm/overview.md" "Aucune action n'est autorisée"
assert_not_contains "$proposed/.calm/overview.md" 'Phase du projet : Exécution active'
pass "proposed plan remains visibly locked"

legacy=$TEST_DIR/legacy-schemas
mkdir -p "$legacy"
cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/06-weekly/.calm" "$legacy/.calm"
printf '%s\n' 'Period,Area,Question,Answer' '2026-01-01,Alignment,Legacy question,Legacy answer' >"$legacy/.calm/strategy.csv"
printf '%s\n' 'Horizon,Objective,Action,Why,Responsible,Due,Deliverable,Success Signal,Status' 'Now,Legacy objective,Legacy action,Legacy reason,Founder,2026-09-01,Legacy deliverable,Legacy signal,Not started' >"$legacy/.calm/action-plan.csv"
printf '%s\n' 'Asset Name,Category,Purpose,Linked Action,File,Status' 'Legacy asset,Messaging,Legacy purpose,Legacy action,.calm/assets/legacy.md,Final' >"$legacy/.calm/assets.csv"
printf '%s\n' 'Date,What Happened,What Matters,What We Learned,Keep,Change,Stop,One Thing Not To Do' '2026-01-01,Legacy week,Legacy matter,Legacy learning,Keep,Change,Stop,Avoid' >"$legacy/.calm/weekly.csv"
for legacy_csv in strategy.csv action-plan.csv assets.csv weekly.csv; do
  cksum "$legacy/.calm/$legacy_csv" >"$TEST_DIR/$legacy_csv.before"
done
"$CALM" status --project "$legacy" >/dev/null
assert_contains "$legacy/.calm/overview.md" '## Migration locale requise'
for legacy_csv in strategy.csv action-plan.csv assets.csv weekly.csv; do
  cksum "$legacy/.calm/$legacy_csv" >"$TEST_DIR/$legacy_csv.after"
  cmp -s "$TEST_DIR/$legacy_csv.before" "$TEST_DIR/$legacy_csv.after" || fail "$legacy_csv was rewritten during legacy detection"
  assert_contains "$legacy/.calm/overview.md" "$legacy_csv"
done
assert_not_contains "$legacy/.calm/overview.md" 'Legacy action |'
pass "legacy project schemas are detected without invented migration fields"

for malformed_model in strategy action-plan assets weekly; do
  malformed=$TEST_DIR/malformed-$malformed_model
  mkdir -p "$malformed"
  cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/06-weekly/.calm" "$malformed/.calm"
  cksum "$malformed/.calm/overview.md" >"$TEST_DIR/$malformed_model-overview.before"
  case "$malformed_model" in
    strategy)
      printf '%s\n' 'Period,Question ID,Area,Question,Answer,State' '2026-08-22T18:00:00+02:00,AL1,Alignment,"Unclosed answer,Known' >"$malformed/.calm/strategy.csv"
      ;;
    action-plan)
      printf '%s\n' 'Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status' 'ACT-001,Now,"Unclosed objective,Do work,Why,PO1,Founder,2026-09-01,File,3 calls,In progress' >"$malformed/.calm/action-plan.csv"
      ;;
    assets)
      printf '%s\n' 'Asset ID,Asset Name,Category,Purpose,Linked Action ID,File,Status' 'ASSET-001,Too,few,columns' >"$malformed/.calm/assets.csv"
      ;;
    weekly)
      printf '%s\n' 'Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do' '2026-08-22,"Unclosed week,Signal,Learning,Noise,None,Keep,Change,Stop,ACT-001,Avoid noise' >"$malformed/.calm/weekly.csv"
      ;;
  esac
  if "$CALM" status --project "$malformed" >"$TEST_DIR/$malformed_model-invalid.log" 2>&1; then
    fail "$malformed_model malformed CSV unexpectedly rendered"
  fi
  assert_contains "$TEST_DIR/$malformed_model-invalid.log" 'invalid CSV structure'
  cksum "$malformed/.calm/overview.md" >"$TEST_DIR/$malformed_model-overview.after"
  cmp -s "$TEST_DIR/$malformed_model-overview.before" "$TEST_DIR/$malformed_model-overview.after" || fail "$malformed_model invalid CSV replaced the last valid overview"
done
pass "malformed current CSV files fail atomically and preserve the last tracker"

multiline=$TEST_DIR/multiline-csv
mkdir -p "$multiline"
cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/06-weekly/.calm" "$multiline/.calm"
cksum "$multiline/.calm/overview.md" >"$TEST_DIR/multiline-overview.before"
printf '%s\n' \
  'Period,Question ID,Area,Question,Answer,State' \
  '2026-08-22T18:00:00+02:00,AL1,Alignment,Question,"First physical line' \
  'second physical line",Known' >"$multiline/.calm/strategy.csv"
if "$CALM" status --project "$multiline" >"$TEST_DIR/multiline-invalid.log" 2>&1; then
  fail "multiline CSV record unexpectedly rendered"
fi
assert_contains "$TEST_DIR/multiline-invalid.log" 'invalid CSV structure'
cksum "$multiline/.calm/overview.md" >"$TEST_DIR/multiline-overview.after"
cmp -s "$TEST_DIR/multiline-overview.before" "$TEST_DIR/multiline-overview.after" || fail "multiline CSV replaced the last valid overview"
pass "CSV records remain one physical line and invalid multiline records fail atomically"

fake_bin=$TEST_DIR/fake-bin
mkdir -p "$fake_bin"
cat >"$fake_bin/codex" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$CALM_CAPTURE"
EOF
chmod +x "$fake_bin/codex"
tty_project=$TEST_DIR/tty-project
mkdir -p "$tty_project"
tty_project_abs=$(CDPATH= cd -- "$tty_project" && pwd)
printf '%s\n' 'I am building a workflow product.' 'We have two design partners and no revenue.' >"$TEST_DIR/tty-input"
: >"$TEST_DIR/tty-output"
CALM_GTM_FORCE_INTERACTIVE=1 \
CALM_GTM_TTY_INPUT="$TEST_DIR/tty-input" \
CALM_GTM_TTY_OUTPUT="$TEST_DIR/tty-output" \
CALM_CAPTURE="$TEST_DIR/codex-args" \
PATH="$fake_bin:/usr/bin:/bin" \
  "$CALM" init --project "$tty_project" --agent auto >/dev/null
assert_contains "$TEST_DIR/tty-output" 'Tell me what you’re building, where you are today, and what feels hardest right now.'
assert_contains "$tty_project/.calm/intake.md" 'We have two design partners and no revenue.'
assert_contains "$TEST_DIR/codex-args" '-C'
assert_contains "$TEST_DIR/codex-args" "$tty_project_abs"
assert_not_contains "$TEST_DIR/codex-args" 'two design partners'
pass "interactive intake and static Codex CLI handoff"

fake_claude_bin=$TEST_DIR/fake-claude-bin
mkdir -p "$fake_claude_bin"
cat >"$fake_claude_bin/claude" <<'EOF'
#!/bin/sh
printf '%s\n' "$PWD" >"$CALM_CLAUDE_CWD"
printf '%s\n' "$@" >"$CALM_CLAUDE_ARGS"
EOF
chmod +x "$fake_claude_bin/claude"
claude_project=$TEST_DIR/claude-project
mkdir -p "$claude_project"
claude_project_abs=$(CDPATH= cd -- "$claude_project" && pwd)
printf '%s\n' 'I am building a vertical SaaS.' >"$TEST_DIR/claude-intake"
CALM_GTM_FORCE_INTERACTIVE=1 \
CALM_CLAUDE_CWD="$TEST_DIR/claude-cwd" \
CALM_CLAUDE_ARGS="$TEST_DIR/claude-args" \
PATH="$fake_claude_bin:/usr/bin:/bin" \
  "$CALM" init --project "$claude_project" --intake "$TEST_DIR/claude-intake" --agent claude >/dev/null
assert_contains "$TEST_DIR/claude-cwd" "$claude_project_abs"
assert_contains "$TEST_DIR/claude-args" 'Start Calm GTM for this project.'

cat >"$fake_claude_bin/codex" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$fake_claude_bin/codex"
printf '%s\n' l >"$TEST_DIR/agent-choice"
: >"$TEST_DIR/agent-choice-output"
selected_agent=$(
  CALM_GTM_FORCE_INTERACTIVE=1 \
  CALM_GTM_TTY_INPUT="$TEST_DIR/agent-choice" \
  CALM_GTM_TTY_OUTPUT="$TEST_DIR/agent-choice-output" \
  PATH="$fake_claude_bin:/usr/bin:/bin" \
  CALM_GTM_PACKAGE_ROOT="$REPO_ROOT" \
  sh -c '. "$CALM_GTM_PACKAGE_ROOT/lib/calm/common.sh"; . "$CALM_GTM_PACKAGE_ROOT/lib/calm/adapter.sh"; calm_choose_agent auto 1'
)
[ "$selected_agent" = claude ] || fail "interactive dual-agent choice did not select Claude"
pass "Claude handoff and dual-agent selection"

existing=$TEST_DIR/existing
mkdir -p "$existing"
cp -R "$REPO_ROOT/tests/golden-path/relaycert/snapshots/04-strategy-agreed/.calm" "$existing/.calm"
before=$(cksum "$existing/.calm/intake.md")
: >"$TEST_DIR/empty-input"
: >"$TEST_DIR/existing-output"
CALM_GTM_FORCE_INTERACTIVE=1 CALM_GTM_TTY_INPUT="$TEST_DIR/empty-input" CALM_GTM_TTY_OUTPUT="$TEST_DIR/existing-output" \
  "$CALM" init --project "$existing" --agent none >/dev/null
after=$(cksum "$existing/.calm/intake.md")
[ "$before" = "$after" ] || fail "existing strategy restarted onboarding"
assert_not_contains "$TEST_DIR/existing-output" 'Tell me what you’re building'
pass "existing strategy skips onboarding"

absent_project=$TEST_DIR/no-agent
mkdir -p "$absent_project"
PATH="/usr/bin:/bin" "$CALM" init --project "$absent_project" --agent auto >"$TEST_DIR/no-agent.log"
assert_contains "$TEST_DIR/no-agent.log" 'No interactive terminal is available, so Calm did not launch a coding agent.'
assert_contains "$TEST_DIR/no-agent.log" 'Paste this handoff:'
assert_file "$absent_project/.calm/intake.md"
pass "non-interactive agent-absent fallback does not hang"

for intake_kind in short long disordered; do
  intake_project=$TEST_DIR/intake-$intake_kind
  mkdir -p "$intake_project"
  case "$intake_kind" in
    short) printf '%s\n' 'Je teste une idée.' >"$TEST_DIR/$intake_kind.txt" ;;
    long)
      : >"$TEST_DIR/$intake_kind.txt"
      line_number=1
      while [ "$line_number" -le 120 ]; do
        printf 'Contexte fondateur ligne %s avec une hypothèse non validée.\n' "$line_number" >>"$TEST_DIR/$intake_kind.txt"
        line_number=$((line_number + 1))
      done
      ;;
    disordered) printf '%s\n' 'prix peut-être 99' 'clients? artisans' 'aucune vente' 'je veux rester bootstrap' >"$TEST_DIR/$intake_kind.txt" ;;
  esac
  "$CALM" init --project "$intake_project" --intake "$TEST_DIR/$intake_kind.txt" --agent none --no-start >/dev/null
  assert_not_file "$intake_project/.calm/strategy.md"
  assert_not_file "$intake_project/.calm/action-plan.csv"
  first_intake_line=$(sed -n '1p' "$TEST_DIR/$intake_kind.txt")
  assert_contains "$intake_project/.calm/intake.md" "$first_intake_line"
done
pass "short, long, and disordered intake is preserved without premature GTM output"
