#!/usr/bin/env sh

set -e
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/calm-install-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/testlib.sh"
INSTALLER=$REPO_ROOT/scripts/install.sh

home_root=$TEST_DIR/home\ with\ spaces
project=$TEST_DIR/project\ with\ spaces
mkdir -p "$home_root/.claude" "$project"
cat >"$project/AGENTS.md" <<'EOF'
# Existing instructions

<!-- calm-gtm skill v1 -->
## Calm GTM
Read .agents/calm-gtm/SKILL.md.
<!-- calm-gtm skill v1 -->
EOF

CALM_GTM_HOME="$home_root" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$project" --agent none --no-start >"$TEST_DIR/install-1.log" 2>&1
assert_file "$home_root/.local/share/calm-gtm/releases/$CALM_TAG/.calm-gtm-manifest"
assert_contains "$TEST_DIR/install-1.log" 'Installed portable user skill'
assert_not_contains "$TEST_DIR/install-1.log" 'Installed Codex user skill'
[ -L "$home_root/.local/bin/calm" ] || fail "calm CLI link was not installed"
assert_file "$home_root/.agents/skills/calm-gtm/SKILL.md"
assert_file "$home_root/.agents/skills/calm-gtm/references/apop-questions.csv"
assert_file "$home_root/.claude/skills/calm-gtm/SKILL.md"
assert_file "$project/.agents/skills/calm-gtm/SKILL.md"
assert_file "$project/.agents/skills/calm-gtm/references/apop-questions.csv"
assert_file "$project/.calm/intake.md"
assert_count "$project/AGENTS.md" '<!-- BEGIN calm-gtm managed v2 -->' 1
assert_count "$project/AGENTS.md" '<!-- END calm-gtm managed v2 -->' 1
assert_not_contains "$project/AGENTS.md" '<!-- calm-gtm skill v1 -->'
assert_contains "$project/AGENTS.md" '# Existing instructions'

CALM_GTM_HOME="$home_root" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$project" --agent none --no-start >"$TEST_DIR/install-2.log" 2>&1
assert_count "$project/AGENTS.md" '<!-- BEGIN calm-gtm managed v2 -->' 1
assert_count "$project/AGENTS.md" '<!-- END calm-gtm managed v2 -->' 1
pass "virgin install, spaces, legacy migration, reinstall, and AGENTS idempotence"

relative_root=$TEST_DIR/relative-root
mkdir -p "$relative_root"
relative_root=$(CDPATH= cd -- "$relative_root" && pwd -P)
relative_home=$relative_root/relative\ home
relative_project=$relative_root/project
mkdir -p "$relative_project"
(
  cd "$relative_root"
  CALM_GTM_HOME='relative home' CALM_GTM_TELEMETRY=0 \
    "$INSTALLER" --project "$relative_project" --agent none --no-start >"$TEST_DIR/relative-home.log" 2>&1
)
[ -L "$relative_home/.local/bin/calm" ] || fail "relative CALM_GTM_HOME did not install the CLI link"
[ "$("$relative_home/.local/bin/calm" version)" = "$CALM_VERSION" ] || fail "relative CALM_GTM_HOME installed an unusable CLI"
[ "$(readlink "$relative_home/.local/share/calm-gtm/current")" = "$relative_home/.local/share/calm-gtm/releases/$CALM_TAG" ] || fail "relative CALM_GTM_HOME did not create an absolute current-release link"
assert_file "$relative_project/.calm/intake.md"
pass "relative CALM_GTM_HOME is normalized before installation"

discovery_home=$TEST_DIR/discovery-home
discovery_project=$TEST_DIR/discovery-project
mkdir -p \
  "$discovery_home/.codex/skills/calm-gtm" \
  "$discovery_home/.agents/skills/calm-gtm.backup.known" \
  "$discovery_project/.agents/calm-gtm"
printf '%s\n' 'legacy codex copy' >"$discovery_home/.codex/skills/calm-gtm/SKILL.md"
printf '%s\n' 'legacy backup copy' >"$discovery_home/.agents/skills/calm-gtm.backup.known/SKILL.md"
printf '%s\n' 'legacy project copy' >"$discovery_project/.agents/calm-gtm/SKILL.md"
CALM_GTM_HOME="$discovery_home" CALM_GTM_TELEMETRY=0 \
  "$INSTALLER" --project "$discovery_project" --agent none --no-start >"$TEST_DIR/discovery.log" 2>&1
