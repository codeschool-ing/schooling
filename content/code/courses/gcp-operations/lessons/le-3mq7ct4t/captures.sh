#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of gcp-operations.
#
#   bash captures.sh
#
# billing.py and q.py are taken out of the lesson. The table is generated, as
# billing.py says; the column names follow the BigQuery billing export, and
# the nesting is flattened. Nothing here comes from a billing account.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/export.md" billing.py > billing.py
from_lesson "$HERE/export.md" q.py > q.py
block make
run 'python3 billing.py'
block project
run 'python3 q.py "SELECT project_id, round(sum(cost), 2) FROM export GROUP BY 1 ORDER BY 2 DESC"'
run 'python3 q.py "SELECT folder, round(sum(cost), 2) FROM export GROUP BY 1 ORDER BY 2 DESC"'
block label
run "python3 q.py \"SELECT coalesce(label_team, '(no label)'), round(sum(cost), 2), round(100 * sum(cost) / (SELECT sum(cost) FROM export), 1) FROM export GROUP BY 1 ORDER BY 2 DESC\""
block nobody
run 'python3 q.py "SELECT project_id, service, resource_name, round(sum(cost), 2) FROM export WHERE label_team IS NULL GROUP BY 1, 2, 3 ORDER BY 4 DESC"'
