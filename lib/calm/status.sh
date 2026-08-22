#!/usr/bin/env sh

calm_detect_language() {
  intake_file=$1
  if grep -Eiq '^(Language|Langue) *: *(French|Français|fr)( |$)' "$intake_file" 2>/dev/null; then
    echo "fr"
  elif [ "$(calm_infer_language_file "$intake_file")" = French ]; then
    echo "fr"
  else
    echo "en"
  fi
}

calm_csv_has_header() {
  csv_file=$1
  expected_header=$2
  [ -f "$csv_file" ] || return 1
  actual_header=$(sed -n '1p' "$csv_file" | tr -d '\r')
  [ "$actual_header" = "$expected_header" ]
}

calm_extract_thesis() {
  strategy_file=$1
  awk '
    !started && /^### / { started=1; active=1; next }
    active && /^## / { active=0 }
    active { line[++count]=$0 }
    END {
      first=1
      while (first <= count && line[first] == "") first++
      last=count
      while (last >= first && line[last] == "") last--
      for (i=first; i<=last; i++) print line[i]
    }
  ' "$strategy_file"
}

calm_project_phase() {
  calm_dir=$1
  strategy_state=$(calm_strategy_status "$calm_dir/strategy.md")
  plan_state=$(calm_plan_status "$calm_dir/action-plan.md")

  if [ "$strategy_state" = absent ]; then
    if calm_intake_is_pending "$calm_dir/intake.md"; then echo "intake-pending"; else echo "intake-complete"; fi
  elif [ "$strategy_state" = proposed ]; then
    echo "strategy-proposed"
  elif [ "$strategy_state" = agreed ] && [ "$plan_state" = absent ] && [ ! -f "$calm_dir/action-plan.csv" ]; then
    echo "strategy-agreed"
  elif [ "$strategy_state" = agreed ] && [ "$plan_state" = proposed ]; then
    echo "plan-proposed"
  elif [ "$strategy_state" = agreed ] && [ "$plan_state" = agreed ]; then
    echo "execution-active"
  elif [ "$strategy_state" = agreed ]; then
    echo "plan-approval-unknown"
  else
    echo "strategy-approval-unknown"
  fi
}

