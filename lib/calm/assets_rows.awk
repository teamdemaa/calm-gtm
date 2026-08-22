function clear_fields(    key) {
  for (key in field) delete field[key]
}

function parse_csv(line,    i,ch,nextch,value,n,in_quotes) {
  clear_fields()
  sub(/\r$/, "", line)
  value = ""
  n = 1
  in_quotes = 0
  for (i = 1; i <= length(line); i++) {
    ch = substr(line, i, 1)
    nextch = substr(line, i + 1, 1)
    if (in_quotes) {
      if (ch == "\"" && nextch == "\"") {
        value = value "\""
        i++
      } else if (ch == "\"") {
        in_quotes = 0
      } else {
        value = value ch
      }
    } else if (ch == "\"") {
      in_quotes = 1
    } else if (ch == ",") {
      field[n++] = value
      value = ""
    } else {
      value = value ch
    }
  }
  field[n] = value
  return n
}

function render_row(row_index) {
  if (lang == "fr") {
    print "- `" asset_id[row_index] "` — " asset_name[row_index] " — " status[row_index] " — lié à `" action_id[row_index] "`."
  } else {
    print "- `" asset_id[row_index] "` — " asset_name[row_index] " — " status[row_index] " — linked to `" action_id[row_index] "`."
  }
}

NR == 1 {
  count = parse_csv($0)
  for (i = 1; i <= count; i++) column[field[i]] = i
  next
}

{
  parse_csv($0)
  row_count++
  asset_id[row_count] = field[column["Asset ID"]]
  asset_name[row_count] = field[column["Asset Name"]]
  status[row_count] = field[column["Status"]]
  action_id[row_count] = field[column["Linked Action ID"]]
  if (status[row_count] == "Superseded") history_count++
  else current_count++
}

END {
  if (current_count) {
    if (lang == "fr") print "## Assets actifs"
    else print "## Active assets"
    print ""
    for (i = 1; i <= row_count; i++) if (status[i] != "Superseded") render_row(i)
    print ""
  }
  if (history_count) {
    if (lang == "fr") print "## Historique des assets"
    else print "## Asset history"
    print ""
    for (i = 1; i <= row_count; i++) if (status[i] == "Superseded") render_row(i)
    print ""
  }
}
