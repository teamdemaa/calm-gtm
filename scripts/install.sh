#!/usr/bin/env sh

# Calm GTM installer for macOS, Linux, and WSL. It installs the local CLI,
# portable project instructions, and supported agent-native skill copies.
# Divergent local content is never overwritten.

set -e

SKILL_NAME=calm-gtm
REPO_URL=https://github.com/teamdemaa/calm-gtm
RELEASE_VERSION=v1.2.0
HOME_ROOT=${CALM_GTM_HOME:-${HOME:-}}
PROJECT_ARG=$PWD
NO_START=0
AGENT=auto
INSTALLED_TARGETS=
CONFLICTS=0

fail() { echo "calm-gtm installer: $*" >&2; exit 1; }
note() { echo "$*"; }
record_target() {
  if [ -z "$INSTALLED_TARGETS" ]; then INSTALLED_TARGETS=$1; else INSTALLED_TARGETS=$INSTALLED_TARGETS,$1; fi
}
usage() {
  cat <<'EOF'
Usage: install.sh [--project DIR] [--agent auto|codex|claude|none] [--no-start]

Environment:
  CALM_GTM_HOME          Alternate user-home root for installed files.
  CALM_GTM_TELEMETRY=0   Disable the anonymous completed-run event.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project) [ "$#" -ge 2 ] || fail "--project requires a directory"; PROJECT_ARG=$2; shift 2 ;;
    --agent) [ "$#" -ge 2 ] || fail "--agent requires auto, codex, claude, or none"; AGENT=$2; shift 2 ;;
    --no-start) NO_START=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
case "$AGENT" in auto|codex|claude|none) ;; *) fail "invalid agent: $AGENT" ;; esac
[ -n "$HOME_ROOT" ] || fail "HOME is not set; set CALM_GTM_HOME to an installation root"
[ ! -e "$HOME_ROOT" ] || [ -d "$HOME_ROOT" ] || fail "installation root is not a directory: $HOME_ROOT"
[ -d "$PROJECT_ARG" ] || fail "project directory does not exist: $PROJECT_ARG"
PROJECT_ROOT=$(CDPATH= cd -- "$PROJECT_ARG" && pwd)