assert_contains "$TEST_DIR/discovery.log" 'Legacy discoverable Calm GTM copy was preserved'
assert_contains "$TEST_DIR/discovery.log" 'Legacy discoverable Calm GTM backup was preserved'
assert_contains "$TEST_DIR/discovery.log" 'Move it outside agent skill directories to avoid ambiguous skill selection.'
assert_contains "$discovery_home/.codex/skills/calm-gtm/SKILL.md" 'legacy codex copy'
assert_contains "$discovery_home/.agents/skills/calm-gtm.backup.known/SKILL.md" 'legacy backup copy'
assert_contains "$discovery_project/.agents/calm-gtm/SKILL.md" 'legacy project copy'
assert_file "$discovery_project/.agents/skills/calm-gtm/SKILL.md"
pass "legacy discoverable skill copies are preserved and reported clearly"

if command -v git >/dev/null 2>&1; then
  legacy_home=$TEST_DIR/legacy-home
  legacy_project=$TEST_DIR/legacy-project
  legacy_target=$legacy_project/.agents/skills/calm-gtm
  mkdir -p "$legacy_home" "$legacy_target"
  LC_ALL=C git -C "$REPO_ROOT" archive v1.1.0 SKILL.md references | LC_ALL=C tar -x -C "$legacy_target"
  CALM_GTM_HOME="$legacy_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$legacy_project" --agent none --no-start >"$TEST_DIR/legacy-skill.log" 2>&1
  assert_contains "$TEST_DIR/legacy-skill.log" 'Recognized unchanged v1.1.0 project skill; upgrading safely'
  assert_file "$legacy_target/.calm-gtm-manifest"
  assert_file "$legacy_target/references/local-tracker.md"
  assert_file "$legacy_target/references/apop-questions.csv"
  pass "unchanged v1.1.0 skill upgrades without treating it as a local fork"
else
  printf '%s\n' 'SKIP: v1.1.0 archive migration fixture requires git'
fi

printf '\nlocal founder note\n' >>"$project/.agents/skills/calm-gtm/SKILL.md"
CALM_GTM_HOME="$home_root" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$project" --agent none --no-start >"$TEST_DIR/conflict.log" 2>&1
assert_contains "$project/.agents/skills/calm-gtm/SKILL.md" 'local founder note'
assert_contains "$TEST_DIR/conflict.log" 'contains local changes; left unchanged'
pass "divergent project skill is preserved"

upgrade_source=$TEST_DIR/upgrade-source
mkdir -p "$upgrade_source"
cp -R "$REPO_ROOT/VERSION" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/bin" "$REPO_ROOT/lib" "$REPO_ROOT/references" "$REPO_ROOT/scripts" "$REPO_ROOT/migrations" "$upgrade_source/"
printf '%s\n' "$CALM_NEXT_VERSION" >"$upgrade_source/VERSION"
printf '\n<!-- upgrade fixture -->\n' >>"$upgrade_source/SKILL.md"
upgrade_home=$TEST_DIR/upgrade-home
upgrade_project=$TEST_DIR/upgrade-project
mkdir -p "$upgrade_home" "$upgrade_project"
CALM_GTM_HOME="$upgrade_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$upgrade_project" --agent none --no-start >/dev/null 2>&1
CALM_GTM_HOME="$upgrade_home" CALM_GTM_TELEMETRY=0 "$upgrade_source/scripts/install.sh" --project "$upgrade_project" --agent none --no-start >/dev/null 2>&1
assert_file "$upgrade_home/.local/share/calm-gtm/releases/$CALM_NEXT_TAG/.calm-gtm-manifest"
assert_contains "$upgrade_project/.agents/skills/calm-gtm/SKILL.md" '<!-- upgrade fixture -->'
[ "$(readlink "$upgrade_home/.local/share/calm-gtm/current")" = "$upgrade_home/.local/share/calm-gtm/releases/$CALM_NEXT_TAG" ] || fail "current release was not upgraded"
pass "safe version upgrade"

