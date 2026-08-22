#!/usr/bin/env sh

set -e
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/calm-e2e-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/testlib.sh"

INSTALLER=$REPO_ROOT/scripts/install.sh
GOLDEN=$REPO_ROOT/tests/golden-path/relaycert
HOME_ROOT=$TEST_DIR/home\ with\ spaces
PROJECT=$TEST_DIR/relaycert\ project
mkdir -p "$HOME_ROOT" "$PROJECT"

CALM_GTM_HOME="$HOME_ROOT" CALM_GTM_TELEMETRY=0 \
  "$INSTALLER" --project "$PROJECT" --agent none --no-start >"$TEST_DIR/install.log" 2>&1

INSTALLED_CALM=$HOME_ROOT/.local/bin/calm
[ -L "$INSTALLED_CALM" ] || fail "clean-room CLI link is missing"
[ "$("$INSTALLED_CALM" version)" = "$CALM_VERSION" ] || fail "clean-room CLI version is not $CALM_VERSION"
cmp -s "$REPO_ROOT/SKILL.md" "$PROJECT/.agents/skills/calm-gtm/SKILL.md" || fail "project skill differs from the source package"
cmp -s "$REPO_ROOT/references/apop-questions.csv" "$PROJECT/.agents/skills/calm-gtm/references/apop-questions.csv" || fail "installed canonical questions drifted"
assert_contains "$PROJECT/AGENTS.md" 'Read .agents/skills/calm-gtm/SKILL.md'
assert_contains "$PROJECT/.calm/intake.md" 'Language: Pending'
assert_contains "$PROJECT/.calm/overview.md" 'Intake pending'
pass "clean-room installer exposes the packaged CLI, skill, questions, and opening state"

"$INSTALLED_CALM" init --project "$PROJECT" --intake "$GOLDEN/fixtures/founder-intake.md" --agent none --no-start >/dev/null
assert_contains "$PROJECT/.calm/intake.md" 'Je construis RelayCert.'
assert_contains "$PROJECT/.calm/intake.md" 'Language: French'
assert_contains "$PROJECT/.calm/overview.md" 'Phase du projet : Intake complet'
assert_not_file "$PROJECT/.calm/strategy.md"
assert_not_file "$PROJECT/.calm/action-plan.csv"
assert_not_file "$PROJECT/.calm/assets.csv"
pass "natural founder intake is preserved without premature strategy, plan, or asset"

source_manifest() {
  calm_dir=$1
  output=$2
  (
    cd "$calm_dir"
    for source_file in intake.md sources.md strategy.md strategy.csv action-plan.md action-plan.csv assets.csv weekly.md weekly.csv; do
      [ -f "$source_file" ] && cksum "$source_file"
    done
    if [ -d assets ]; then
      find assets -type f ! -name '.gitkeep' -print | LC_ALL=C sort | while IFS= read -r asset_file; do cksum "$asset_file"; done
    fi
  ) >"$output"
}