case "$0" in
  */*) SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true) ;;
  *) SCRIPT_DIR= ;;
esac
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/calm-gtm-work.XXXXXX") || fail "could not create a temporary directory"
TMP_DIR=
STAGE_DIR=
cleanup() {
  if [ -n "$STAGE_DIR" ] && [ -d "$STAGE_DIR" ]; then rm -rf "$STAGE_DIR"; fi
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi
  if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then rm -rf "$WORK_DIR"; fi
}
trap cleanup EXIT HUP INT TERM

source_package_is_complete() {
  candidate=$1
  for required_file in \
    VERSION \
    SKILL.md \
    bin/calm \
    lib/calm/common.sh \
    lib/calm/status.sh \
    lib/calm/init.sh \
    lib/calm/adapter.sh \
    references/apop-questions.csv \
    references/apop-strategy.md \
    references/action-plan.md \
    references/assets.md \
    references/weekly-update.md \
    references/local-tracker.md \
    migrations/v1.1.0-skill.manifest
  do
    [ -f "$candidate/$required_file" ] || return 1
  done
}

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../SKILL.md" ] && [ -f "$SCRIPT_DIR/../bin/calm" ]; then
  SRC_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
  source_package_is_complete "$SRC_DIR" || fail "local release package is incomplete; no project or user files were changed"
  if [ -f "$SRC_DIR/VERSION" ]; then RELEASE_VERSION=v$(sed -n '1p' "$SRC_DIR/VERSION" | sed 's/^v//'); fi
else
  command -v curl >/dev/null 2>&1 || fail "curl is required for a network installation"
  command -v tar >/dev/null 2>&1 || fail "tar is required for a network installation"
  TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/calm-gtm-install.XXXXXX") || fail "could not create a temporary directory"
  note "Downloading calm-gtm $RELEASE_VERSION..."
  archive=$TMP_DIR/calm-gtm.tar.gz
  if ! curl -fsSL --max-time 30 "$REPO_URL/archive/refs/tags/$RELEASE_VERSION.tar.gz" -o "$archive"; then
    fail "download failed; no project or user files were changed"
  fi
  if ! tar -xzf "$archive" -C "$TMP_DIR"; then fail "downloaded archive is invalid; no project or user files were changed"; fi
  SRC_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d -name 'calm-gtm-*' | sed -n '1p')
  [ -n "$SRC_DIR" ] && source_package_is_complete "$SRC_DIR" || fail "downloaded release is incomplete; no project or user files were changed"
fi

make_manifest() {
  source_dir=$1; selection=$2; output=$3
  paths_file=$output.paths
  sorted_paths=$output.sorted
  if ! (
    cd "$source_dir" || exit 1
    if [ "$selection" = package ]; then
      find VERSION bin lib SKILL.md references -type f -print
    else
      find SKILL.md references -type f -print
    fi
  ) >"$paths_file"; then
    rm -f "$paths_file" "$sorted_paths" "$output"
    return 1
  fi
  LC_ALL=C sort "$paths_file" >"$sorted_paths" || { rm -f "$paths_file" "$sorted_paths" "$output"; return 1; }
  if ! (
    cd "$source_dir" || exit 1
    while IFS= read -r managed_file; do cksum "$managed_file" || exit 1; done <"$sorted_paths"
  ) >"$output"; then
    rm -f "$paths_file" "$sorted_paths" "$output"
    return 1
  fi
  rm -f "$paths_file" "$sorted_paths"
}
verify_manifest() {
  target_dir=$1; selection=$2; expected=$3
  actual=$WORK_DIR/manifest.actual
  if ! make_manifest "$target_dir" "$selection" "$actual" 2>/dev/null; then rm -f "$actual"; return 1; fi
  if cmp -s "$actual" "$expected"; then rm -f "$actual"; return 0; fi
  rm -f "$actual"; return 1
}

PACKAGE_MANIFEST=$WORK_DIR/package.manifest
SKILL_MANIFEST=$WORK_DIR/skill.manifest
make_manifest "$SRC_DIR" package "$PACKAGE_MANIFEST"
make_manifest "$SRC_DIR" skill "$SKILL_MANIFEST"

SHARE_ROOT=$HOME_ROOT/.local/share/calm-gtm
RELEASES_DIR=$SHARE_ROOT/releases
RELEASE_DIR=$RELEASES_DIR/$RELEASE_VERSION
CURRENT_LINK=$SHARE_ROOT/current
BIN_DIR=$HOME_ROOT/.local/bin
BIN_LINK=$BIN_DIR/calm

preflight_release_links() {
  if [ -L "$CURRENT_LINK" ]; then
    existing_current=$(readlink "$CURRENT_LINK")
    resolved_current=$(CDPATH= cd -- "$existing_current" 2>/dev/null && pwd || true)
    resolved_releases=$(CDPATH= cd -- "$RELEASES_DIR" 2>/dev/null && pwd || true)
    [ -n "$resolved_releases" ] || fail "current release symlink exists without a managed releases directory: $CURRENT_LINK"
    case "$resolved_current" in
      "$resolved_releases"/*) ;;
      *) fail "current release symlink points outside Calm GTM; refusing to overwrite: $CURRENT_LINK" ;;
    esac
  elif [ -e "$CURRENT_LINK" ]; then
    fail "current release path is not a managed symlink: $CURRENT_LINK"
  fi

  if [ -L "$BIN_LINK" ]; then
    existing_bin=$(readlink "$BIN_LINK")
    [ "$existing_bin" = "$CURRENT_LINK/bin/calm" ] || fail "CLI symlink is not managed by Calm GTM; refusing to overwrite: $BIN_LINK"
  elif [ -e "$BIN_LINK" ]; then
    fail "CLI path already contains a non-symlink file; refusing to overwrite: $BIN_LINK"
  fi
}

install_release() {
  preflight_release_links
  mkdir -p "$RELEASES_DIR" "$BIN_DIR" || fail "could not create installation directories under $HOME_ROOT"
  if [ -d "$RELEASE_DIR" ]; then
    installed_manifest=$RELEASE_DIR/.calm-gtm-manifest
    if [ ! -f "$installed_manifest" ] || ! verify_manifest "$RELEASE_DIR" package "$installed_manifest"; then
      fail "existing release has local changes; refusing to overwrite: $RELEASE_DIR"
    fi
    if ! cmp -s "$installed_manifest" "$PACKAGE_MANIFEST"; then
      fail "release $RELEASE_VERSION already exists with different source content; choose a new version"
    fi
    note "CLI release already installed and unchanged -> $RELEASE_DIR"
  elif [ -e "$RELEASE_DIR" ] || [ -L "$RELEASE_DIR" ]; then
    fail "release path exists but is not a directory: $RELEASE_DIR"
  else
    STAGE_DIR=$(mktemp -d "$RELEASES_DIR/.stage.XXXXXX") || fail "could not stage CLI release"
    cp -R "$SRC_DIR/VERSION" "$SRC_DIR/bin" "$SRC_DIR/lib" "$SRC_DIR/SKILL.md" "$SRC_DIR/references" "$STAGE_DIR/"
    cp "$PACKAGE_MANIFEST" "$STAGE_DIR/.calm-gtm-manifest"
    mv "$STAGE_DIR" "$RELEASE_DIR"
    STAGE_DIR=
    note "Installed CLI release -> $RELEASE_DIR"
  fi
  ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"
  ln -sfn "$CURRENT_LINK/bin/calm" "$BIN_LINK"
  chmod +x "$RELEASE_DIR/bin/calm"
}

prune_removed_managed_skill_files() {
  target_dir=$1
  previous_manifest=$2
  [ -f "$previous_manifest" ] || return 0
  while IFS= read -r manifest_line; do
    managed_file=$(printf '%s\n' "$manifest_line" | sed 's/^[0-9][0-9]*[[:space:]][0-9][0-9]*[[:space:]]//')
    case "$managed_file" in
      SKILL.md|references/*) ;;
      *) continue ;;
    esac
    if ! awk -v wanted="$managed_file" '
      { checksum=$1; size=$2; $1=""; $2=""; sub(/^[[:space:]]+/, ""); if ($0 == wanted) found=1 }
      END { exit !found }
    ' "$SKILL_MANIFEST"; then
      [ -f "$target_dir/$managed_file" ] && rm -f "$target_dir/$managed_file"
    fi
  done <"$previous_manifest"
}

install_skill() {
  target_dir=$1; label=$2; target_name=$3
  target_manifest=$target_dir/.calm-gtm-manifest
  previous_manifest=
  if [ -d "$target_dir" ]; then
    if [ -f "$target_manifest" ]; then
      if ! verify_manifest "$target_dir" skill "$target_manifest"; then
        note "Conflict: $label contains local changes; left unchanged -> $target_dir" >&2
        CONFLICTS=$((CONFLICTS + 1)); return 0
      fi
      previous_manifest=$target_manifest
    elif [ -f "$SRC_DIR/migrations/v1.1.0-skill.manifest" ] && verify_manifest "$target_dir" skill "$SRC_DIR/migrations/v1.1.0-skill.manifest"; then
      note "Recognized unchanged v1.1.0 $label skill; upgrading safely -> $target_dir"
      previous_manifest=$SRC_DIR/migrations/v1.1.0-skill.manifest
    elif verify_manifest "$target_dir" skill "$SKILL_MANIFEST"; then
      cp "$SKILL_MANIFEST" "$target_manifest"
      previous_manifest=$target_manifest
    else
      note "Conflict: unmanaged $label skill already exists; left unchanged -> $target_dir" >&2
      CONFLICTS=$((CONFLICTS + 1)); return 0
    fi
  elif [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
    note "Conflict: $label target is not a directory; left unchanged -> $target_dir" >&2
    CONFLICTS=$((CONFLICTS + 1)); return 0
  else
    mkdir -p "$target_dir"
  fi
  prune_removed_managed_skill_files "$target_dir" "$previous_manifest"
  cp "$SRC_DIR/SKILL.md" "$target_dir/SKILL.md"
  mkdir -p "$target_dir/references"
  for reference_file in "$SRC_DIR"/references/*; do
    [ -f "$reference_file" ] && cp "$reference_file" "$target_dir/references/"
  done
  cp "$SKILL_MANIFEST" "$target_manifest"
  note "Installed $label skill -> $target_dir"
  record_target "$target_name"
}

write_agents_block() {
  cat >"$1" <<'EOF'
<!-- BEGIN calm-gtm managed v2 -->
## Calm GTM
Read .agents/skills/calm-gtm/SKILL.md and follow it whenever the user asks
about go-to-market strategy, positioning, ICP, an action plan,
marketing/sales assets, or a weekly GTM review. Load the matching reference
only when producing that output, as SKILL.md directs.
<!-- END calm-gtm managed v2 -->
EOF
}
install_agents_pointer() {
  agents_file=$PROJECT_ROOT/AGENTS.md
  block_file=$WORK_DIR/agents-block
  write_agents_block "$block_file"
  begin='<!-- BEGIN calm-gtm managed v2 -->'; end='<!-- END calm-gtm managed v2 -->'; legacy='<!-- calm-gtm skill v1 -->'
  if [ ! -f "$agents_file" ]; then cp "$block_file" "$agents_file"; note "Created $agents_file"; return; fi
  begin_count=$(grep -cF "$begin" "$agents_file" 2>/dev/null || true)
  end_count=$(grep -cF "$end" "$agents_file" 2>/dev/null || true)
  legacy_count=$(grep -cF "$legacy" "$agents_file" 2>/dev/null || true)
  if [ "$begin_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
    note "AGENTS.md already references Calm GTM -> $agents_file"
  elif [ "$begin_count" -ne 0 ] || [ "$end_count" -ne 0 ]; then
    note "Conflict: malformed Calm GTM markers in $agents_file; left unchanged" >&2; CONFLICTS=$((CONFLICTS + 1))
  elif [ "$legacy_count" -eq 2 ]; then
    rewritten=$WORK_DIR/agents-rewritten
    awk -v marker="$legacy" -v block="$block_file" '
      $0 == marker {
        if (!skipping) { while ((getline line < block) > 0) print line; close(block); skipping=1 }
        else { skipping=0 }
        next
      }
      !skipping { print }
    ' "$agents_file" >"$rewritten"
    mv "$rewritten" "$agents_file"
    note "Migrated the Calm GTM block in $agents_file"
  elif [ "$legacy_count" -ne 0 ]; then
    note "Conflict: malformed legacy Calm GTM marker in $agents_file; left unchanged" >&2; CONFLICTS=$((CONFLICTS + 1))
  else
    { printf '\n'; cat "$block_file"; } >>"$agents_file"
    note "Added Calm GTM to $agents_file"
  fi
}

install_release
install_skill "$HOME_ROOT/.agents/skills/$SKILL_NAME" "Codex user" codex
install_skill "$PROJECT_ROOT/.agents/skills/$SKILL_NAME" "project" project
if [ -d "$HOME_ROOT/.claude" ] || command -v claude >/dev/null 2>&1; then
  install_skill "$HOME_ROOT/.claude/skills/$SKILL_NAME" "Claude Code user" claude
fi
install_agents_pointer

if [ "${CALM_GTM_TELEMETRY:-1}" != 0 ] && [ -n "$INSTALLED_TARGETS" ]; then
  targets_json=$(printf '%s' "$INSTALLED_TARGETS" | sed 's/[^,]*/"&"/g')
  curl -fsS --max-time 2 -X POST -H 'Content-Type: application/json' \
    --data "{\"version\":\"$RELEASE_VERSION\",\"targets\":[$targets_json]}" \
    'https://calmgtm.com/api/install-event' >/dev/null 2>&1 || true
fi

note "calm-gtm $RELEASE_VERSION installation complete."
case :$PATH: in *:"$BIN_DIR":*) ;; *) note "Add $BIN_DIR to PATH to run calm from any directory." ;; esac
if [ "$CONFLICTS" -gt 0 ]; then note "$CONFLICTS local conflict(s) were preserved. Review them before relying on every adapter." >&2; fi
if [ "$NO_START" = 1 ]; then
  "$BIN_LINK" init --project "$PROJECT_ROOT" --agent "$AGENT" --no-start
else
  note "Starting Calm in this terminal. A compatible coding-agent CLI may continue the conversation automatically; otherwise Calm will print a handoff."
  "$BIN_LINK" init --project "$PROJECT_ROOT" --agent "$AGENT"
fi
