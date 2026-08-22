#!/usr/bin/env sh

calm_handoff_message() {
  root=$1
  state=$2
  case "$state" in
    existing)
      prompt="Continue Calm GTM for this project. Read AGENTS.md and the existing .calm files before responding. Resume from the current state; do not repeat onboarding."
      ;;
    intake)
      prompt="Start Calm GTM for this project. Read AGENTS.md and .calm/intake.md, then continue the natural conversation. Read any supplied sources before asking only the questions that could materially change the strategy."
      ;;
    *)
      prompt="Start Calm GTM for this project. Read AGENTS.md and .calm/intake.md, then ask the approved opening question found there."
      ;;
  esac
  printf '%s\n' "$prompt"
}

calm_choose_agent() {
  requested=$1
  interactive=$2

  case "$requested" in
    codex|claude|none) echo "$requested"; return ;;
    auto) ;;
    *) calm_error "invalid agent: $requested"; return 2 ;;
  esac

  has_codex=0
  has_claude=0
  calm_has_command codex && has_codex=1
  calm_has_command claude && has_claude=1

  if [ "$has_codex" = 1 ] && [ "$has_claude" = 0 ]; then
    echo "codex"
  elif [ "$has_codex" = 0 ] && [ "$has_claude" = 1 ]; then
    echo "claude"
  elif [ "$has_codex" = 1 ] && [ "$has_claude" = 1 ] && [ "$interactive" = 1 ]; then
    tty_in=$(calm_tty_input)
    tty_out=$(calm_tty_output)
    printf 'Both Codex and Claude Code are available. Launch [c] Codex, [l] Claude Code, or [n] neither? ' >>"$tty_out"
    IFS= read -r choice <"$tty_in" || choice=n
    case "$choice" in
      c|C|codex|Codex) echo "codex" ;;
      l|L|claude|Claude) echo "claude" ;;
      *) echo "none" ;;
    esac
  else
    echo "none"
  fi
}

calm_start_agent() {
  root=$1
  requested=$2
  state=$3
  interactive=0
  calm_is_interactive && interactive=1

  selected=$(calm_choose_agent "$requested" "$interactive") || return $?
  prompt=$(calm_handoff_message "$root" "$state")

  if [ "$interactive" = 0 ]; then
    calm_note "No interactive terminal is available, so Calm did not launch a coding agent."
    calm_note "Open your coding agent in: $root"
    calm_note "Paste this handoff: $prompt"
    return 0
  fi

  case "$selected" in
    codex)
      if ! calm_has_command codex; then
        calm_note "Codex was requested but its CLI is not available."
        calm_note "Open a compatible coding agent in: $root"
        calm_note "Paste this handoff: $prompt"
        return 0
      fi
      calm_note "Launching Codex in $root..."
      codex -C "$root" "$prompt"
      ;;
    claude)
      if ! calm_has_command claude; then
        calm_note "Claude Code was requested but its CLI is not available."
        calm_note "Open a compatible coding agent in: $root"
        calm_note "Paste this handoff: $prompt"
        return 0
      fi
      calm_note "Launching Claude Code in $root..."
      (cd "$root" && claude "$prompt")
      ;;
    none)
      calm_note "Calm initialized the local handoff but did not inject a conversation into an agent UI."
      calm_note "Open your coding agent in: $root"
      calm_note "Paste this handoff: $prompt"
      ;;
  esac
}
