#!/usr/bin/env sh

set -e
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/testlib.sh"
GOLDEN=$REPO_ROOT/tests/golden-path/relaycert
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/calm-golden-tests.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

csv_projection() {
  input=$1
  first=$2
  second=$3
  third=$4
  fourth=${5:-}
  fifth=${6:-}
  sixth=${7:-}
  seventh=${8:-}
  awk -v first="$first" -v second="$second" -v third="$third" \
    -v fourth="$fourth" -v fifth="$fifth" -v sixth="$sixth" -v seventh="$seventh" '
    function clear_fields(    key) {
      for (key in field) delete field[key]
    }
    function parse_csv(line,    i,ch,nextch,value,n,in_quotes) {
      clear_fields()
      parse_unclosed = 0
      sub(/\r$/, "", line)
      value = ""
      n = 1
      in_quotes = 0
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        nextch = substr(line, i + 1, 1)
        if (in_quotes) {
          if (ch == "\"" && nextch == "\"") {
            value = value "\""
            i++
          } else if (ch == "\"") {
            in_quotes = 0
          } else {
            value = value ch
          }
        } else if (ch == "\"") {
          in_quotes = 1
        } else if (ch == ",") {
          field[n++] = value
          value = ""
        } else {
          value = value ch
        }
      }
      field[n] = value
      if (in_quotes) parse_unclosed = 1
      return n
    }
    NR == 1 {
      expected_width = parse_csv($0)
      if (parse_unclosed) bad = 1
      next
    }
    {
      width = parse_csv($0)
      if (parse_unclosed || width != expected_width) bad = 1
      output = field[first] "\t" field[second] "\t" field[third]
      if (fourth != "") output = output "\t" field[fourth]
      if (fifth != "") output = output "\t" field[fifth]
      if (sixth != "") output = output "\t" field[sixth]
      if (seventh != "") output = output "\t" field[seventh]
      print output
    }
    END { exit bad }
  ' "$input"
}

action_plan_md_projection() {
  awk -F '|' '
    function trim(value) {
      gsub(/^[ \t]+/, "", value)
      gsub(/[ \t]+$/, "", value)
      return value
    }
    /^\| Action \| Why \| Responsible \| Due \| Deliverable \| Success Signal \| Status \|$/ {
      in_actions = 1
      next
    }
    in_actions && /^\|---/ { next }
    in_actions && /^\| / {
      print trim($2) "\t" trim($3) "\t" trim($4) "\t" trim($5) "\t" trim($6) "\t" trim($7) "\t" trim($8)
      next
    }
    in_actions && !/^\|/ { in_actions = 0 }
  ' "$1"
}

strategy_md_projection() {
  awk '
    function trim(value) {
      gsub(/^[ \t]+/, "", value)
      gsub(/[ \t]+$/, "", value)
      return value
    }
    function append_answer(value) {
      value = trim(value)
      if (value == "") return
      if (answer != "") answer = answer " "
      answer = answer value
    }
    /^### / {
      if ($0 == "### Thèse GTM") next
      question = substr($0, 5)
      answer = ""
      reading_answer = 0
      active = 1
      next
    }
    active && /^\*\*Answer:\*\*/ {
      value = $0
      sub(/^\*\*Answer:\*\*[ \t]*/, "", value)
      append_answer(value)
      reading_answer = 1
      next
    }
    active && /^\*\*State:\*\*/ {
      state = $0
      sub(/^\*\*State:\*\*[ \t]*/, "", state)
      print question "\t" answer "\t" trim(state)
      active = 0
      reading_answer = 0
      next
    }
    active && reading_answer { append_answer($0) }
  ' "$1"
}

md_section_projection() {
  file=$1
  heading=$2
  awk -v heading="$heading" '
    $0 == heading { active=1; next }
    active && /^#/ { exit }
    active {
      value=$0
      gsub(/^[ \t]+/, "", value)
      gsub(/[ \t]+$/, "", value)
      if (value != "") {
        if (output != "") output=output " "
        output=output value
      }
    }
    END { print output }
  ' "$file"
}