if command -v git >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse -q --verify 'refs/tags/v1.2.1' >/dev/null; then
  published_source=$TEST_DIR/published-v1.2.1
  published_home=$TEST_DIR/published-upgrade-home
  published_project=$TEST_DIR/published-upgrade-project
  mkdir -p "$published_source" "$published_home" "$published_project"
  LC_ALL=C git -C "$REPO_ROOT" archive v1.2.1 | LC_ALL=C tar -x -C "$published_source"
  CALM_GTM_HOME="$published_home" CALM_GTM_TELEMETRY=0 \
    "$published_source/scripts/install.sh" --project "$published_project" --agent none --no-start >/dev/null 2>&1
  [ "$("$published_home/.local/bin/calm" version)" = '1.2.1' ] || fail "published upgrade fixture did not install v1.2.1"
  CALM_GTM_HOME="$published_home" CALM_GTM_TELEMETRY=0 \
    "$INSTALLER" --project "$published_project" --agent none --no-start >/dev/null 2>&1
  [ "$("$published_home/.local/bin/calm" version)" = "$CALM_VERSION" ] || fail "published v1.2.1 installation did not upgrade to $CALM_VERSION"
  assert_file "$published_home/.local/share/calm-gtm/releases/$CALM_TAG/.calm-gtm-manifest"
  assert_file "$published_project/.agents/skills/calm-gtm/references/apop-questions.csv"
  pass "published v1.2.1 installation upgrades safely to the current source"
else
  printf '%s\n' 'SKIP: published v1.2.1 upgrade fixture requires its Git tag'
fi

stale_home=$TEST_DIR/stale-home
stale_project=$TEST_DIR/stale-project
stale_target=$stale_project/.agents/skills/calm-gtm
mkdir -p "$stale_home" "$stale_project"
CALM_GTM_HOME="$stale_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$stale_project" --agent none --no-start >/dev/null 2>&1
printf '%s\n' 'obsolete managed reference' >"$stale_target/references/obsolete.md"
(
  cd "$stale_target"
  find SKILL.md references -type f -print | LC_ALL=C sort | while IFS= read -r managed_file; do cksum "$managed_file"; done
) >"$stale_target/.calm-gtm-manifest"
CALM_GTM_HOME="$stale_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$stale_project" --agent none --no-start >/dev/null 2>&1
assert_not_file "$stale_target/references/obsolete.md"
assert_file "$stale_target/references/local-tracker.md"
pass "obsolete unchanged managed references are pruned during a safe upgrade"

changed_home=$TEST_DIR/changed-home
changed_project=$TEST_DIR/changed-project
mkdir -p "$changed_home" "$changed_project"
CALM_GTM_HOME="$changed_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$changed_project" --agent none --no-start >/dev/null 2>&1
printf '\nlocal change\n' >>"$changed_home/.local/share/calm-gtm/releases/$CALM_TAG/bin/calm"
if CALM_GTM_HOME="$changed_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$changed_project" --agent none --no-start >"$TEST_DIR/release-conflict.log" 2>&1; then
  fail "modified CLI release was silently overwritten"
fi
assert_contains "$TEST_DIR/release-conflict.log" 'existing release has local changes; refusing to overwrite'
pass "divergent CLI release fails safely"

foreign_home=$TEST_DIR/foreign-home
foreign_project=$TEST_DIR/foreign-project
mkdir -p "$foreign_home/.local/share/calm-gtm" "$foreign_home/.local/bin" "$foreign_project" "$TEST_DIR/unrelated"
ln -s "$TEST_DIR/unrelated" "$foreign_home/.local/share/calm-gtm/current"
if CALM_GTM_HOME="$foreign_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$foreign_project" --agent none --no-start >"$TEST_DIR/foreign-link.log" 2>&1; then
  fail "foreign current symlink was silently replaced"
fi
[ "$(readlink "$foreign_home/.local/share/calm-gtm/current")" = "$TEST_DIR/unrelated" ] || fail "foreign current symlink target changed"
assert_contains "$TEST_DIR/foreign-link.log" 'current release symlink'
pass "foreign symlink is preserved"

traversal_home=$TEST_DIR/traversal-home
traversal_project=$TEST_DIR/traversal-project
traversal_releases=$traversal_home/.local/share/calm-gtm/releases
traversal_target=$traversal_home/.local/share/outside
mkdir -p "$traversal_releases" "$traversal_target" "$traversal_project"
traversal_link=$traversal_releases/../../outside
ln -s "$traversal_link" "$traversal_home/.local/share/calm-gtm/current"
if CALM_GTM_HOME="$traversal_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$traversal_project" --agent none --no-start >"$TEST_DIR/traversal-link.log" 2>&1; then
  fail "path-traversing current symlink was accepted as managed"
fi
assert_contains "$TEST_DIR/traversal-link.log" 'current release symlink points outside Calm GTM'
[ "$(readlink "$traversal_home/.local/share/calm-gtm/current")" = "$traversal_link" ] || fail "path-traversing symlink was changed"
pass "path-traversing release symlink is rejected"

