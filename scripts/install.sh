#!/usr/bin/env sh
# Installs the calm-gtm skill for whichever coding agent(s) the founder is
# using -- this must work identically for Claude Code, Codex, Cursor,
# Windsurf, or anything else, since Calm GTM is not tied to any one tool.
#
# Two install paths run every time:
#   1. Native skill folders, for tools known to use one (Claude Code
#      confirmed; Codex is a best-effort guess -- see note below).
#   2. AGENTS.md at the project root you run this from. AGENTS.md is the
#      open, cross-tool convention that Cursor, Windsurf, Codex, and
#      Claude Code (via an explicit @AGENTS.md import) all read -- this is
#      the path that makes "works with all" actually true, independent of
#      whether a native skill folder exists for a given tool.
#
# This script only ever ADDS files under known, tool-owned directories or
# appends to AGENTS.md in the current directory. It never overwrites a
# differently-named existing skill and never touches anything else.

set -e

SKILL_NAME="calm-gtm"
REPO_URL="https://github.com/teamdemaa/calm-gtm"
INSTALLED_ANY=0

# Resolve where SKILL.md and references/ actually are. If this script is
# running from inside a local clone (has SKILL.md next to its parent
# directory), use that. Otherwise -- which is the normal case for
# `curl ... | sh`, where there is no sibling repo on disk -- download a
# fresh copy of the skill into a temp directory.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || true)"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../SKILL.md" ]; then
  SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  echo "Downloading calm-gtm..."
  curl -fsSL "$REPO_URL/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
  SRC_DIR="$TMP_DIR/calm-gtm-main"
fi

install_into() {
  target_dir="$1"
  label="$2"
  # Check for the tool's own base directory (e.g. ~/.claude), not the
  # skills subfolder itself -- the subfolder often doesn't exist yet even
  # on a machine that has the tool installed, and mkdir -p creates it fine.
  tool_home="$(dirname "$(dirname "$target_dir")")"
  if [ -d "$tool_home" ]; then
    mkdir -p "$target_dir"
    cp -R "$SRC_DIR/SKILL.md" "$SRC_DIR/references" "$target_dir/"
    echo "Installed for $label -> $target_dir"
    INSTALLED_ANY=1
  fi
}

# Claude Code: personal skills folder (all projects, auto-discovered).
install_into "$HOME/.claude/skills/$SKILL_NAME" "Claude Code"

# Codex: mirrors the same folder-of-markdown convention, if present on
# this machine. (Unverified against Codex's current docs -- this is a
# best-effort guess, not a confirmed path. The AGENTS.md step below is
# what actually guarantees Codex support regardless.)
install_into "$HOME/.codex/skills/$SKILL_NAME" "Codex"

# Universal path: works for Cursor, Windsurf, Codex, Claude Code, and any
# other agent that reads AGENTS.md from the project root -- run this from
# inside the project you want Calm GTM active in.
PROJECT_ROOT="$PWD"
POINTER_DIR="$PROJECT_ROOT/.agents/$SKILL_NAME"
mkdir -p "$POINTER_DIR"
cp -R "$SRC_DIR/SKILL.md" "$SRC_DIR/references" "$POINTER_DIR/"

MARKER="<!-- calm-gtm skill v1 -->"
if [ -f "$PROJECT_ROOT/AGENTS.md" ] && grep -qF "$MARKER" "$PROJECT_ROOT/AGENTS.md" 2>/dev/null; then
  echo "AGENTS.md already references calm-gtm -> $PROJECT_ROOT/AGENTS.md"
else
  {
    echo ""
    echo "$MARKER"
    echo "## Calm GTM"
    echo "Read .agents/calm-gtm/SKILL.md and follow it whenever the user asks"
    echo "about go-to-market strategy, positioning, ICP, an action plan,"
    echo "marketing/sales assets, or a weekly GTM review -- load the files"
    echo "under .agents/calm-gtm/references/ only when producing the"
    echo "matching output, as SKILL.md directs."
    echo "$MARKER"
  } >> "$PROJECT_ROOT/AGENTS.md"
  echo "Added calm-gtm to $PROJECT_ROOT/AGENTS.md (works with Cursor, Windsurf, Codex, Claude Code, and any agent that reads AGENTS.md)"
fi
INSTALLED_ANY=1

if [ "$INSTALLED_ANY" = "0" ]; then
  echo "Could not install anywhere -- check permissions on \$HOME and the current directory."
  exit 1
fi
