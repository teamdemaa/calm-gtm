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

function md(value) {
  gsub(/\\/, "\\\\", value)
  gsub(/\|/, "\\|", value)
  return value
}

NR == 1 {
  count = parse_csv($0)
  for (i = 1; i <= count; i++) column[field[i]] = i
  next
}

{
  parse_csv($0)
  if (field[column["Horizon"]] != "Now") next
  if (!started) {
    if (lang == "fr") {
      if (proposed == 1) print "## Maintenant — proposé"
      else print "## Maintenant"
      print ""
      print "Objectif : " md(field[column["Objective"]])
      print ""
      print "| Action | Échéance | Statut |"
    } else {
      if (proposed == 1) print "## Now — proposed"
      else print "## Now"
      print ""
      print "Objective: " md(field[column["Objective"]])
      print ""
      print "| Action | Due | Status |"
    }
    print "|---|---|---|"
    started = 1
  }
  print "| " md(field[column["Action"]]) " | " md(field[column["Due"]]) " | " md(field[column["Status"]]) " |"
}

END {
  if (started) print ""
}