assert_contains "$GOLDEN/conversation.md" 'Tell me what you’re building, where you are today, and what feels hardest right now. Write naturally — I’ll ask only what I need.'
assert_contains "$GOLDEN/conversation.md" '## 2. Founder intake'
assert_contains "$GOLDEN/conversation.md" '**Founder**'
assert_contains "$GOLDEN/acceptance.md" 'No market size, conversion rate, ROI, customer quote, or product capability'
assert_contains "$GOLDEN/acceptance.md" 'five weekly section titles remain in English'
assert_contains "$GOLDEN/acceptance.md" 'Action IDs are monotonic and are never reused or renumbered.'
assert_contains "$GOLDEN/acceptance.md" '`Not started`, `In progress`,'
assert_contains "$GOLDEN/acceptance.md" '`Done`, `Blocked`, and `Stopped`.'
assert_contains "$GOLDEN/acceptance.md" '`calm:supersedes` metadata.'
assert_contains "$GOLDEN/acceptance.md" '`APOP Changes` is either `None` or a pipe-separated list'

cmp -s "$REPO_ROOT/references/apop-questions.csv" "$GOLDEN/contract/apop-questions.csv" || fail "installed canonical questions drifted from the golden contract"
assert_contains "$REPO_ROOT/references/apop-strategy.md" 'Period,Question ID,Area,Question,Answer,State'
assert_contains "$REPO_ROOT/references/action-plan.md" 'Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status'
assert_contains "$REPO_ROOT/references/assets.md" 'Asset ID,Asset Name,Category,Purpose,Linked Action ID,File,Status'
assert_contains "$REPO_ROOT/references/weekly-update.md" 'Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do'
assert_not_contains "$REPO_ROOT/references/apop-strategy.md" 'Period,Area,Question,Answer'
assert_not_contains "$REPO_ROOT/references/action-plan.md" 'Horizon,Objective,Action,Why,Responsible,Due,Deliverable,Success Signal,Status'
assert_not_contains "$REPO_ROOT/references/assets.md" 'Asset Name,Category,Purpose,Linked Action,File,Status'
assert_not_contains "$REPO_ROOT/references/weekly-update.md" 'Date,What Happened,What Matters,What We Learned,Keep,Change,Stop,One Thing Not To Do'
assert_not_contains "$REPO_ROOT/references/apop-strategy.md" 'Close every strategy with'
assert_contains "$REPO_ROOT/references/weekly-update.md" 'It always has exactly these five'
assert_contains "$REPO_ROOT/references/assets.md" 'Use a prompt only when the founder explicitly asks for one'
assert_contains "$REPO_ROOT/references/assets.md" 'Plan approval alone is never asset approval.'
assert_contains "$REPO_ROOT/SKILL.md" '`.calm/assets.csv`, any existing asset or manifest relevant to the request'
assert_contains "$REPO_ROOT/references/assets.md" 'Choose the next unused'
assert_contains "$REPO_ROOT/references/assets.md" 'preserve every existing row'
assert_contains "$REPO_ROOT/references/action-plan.md" 'at most three actions in each horizon'
assert_contains "$REPO_ROOT/references/assets.md" '`Draft`, `Final`, or `Superseded`'
assert_contains "$REPO_ROOT/SKILL.md" 'Every structured CSV record occupies exactly one physical line.'
assert_file "$REPO_ROOT/lib/calm/csv.awk"
assert_file "$REPO_ROOT/lib/calm/csv_validate.awk"
assert_contains "$REPO_ROOT/scripts/install.sh" "RELEASE_VERSION=$CALM_TAG"
pass "source skill contracts match the golden schemas"

find "$GOLDEN" -type f -name '*.csv' | LC_ALL=C sort >"$TMP_ROOT/csv-files"
while IFS= read -r csv_file; do
  csv_projection "$csv_file" 1 1 1 >/dev/null || fail "$csv_file has invalid quoting or inconsistent row widths"
