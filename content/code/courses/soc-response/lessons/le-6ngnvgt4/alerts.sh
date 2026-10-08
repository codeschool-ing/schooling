#!/bin/bash
# alerts.sh RULES.sql: run converted Sigma rules against siem.db, one row per alert
while IFS= read -r query; do
  sqlite3 -header -column siem.db "SELECT group_keys, metric_name AS kind, event_count AS events,
    datetime(occurrence_time, 'unixepoch') AS at_utc FROM ($query)"
done < "$1"
