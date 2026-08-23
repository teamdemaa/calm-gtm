#!/usr/bin/env sh

set -e
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REGISTRY=$REPO_ROOT/skills/registry.tsv
SEEN=$REPO_ROOT/.validate-skills-seen.$$
trap 'rm -f "$SEEN"' EXIT HUP INT TERM

fail() { echo "validate-skills: $*" >&2; exit 1; }
[ -f "$REGISTRY" ] || fail "missing skills/registry.tsv"
: >"$SEEN"

while IFS='|' read -r name source default_value layout validator extra; do
  case "$name" in ''|'#'*) continue ;; esac
  [ -z "$extra" ] || fail "too many fields for $name"
  case "$name" in *[!a-z0-9-]*|-*|*-) fail "invalid skill name: $name" ;; esac
  grep -qxF "$name" "$SEEN" && fail "duplicate skill: $name"
  printf '%s\n' "$name" >>"$SEEN"
  case "$source" in ''|/*|../*|*/../*|*/..) fail "unsafe source for $name: $source" ;; esac
  case "$default_value" in yes|no) ;; *) fail "invalid default for $name: $default_value" ;; esac
  case "$layout" in core|bundle) ;; *) fail "invalid layout for $name: $layout" ;; esac
  case "$validator" in ''|/*|../*|*/../*|*/..) fail "unsafe validator for $name: $validator" ;; esac

  source_dir=$REPO_ROOT/$source
  [ -d "$source_dir" ] || fail "missing source for $name: $source"
  [ -f "$source_dir/SKILL.md" ] || fail "missing SKILL.md for $name"
  registered_name=$(awk '
    NR == 1 && $0 == "---" { frontmatter=1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      print
      exit
    }
  ' "$source_dir/SKILL.md")
  [ "$registered_name" = "$name" ] || fail "$name source declares name: $registered_name"
  [ -x "$REPO_ROOT/$validator" ] || fail "validator is missing or not executable for $name: $validator"

  if [ "$layout" = bundle ]; then
    symlink=$(find "$source_dir" \( -path "$source_dir/.git" -o -path "$source_dir/.git/*" \) -prune -o -type l -print | sed -n '1p')
    [ -z "$symlink" ] || fail "installable bundle contains a symlink: $symlink"
  fi

  "$REPO_ROOT/$validator"
done <"$REGISTRY"

[ -s "$SEEN" ] || fail "registry contains no skills"
echo "validate-skills: ok"
