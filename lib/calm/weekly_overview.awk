function clear_fields(    key) {
  for (key in field) delete field[key]
}

function clear_columns(    key) {
  for (key in column) delete column[key]
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

FNR == 1 {
  clear_columns()
  count = parse_csv($0)
  for (i = 1; i <= count; i++) column[field[i]] = i
  next
}

FILENAME == ARGV[1] {
  parse_csv($0)
  action[field[column["Action ID"]]] = field[column["Action"]]
  next
}

FILENAME == ARGV[2] {
  parse_csv($0)
  this_week = field[column["This Week"]]
  what_matters = field[column["What Matters"]]
  apop_changes = field[column["APOP Changes"]]
  priority_ids = field[column["Priority Action IDs"]]
  one_thing = field[column["One Thing Not To Do"]]
  found = 1
}

END {
  if (!found) exit
  if (lang == "fr") print "## Dernier check-in"
  else print "## Latest check-in"
  print ""
  print "### This Week"
  print ""
  print this_week
  print ""
  print "### What Matters"
  print ""
  print what_matters
  print ""
  print "### APOP Changes"
  print ""
  print apop_changes
  print ""
  print "### Priorities"
  print ""
  priority_count = split(priority_ids, priorities, /\|/)
  for (i = 1; i <= priority_count && priorities[i] != ""; i++) {
    if (action[priorities[i]] != "") print i ". `" priorities[i] "` — " action[priorities[i]]
    else print i ". `" priorities[i] "`"
  }
  print ""
  print "### One Thing Not To Do"
  print ""
  print one_thing
  print ""
}
