#!/bin/bash
# grouped.sh RULES.sql: the same alerts as alerts.sh, one row per address instead of per window
while IFS= read -r query; do
  sqlite3 -header -column siem.db "SELECT group_keys, count(*) AS windows,
    datetime(min(occurrence_time), 'unixepoch') AS first_utc,
    datetime(max(occurrence_time), 'unixepoch') AS last_utc FROM ($query) GROUP BY group_keys"
done < "$1"