foreign_bin_home=$TEST_DIR/foreign-bin-home
foreign_bin_project=$TEST_DIR/foreign-bin-project
mkdir -p "$foreign_bin_home/.local/bin" "$foreign_bin_project"
printf '%s\n' 'unrelated executable' >"$foreign_bin_home/.local/bin/calm"
if CALM_GTM_HOME="$foreign_bin_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$foreign_bin_project" --agent none --no-start >"$TEST_DIR/foreign-bin.log" 2>&1; then
  fail "foreign CLI file was silently replaced"
fi
assert_contains "$TEST_DIR/foreign-bin.log" 'CLI path already contains a non-symlink file; refusing to overwrite'
assert_not_file "$foreign_bin_project/.calm/intake.md"
[ ! -e "$foreign_bin_home/.local/share/calm-gtm/current" ] || fail "failed foreign-bin preflight changed the active release"
assert_contains "$foreign_bin_home/.local/bin/calm" 'unrelated executable'
pass "foreign CLI path fails before changing the active release or project"

invalid_home=$TEST_DIR/not-a-directory
invalid_home_project=$TEST_DIR/invalid-home-project
printf '%s\n' 'file, not directory' >"$invalid_home"
mkdir -p "$invalid_home_project"
if CALM_GTM_HOME="$invalid_home" CALM_GTM_TELEMETRY=0 "$INSTALLER" --project "$invalid_home_project" --agent none --no-start >"$TEST_DIR/invalid-home.log" 2>&1; then
  fail "non-directory installation root unexpectedly succeeded"
fi
assert_contains "$TEST_DIR/invalid-home.log" 'installation root is not a directory'
assert_not_file "$invalid_home_project/.calm/intake.md"
pass "invalid installation root fails proportionately before project mutation"

permission_home=$TEST_DIR/permission-home
permission_project=$TEST_DIR/permission-project
permission_bin=$TEST_DIR/permission-bin
mkdir -p "$permission_home" "$permission_project" "$permission_bin"
cat >"$permission_bin/mkdir" <<'EOF'
#!/bin/sh
echo "simulated permission denied" >&2
exit 1
EOF
chmod +x "$permission_bin/mkdir"
if PATH="$permission_bin:/usr/bin:/bin" CALM_GTM_HOME="$permission_home" CALM_GTM_TELEMETRY=0 \
  "$INSTALLER" --project "$permission_project" --agent none --no-start >"$TEST_DIR/permission.log" 2>&1; then
  fail "simulated installation permission failure unexpectedly succeeded"
fi
assert_contains "$TEST_DIR/permission.log" 'could not create installation directories'
assert_not_file "$permission_project/.calm/intake.md"
pass "installation permission failure is clear and leaves the project untouched"

telemetry_home=$TEST_DIR/telemetry-home
telemetry_project=$TEST_DIR/telemetry-project
telemetry_bin=$TEST_DIR/telemetry-bin
mkdir -p "$telemetry_home" "$telemetry_project" "$telemetry_bin"
cat >"$telemetry_bin/curl" <<'EOF'
#!/bin/sh
printf 'called\n' >"$CALM_TELEMETRY_CAPTURE"
exit 0
EOF
chmod +x "$telemetry_bin/curl"
PATH="$telemetry_bin:/usr/bin:/bin" CALM_TELEMETRY_CAPTURE="$TEST_DIR/telemetry-called" \
  CALM_GTM_HOME="$telemetry_home" CALM_GTM_TELEMETRY=0 \
  "$INSTALLER" --project "$telemetry_project" --agent none --no-start >/dev/null 2>&1
assert_not_file "$TEST_DIR/telemetry-called"
pass "CALM_GTM_TELEMETRY=0 prevents the network event"

telemetry_enabled_home=$TEST_DIR/telemetry-enabled-home
telemetry_enabled_project=$TEST_DIR/telemetry-enabled-project
telemetry_enabled_bin=$TEST_DIR/telemetry-enabled-bin
mkdir -p "$telemetry_enabled_home" "$telemetry_enabled_project" "$telemetry_enabled_bin"
cat >"$telemetry_enabled_bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$CALM_TELEMETRY_CAPTURE"
exit 0
EOF
chmod +x "$telemetry_enabled_bin/curl"
PATH="$telemetry_enabled_bin:/usr/bin:/bin" CALM_TELEMETRY_CAPTURE="$TEST_DIR/telemetry-payload" \
  CALM_GTM_HOME="$telemetry_enabled_home" \
  "$INSTALLER" --project "$telemetry_enabled_project" --agent none --no-start >/dev/null 2>&1