calm_render_overview() {
  root=$1
  calm_dir=$root/.calm
  mkdir -p "$calm_dir"

  calm_validate_current_csv "$calm_dir/strategy.csv" 'Period,Question ID,Area,Question,Answer,State' 6 || return 1
  calm_validate_current_csv "$calm_dir/action-plan.csv" 'Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status' 11 || return 1
  calm_validate_current_csv "$calm_dir/assets.csv" 'Asset ID,Asset Name,Category,Purpose,Linked Action ID,File,Status' 7 || return 1
  calm_validate_current_csv "$calm_dir/weekly.csv" 'Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do' 11 || return 1

  language=$(calm_detect_language "$calm_dir/intake.md")
  phase=$(calm_project_phase "$calm_dir")
  strategy_state=$(calm_strategy_status "$calm_dir/strategy.md")
  plan_state=$(calm_plan_status "$calm_dir/action-plan.md")
  strategy_agreed_at=$(calm_metadata_value "$calm_dir/strategy.md" strategy-agreed-at)
  plan_agreed_at=$(calm_metadata_value "$calm_dir/action-plan.md" plan-agreed-at)
  today=$(calm_today)
  temp_file=$(calm_safe_temp "$calm_dir") || return 1
  legacy_models=

  if [ -f "$calm_dir/strategy.csv" ] && ! calm_csv_has_header "$calm_dir/strategy.csv" 'Period,Question ID,Area,Question,Answer,State'; then
    legacy_models="$legacy_models strategy.csv"
  fi

  if [ "$language" = fr ]; then
    case "$phase" in
      intake-pending) phase_label="Intake en attente" ;;
      intake-complete) phase_label="Intake complet" ;;
      strategy-proposed) phase_label="Stratégie proposée" ;;
      strategy-agreed) phase_label="Stratégie validée" ;;
      plan-proposed) phase_label="Plan proposé" ;;
      execution-active) phase_label="Exécution active" ;;
      plan-approval-unknown) phase_label="Plan présent — validation inconnue" ;;
      *) phase_label="Stratégie présente — validation inconnue" ;;
    esac
    {
      echo "# Vue d'ensemble Calm GTM"
      echo ""
      echo "Générée le : $today"
      echo "Phase du projet : $phase_label"
      case "$strategy_state" in
        proposed) echo "Statut de la stratégie : Proposée — en attente de l'accord explicite du fondateur" ;;
        agreed)
          if [ -n "$strategy_agreed_at" ]; then echo "Statut de la stratégie : Validée le $strategy_agreed_at"; else echo "Statut de la stratégie : Validée"; fi
          ;;
        unknown) echo "Statut de la stratégie : Inconnu" ;;
      esac
      case "$plan_state" in
        proposed) echo "Statut du plan : Proposé — en attente de l'accord explicite du fondateur" ;;
        agreed)
          if [ -n "$plan_agreed_at" ]; then echo "Statut du plan : Validé le $plan_agreed_at"; else echo "Statut du plan : Validé"; fi
          ;;
        unknown) echo "Statut du plan : Inconnu" ;;
      esac
      echo ""
    } >"$temp_file"
  else
    case "$phase" in
      intake-pending) phase_label="Intake pending" ;;
      intake-complete) phase_label="Intake complete" ;;
      strategy-proposed) phase_label="Strategy proposed" ;;
      strategy-agreed) phase_label="Strategy agreed" ;;
      plan-proposed) phase_label="Plan proposed" ;;
      execution-active) phase_label="Execution active" ;;
      plan-approval-unknown) phase_label="Plan present — approval unknown" ;;
      *) phase_label="Strategy present — approval unknown" ;;
    esac
    {
      echo "# Calm GTM Overview"
      echo ""
      echo "Generated: $today"
      echo "Project phase: $phase_label"
      case "$strategy_state" in
        proposed) echo "Strategy status: Proposed — awaiting explicit founder agreement" ;;
        agreed)
          if [ -n "$strategy_agreed_at" ]; then echo "Strategy status: Agreed on $strategy_agreed_at"; else echo "Strategy status: Agreed"; fi
          ;;
        unknown) echo "Strategy status: Unknown" ;;
      esac
      case "$plan_state" in
        proposed) echo "Plan status: Proposed — awaiting explicit founder agreement" ;;
        agreed)
          if [ -n "$plan_agreed_at" ]; then echo "Plan status: Agreed on $plan_agreed_at"; else echo "Plan status: Agreed"; fi
          ;;
        unknown) echo "Plan status: Unknown" ;;
      esac
      echo ""
    } >"$temp_file"
  fi

  if [ -f "$calm_dir/strategy.md" ]; then
    if [ "$language" = fr ]; then echo "## Thèse GTM" >>"$temp_file"; else echo "## GTM thesis" >>"$temp_file"; fi
    echo "" >>"$temp_file"
    calm_extract_thesis "$calm_dir/strategy.md" >>"$temp_file"
    echo "" >>"$temp_file"
  fi

  if [ -f "$calm_dir/action-plan.csv" ]; then
    if calm_csv_has_header "$calm_dir/action-plan.csv" 'Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status'; then
      proposed=0
      [ "$plan_state" = proposed ] && proposed=1
      awk -v lang="$language" -v proposed="$proposed" -f "$CALM_GTM_PACKAGE_ROOT/lib/calm/action_rows.awk" "$calm_dir/action-plan.csv" >>"$temp_file"
    else
      legacy_models="$legacy_models action-plan.csv"
    fi
  fi

  if [ -f "$calm_dir/assets.csv" ]; then
    if calm_csv_has_header "$calm_dir/assets.csv" 'Asset ID,Asset Name,Category,Purpose,Linked Action ID,File,Status'; then
      awk -v lang="$language" -f "$CALM_GTM_PACKAGE_ROOT/lib/calm/assets_rows.awk" "$calm_dir/assets.csv" >>"$temp_file"
    else
      legacy_models="$legacy_models assets.csv"
    fi
  fi

  if [ -f "$calm_dir/weekly.csv" ] && [ -f "$calm_dir/action-plan.csv" ]; then
    if calm_csv_has_header "$calm_dir/weekly.csv" 'Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do' && \
       calm_csv_has_header "$calm_dir/action-plan.csv" 'Action ID,Horizon,Objective,Action,Why,APOP Link,Responsible,Due,Deliverable,Success Signal,Status'; then
      awk -v lang="$language" -f "$CALM_GTM_PACKAGE_ROOT/lib/calm/weekly_overview.awk" "$calm_dir/action-plan.csv" "$calm_dir/weekly.csv" >>"$temp_file"
    elif ! calm_csv_has_header "$calm_dir/weekly.csv" 'Date,This Week,What Matters,What We Learned,What Not To Overreact To,APOP Changes,Keep,Change,Stop,Priority Action IDs,One Thing Not To Do'; then
      legacy_models="$legacy_models weekly.csv"
    fi
  elif [ "$phase" = execution-active ]; then
    if [ "$language" = fr ]; then
      printf '%s\n\n%s\n\n' '## Dernier check-in hebdomadaire' 'Aucun check-in hebdomadaire enregistré.' >>"$temp_file"
    else
      printf '%s\n\n%s\n\n' '## Latest weekly check-in' 'No weekly check-in recorded.' >>"$temp_file"
    fi
  fi

  case "$phase" in
    strategy-proposed)
      if [ "$language" = fr ]; then
        echo "La stratégie attend l'accord explicite du fondateur. Aucun plan d'action ni asset n'est autorisé." >>"$temp_file"
      else
        echo "The strategy is awaiting explicit founder agreement. No action plan or asset is authorized." >>"$temp_file"
      fi
      ;;
    strategy-agreed)
      if [ "$language" = fr ]; then echo "La stratégie est validée. Aucun plan d'action n'existe encore." >>"$temp_file"; else echo "The strategy is agreed. No action plan exists yet." >>"$temp_file"; fi
      ;;
    plan-proposed)
      if [ "$language" = fr ]; then echo "Le plan attend l'accord explicite du fondateur. Aucune action n'est autorisée et aucun asset ne doit être créé." >>"$temp_file"; else echo "The plan awaits explicit founder agreement. No action is authorized and no asset may be created." >>"$temp_file"; fi
      ;;
    intake-pending)
      if [ "$language" = fr ]; then echo "La réponse initiale du fondateur n'a pas encore été enregistrée." >>"$temp_file"; else echo "The founder's opening response has not been recorded yet." >>"$temp_file"; fi
      ;;
    intake-complete)
      if [ "$language" = fr ]; then echo "L'intake est enregistré. La prochaine étape est la proposition de stratégie APOP." >>"$temp_file"; else echo "The intake is recorded. The next step is the APOP strategy proposal." >>"$temp_file"; fi
      ;;
  esac

  if [ -n "$legacy_models" ]; then
    if [ "$language" = fr ]; then
      {
        echo ""
        echo "## Migration locale requise"
        echo ""
        echo "Schéma legacy détecté :$legacy_models. Les fichiers source ont été préservés et leurs champs manquants n'ont pas été inventés. Ouvre Calm dans un agent compatible pour effectuer la migration sémantique."
      } >>"$temp_file"
    else
      {
        echo ""
        echo "## Local migration required"
        echo ""
        echo "Legacy schema detected:$legacy_models. Source files were preserved and missing fields were not invented. Open Calm in a compatible agent to perform the semantic migration."
      } >>"$temp_file"
    fi
  fi

  mv "$temp_file" "$calm_dir/overview.md"
}

