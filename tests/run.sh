#!/usr/bin/env sh

set -e
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for test_file in test_skills.sh test_golden.sh test_cli.sh test_install.sh test_end_to_end.sh; do
  echo "== $test_file =="
  "$REPO_ROOT/tests/$test_file"
done

echo "All Calm GTM tests passed."
