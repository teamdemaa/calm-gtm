#!/usr/bin/env sh
# Installs the calm-gtm skill into whichever coding-agent skill folders
# already exist on this machine, so the same $calm-gtm command works no
# matter which agent the founder happens to use.
#
# This script only ever ADDS files under known, tool-owned directories
# (~/.claude/skills, ~/.codex/skills). It never touches anything else,
# and it never overwrites a differently-named existing skill.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_NAME="calm-gtm"
INSTALLED_ANY=0

install_into() {
  target_dir="$1"
  label="$2"
  if [ -d "$(dirname "$target_dir")" ]; then
    mkdir -p "$target_dir"
    cp -R "$SCRIPT_DIR/SKILL.md" "$SCRIPT_DIR/references" "$target_dir/"
    echo "Installed for $label -> $target_dir"
    INSTALLED_ANY=1
  fi
}

# Claude Code: personal skills folder (all projects)
install_into "$HOME/.claude/skills/$SKILL_NAME" "Claude Code"

# Codex: mirrors the same folder-of-markdown convention, if present on
# this machine. (Verify this path against Codex's current docs before
# relying on it in production -- skill folder locations are still
# settling across tools.)
install_into "$HOME/.codex/skills/$SKILL_NAME" "Codex"

if [ "$INSTALLED_ANY" = "0" ]; then
  echo "No known agent skill folders found (~/.claude/skills, ~/.codex/skills)."
  echo "Universal fallback: copy SKILL.md's content into an AGENTS.md file"
  echo "at the root of your project -- any coding agent that reads AGENTS.md"
  echo "will pick it up automatically, with no install step at all."
fi