done <"$TMP_ROOT/csv-files"
pass "all golden CSV files have valid quoting and stable row widths"

for early in 01-initialized 02-intake-complete; do
  assert_not_file "$GOLDEN/snapshots/$early/.calm/strategy.md"
  assert_not_file "$GOLDEN/snapshots/$early/.calm/action-plan.csv"
done
for gated in 01-initialized 02-intake-complete 03-strategy-proposed; do
  assert_not_file "$GOLDEN/snapshots/$gated/.calm/action-plan.md"
  assert_not_file "$GOLDEN/snapshots/$gated/.calm/assets.csv"
done
assert_contains "$GOLDEN/snapshots/03-strategy-proposed/.calm/strategy.md" '<!-- calm:strategy-status=proposed -->'
assert_contains "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" '<!-- calm:strategy-status=agreed -->'
assert_contains "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" '<!-- calm:strategy-agreed-at=2026-08-22 -->'
assert_not_file "$GOLDEN/snapshots/04-strategy-agreed/.calm/action-plan.md"
assert_contains "$GOLDEN/snapshots/04a-plan-proposed/.calm/action-plan.md" '<!-- calm:plan-status=proposed -->'
assert_not_file "$GOLDEN/snapshots/04a-plan-proposed/.calm/assets.csv"
assert_not_file "$GOLDEN/snapshots/04a-plan-proposed/.calm/assets/outreach-owner-v1.md"
assert_contains "$GOLDEN/snapshots/04b-plan-agreed/.calm/action-plan.md" '<!-- calm:plan-status=agreed -->'
assert_not_file "$GOLDEN/snapshots/04b-plan-agreed/.calm/assets.csv"
assert_not_file "$GOLDEN/snapshots/04b-plan-agreed/.calm/assets/outreach-owner-v1.md"
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.md" '<!-- calm:plan-status=agreed -->'
cmp -s "$GOLDEN/snapshots/03-strategy-proposed/.calm/strategy.csv" "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" || fail "strategy approval changed or duplicated strategy rows"
grep -v '^<!-- calm:' "$GOLDEN/snapshots/03-strategy-proposed/.calm/strategy.md" >"$TMP_ROOT/strategy-proposed"
grep -v '^<!-- calm:' "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" >"$TMP_ROOT/strategy-agreed"
cmp -s "$TMP_ROOT/strategy-proposed" "$TMP_ROOT/strategy-agreed" || fail "strategy approval changed strategy content"
cmp -s "$GOLDEN/snapshots/04a-plan-proposed/.calm/action-plan.csv" "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv" || fail "plan approval changed action rows"
grep -v '^<!-- calm:' "$GOLDEN/snapshots/04a-plan-proposed/.calm/action-plan.md" >"$TMP_ROOT/plan-proposed"
grep -v '^<!-- calm:' "$GOLDEN/snapshots/04b-plan-agreed/.calm/action-plan.md" >"$TMP_ROOT/plan-agreed"
cmp -s "$TMP_ROOT/plan-proposed" "$TMP_ROOT/plan-agreed" || fail "plan approval changed plan content"
for snapshot in 03-strategy-proposed 04-strategy-agreed 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  assert_not_contains "$GOLDEN/snapshots/$snapshot/.calm/strategy.md" 'Veux-tu'
done
for snapshot in 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  assert_not_contains "$GOLDEN/snapshots/$snapshot/.calm/action-plan.md" 'Veux-tu'
done
for snapshot in 03-strategy-proposed 04-strategy-agreed 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  cmp -s "$GOLDEN/snapshots/02-intake-complete/.calm/intake.md" "$GOLDEN/snapshots/$snapshot/.calm/intake.md" || fail "$snapshot changed intake after material clarification"
done
assert_not_contains "$GOLDEN/snapshots/02-intake-complete/.calm/intake.md" 'Accord sur la stratégie'
pass "conversation and separate strategy/plan approval gates"

