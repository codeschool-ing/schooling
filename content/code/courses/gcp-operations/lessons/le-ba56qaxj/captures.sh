#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of gcp-operations.
#
#   bash captures.sh
#
# errlog.py is taken out of the lesson. The jq grouping stands for what the
# lesson says Error Reporting would do; it is not Error Reporting.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/error-reporting.md" errlog.py > errlog.py

block run
run 'python3 errlog.py | wc -l'
run "python3 errlog.py | jq -rs '.[0].message'"
block group
run "python3 errlog.py | jq -r '.message | split(\"\\n\") | map(select(startswith(\"  File\"))) | join(\" > \")' | sort | uniq -c"
run "python3 errlog.py | jq -r '.message | split(\"\\n\") | map(select(length > 0)) | last'"
