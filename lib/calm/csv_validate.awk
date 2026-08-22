NR == 1 { next }

{
  width = parse_csv($0)
  if (csv_invalid || width != expected_width) {
    printf "calm: invalid CSV structure: %s line %d (expected %d columns)\n", FILENAME, NR, expected_width > "/dev/stderr"
    bad = 1
  }
}

END { exit bad }
