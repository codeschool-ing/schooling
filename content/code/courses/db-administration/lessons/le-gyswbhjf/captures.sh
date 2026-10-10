#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 and every later lesson start: shop loaded and
# analysed. Everything this lesson builds is dropped again by the end of it,
# and shop's indexes are rebuilt rather than changed, so the database is left
# as it was found.
#
# SEVERAL TERMINALS AT ONCE. The lock sections need two or three psql sessions
# open together, one of them stuck behind another. `terminals` below runs them
# from one script: each is a real psql in its own pseudo-terminal, every line
# is typed into the session it names, and a line marked & is expected to block
# — the script types it, waits a moment, and goes on to the next line, so the
# blocked statement finishes whenever the session holding it lets go. What is
# printed is each run of lines typed into one terminal, in the order they were
# typed, with the output each statement produced when it finished.
#
# STAGED: the collation section shows `sort` from glibc 2.39, the version on
# Ubuntu 24.04; the order glibc 2.27 and earlier gave is quoted from the
# PostgreSQL wiki's page on locale data changes and was not run here. The
# version-mismatch warning is produced by editing the collation version
# recorded for a throwaway database, coll_check, by hand, since the machine
# has only one glibc; the lesson says so, and that the edit is never made on a
# database anybody keeps. The recording machine's cluster was created under
# C.UTF-8, so coll_check is made with en_US.UTF-8 to have a version at all.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
export LAB_NAME=${LAB_NAME:-db}

lab reset 17

lab root 'cat > /usr/local/lib/lab/terminals.py' <<'PY'
"""Several interactive psql sessions typed into from one script.

    python3 terminals.py DBNAME < script

A script line is `NAME|text` (type text into terminal NAME and wait for its
prompt) or `NAME&|text` (type it, wait 1.5 s, carry on: the statement is
expected to block). `NAME|#quiet text` types without printing. `@sleep N`
waits. Each run of consecutive lines for one terminal is printed after a
`##### terminal NAME` marker, prompt and all, with the output of each
statement under it, whenever that output arrived.
"""
import os, pty, re, select, sys, time

PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] )$')
db = sys.argv[1]
env = dict(os.environ, PAGER='', PSQL_PAGER='', COLUMNS='400', LINES='400')

class T:
    pass

terms, records = {}, []

def pump(t, extra=()):
    fds = {x.fd: x for x in list(terms.values()) + list(extra)}
    r, _, _ = select.select(list(fds), [], [], t)
    for fd in r:
        try:
            fds[fd].buf += os.read(fd, 65536)
        except OSError:
            pass
    for x in fds.values():
        m = PROMPT.search(x.buf)
        if not m:
            continue
        r2, _, _ = select.select([x.fd], [], [], 0.3)   # nothing more coming?
        if r2:
            continue
        out, x.buf = x.buf[:m.start(1)], b''
        if x.pending is not None:
            text = out.replace(b'\r\n', b'\n').decode()
            echo = x.pending['line'] + '\n'
            if text.startswith(echo):
                text = text[len(echo):]
            x.pending['out'] = text.rstrip('\n')
            x.pending = None
        x.prompt = m.group(1).decode()

def term(name):
    if name not in terms:
        t = T()
        t.name, t.buf, t.prompt, t.pending = name, b'', None, None
        t.pid, t.fd = pty.fork()
        if t.pid == 0:
            os.execvpe('psql', ['psql', '-n', '-P', 'pager=off', db], env)
        while t.prompt is None:
            pump(0.2, [t])
        terms[name] = t
    return terms[name]

for raw in sys.stdin.read().split('\n'):
    if not raw:
        continue
    if raw.startswith('@sleep '):
        end = time.time() + float(raw.split()[1])
        while time.time() < end:
            pump(0.2)
        continue
    head, line = raw.split('|', 1)
    block = head.endswith('&')
    t = term(head.rstrip('&'))
    while t.pending is not None:      # a terminal answers one thing at a time
        pump(0.2)
    quiet = line.startswith('#quiet ')
    if quiet:
        line = line[len('#quiet '):]
    rec = {'term': t.name, 'prompt': t.prompt, 'line': line, 'out': None, 'quiet': quiet}
    records.append(rec)
    t.pending = rec
    t.prompt = None
    os.write(t.fd, line.encode() + b'\n')
    if block:
        end = time.time() + 1.5
        while time.time() < end:
            pump(0.2)
    else:
        end = time.time() + 600
        while t.pending is not None and time.time() < end:
            pump(0.2)

end = time.time() + 600
while any(x.pending is not None for x in terms.values()) and time.time() < end:
    pump(0.2)
for x in terms.values():
    os.write(x.fd, b'\\q\n')

cur, gap = None, False
for r in records:
    if r['quiet']:
        continue
    if r['term'] != cur:
        sys.stdout.write('##### terminal %s\n' % r['term'])
        cur, gap = r['term'], False
    if gap:
        sys.stdout.write('\n')
    sys.stdout.write(r['prompt'] + r['line'] + '\n')
    if r['out']:
        sys.stdout.write(r['out'] + '\n')
    gap = bool(r['out'])
PY
terminals() { lab as "python3 /usr/local/lib/lab/terminals.py $1"; }