[ "$(sed -n '1p' "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv")" = 'Period,Question ID,Area,Question,Answer,State' ] || fail "strategy CSV header changed"
[ "$(sed -n '1p' "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv")" = 'Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status' ] || fail "action-plan CSV header changed"
[ "$(sed -n '1p' "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets.csv")" = 'Asset ID,Asset Name,Category,Purpose,Linked Action ID,File,Status' ] || fail "assets CSV header changed"
[ "$(sed -n '1p' "$GOLDEN/snapshots/06-weekly/.calm/weekly.csv")" = 'Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do' ] || fail "weekly CSV header changed"
[ "$(wc -l < "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" | tr -d ' ')" -eq 13 ] || fail "strategy CSV does not contain exactly 12 rows"
[ "$(wc -l < "$GOLDEN/snapshots/06-weekly/.calm/weekly.csv" | tr -d ' ')" -eq 2 ] || fail "weekly CSV does not contain one row"

csv_projection "$GOLDEN/contract/apop-questions.csv" 1 2 3 >"$TMP_ROOT/canonical-questions"
csv_projection "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" 2 3 4 >"$TMP_ROOT/strategy-questions"
cmp -s "$TMP_ROOT/canonical-questions" "$TMP_ROOT/strategy-questions" || fail "strategy questions differ from the immutable 12-question contract"
awk -F '\t' '{ print "### " $3 }' "$TMP_ROOT/canonical-questions" >"$TMP_ROOT/canonical-headings"
grep '^### ' "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" | grep -v '^### Thèse GTM$' >"$TMP_ROOT/strategy-headings"
cmp -s "$TMP_ROOT/canonical-headings" "$TMP_ROOT/strategy-headings" || fail "strategy markdown has missing, changed, reordered, or extra question headings"
[ "$(grep -c '^### ' "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md")" -eq 13 ] || fail "strategy markdown must contain one thesis and exactly 12 questions"
if awk -F ',' 'NR > 1 && $NF !~ /^(Known|Hypothesis|Unknown)$/ { bad=1 } END { exit bad }' "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv"; then :; else fail "strategy state is outside Known, Hypothesis, or Unknown"; fi
csv_projection "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" 2 6 6 >"$TMP_ROOT/strategy-states"
if awk -F '\t' '
  $2 == "Known" { known++; if ($1 !~ /^AL[123]$/) bad=1 }
  $2 == "Hypothesis" { hypotheses++ }
  END { if (known != 3 || hypotheses != 9) bad=1; exit bad }
' "$TMP_ROOT/strategy-states"; then :; else fail "only AL1-AL3 may be Known in the golden strategy"; fi
assert_contains "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" 'Les notes fournies par le fondateur sur deux pilotes indiquent'
cut -d, -f1 "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" | sed -n '2,$p' | LC_ALL=C sort -u >"$TMP_ROOT/strategy-periods"
[ "$(wc -l < "$TMP_ROOT/strategy-periods" | tr -d ' ')" -eq 1 ] || fail "one strategy revision must share one Period"
strategy_period=$(sed -n '1p' "$TMP_ROOT/strategy-periods")
printf '%s\n' "$strategy_period" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{2}:[0-9]{2})$' || fail "strategy Period is not a unique ISO-8601 timestamp"
strategy_md_projection "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" >"$TMP_ROOT/strategy-md-answers"
csv_projection "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" 4 5 6 >"$TMP_ROOT/strategy-csv-answers" || fail "strategy CSV is invalid"
cmp -s "$TMP_ROOT/strategy-md-answers" "$TMP_ROOT/strategy-csv-answers" || fail "strategy Markdown and CSV answers or states differ"
for snapshot in 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  cmp -s "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" "$GOLDEN/snapshots/$snapshot/.calm/strategy.md" || fail "$snapshot rewrote the agreed strategy Markdown"
  cmp -s "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" "$GOLDEN/snapshots/$snapshot/.calm/strategy.csv" || fail "$snapshot rewrote the agreed strategy CSV"
