#!/usr/bin/env sh

CALM_OPENING="Tell me what you’re building, where you are today, and what feels hardest right now. Write naturally — I’ll ask only what I need."

calm_error() {
  echo "calm: $*" >&2
}

calm_note() {
  echo "$*"
}

calm_has_command() {
  command -v "$1" >/dev/null 2>&1
}

calm_today() {
  date '+%Y-%m-%d'
}

calm_absolute_dir() {
  if [ ! -d "$1" ]; then
    calm_error "project directory does not exist: $1"
    return 1
  fi
  CDPATH= cd -- "$1" && pwd
}

calm_find_existing_root() {
  search_dir=$(calm_absolute_dir "$1") || return 1
  while :; do
    if [ -d "$search_dir/.calm" ]; then
      printf '%s\n' "$search_dir"
      return 0
    fi
    parent_dir=$(dirname -- "$search_dir")
    if [ "$parent_dir" = "$search_dir" ]; then
      return 1
    fi
    search_dir=$parent_dir
  done
}

calm_resolve_project_root() {
  requested_dir=${1:-$PWD}
  requested_dir=$(calm_absolute_dir "$requested_dir") || return 1

  existing_root=$(calm_find_existing_root "$requested_dir" 2>/dev/null || true)
  if [ -n "$existing_root" ]; then
    printf '%s\n' "$existing_root"
    return 0
  fi

  if calm_has_command git; then
    git_root=$(git -C "$requested_dir" rev-parse --show-toplevel 2>/dev/null || true)
    if [ -n "$git_root" ]; then
      printf '%s\n' "$git_root"
      return 0
    fi
  fi

  printf '%s\n' "$requested_dir"
}

calm_is_interactive() {
  if [ "${CALM_GTM_FORCE_INTERACTIVE:-0}" = 1 ]; then
    return 0
  fi
  [ -t 1 ] && [ -r /dev/tty ] && [ -w /dev/tty ]
}

calm_tty_input() {
  printf '%s\n' "${CALM_GTM_TTY_INPUT:-/dev/tty}"
}

calm_tty_output() {
  printf '%s\n' "${CALM_GTM_TTY_OUTPUT:-/dev/tty}"
}

calm_strategy_status() {
  strategy_file=$1
  if [ ! -f "$strategy_file" ]; then
    echo "absent"
    return
  fi
  status=$(sed -n 's/^<!-- calm:strategy-status=\([^ ]*\) -->$/\1/p' "$strategy_file" | sed -n '1p')
  if [ -n "$status" ]; then
    echo "$status"
  else
    echo "unknown"
  fi
}

calm_plan_status() {
  plan_file=$1
  if [ ! -f "$plan_file" ]; then
    echo "absent"
    return
  fi
  status=$(sed -n 's/^<!-- calm:plan-status=\([^ ]*\) -->$/\1/p' "$plan_file" | sed -n '1p')
  if [ -n "$status" ]; then
    echo "$status"
  else
    echo "unknown"
  fi
}

calm_metadata_value() {
  metadata_file=$1
  metadata_key=$2
  [ -f "$metadata_file" ] || return 0
  sed -n "s/^<!-- calm:${metadata_key}=\(.*\) -->$/\1/p" "$metadata_file" | sed -n '1p'
}

calm_infer_language_file() {
  text_file=$1
  if grep -Eiq '(^|[[:space:][:punct:]])(je|nous|vous|avec|pour|mais|pas|une|des|dans|construis|entreprise|aujourd.hui|désordonné)([[:space:][:punct:]]|$)|[àâçéèêëîïôùûüÿœ]' "$text_file" 2>/dev/null; then
    echo "French"
  else
    echo "English"
  fi
}

calm_intake_is_pending() {
  intake_file=$1
  [ ! -f "$intake_file" ] && return 0
  grep -q '^Language: Pending$' "$intake_file" 2>/dev/null
}

calm_validate_csv_rows() {
  csv_file=$1
  expected_width=$2
  awk -v expected_width="$expected_width" '
    function parse_csv(line,    i,ch,nextch,width,in_quotes,after_quote,value) {
      sub(/\r$/, "", line)
      width = 1
      in_quotes = 0
      after_quote = 0
      value = ""
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        nextch = substr(line, i + 1, 1)
        if (in_quotes) {
          if (ch == "\"" && nextch == "\"") {
            value = value "\""
            i++
          } else if (ch == "\"") {
            in_quotes = 0
            after_quote = 1
          } else {
            value = value ch
          }
        } else if (after_quote) {
          if (ch != ",") return -1
          width++
          value = ""
          after_quote = 0
        } else if (ch == "\"") {
          if (value != "") return -1
          in_quotes = 1
        } else if (ch == ",") {
          width++
          value = ""
        } else {
          value = value ch
        }
      }
      if (in_quotes) return -1
      return width
    }
    NR == 1 { next }
    {
      width = parse_csv($0)
      if (width != expected_width) {
        printf "calm: invalid CSV structure: %s line %d (expected %d columns)\n", FILENAME, NR, expected_width > "/dev/stderr"
        bad = 1
      }
    }
    END { exit bad }
  ' "$csv_file"
}

calm_validate_current_csv() {
  csv_file=$1
  expected_header=$2
  expected_width=$3
  [ -f "$csv_file" ] || return 0
  calm_csv_has_header "$csv_file" "$expected_header" || return 0
  calm_validate_csv_rows "$csv_file" "$expected_width"
}

calm_safe_temp() {
  target_dir=$1
  template=$target_dir/.calm-tmp.XXXXXX
  mktemp "$template"
}
