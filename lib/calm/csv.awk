function csv_clear_fields(    key) {
  for (key in field) delete field[key]
}

function parse_csv(line,    i,ch,nextch,value,n,in_quotes,after_quote) {
  csv_clear_fields()
  csv_invalid = 0
  sub(/\r$/, "", line)
  value = ""
  n = 1
  in_quotes = 0
  after_quote = 0

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
      if (ch != ",") {
        csv_invalid = 1
        return -1
      }
      field[n++] = value
      value = ""
      after_quote = 0
    } else if (ch == "\"") {
      if (value != "") {
        csv_invalid = 1
        return -1
      }
      in_quotes = 1
    } else if (ch == ",") {
      field[n++] = value
      value = ""
    } else {
      value = value ch
    }
  }

  if (in_quotes) {
    csv_invalid = 1
    return -1
  }
  field[n] = value
  return n
}
