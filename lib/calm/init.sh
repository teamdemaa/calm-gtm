#!/usr/bin/env sh

calm_write_initial_files() {
  root=$1
  calm_dir=$root/.calm
  today=$(calm_today)

  mkdir -p "$calm_dir/assets"

  if [ ! -f "$calm_dir/intake.md" ]; then
    cat >"$calm_dir/intake.md" <<EOF
# Calm GTM Intake

Initialized: $today
Language: Pending

## Opening question

$CALM_OPENING

## Founder response

Pending.
EOF
  fi

  if [ ! -f "$calm_dir/sources.md" ]; then
    cat >"$calm_dir/sources.md" <<'EOF'
# Calm GTM Sources
EOF
  fi
}

calm_record_intake() {
  intake_file=$1
  response_file=$2
  today=$(calm_today)

  if [ ! -s "$response_file" ]; then
    calm_note "No founder response was recorded."
    return 0
  fi

  temp_file=$(calm_safe_temp "$(dirname -- "$intake_file")") || return 1
  if calm_intake_is_pending "$intake_file"; then
    inferred_language=$(calm_infer_language_file "$response_file")
    awk -v inferred_language="$inferred_language" '
      /^Language: Pending$/ { print "Language: " inferred_language; next }
      /^## Founder response$/ { print; print ""; exit }
      { print }
    ' "$intake_file" >"$temp_file"
    cat "$response_file" >>"$temp_file"
    printf '\n' >>"$temp_file"
  else
    cat "$intake_file" >"$temp_file"
    {
      printf '\n## Additional founder context — %s\n\n' "$today"
      cat "$response_file"
      printf '\n'
    } >>"$temp_file"
  fi
  mv "$temp_file" "$intake_file"
}

calm_init() {
  project_arg=$PWD
  project_explicit=0
  intake_source=
  agent=auto
  no_start=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --project)
        [ "$#" -ge 2 ] || { calm_error "--project requires a directory"; return 2; }
        project_arg=$2
        project_explicit=1
        shift 2
        ;;
      --intake)
        [ "$#" -ge 2 ] || { calm_error "--intake requires a file path or -"; return 2; }
        intake_source=$2
        shift 2
        ;;
      --agent)
        [ "$#" -ge 2 ] || { calm_error "--agent requires auto, codex, claude, or none"; return 2; }
        agent=$2
        shift 2
        ;;
      --no-start) no_start=1; shift ;;
      --help|-h)
        calm_usage
        return 0
        ;;
      *) calm_error "unknown init option: $1"; return 2 ;;
    esac
  done

  case "$agent" in auto|codex|claude|none) ;; *) calm_error "invalid agent: $agent"; return 2 ;; esac

  if [ "$project_explicit" = 1 ]; then
    root=$(calm_absolute_dir "$project_arg") || return 1
  else
    root=$(calm_resolve_project_root "$project_arg") || return 1
  fi

  calm_write_initial_files "$root"
  calm_dir=$root/.calm
  response_temp=

  if [ -n "$intake_source" ]; then
    response_temp=$(calm_safe_temp "$calm_dir") || return 1
    if [ "$intake_source" = - ]; then
      cat >"$response_temp"
    elif [ -f "$intake_source" ]; then
      cat "$intake_source" >"$response_temp"
    else
      calm_error "intake file does not exist: $intake_source"
      rm -f "$response_temp"
      return 1
    fi
    calm_record_intake "$calm_dir/intake.md" "$response_temp"
    rm -f "$response_temp"
  fi

  strategy_state=$(calm_strategy_status "$calm_dir/strategy.md")
  if [ "$strategy_state" = absent ] && calm_intake_is_pending "$calm_dir/intake.md" && [ "$no_start" = 0 ] && calm_is_interactive; then
    tty_in=$(calm_tty_input)
    tty_out=$(calm_tty_output)
    printf '\n%s\n\n' "$CALM_OPENING" >>"$tty_out"
    printf 'Write naturally. Press Ctrl-D on a new line when you are done.\n\n' >>"$tty_out"
    response_temp=$(calm_safe_temp "$calm_dir") || return 1
    cat <"$tty_in" >"$response_temp" || true
    calm_record_intake "$calm_dir/intake.md" "$response_temp"
    rm -f "$response_temp"
  fi

  calm_render_overview "$root"
  calm_note "Calm GTM initialized in $calm_dir"

  if [ "$no_start" = 1 ]; then
    calm_note "Agent start skipped (--no-start)."
    return 0
  fi

  if [ "$strategy_state" != absent ]; then
    handoff_state=existing
  elif calm_intake_is_pending "$calm_dir/intake.md"; then
    handoff_state=pending
  else
    handoff_state=intake
  fi
  calm_start_agent "$root" "$agent" "$handoff_state"
}
