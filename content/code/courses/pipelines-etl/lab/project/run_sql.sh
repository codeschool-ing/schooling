#!/bin/sh
# Build staging, then marts, one file at a time, in the order of their names.
# Stops at the first file that fails, and says which.
set -e
export PGOPTIONS="-c client_min_messages=warning"   # no NOTICE for each DROP IF EXISTS

for f in sql/staging/*.sql sql/marts/*.sql; do
  psql -q -v ON_ERROR_STOP=1 -d wh -f "$f"
  echo "built $f"
done