done
for snapshot in 03-strategy-proposed 04-strategy-agreed 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  md_section_projection "$GOLDEN/snapshots/$snapshot/.calm/strategy.md" '### Thèse GTM' >"$TMP_ROOT/$snapshot-strategy-thesis"
  md_section_projection "$GOLDEN/snapshots/$snapshot/.calm/overview.md" '## Thèse GTM' >"$TMP_ROOT/$snapshot-overview-thesis"
  cmp -s "$TMP_ROOT/$snapshot-strategy-thesis" "$TMP_ROOT/$snapshot-overview-thesis" || fail "$snapshot overview paraphrased the strategy thesis"
done
pass "immutable 12-question strategy output"

csv_projection "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv" 1 6 2 >"$TMP_ROOT/actions"
if awk -F '\t' '
  NR == FNR { valid_question[$1] = 1; next }
  {
    if (seen_action[$1]++) bad = 1
    horizon[$3]++
    count = split($2, links, /\|/)
    for (i = 1; i <= count; i++) if (!valid_question[links[i]]) bad = 1
  }
  END {
    if (!horizon["Now"] || !horizon["Next"] || !horizon["Later"]) bad = 1
    for (value in horizon) if (horizon[value] > 3) bad = 1
    for (value in horizon) if (value != "Now" && value != "Next" && value != "Later") bad = 1
    exit bad
  }
' "$TMP_ROOT/canonical-questions" "$TMP_ROOT/actions"; then :; else fail "action IDs, horizons, three-action limit, or APOP links are invalid"; fi
cut -d, -f1 "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv" | sed -n '2,$p' | awk '
  { expected=sprintf("ACT-%03d", NR); if ($0 != expected) bad=1 }
  END { exit bad }
' || fail "golden action IDs are not monotonic and contiguous"
csv_projection "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv" 11 1 1 | awk -F '\t' '
  $1 !~ /^(Not started|In progress|Done|Blocked|Stopped)$/ { bad=1 }
  END { exit bad }
' || fail "action status is outside the five stable tokens"
for snapshot in 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  action_plan_md_projection "$GOLDEN/snapshots/$snapshot/.calm/action-plan.md" >"$TMP_ROOT/$snapshot-plan-md"
  csv_projection "$GOLDEN/snapshots/$snapshot/.calm/action-plan.csv" 4 5 7 8 9 10 11 >"$TMP_ROOT/$snapshot-plan-csv" || fail "$snapshot action CSV is invalid"
  cmp -s "$TMP_ROOT/$snapshot-plan-md" "$TMP_ROOT/$snapshot-plan-csv" || fail "$snapshot action Markdown and CSV rows differ"
  for horizon in Now Next Later; do
    assert_count "$GOLDEN/snapshots/$snapshot/.calm/action-plan.md" "## $horizon" 1
  done
done

tab=$(printf '\t')
for snapshot in 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  csv_projection "$GOLDEN/snapshots/$snapshot/.calm/action-plan.csv" 2 4 8 11 >"$TMP_ROOT/$snapshot-overview-actions"
  while IFS="$tab" read -r horizon action due status; do
    [ "$horizon" = Now ] || continue
    assert_contains "$GOLDEN/snapshots/$snapshot/.calm/overview.md" "| $action | $due | $status |"
  done <"$TMP_ROOT/$snapshot-overview-actions"
  action_objective=$(csv_projection "$GOLDEN/snapshots/$snapshot/.calm/action-plan.csv" 3 2 2 | sed -n '1p' | cut -f1)
  assert_contains "$GOLDEN/snapshots/$snapshot/.calm/overview.md" "Objectif : $action_objective"
done
assert_not_contains "$GOLDEN/snapshots/06-weekly/.calm/overview.md" 'Mesurer le délai sur au moins 20 interventions pilotes'

