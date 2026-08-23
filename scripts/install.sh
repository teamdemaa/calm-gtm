#!/usr/bin/env sh

# Calm skills installer for macOS, Linux, and WSL. It installs the Calm CLI,
# explicitly selected skill bundles, portable project instructions, and
# supported agent-native copies. Divergent local content is never overwritten.

set -e

SKILL_NAME=calm-gtm
REPO_URL=https://github.com/teamdemaa/calm-gtm
RELEASE_VERSION=v1.3.0
HOME_ROOT=${CALM_GTM_HOME:-${HOME:-}}
PROJECT_ARG=$PWD
NO_START=0
AGENT=auto
REQUESTED_SKILLS=
ALL_SKILLS=0
REQUESTED_TARGETS=
TARGETS_EXPLICIT=0
INSTALLED_TARGETS=
CONFLICTS=0

fail() { echo "calm-gtm installer: $*" >&2; exit 1; }
note() { echo "$*"; }
record_target() {
  case ",$INSTALLED_TARGETS," in *,$1,*) ;; *)
    if [ -z "$INSTALLED_TARGETS" ]; then INSTALLED_TARGETS=$1; else INSTALLED_TARGETS=$INSTALLED_TARGETS,$1; fi
  esac
}
append_csv() {
  current=$1; value=$2
  if [ -z "$current" ]; then printf '%s\n' "$value"; else printf '%s,%s\n' "$current" "$value"; fi
}
usage() {
  cat <<'EOF'
Usage: install.sh [--project DIR] [--agent auto|codex|claude|none]
                  [--skill NAME ... | --all-skills]
                  [--target agents|codex|claude|all ...] [--no-start]

Skills:
  With no skill option, install only the default calm-gtm skill.
  --skill may be repeated. Add-ons are always opt-in.

Targets:
  With no target option, install the portable .agents copies and add Claude
  when detected. --target may be repeated; all selects every target.

Environment:
  CALM_GTM_HOME          Alternate user-home root for installed files.
  CALM_GTM_TELEMETRY=0   Disable the anonymous completed-run event.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project) [ "$#" -ge 2 ] || fail "--project requires a directory"; PROJECT_ARG=$2; shift 2 ;;
    --agent) [ "$#" -ge 2 ] || fail "--agent requires auto, codex, claude, or none"; AGENT=$2; shift 2 ;;
    --skill)
      [ "$#" -ge 2 ] || fail "--skill requires a registered skill name"
      REQUESTED_SKILLS=$(append_csv "$REQUESTED_SKILLS" "$2"); shift 2 ;;
    --all-skills) ALL_SKILLS=1; shift ;;
    --target)
      [ "$#" -ge 2 ] || fail "--target requires agents, codex, claude, or all"
      REQUESTED_TARGETS=$(append_csv "$REQUESTED_TARGETS" "$2"); TARGETS_EXPLICIT=1; shift 2 ;;
    --no-start) NO_START=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