calm_render_dashboard() {
  root=$1
  calm_dir=$root/.calm
  language=$(calm_detect_language "$calm_dir/intake.md")
  temp_file=$(calm_safe_temp "$calm_dir") || return 1
  {
    cat <<'EOF'
<!doctype html>
EOF
    printf '<html lang="%s">\n' "$language"
    cat <<'EOF'
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<title>Calm GTM local tracker</title>
<style>
  :root { color-scheme: light dark; font-family: ui-sans-serif, system-ui, sans-serif; }
  body { margin: 0; background: #f3f0e8; color: #17201b; }
  main { max-width: 900px; margin: 48px auto; padding: 32px; background: #fffdf7; border: 1px solid #d9d2c3; border-radius: 18px; }
  pre { white-space: pre-wrap; overflow-wrap: anywhere; font: 15px/1.6 ui-monospace, SFMono-Regular, Consolas, monospace; }
  .local { color: #526057; font-size: 14px; }
  @media (prefers-color-scheme: dark) { body { background: #101612; color: #e8eee9; } main { background: #17201b; border-color: #344039; } .local { color: #aebbb2; } }
</style>
</head>
<body><main>
<p class="local">Local derived view · no account, server, scripts, analytics, or synchronization</p>
<pre>
EOF
    awk '
      function html_escape(value,    output,pos,char) {
        output = ""
        for (pos = 1; pos <= length(value); pos++) {
          char = substr(value, pos, 1)
          if (char == "&") output = output "&amp;"
          else if (char == "<") output = output "&lt;"
          else if (char == ">") output = output "&gt;"
          else output = output char
        }
        return output
      }
      { print html_escape($0) }
    ' "$calm_dir/overview.md"
    cat <<'EOF'
</pre>
</main></body>
</html>
EOF
  } >"$temp_file"
  mv "$temp_file" "$calm_dir/dashboard.html"
}

calm_status() {
  project_arg=$PWD
  project_explicit=0
  with_html=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --project)
        [ "$#" -ge 2 ] || { calm_error "--project requires a directory"; return 2; }
        project_arg=$2
        project_explicit=1
        shift 2
        ;;
      --html) with_html=1; shift ;;
      --help|-h) calm_usage; return 0 ;;
      *) calm_error "unknown status option: $1"; return 2 ;;
    esac
  done

  if [ "$project_explicit" = 1 ]; then
    root=$(calm_absolute_dir "$project_arg") || return 1
  else
    root=$(calm_resolve_project_root "$project_arg") || return 1
  fi
  if [ ! -d "$root/.calm" ]; then
    calm_error "no .calm project found; run calm init first"
    return 1
  fi

  calm_render_overview "$root"
  if [ "$with_html" = 1 ]; then
    calm_render_dashboard "$root"
    calm_note "Local HTML tracker: $root/.calm/dashboard.html"
  fi
  cat "$root/.calm/overview.md"
}