assert_file "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets/outreach-owner-v1.md"
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv" 'ACT-003'
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/action-plan.csv" 'PO2|PR1'
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets.csv" 'ASSET-001'
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets.csv" 'ACT-003'
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets.csv" '.calm/assets/outreach-owner-v1.md'
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets/outreach-owner-v1.md" '<!-- calm:asset-id=ASSET-001 -->'
assert_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets/outreach-owner-v1.md" '<!-- calm:linked-action-id=ACT-003 -->'
assert_not_contains "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets/outreach-owner-v1.md" 'Prompt:'
csv_projection "$GOLDEN/snapshots/05-plan-and-asset/.calm/assets.csv" 1 5 7 >"$TMP_ROOT/assets"
if awk -F '\t' '
  NR == FNR { valid_action[$1] = 1; next }
  {
    if (seen_asset[$1]++ || !valid_action[$2]) bad = 1
    if ($3 !~ /^(Draft|Final|Superseded)$/) bad = 1
  }
  END { exit bad }
' "$TMP_ROOT/actions" "$TMP_ROOT/assets"; then :; else fail "asset IDs or action links are invalid"; fi
pass "stable action IDs and finished asset traceability"

PROJECT_ASSET=$REPO_ROOT/tests/fixtures/project-asset
assert_contains "$PROJECT_ASSET/README.md" 'explicit, sufficiently'
assert_contains "$PROJECT_ASSET/README.md" 'Plan approval alone did not authorize'
assert_contains "$PROJECT_ASSET/.calm/action-plan.md" '<!-- calm:plan-status=agreed -->'
assert_contains "$PROJECT_ASSET/.calm/action-plan.csv" 'ACT-001,Now'
assert_contains "$PROJECT_ASSET/.calm/assets.csv" 'ASSET-001,FieldNote landing page'
assert_contains "$PROJECT_ASSET/.calm/assets.csv" 'ACT-001,site/index.html,Final'
assert_contains "$PROJECT_ASSET/.calm/assets/ASSET-001.md" '<!-- calm:asset-id=ASSET-001 -->'
assert_contains "$PROJECT_ASSET/.calm/assets/ASSET-001.md" '<!-- calm:linked-action-id=ACT-001 -->'
assert_contains "$PROJECT_ASSET/.calm/assets/ASSET-001.md" '`site/index.html`'
assert_contains "$PROJECT_ASSET/.calm/assets/ASSET-001.md" '`site/styles.css`'
assert_contains "$PROJECT_ASSET/.calm/assets/ASSET-001.md" '`tests/landing-page-smoke.sh`'
assert_file "$PROJECT_ASSET/site/index.html"
assert_file "$PROJECT_ASSET/site/styles.css"
assert_file "$PROJECT_ASSET/tests/landing-page-smoke.sh"
assert_not_contains "$PROJECT_ASSET/.calm/assets/ASSET-001.md" 'Prompt:'
(cd "$PROJECT_ASSET" && sh tests/landing-page-smoke.sh) || fail "multi-file project asset smoke test failed"
pass "agreed multi-file project asset is implemented, indexed, traced, and tested"

cmp -s "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.md" "$GOLDEN/snapshots/06-weekly/.calm/strategy.md" || fail "weak weekly signal rewrote strategy.md"
cmp -s "$GOLDEN/snapshots/04-strategy-agreed/.calm/strategy.csv" "$GOLDEN/snapshots/06-weekly/.calm/strategy.csv" || fail "weak weekly signal rewrote strategy.csv"
grep '^### ' "$GOLDEN/snapshots/06-weekly/.calm/weekly.md" >"$TMP_ROOT/weekly-headings"
printf '%s\n' '### 1. This week' '### 2. What it means' '### 3. APOP decision' '### 4. Decisions' '### 5. Next week' >"$TMP_ROOT/expected-weekly-headings"
cmp -s "$TMP_ROOT/expected-weekly-headings" "$TMP_ROOT/weekly-headings" || fail "weekly markdown does not have exactly the five fixed sections"
assert_contains "$GOLDEN/snapshots/06-weekly/.calm/weekly.md" '**Strategy changes:** None.'
assert_contains "$GOLDEN/snapshots/06-weekly/.calm/weekly.md" '12 messages'
assert_contains "$GOLDEN/snapshots/06-weekly/.calm/weekly.md" "aucun n'a accepté de pilote payant"
for action_id in ACT-001 ACT-002 ACT-004; do
  assert_contains "$GOLDEN/snapshots/06-weekly/.calm/weekly.csv" "$action_id"
  assert_contains "$GOLDEN/snapshots/06-weekly/.calm/action-plan.csv" "$action_id"