case "$AGENT" in auto|codex|claude|none) ;; *) fail "invalid agent: $AGENT" ;; esac
[ "$ALL_SKILLS" -eq 0 ] || [ -z "$REQUESTED_SKILLS" ] || fail "--all-skills cannot be combined with --skill"
[ -n "$HOME_ROOT" ] || fail "HOME is not set; set CALM_GTM_HOME to an installation root"
case "$HOME_ROOT" in
  /*) ;;
  *) HOME_ROOT=$(pwd -P)/$HOME_ROOT ;;
esac
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
    lib/calm/csv.awk \
    lib/calm/csv_validate.awk \
    lib/calm/action_rows.awk \
    lib/calm/assets_rows.awk \
    lib/calm/weekly_overview.awk \
    references/apop-questions.csv \
    references/apop-strategy.md \
    references/action-plan.md \
    references/assets.md \
    references/weekly-update.md \
    references/local-tracker.md \
    skills/registry.tsv \
    scripts/quick_validate.sh \
    scripts/validate-skills.sh \
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
  if ! LC_ALL=C tar -xzf "$archive" -C "$TMP_DIR"; then fail "downloaded archive is invalid; no project or user files were changed"; fi
  SRC_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d -name 'calm-gtm-*' | sed -n '1p')
  [ -n "$SRC_DIR" ] && source_package_is_complete "$SRC_DIR" || fail "downloaded release is incomplete; no project or user files were changed"
fi

REGISTRY=$SRC_DIR/skills/registry.tsv
REGISTRY_SEEN=$WORK_DIR/registry-seen
: >"$REGISTRY_SEEN"

registry_field() {
  wanted_name=$1; wanted_field=$2
  awk -F'|' -v wanted_name="$wanted_name" -v wanted_field="$wanted_field" '
    $0 !~ /^#/ && $1 == wanted_name { print $wanted_field; found=1; exit }
    END { if (!found) exit 1 }
  ' "$REGISTRY"
}
csv_has() {
  csv_values=$1; csv_wanted=$2
  case ",$csv_values," in *,$csv_wanted,*) return 0 ;; *) return 1 ;; esac
}
csv_add_unique() {
  csv_values=$1; csv_value=$2
  if csv_has "$csv_values" "$csv_value"; then printf '%s\n' "$csv_values"; else append_csv "$csv_values" "$csv_value"; fi
}
skill_file_paths() {
  skill_source=$1; skill_layout=$2
  (
    cd "$skill_source" || exit 1
    if [ "$skill_layout" = core ]; then
      find SKILL.md references scripts/quick_validate.sh -type f -print
    else
      for skill_entry in SKILL.md agents assets references scripts; do
        [ ! -e "$skill_entry" ] || find "$skill_entry" -type f -print
      done
    fi
  )
}

while IFS='|' read -r registry_name registry_source registry_default registry_layout registry_validator registry_extra; do
  case "$registry_name" in ''|'#'*) continue ;; esac
  [ -z "$registry_extra" ] || fail "invalid skill registry row for $registry_name"
  case "$registry_name" in *[!a-z0-9-]*|-*|*-) fail "invalid registered skill name: $registry_name" ;; esac
  if grep -qxF "$registry_name" "$REGISTRY_SEEN"; then fail "duplicate registered skill: $registry_name"; fi
  printf '%s\n' "$registry_name" >>"$REGISTRY_SEEN"
  case "$registry_source" in ''|/*|../*|*/../*|*/..) fail "unsafe source path for $registry_name" ;; esac
  case "$registry_default" in yes|no) ;; *) fail "invalid default flag for $registry_name" ;; esac
  case "$registry_layout" in core|bundle) ;; *) fail "invalid layout for $registry_name" ;; esac
  case "$registry_validator" in ''|/*|../*|*/../*|*/..) fail "unsafe validator path for $registry_name" ;; esac
  registry_source_dir=$(CDPATH= cd -- "$SRC_DIR/$registry_source" 2>/dev/null && pwd || true)
  case "$registry_source_dir" in "$SRC_DIR"|"$SRC_DIR"/*) ;; *) fail "skill source escapes release package: $registry_name" ;; esac
  [ -f "$registry_source_dir/SKILL.md" ] || fail "registered skill is incomplete: $registry_name"
  declared_name=$(awk '
    NR == 1 && $0 == "---" { frontmatter=1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^name:[[:space:]]*/ { sub(/^name:[[:space:]]*/, ""); print; exit }
  ' "$registry_source_dir/SKILL.md")
  [ "$declared_name" = "$registry_name" ] || fail "registered skill name does not match SKILL.md: $registry_name"
  [ -x "$SRC_DIR/$registry_validator" ] || fail "quick validator is missing or not executable: $registry_name"
  if [ "$registry_layout" = bundle ]; then
    registry_symlink=$(find "$registry_source_dir" -type l -print | sed -n '1p')
    [ -z "$registry_symlink" ] || fail "skill bundle contains an unsupported symlink: $registry_name"
  fi
  registry_files=$(skill_file_paths "$registry_source_dir" "$registry_layout" | sed -n '1p')
  [ -n "$registry_files" ] || fail "registered skill has no installable files: $registry_name"
done <"$REGISTRY"
[ -s "$REGISTRY_SEEN" ] || fail "skill registry is empty"

SELECTED_SKILLS=
if [ "$ALL_SKILLS" -eq 1 ]; then
  while IFS='|' read -r registry_name _; do
    case "$registry_name" in ''|'#'*) continue ;; esac
    SELECTED_SKILLS=$(csv_add_unique "$SELECTED_SKILLS" "$registry_name")
  done <"$REGISTRY"
elif [ -n "$REQUESTED_SKILLS" ]; then
  old_ifs=$IFS; IFS=,
  for requested_skill in $REQUESTED_SKILLS; do
    IFS=$old_ifs
    case "$requested_skill" in *[!a-z0-9-]*|-*|*-) fail "invalid skill name: $requested_skill" ;; esac
    registry_field "$requested_skill" 2 >/dev/null 2>&1 || fail "unknown skill: $requested_skill"
    SELECTED_SKILLS=$(csv_add_unique "$SELECTED_SKILLS" "$requested_skill")
    IFS=,
  done
  IFS=$old_ifs