LOCKS="SELECT l.pid, l.relation::regclass, l.mode, l.granted, pg_blocking_pids(l.pid) AS blocked_by FROM pg_locks l WHERE l.relation IN ('orders'::regclass, 'orders_created_at'::regclass) ORDER BY l.pid, l.relation;"
ACTIVITY="SELECT pid, wait_event_type, wait_event, pg_blocking_pids(pid) AS blocked_by, left(query, 50) AS query FROM pg_stat_activity WHERE datname = 'shop' AND pid <> pg_backend_pid();"

block glibc
on 'ldd --version | head -1'
on "printf 'B\na\n11\n1-1\n' | LC_COLLATE=C sort"
on "printf 'B\na\n11\n1-1\n' | LC_COLLATE=en_US.UTF-8 sort"

block collversion
session shop <<'EOF'
SELECT datname, datcollate, datcollversion FROM pg_database WHERE datname = 'shop';
CREATE DATABASE coll_check TEMPLATE template0 LOCALE 'en_US.UTF-8';
SELECT datname, datcollate, datcollversion FROM pg_database WHERE datname = 'coll_check';
EOF

block mismatch
session shop <<'EOF'
UPDATE pg_database SET datcollversion = '2.27' WHERE datname = 'coll_check';
\c coll_check
REINDEX DATABASE coll_check;
ALTER DATABASE coll_check REFRESH COLLATION VERSION;
\c shop
DROP DATABASE coll_check;
EOF

block filepath
session shop <<'EOF'
SELECT pg_relation_filepath('orders_created_at');
REINDEX INDEX orders_created_at;
SELECT pg_relation_filepath('orders_created_at');
EOF

block reindex-lock
terminals shop <<EOF
2|#quiet \\timing on
3|#quiet \\timing on
1|BEGIN;
1|REINDEX INDEX orders_created_at;
2&|SELECT count(*) FROM orders WHERE customer_id = 42;
3&|UPDATE orders SET total_cents = total_cents WHERE id = 1;
4|$LOCKS
@sleep 3
1|COMMIT;
EOF

block timings
session shop <<'EOF'
\timing on
REINDEX INDEX orders_customer_id;
REINDEX INDEX CONCURRENTLY orders_customer_id;
EOF

block concurrently
terminals shop <<EOF
1|#quiet \\timing on
3|#quiet \\timing on
2|BEGIN;
2|UPDATE orders SET total_cents = total_cents WHERE id = 1;
1&|REINDEX INDEX CONCURRENTLY orders_created_at;
3|SELECT count(*) FROM orders WHERE customer_id = 42;
3|UPDATE orders SET total_cents = total_cents WHERE id = 2;
3|$ACTIVITY
3|SELECT phase FROM pg_stat_progress_create_index;
@sleep 2
2|COMMIT;
EOF

block failed
terminals shop <<EOF
2|BEGIN;
2|UPDATE orders SET total_cents = total_cents WHERE id = 1;
1|SET statement_timeout = '5s';
1|REINDEX INDEX CONCURRENTLY orders_created_at;
2|ROLLBACK;
1|RESET statement_timeout;
1|\\d orders
1|SELECT indexrelid::regclass, indisvalid FROM pg_index WHERE NOT indisvalid;
1|DROP INDEX CONCURRENTLY orders_created_at_ccnew;
1|SELECT count(*) FROM pg_index WHERE NOT indisvalid;
EOF

block create-concurrently
session shop <<'EOF'
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS orders_one_per_customer ON orders (customer_id);
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS orders_one_per_customer ON orders (customer_id);
SELECT indexrelid::regclass, indisvalid, indisready FROM pg_index WHERE indrelid = 'orders'::regclass;
DROP INDEX CONCURRENTLY orders_one_per_customer;
EOF

block amcheck
session shop <<'EOF'
CREATE EXTENSION amcheck;
SELECT c.relname, bt_index_check(c.oid, heapallindexed => true) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am am ON am.oid = c.relam WHERE am.amname = 'btree' AND c.relnamespace = 'public'::regnamespace;
EOF
on '/usr/lib/postgresql/16/bin/pg_amcheck --heapallindexed shop && echo clean'

block lie
session shop <<'EOF'
CREATE FUNCTION order_day(ts timestamptz) RETURNS date LANGUAGE sql IMMUTABLE AS $$ SELECT ts::date $$;
CREATE TABLE day_check AS SELECT id, created_at FROM orders WHERE id <= 100000;
SET TimeZone = 'America/Sao_Paulo';
CREATE INDEX day_check_day ON day_check (order_day(created_at));
ANALYZE day_check;
SELECT bt_index_check('day_check_day', heapallindexed => true);
SET TimeZone = 'UTC';
EXPLAIN (COSTS OFF) SELECT min(created_at), max(created_at) FROM day_check WHERE order_day(created_at) = '2026-01-02';
SELECT min(created_at), max(created_at) FROM day_check WHERE order_day(created_at) = '2026-01-02';
SELECT bt_index_check('day_check_day', heapallindexed => true);
RESET TimeZone;
DROP TABLE day_check;
DROP FUNCTION order_day;
DROP EXTENSION amcheck;
EOF

lab down
