#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 left the server: shop loaded, logging as Ubuntu's
# package configures it. logcost.sh is taken out of this lesson's own .md and
# run as printed there. The lock-wait section needs two terminals; the first
# one's command is run in the background and its output printed when it ends,
# under its own prompt. Everything the lesson changes is put back at the end.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh
LOG=/var/log/postgresql/postgresql-16-main.log

lab down; sleep 3   # let the old machine finish exiting before reset removes it
lab reset 19

block defaults
printf "%s\n" "SELECT name, setting FROM pg_settings" " WHERE name IN ('logging_collector', 'log_destination', 'log_line_prefix'," "                'log_min_messages', 'log_min_duration_statement', 'log_statement'," "                'log_lock_waits', 'log_temp_files', 'log_connections'," "                'log_checkpoints', 'log_autovacuum_min_duration')" " ORDER BY name;" "SELECT pg_current_logfile();" | session shop

block where
on 'ls -l /var/log/postgresql'
on 'sudo ls -l /proc/$(sudo head -1 /var/lib/postgresql/16/main/postmaster.pid)/fd/2'
on "sudo tail -n 4 $LOG"
on 'sudo journalctl -u postgresql@16-main --no-pager -n 4'

block prefix
printf "%s\n" "SHOW log_line_prefix;" "SELECT 1/0;" | session shop
on "sudo tail -n 2 $LOG"
printf "%s\n" "ALTER SYSTEM SET log_line_prefix = '%m [%p] %q%u@%d %a ';" "SELECT pg_reload_conf();" "SELECT 1/0;" | session shop
on "sudo tail -n 3 $LOG"

block record
printf "%s\n" "ALTER SYSTEM SET log_min_duration_statement = '50ms';" "ALTER SYSTEM SET log_lock_waits = on;" "ALTER SYSTEM SET log_temp_files = 0;" "SELECT pg_reload_conf();" | session shop

block slow
printf "%s\n" "SELECT count(*) FROM orders WHERE status = 'cancelled' AND total_cents > 49000;" "SELECT name FROM customers WHERE id = 42;" | session shop
on "sudo grep duration: $LOG"

block temp
printf "%s\n" "SET work_mem = '1MB';" "SELECT count(DISTINCT total_cents) FROM orders;" | session shop
on "sudo grep -A1 'temporary file' $LOG"

block locks
T1='psql shop -c "BEGIN; UPDATE customers SET name = name WHERE id = 1; SELECT pg_sleep(4); COMMIT;"'
lab as "setsid $T1 > /tmp/t1.out 2>&1 < /dev/null &"
sleep 1
on 'psql shop -c "UPDATE customers SET name = name WHERE id = 1"'
sleep 2
block locks-t1
printf 'ana@db:~$ %s\n' "$T1"; lab as 'cat /tmp/t1.out; rm /tmp/t1.out'
block locks-log
on "sudo tail -n 9 $LOG"

block connections
printf "%s\n" "ALTER SYSTEM SET log_connections = on;" "ALTER SYSTEM SET log_disconnections = on;" "SELECT pg_reload_conf();" | session shop
on 'psql shop -c "SELECT 1"'
on "sudo grep -E 'connection (received|authenticated|authorized)|disconnection' $LOG"

block checkpoint
printf "CHECKPOINT;\n" | session shop
on "sudo grep checkpoint $LOG | tail -n 2"

block cost-setup
printf "%s\n" "ALTER SYSTEM RESET log_connections;" "ALTER SYSTEM RESET log_disconnections;" "ALTER SYSTEM RESET log_min_duration_statement;" "SELECT pg_reload_conf();" | session shop
on 'createdb bench'
on 'pgbench -i -q -s 10 bench'
fence le-kxfa0f62/what-it-costs.md '#!/usr/bin/env bash' | lab as 'cat > logcost.sh'

block cost-none
on 'bash logcost.sh'

block cost-all
printf "%s\n" "ALTER SYSTEM SET log_statement = 'all';" "SELECT pg_reload_conf();" | session shop
on 'bash logcost.sh'
on "sudo tail -n 7 $LOG"

block cost-duration
printf "%s\n" "ALTER SYSTEM RESET log_statement;" "ALTER SYSTEM SET log_min_duration_statement = 0;" "SELECT pg_reload_conf();" | session shop
on 'bash logcost.sh'
on "sudo tail -n 1 $LOG"
printf "%s\n" "ALTER SYSTEM RESET log_min_duration_statement;" "SELECT pg_reload_conf();" | session shop

block reading
on "sudo grep -oE '(LOG|ERROR|FATAL|PANIC|WARNING|DETAIL|HINT|CONTEXT|STATEMENT): ' $LOG | sort | uniq -c | sort -rn"
on "sudo grep -E 'ERROR|FATAL|PANIC' $LOG"

block rotate
on 'cat /etc/logrotate.d/postgresql-common'
on 'sudo logrotate -f /etc/logrotate.d/postgresql-common'
on 'ls -l /var/log/postgresql'

block jsonlog
printf "%s\n" "ALTER SYSTEM SET logging_collector = on;" "ALTER SYSTEM SET log_destination = 'jsonlog';" | session shop
on 'sudo systemctl restart postgresql@16-main'
printf "%s\n" "SELECT pg_current_logfile();" "SELECT 1/0;" | session shop
on "sudo tail -n 5 $LOG"
on 'sudo ls -l /var/lib/postgresql/16/main/log'
on "sudo sh -c 'tail -n 1 /var/lib/postgresql/16/main/log/*.json' | jq ."

block putback
printf "%s\n" "ALTER SYSTEM RESET logging_collector;" "ALTER SYSTEM RESET log_destination;" "ALTER SYSTEM RESET log_line_prefix;" "ALTER SYSTEM RESET log_lock_waits;" "ALTER SYSTEM RESET log_temp_files;" | session shop
on 'sudo systemctl restart postgresql@16-main'
on 'sudo cat /var/lib/postgresql/16/main/postgresql.auto.conf'
on 'dropdb bench'
on 'rm logcost.sh'

lab down
