#!/usr/bin/env sh

set -e
FIXTURE_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

grep -q 'FieldNote' "$FIXTURE_ROOT/site/index.html"
grep -q 'styles.css' "$FIXTURE_ROOT/site/index.html"
grep -q 'Early offer under validation' "$FIXTURE_ROOT/site/index.html"
grep -q 'ASSET-001' "$FIXTURE_ROOT/.calm/assets.csv"
grep -q 'ACT-001' "$FIXTURE_ROOT/.calm/assets/ASSET-001.md"
