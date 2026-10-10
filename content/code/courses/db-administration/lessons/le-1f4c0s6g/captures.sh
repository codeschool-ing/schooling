#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 starts: PostgreSQL 16 with the course's database
# shop loaded.
#
# STAGED: the lesson asks the student to open more terminals and leave a psql
# running in each. Here those sessions are background processes started with
# setsid, an idle one fed by `sleep` so it waits at its prompt as a person's
# would, and a busy one running `SELECT pg_sleep(...)`. The server sees the
# same thing in both cases: a connection, a backend and a state. The session
# that is left idle in a transaction and later finds itself disconnected is a
# copy of the lab's psql driver that understands one extra line, `#sleep N`,
# which waits N seconds before typing the next line and prints nothing; it
# stands for the person who walked away from the terminal.
#
# The pgbench numbers are the recording computer's: 4 processors shared by
# the server and by pgbench itself. Everything the lesson changes is put back
# at the end: max_connections, the role and user app, the database bench.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

lab reset 5

n=0
bg() { # bg USER 'command' — leave a client running in the background
  n=$((n + 1))
  printf '%s\n' "$2" | lab root "cat > /tmp/bg$n.sh"
  lab root "setsid su - $1 -c 'bash /tmp/bg$n.sh' >/dev/null 2>&1 </dev/null &"
}
clients() { # wait until N client backends are connected, counted from outside
  # (a psql here would need a connection slot, which is what runs out)
  lab as "until [ \"\$(ps -u postgres -o cmd | grep -c '\\[local\\]')\" = $1 ]; do sleep 0.3; done"
}
kickall() { # end every client but the caller, silently
  lab as "psql -XAtc \"SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()\" shop" >/dev/null
  clients 0
}
# the driver with #sleep (see the header)
lab root "sed 's/^        quiet = line.startswith(.#quiet .)$/        if line.startswith(\"#sleep \"):\n            time.sleep(float(line[7:])); continue\n&/' /usr/local/lib/lab/session.py > /usr/local/lib/lab/slow.py"
slow() { lab root "su - $1 -c 'python3 /usr/local/lib/lab/slow.py $2'"; }

block processes
bg ana 'sleep 600 | psql shop'
bg ana 'psql shop -c "SELECT pg_sleep(600)"'
clients 2
on 'ps -u postgres -o pid,ppid,cmd'
printf 'ana@db:~$ psql shop\n'
printf "SELECT pid, backend_type, usename, state, left(query, 24) AS query\n  FROM pg_stat_activity ORDER BY backend_type, pid;\n" | session shop
kickall

block max
printf 'SHOW max_connections;\nSHOW superuser_reserved_connections;\nSHOW reserved_connections;\nSHOW shared_memory_size;\n' | session shop
on 'sudo useradd --create-home app'
on 'createuser app'
on 'psql shop -c "GRANT SELECT, UPDATE ON customers, orders TO app"'
on 'psql shop -c "ALTER SYSTEM SET max_connections = 5"'
on 'sudo systemctl restart postgresql@16-main'
on 'psql shop -c "SHOW max_connections" -c "SHOW shared_memory_size"'
bg app 'psql shop -c "SELECT pg_sleep(600)"'
bg app 'psql shop -c "SELECT pg_sleep(600)"'
clients 2
on 'sudo -u app psql shop'
on "psql shop -c \"SELECT usename, count(*) FROM pg_stat_activity WHERE backend_type = 'client backend' GROUP BY usename\""
bg ana 'psql shop -c "SELECT pg_sleep(600)"'
bg ana 'psql shop -c "SELECT pg_sleep(600)"'
bg ana 'psql shop -c "SELECT pg_sleep(600)"'
clients 5
on 'psql shop'
on 'sudo -u postgres psql'
on "sudo pkill --oldest --full 'postgres: 16/main: ana shop'"
on "psql shop -c \"SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()\""
clients 0

block raising
on 'psql shop -c "ALTER SYSTEM SET max_connections = 1000"'
on 'sudo systemctl restart postgresql@16-main'
on 'psql shop -c "SHOW max_connections" -c "SHOW shared_memory_size"'
printf 'ana@db:~$ psql shop\n'
printf "SELECT pg_size_pretty(sum(total_bytes)) FROM pg_backend_memory_contexts;\n\\\\d+ orders\n#quiet SELECT 1;\nSELECT pg_size_pretty(sum(total_bytes)) FROM pg_backend_memory_contexts;\n" | session shop
on 'createdb bench'
on 'pgbench --initialize --quiet --scale=10 bench'
on 'pgbench --select-only --client=4 --jobs=4 --time=15 bench'
on 'pgbench --select-only --client=80 --jobs=4 --time=15 bench'

block idle
on 'psql shop -c "ALTER SYSTEM RESET max_connections"'
on 'sudo systemctl restart postgresql@16-main'
(printf "BEGIN;\nUPDATE customers SET name = 'Customer 1' WHERE id = 1;\n#sleep 20\nSELECT name FROM customers WHERE id = 1;\n" | slow app shop > /tmp/claude-victim-$LAB_NAME.out) &
victim=$!
clients 1
lab as "until [ \"\$(psql -XAtc \"SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction'\" shop)\" = 1 ]; do sleep 0.3; done"
on 'ps -u postgres -o pid,cmd | grep "app shop"'
printf 'ana@db:~$ psql shop\n'
printf "SELECT pid, usename, state, now() - xact_start AS open_for, query\n  FROM pg_stat_activity WHERE state = 'idle in transaction';\nSELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';\nSELECT pid, state FROM pg_stat_activity WHERE usename = 'app';\nSELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';\nSELECT pid, state FROM pg_stat_activity WHERE usename = 'app';\n" | session shop
wait $victim
block victim
printf 'app@db:~$ psql shop\n'
cat /tmp/claude-victim-$LAB_NAME.out; rm -f /tmp/claude-victim-$LAB_NAME.out

block timeout
on "psql shop -c \"ALTER ROLE app SET idle_in_transaction_session_timeout = '10s'\""
printf 'app@db:~$ psql shop\n'
printf "BEGIN;\nSELECT count(*) FROM orders WHERE customer_id = 42;\n#sleep 12\nSELECT 1;\n" | slow app shop
on 'sudo grep "idle-in-transaction" /var/log/postgresql/postgresql-16-main.log'

block pooling
on 'pgbench --select-only --connect --client=4 --jobs=4 --time=15 bench'

block cleanup
on 'dropdb bench'
on 'dropuser app'
on 'sudo userdel --remove app'
on 'psql shop -Atc "SHOW max_connections"'

lab down
