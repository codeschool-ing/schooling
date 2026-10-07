#!/bin/bash
# context.sh ADDRESS: what the week knows about one address, one row per day and kind
sqlite3 -header -column siem.db "SELECT date(timestamp, '-3 hours') AS day, product,
  action, group_concat(DISTINCT user) AS accounts, count(*) AS n
  FROM logs WHERE src_ip = '$1' GROUP BY day, product, action"