else
  while IFS='|' read -r registry_name _ registry_default _; do
    case "$registry_name" in ''|'#'*) continue ;; esac
    [ "$registry_default" = yes ] || continue
    SELECTED_SKILLS=$(csv_add_unique "$SELECTED_SKILLS" "$registry_name")
  done <"$REGISTRY"
fi
[ -n "$SELECTED_SKILLS" ] || fail "no skills selected"

SELECTED_TARGETS=
if [ "$TARGETS_EXPLICIT" -eq 1 ]; then
  old_ifs=$IFS; IFS=,
  for requested_target in $REQUESTED_TARGETS; do
    IFS=$old_ifs
    case "$requested_target" in
      all)
        for expanded_target in agents codex claude; do
          SELECTED_TARGETS=$(csv_add_unique "$SELECTED_TARGETS" "$expanded_target")
        done ;;
      agents|codex|claude) SELECTED_TARGETS=$(csv_add_unique "$SELECTED_TARGETS" "$requested_target") ;;
      *) fail "invalid target: $requested_target" ;;
    esac
    IFS=,
  done
  IFS=$old_ifs
else
  SELECTED_TARGETS=agents
  if [ -d "$HOME_ROOT/.claude" ] || command -v claude >/dev/null 2>&1; then
    SELECTED_TARGETS=$(csv_add_unique "$SELECTED_TARGETS" claude)
  fi
fi

old_ifs=$IFS; IFS=,
for selected_skill in $SELECTED_SKILLS; do
  IFS=$old_ifs
  selected_validator=$(registry_field "$selected_skill" 5)
  "$SRC_DIR/$selected_validator" >/dev/null || fail "quick validation failed: $selected_skill"
  IFS=,
done
IFS=$old_ifs