for stage in 01-initialized 02-intake-complete 03-strategy-proposed 04-strategy-agreed 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  STAGE_PROJECT=$TEST_DIR/$stage
  mkdir -p "$STAGE_PROJECT"
  cp -R "$GOLDEN/snapshots/$stage/.calm" "$STAGE_PROJECT/.calm"
  source_manifest "$STAGE_PROJECT/.calm" "$TEST_DIR/$stage.before"
  if [ "$stage" = 07-html-opt-in ]; then
    "$INSTALLED_CALM" status --project "$STAGE_PROJECT" --html >/dev/null
  else
    "$INSTALLED_CALM" status --project "$STAGE_PROJECT" >/dev/null
  fi
  source_manifest "$STAGE_PROJECT/.calm" "$TEST_DIR/$stage.after"
  cmp -s "$TEST_DIR/$stage.before" "$TEST_DIR/$stage.after" || fail "$stage status regeneration changed a source model"

  case "$stage" in
    01-initialized)
      assert_contains "$STAGE_PROJECT/.calm/overview.md" 'Intake pending'
      assert_not_file "$STAGE_PROJECT/.calm/strategy.md"
      ;;
    02-intake-complete)
      assert_contains "$STAGE_PROJECT/.calm/overview.md" 'Intake complet'
      assert_not_file "$STAGE_PROJECT/.calm/strategy.md"
      ;;
    03-strategy-proposed)
      assert_contains "$STAGE_PROJECT/.calm/strategy.md" 'calm:strategy-status=proposed'
      assert_not_file "$STAGE_PROJECT/.calm/action-plan.md"
      ;;
    04-strategy-agreed)
      assert_contains "$STAGE_PROJECT/.calm/strategy.md" 'calm:strategy-status=agreed'
      assert_not_file "$STAGE_PROJECT/.calm/action-plan.md"
      ;;
    04a-plan-proposed)
      assert_contains "$STAGE_PROJECT/.calm/action-plan.md" 'calm:plan-status=proposed'
      assert_not_file "$STAGE_PROJECT/.calm/assets.csv"
      ;;
    04b-plan-agreed)
      assert_contains "$STAGE_PROJECT/.calm/action-plan.md" 'calm:plan-status=agreed'
      assert_not_file "$STAGE_PROJECT/.calm/assets.csv"
      assert_not_file "$STAGE_PROJECT/.calm/assets/outreach-owner-v1.md"
      ;;
    05-plan-and-asset)
      assert_contains "$STAGE_PROJECT/.calm/action-plan.md" 'calm:plan-status=agreed'
      assert_file "$STAGE_PROJECT/.calm/assets/outreach-owner-v1.md"
      assert_not_file "$STAGE_PROJECT/.calm/weekly.md"
      ;;
    06-weekly)
      assert_file "$STAGE_PROJECT/.calm/weekly.md"
      assert_contains "$STAGE_PROJECT/.calm/weekly.md" '**Strategy changes:** None.'
      assert_not_file "$STAGE_PROJECT/.calm/dashboard.html"
      ;;
    07-html-opt-in)
      assert_file "$STAGE_PROJECT/.calm/dashboard.html"
      assert_contains "$STAGE_PROJECT/.calm/dashboard.html" 'Content-Security-Policy'
      assert_not_contains "$STAGE_PROJECT/.calm/dashboard.html" '<script'
      ;;
  esac
done
pass "installed CLI replays every documented gate without mutating source models"

FINAL=$TEST_DIR/07-html-opt-in/.calm
for deliverable in intake.md overview.md dashboard.html strategy.md strategy.csv action-plan.md action-plan.csv weekly.md weekly.csv sources.md assets.csv assets/outreach-owner-v1.md; do
  assert_file "$FINAL/$deliverable"
done
[ "$(sed -n '2,$p' "$FINAL/strategy.csv" | wc -l | tr -d ' ')" -eq 12 ] || fail "final strategy does not contain exactly 12 canonical rows"
assert_contains "$FINAL/action-plan.md" '## Now'
assert_contains "$FINAL/action-plan.md" '## Next'
assert_contains "$FINAL/action-plan.md" '## Later'
assert_count "$FINAL/weekly.md" '### 1. This week' 1
assert_count "$FINAL/weekly.md" '### 2. What it means' 1
assert_count "$FINAL/weekly.md" '### 3. APOP decision' 1
assert_count "$FINAL/weekly.md" '### 4. Decisions' 1
assert_count "$FINAL/weekly.md" '### 5. Next week' 1
assert_contains "$FINAL/assets.csv" 'ASSET-001'
assert_contains "$FINAL/assets.csv" 'ACT-003'
assert_not_contains "$FINAL/assets/outreach-owner-v1.md" 'Prompt:'
if awk -F ',' 'NR > 1 { count[$2]++ } END { for (horizon in count) if (count[horizon] > 3) bad=1; exit bad }' "$FINAL/action-plan.csv"; then :; else fail "final action plan exceeds three actions in a horizon"; fi
pass "final acceptance bundle contains every required document and stable structure"

REPORT=$REPO_ROOT/tests/ACCEPTANCE-REPORT.md
assert_file "$REPORT"
assert_contains "$REPORT" 'Result:** PASS for the complete deterministic local contract.'
assert_contains "$REPORT" 'Reference journey and deliverable documents'
assert_contains "$REPORT" 'Final deliverable bundle'
assert_contains "$REPORT" 'Real asset construction verified'
assert_contains "$REPORT" 'Explicit boundaries'
pass "human-readable delivery report indexes the journey, deliverables, tests, and boundaries"