done
previous_sources="$GOLDEN/snapshots/01-initialized/.calm/sources.md"
for snapshot in 02-intake-complete 03-strategy-proposed 04-strategy-agreed 04a-plan-proposed 04b-plan-agreed 05-plan-and-asset 06-weekly 07-html-opt-in; do
  current_sources="$GOLDEN/snapshots/$snapshot/.calm/sources.md"
  source_size=$(wc -c < "$previous_sources" | tr -d ' ')
  head -c "$source_size" "$current_sources" >"$TMP_ROOT/source-prefix"
  cmp -s "$previous_sources" "$TMP_ROOT/source-prefix" || fail "$snapshot rewrote the append-only source log"
  previous_sources=$current_sources
done
assert_contains "$GOLDEN/snapshots/06-weekly/.calm/sources.md" '`fixtures/website.html`'
assert_contains "$GOLDEN/snapshots/06-weekly/.calm/sources.md" '`fixtures/pilot-notes.md`'
assert_not_contains "$GOLDEN/snapshots/06-weekly/.calm/sources.md" 'compte rendu hebdomadaire du fondateur'
assert_file "$REPO_ROOT/tests/semantic/weekly-strategy-change.md"
assert_contains "$REPO_ROOT/tests/semantic/weekly-strategy-change.md" '`PO1|PO2|OF3`'
assert_contains "$REPO_ROOT/tests/semantic/weekly-strategy-change.md" 'unique ISO-8601 `Period` later than the prior revision'
assert_file "$REPO_ROOT/tests/semantic/intake-acceptance.md"
assert_contains "$REPO_ROOT/tests/semantic/intake-acceptance.md" 'do not create `strategy.md`, a plan, an asset, or invented traction'
assert_contains "$REPO_ROOT/tests/semantic/intake-acceptance.md" 'propose exactly the 12 canonical APOP answers'
assert_contains "$REPO_ROOT/tests/semantic/intake-acceptance.md" 'never add a thirteenth strategy question'
csv_projection "$GOLDEN/snapshots/06-weekly/.calm/weekly.csv" 2 3 6 10 11 >"$TMP_ROOT/weekly-overview-fields"
IFS="$tab" read -r this_week what_matters apop_changes priority_ids one_thing_not_to_do <"$TMP_ROOT/weekly-overview-fields"
for weekly_value in "$this_week" "$what_matters" "$apop_changes" "$one_thing_not_to_do"; do
  assert_contains "$GOLDEN/snapshots/06-weekly/.calm/overview.md" "$weekly_value"
done
for action_id in ACT-001 ACT-002 ACT-004; do
  action_text=$(csv_projection "$GOLDEN/snapshots/06-weekly/.calm/action-plan.csv" 1 4 4 | awk -F '\t' -v wanted="$action_id" '$1 == wanted { print $2 }')
  assert_contains "$GOLDEN/snapshots/06-weekly/.calm/overview.md" "$action_id"
  assert_contains "$GOLDEN/snapshots/06-weekly/.calm/overview.md" "$action_text"
done
pass "five-section weekly behavior with stable strategy on weak evidence"

assert_not_file "$GOLDEN/snapshots/06-weekly/.calm/dashboard.html"
assert_file "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html"
assert_not_contains "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html" '<script'
if grep -Eq 'https?://' "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html"; then fail "golden dashboard contains a remote URL"; fi
assert_contains "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html" 'ASSET-001'
assert_contains "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html" 'ACT-003'
assert_contains "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html" 'Local derived view'
assert_contains "$GOLDEN/snapshots/07-html-opt-in/.calm/dashboard.html" '<pre>'
pass "local opt-in derived tracker boundaries"