assert_contains "$TEST_DIR/telemetry-payload" '"project"'
assert_contains "$TEST_DIR/telemetry-payload" '"agents"'
assert_not_contains "$TEST_DIR/telemetry-payload" '"codex"'
assert_not_contains "$TEST_DIR/telemetry-payload" '"cli"'
pass "telemetry targets match the public API contract"

partial=$TEST_DIR/partial-release
partial_home=$TEST_DIR/partial-home
partial_project=$TEST_DIR/partial-project
mkdir -p "$partial/scripts" "$partial/bin" "$partial_home" "$partial_project"
cp "$INSTALLER" "$partial/scripts/install.sh"
cp "$REPO_ROOT/SKILL.md" "$partial/SKILL.md"
cp "$REPO_ROOT/bin/calm" "$partial/bin/calm"
if CALM_GTM_HOME="$partial_home" CALM_GTM_TELEMETRY=0 \
  "$partial/scripts/install.sh" --project "$partial_project" --agent none --no-start >"$TEST_DIR/partial.log" 2>&1; then
  fail "incomplete local release unexpectedly installed"
fi
assert_contains "$TEST_DIR/partial.log" 'local release package is incomplete; no project or user files were changed'
assert_not_file "$partial_project/AGENTS.md"
assert_not_file "$partial_project/.calm/intake.md"
[ -z "$(find "$partial_home" -mindepth 1 -print -quit)" ] || fail "incomplete release mutated the installation root"
pass "incomplete local release fails before user or project mutation"

for missing_runtime in \
  lib/calm/csv.awk \
  lib/calm/csv_validate.awk \
  lib/calm/action_rows.awk \
  lib/calm/assets_rows.awk \
  lib/calm/weekly_overview.awk
do
  runtime_name=$(printf '%s\n' "$missing_runtime" | tr '/.' '--')
  runtime_source=$TEST_DIR/runtime-missing-$runtime_name
  runtime_home=$TEST_DIR/runtime-home-$runtime_name
  runtime_project=$TEST_DIR/runtime-project-$runtime_name
  mkdir -p "$runtime_source" "$runtime_home" "$runtime_project"
  cp -R "$REPO_ROOT/VERSION" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/bin" "$REPO_ROOT/lib" "$REPO_ROOT/references" "$REPO_ROOT/scripts" "$REPO_ROOT/migrations" "$runtime_source/"
  rm -f "$runtime_source/$missing_runtime"
  if CALM_GTM_HOME="$runtime_home" CALM_GTM_TELEMETRY=0 \
    "$runtime_source/scripts/install.sh" --project "$runtime_project" --agent none --no-start >"$TEST_DIR/runtime-$runtime_name.log" 2>&1; then
    fail "release missing $missing_runtime unexpectedly installed"
  fi
  assert_contains "$TEST_DIR/runtime-$runtime_name.log" 'local release package is incomplete; no project or user files were changed'
  assert_not_file "$runtime_project/AGENTS.md"
  assert_not_file "$runtime_project/.calm/intake.md"
  [ -z "$(find "$runtime_home" -mindepth 1 -print -quit)" ] || fail "release missing $missing_runtime mutated the installation root"
done
pass "every runtime renderer is required before installation mutates user or project files"

standalone=$TEST_DIR/standalone
mkdir -p "$standalone/scripts" "$standalone/fake-bin" "$standalone/project" "$standalone/home"
cp "$INSTALLER" "$standalone/scripts/install.sh"
cat >"$standalone/fake-bin/curl" <<'EOF'
#!/bin/sh
exit 22
EOF
chmod +x "$standalone/fake-bin/curl"
if PATH="$standalone/fake-bin:/usr/bin:/bin" CALM_GTM_HOME="$standalone/home" CALM_GTM_TELEMETRY=0 \
  "$standalone/scripts/install.sh" --project "$standalone/project" --no-start >"$TEST_DIR/network.log" 2>&1; then
  fail "network failure unexpectedly succeeded"
fi
assert_contains "$TEST_DIR/network.log" 'download failed; no project or user files were changed'
assert_not_file "$standalone/project/AGENTS.md"
assert_not_file "$standalone/project/.calm/intake.md"
pass "network failure is proportional and leaves the project untouched"