make_manifest() {
  source_dir=$1; selection=$2; output=$3
  paths_file=$output.paths
  sorted_paths=$output.sorted
  if ! (
    cd "$source_dir" || exit 1
    if [ "$selection" = package ]; then
      find VERSION bin lib SKILL.md references skills \
        scripts/quick_validate.sh scripts/validate-skills.sh -type f -print
    elif [ "$selection" = core ]; then
      find SKILL.md references scripts/quick_validate.sh -type f -print
    elif [ "$selection" = legacy-core ]; then
      find SKILL.md references -type f -print
    else
      for skill_entry in SKILL.md agents assets references scripts; do
        [ ! -e "$skill_entry" ] || find "$skill_entry" -type f -print
      done
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
make_manifest "$SRC_DIR" package "$PACKAGE_MANIFEST"

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
    cp -R "$SRC_DIR/VERSION" "$SRC_DIR/bin" "$SRC_DIR/lib" "$SRC_DIR/SKILL.md" \
      "$SRC_DIR/references" "$SRC_DIR/skills" "$STAGE_DIR/"
    mkdir -p "$STAGE_DIR/scripts"
    cp "$SRC_DIR/scripts/quick_validate.sh" "$SRC_DIR/scripts/validate-skills.sh" "$STAGE_DIR/scripts/"
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
  expected_manifest=$3
  [ -f "$previous_manifest" ] || return 0
  while IFS= read -r manifest_line; do
    managed_file=$(printf '%s\n' "$manifest_line" | sed 's/^[0-9][0-9]*[[:space:]][0-9][0-9]*[[:space:]]//')
    case "$managed_file" in
      SKILL.md|agents/*|assets/*|references/*|scripts/*) ;;
      *) continue ;;
    esac
    if ! awk -v wanted="$managed_file" '
      { checksum=$1; size=$2; $1=""; $2=""; sub(/^[[:space:]]+/, ""); if ($0 == wanted) found=1 }
      END { exit !found }
    ' "$expected_manifest"; then
      [ -f "$target_dir/$managed_file" ] && rm -f "$target_dir/$managed_file"
    fi
  done <"$previous_manifest"
}

install_skill() {
  skill_name=$1; skill_source=$2; skill_layout=$3; target_dir=$4; label=$5; target_name=$6
  if [ "$skill_name" = calm-gtm ]; then
    target_manifest=$target_dir/.calm-gtm-manifest
  else
    target_manifest=$target_dir/.calm-skill-manifest
  fi
  skill_manifest=$WORK_DIR/$skill_name.manifest
  make_manifest "$skill_source" "$skill_layout" "$skill_manifest" || fail "could not build manifest for $skill_name"
  previous_manifest=
  if [ -L "$target_dir" ]; then
    note "Conflict: $label target is a symlink; left unchanged -> $target_dir" >&2
    CONFLICTS=$((CONFLICTS + 1)); return 0
  elif [ -d "$target_dir" ]; then
    if [ -f "$target_manifest" ]; then
      if verify_manifest "$target_dir" "$skill_layout" "$target_manifest"; then
        previous_manifest=$target_manifest
      elif [ "$skill_name" = calm-gtm ] && verify_manifest "$target_dir" legacy-core "$target_manifest"; then
        note "Recognized unchanged legacy $label skill; upgrading safely -> $target_dir"
        previous_manifest=$target_manifest
      else
        note "Conflict: $label contains local changes; left unchanged -> $target_dir" >&2
        CONFLICTS=$((CONFLICTS + 1)); return 0
      fi
    elif [ "$skill_name" = calm-gtm ] && [ -f "$SRC_DIR/migrations/v1.1.0-skill.manifest" ] && verify_manifest "$target_dir" legacy-core "$SRC_DIR/migrations/v1.1.0-skill.manifest"; then
      note "Recognized unchanged v1.1.0 $label skill; upgrading safely -> $target_dir"
      previous_manifest=$SRC_DIR/migrations/v1.1.0-skill.manifest
    elif verify_manifest "$target_dir" "$skill_layout" "$skill_manifest"; then
      cp "$skill_manifest" "$target_manifest"
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
  prune_removed_managed_skill_files "$target_dir" "$previous_manifest" "$skill_manifest"
  paths_file=$WORK_DIR/$skill_name.paths
  skill_file_paths "$skill_source" "$skill_layout" | LC_ALL=C sort >"$paths_file"
  while IFS= read -r skill_file; do
    skill_parent=$(dirname -- "$skill_file")
    [ "$skill_parent" = . ] || mkdir -p "$target_dir/$skill_parent"
    cp "$skill_source/$skill_file" "$target_dir/$skill_file"
  done <"$paths_file"
  cp "$skill_manifest" "$target_manifest"
  note "Installed $label skill $skill_name -> $target_dir"
  record_target "$target_name"
}

write_agents_block() {
  block_output=$1; block_skill=$2
  if [ "$block_skill" = calm-gtm ]; then
    cat >"$block_output" <<'EOF'
<!-- BEGIN calm-gtm managed v2 -->
## Calm GTM
Read .agents/skills/calm-gtm/SKILL.md and follow it whenever the user asks
about go-to-market strategy, positioning, ICP, an action plan,
marketing/sales assets, or a weekly GTM review. Load the matching reference
only when producing that output, as SKILL.md directs.
<!-- END calm-gtm managed v2 -->
EOF
  else
    cat >"$block_output" <<EOF
<!-- BEGIN calm-skill $block_skill managed v1 -->
## $block_skill
Read .agents/skills/$block_skill/SKILL.md and follow it whenever its
frontmatter description matches the user's request. Load only the supporting
files that SKILL.md directs you to use.
<!-- END calm-skill $block_skill managed v1 -->
EOF
  fi
}
install_agents_pointer() {
  pointer_skill=$1
  agents_file=$PROJECT_ROOT/AGENTS.md
  block_file=$WORK_DIR/agents-block-$pointer_skill
  write_agents_block "$block_file" "$pointer_skill"
  if [ "$pointer_skill" = calm-gtm ]; then
    begin='<!-- BEGIN calm-gtm managed v2 -->'; end='<!-- END calm-gtm managed v2 -->'; legacy='<!-- calm-gtm skill v1 -->'
  else
    begin="<!-- BEGIN calm-skill $pointer_skill managed v1 -->"
    end="<!-- END calm-skill $pointer_skill managed v1 -->"
    legacy=
  fi
  if [ ! -f "$agents_file" ]; then cp "$block_file" "$agents_file"; note "Created $agents_file"; return; fi
  begin_count=$(grep -cF "$begin" "$agents_file" 2>/dev/null || true)
  end_count=$(grep -cF "$end" "$agents_file" 2>/dev/null || true)
  if [ -n "$legacy" ]; then legacy_count=$(grep -cF "$legacy" "$agents_file" 2>/dev/null || true); else legacy_count=0; fi
  if [ "$begin_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
    note "AGENTS.md already references $pointer_skill -> $agents_file"
  elif [ "$begin_count" -ne 0 ] || [ "$end_count" -ne 0 ]; then
    note "Conflict: malformed $pointer_skill markers in $agents_file; left unchanged" >&2; CONFLICTS=$((CONFLICTS + 1))
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
    note "Migrated the $pointer_skill block in $agents_file"
  elif [ "$legacy_count" -ne 0 ]; then
    note "Conflict: malformed legacy $pointer_skill marker in $agents_file; left unchanged" >&2; CONFLICTS=$((CONFLICTS + 1))
  else
    { printf '\n'; cat "$block_file"; } >>"$agents_file"
    note "Added $pointer_skill to $agents_file"
  fi
}

warn_legacy_skill_copies() {
  warning_skill=$1
  if [ "$warning_skill" = calm-gtm ]; then warning_label='Calm GTM'; else warning_label=$warning_skill; fi
  for legacy_path in \
    "$PROJECT_ROOT/.agents/$warning_skill"
  do
    if [ -d "$legacy_path" ]; then
      note "Legacy discoverable $warning_label copy was preserved -> $legacy_path" >&2
      note "Move it outside agent skill directories to avoid ambiguous skill selection." >&2
    fi
  done

  if ! csv_has "$SELECTED_TARGETS" codex && [ -d "$HOME_ROOT/.codex/skills/$warning_skill" ]; then
    note "Legacy discoverable $warning_label copy was preserved -> $HOME_ROOT/.codex/skills/$warning_skill" >&2
    note "Move it outside agent skill directories or install with --target codex to manage it explicitly." >&2
  fi

  for legacy_path in \
    "$HOME_ROOT"/.agents/skills/"$warning_skill".backup* \
    "$HOME_ROOT"/.codex/skills/"$warning_skill".backup* \
    "$HOME_ROOT"/.claude/skills/"$warning_skill".backup*
  do
    if [ -d "$legacy_path" ]; then
      note "Legacy discoverable $warning_label backup was preserved -> $legacy_path" >&2
      note "Move it outside agent skill directories to avoid ambiguous skill selection." >&2
    fi
  done
}

install_release
old_ifs=$IFS; IFS=,
for selected_skill in $SELECTED_SKILLS; do
  IFS=$old_ifs
  selected_source=$(registry_field "$selected_skill" 2)
  selected_layout=$(registry_field "$selected_skill" 4)
  selected_source_dir=$(CDPATH= cd -- "$SRC_DIR/$selected_source" && pwd)

  if csv_has "$SELECTED_TARGETS" agents; then
    install_skill "$selected_skill" "$selected_source_dir" "$selected_layout" \
      "$HOME_ROOT/.agents/skills/$selected_skill" "portable user" agents
    install_skill "$selected_skill" "$selected_source_dir" "$selected_layout" \
      "$PROJECT_ROOT/.agents/skills/$selected_skill" "project" project
    install_agents_pointer "$selected_skill"
  fi
  if csv_has "$SELECTED_TARGETS" codex; then
    install_skill "$selected_skill" "$selected_source_dir" "$selected_layout" \
      "$HOME_ROOT/.codex/skills/$selected_skill" "Codex user" codex
  fi
  if csv_has "$SELECTED_TARGETS" claude; then
    install_skill "$selected_skill" "$selected_source_dir" "$selected_layout" \
      "$HOME_ROOT/.claude/skills/$selected_skill" "Claude Code user" claude
  fi
  warn_legacy_skill_copies "$selected_skill"
  IFS=,
done
IFS=$old_ifs

if [ "${CALM_GTM_TELEMETRY:-1}" != 0 ] && [ -n "$INSTALLED_TARGETS" ]; then
  targets_json=$(printf '%s' "$INSTALLED_TARGETS" | sed 's/[^,]*/"&"/g')
  curl -fsS --max-time 2 -X POST -H 'Content-Type: application/json' \
    --data "{\"version\":\"$RELEASE_VERSION\",\"targets\":[$targets_json]}" \
    'https://calmgtm.com/api/install-event' >/dev/null 2>&1 || true
fi

note "calm-gtm $RELEASE_VERSION installation complete."
case :$PATH: in *:"$BIN_DIR":*) ;; *) note "Add $BIN_DIR to PATH to run calm from any directory." ;; esac
if [ "$CONFLICTS" -gt 0 ]; then note "$CONFLICTS local conflict(s) were preserved. Review them before relying on every adapter." >&2; fi
if csv_has "$SELECTED_SKILLS" calm-gtm; then
  if [ "$NO_START" = 1 ]; then
    "$BIN_LINK" init --project "$PROJECT_ROOT" --agent "$AGENT" --no-start
  else
    note "Starting Calm in this terminal. A compatible coding-agent CLI may continue the conversation automatically; otherwise Calm will print a handoff."
    "$BIN_LINK" init --project "$PROJECT_ROOT" --agent "$AGENT"
  fi
else
  note "Only optional skills were selected; the Calm GTM project model was not initialized."
fi
