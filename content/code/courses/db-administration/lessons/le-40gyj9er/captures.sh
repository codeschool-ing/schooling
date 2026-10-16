#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 ends, with shop loaded, and works on orders_live, a
# copy of orders the lesson makes, so shop is left as lesson 4 left it; the
# lesson drops the copy at the end and so does this script.
#
# STAGED: the sections with several terminals open at once (the lock queue,
# lock_timeout, VALIDATE beside a write, the retry script beside a held
# transaction) are typed by a small driver, written into the machine below,
# that runs one psql per terminal in a pseudo-terminal, types each line when
# the scenario says, and prints each terminal's transcript afterwards in the
# layout session.py uses. The pauses between steps are the driver's sleeps;
# what each terminal printed, and the times \timing reported, are what
# happened.
set -uo pipefail
export LAB_NAME=${LAB_NAME:-db}
cd "$(dirname "$0")"
. ../../lab/capture.sh

L=le-40gyj9er
lab reset 5
lab root 'cat > /usr/local/lib/lab/terms.py' <<'PY'
"""Several psql sessions at once, driven from one script, each printed as the
terminal it was typed in. Same layout as session.py."""
import os, pty, re, select, sys, time

PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] )$')

class Term:
    def __init__(self, db):
        env = dict(os.environ, PAGER='', PSQL_PAGER='', COLUMNS='400', LINES='400')
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.execvpe('psql', ['psql', '-n', '-P', 'pager=off', db], env)
        _, self.prompt = self._read(60)
        self.log, self.pending = [], None

    def _read(self, timeout):
        buf, end = b'', time.time() + timeout
        while time.time() < end:
            r, _, _ = select.select([self.fd], [], [], 0.2)
            if r:
                chunk = os.read(self.fd, 65536)
                if not chunk:
                    return buf, None
                buf += chunk
                m = PROMPT.search(buf)
                if m:
                    r, _, _ = select.select([self.fd], [], [], 0.3)
                    if not r:
                        return buf[:m.start(1)], m.group(1).decode()
        raise SystemExit('terms.py: no prompt; got %r' % buf)

    def run(self, line, timeout=600):
        """type a line and wait for the prompt to come back"""
        self.start(line)
        self.wait(timeout)

    def start(self, line):
        """type a line and do not wait: the statement may be blocked"""
        os.write(self.fd, line.encode() + b'\n')
        self.pending = line

    def wait(self, timeout=600):
        out, nprompt = self._read(timeout)
        text = out.replace(b'\r\n', b'\n').decode()
        echo = self.pending + '\n'
        if text.startswith(echo):
            text = text[len(echo):]
        self.log.append((self.prompt, self.pending, text.rstrip('\n')))
        self.prompt, self.pending = nprompt, None

    def show(self, first):
        """print the transcript, with `first` as the shell line that opened it"""
        sys.stdout.write(first + '\n')
        gap = False
        for prompt, line, text in self.log:
            if gap:
                sys.stdout.write('\n')
            sys.stdout.write(prompt + line + '\n')
            if text:
                sys.stdout.write(text + '\n')
            gap = bool(text)
        sys.stdout.flush()
PY
scenario() { # scenario NAME: python on stdin, run as ana with Term importable
  lab root "cat > /usr/local/lib/lab/scenario-$1.py"
  lab as "python3 /usr/local/lib/lab/scenario-$1.py"
}

block copy
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
\timing on
CREATE TABLE orders_live AS SELECT * FROM orders;
\q
EOF

block queue
scenario queue <<'EOF'
import sys, time
sys.path.insert(0, '/usr/local/lib/lab')
from terms import Term
a, b, c, d = Term('shop'), Term('shop'), Term('shop'), Term('shop')
for t in (a, b, c):
    t.run('SELECT pg_backend_pid();')
a.run('BEGIN;')
a.run('SELECT count(*) FROM orders_live;')
b.run('\\timing on')
b.start('ALTER TABLE orders_live ADD COLUMN note text;')
time.sleep(1)
c.run('\\timing on')
c.start("SELECT status FROM orders_live WHERE id = 1;")
time.sleep(1)
d.run("SELECT pid, pg_blocking_pids(pid) AS blocked_by, state, wait_event_type, wait_event, left(query, 45) AS query FROM pg_stat_activity WHERE datname = 'shop' AND pid <> pg_backend_pid() ORDER BY backend_start;")
d.run("SELECT pid, mode, granted FROM pg_locks WHERE relation = 'orders_live'::regclass ORDER BY granted DESC, pid;")
time.sleep(1)
a.run('COMMIT;')
b.wait()
c.wait()
print('##### queue-a'); a.show('ana@db:~$ psql shop')
print('##### queue-b'); b.show('ana@db:~$ psql shop')
print('##### queue-c'); c.show('ana@db:~$ psql shop')
print('##### queue-d'); d.show('ana@db:~$ psql shop')
EOF

block timeout
scenario timeout <<'EOF'
import sys, time
sys.path.insert(0, '/usr/local/lib/lab')
from terms import Term
a, b, c = Term('shop'), Term('shop'), Term('shop')
a.run('BEGIN;')
a.run('SELECT count(*) FROM orders_live;')
b.run('\\timing on')
b.run("SET lock_timeout = '2s';")
b.start('ALTER TABLE orders_live ADD COLUMN source text;')
time.sleep(0.5)
c.run('\\timing on')
c.run("SELECT status FROM orders_live WHERE id = 1;")
b.wait()
a.run('COMMIT;')
print('##### timeout-a'); a.show('ana@db:~$ psql shop')
print('##### timeout-b'); b.show('ana@db:~$ psql shop')
print('##### timeout-c'); c.show('ana@db:~$ psql shop')
EOF

block retry
python3 - "$(pwd)/lock-timeout.md" <<'EOF' | lab as 'cat > retry-ddl.sh'
import json, sys
text = open(sys.argv[1], encoding='utf-8').read()
body = text.split('```schooling-example\n', 1)[1].split('\n```', 1)[0]
ex = json.loads(body)
sys.stdout.write(''.join(p['code'] + '\n' for p in ex['parts']))
EOF
scenario retry <<'EOF'
import subprocess, sys, time
sys.path.insert(0, '/usr/local/lib/lab')
from terms import Term
a = Term('shop')
a.run('BEGIN;')
a.run('SELECT count(*) FROM orders_live;')
p = subprocess.Popen(['bash', 'retry-ddl.sh'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
time.sleep(8)
a.run('COMMIT;')
out = p.communicate()[0].decode()
print('##### retry-a'); a.show('ana@db:~$ psql shop')
print('##### retry-b'); sys.stdout.write('ana@db:~$ bash retry-ddl.sh\n' + out)
EOF

block cheap
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
\timing on
SET client_min_messages = debug1;
SELECT pg_relation_filepath('orders_live');
ALTER TABLE orders_live ADD COLUMN channel text NOT NULL DEFAULT 'web';
SELECT pg_relation_filepath('orders_live');
BEGIN;
ALTER TABLE orders_live ADD COLUMN token uuid DEFAULT gen_random_uuid();
ALTER TABLE orders_live ALTER COLUMN total_cents TYPE bigint;
SELECT pg_relation_filepath('orders_live');
SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
ROLLBACK;
SELECT pg_relation_filepath('orders_live');
ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(20);
ALTER TABLE orders_live ALTER COLUMN status TYPE varchar(40);
\q
EOF

block check-plain
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
\timing on
BEGIN;
ALTER TABLE orders_live ADD CONSTRAINT total_positive CHECK (total_cents > 0);
SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();
ROLLBACK;
ALTER TABLE orders_live ADD CONSTRAINT total_positive CHECK (total_cents > 0) NOT VALID;
INSERT INTO orders_live (id, customer_id, status, total_cents, created_at) VALUES (0, 1, 'paid', 0, now());
\q
EOF

block validate
scenario validate <<'EOF'
import sys, time
sys.path.insert(0, '/usr/local/lib/lab')
from terms import Term
a, b = Term('shop'), Term('shop')
a.run('\\timing on')
a.run('BEGIN;')
a.run('ALTER TABLE orders_live VALIDATE CONSTRAINT total_positive;')
a.run("SELECT mode FROM pg_locks WHERE relation = 'orders_live'::regclass AND pid = pg_backend_pid();")
b.run('\\timing on')
b.run("UPDATE orders_live SET status = 'shipped' WHERE id = 2;")
a.run('COMMIT;')
print('##### validate-a'); a.show('ana@db:~$ psql shop')
print('##### validate-b'); b.show('ana@db:~$ psql shop')
EOF

block pkey
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
\timing on
CREATE UNIQUE INDEX CONCURRENTLY orders_live_id ON orders_live (id);
ALTER TABLE orders_live ADD CONSTRAINT id_not_null CHECK (id IS NOT NULL) NOT VALID;
ALTER TABLE orders_live VALIDATE CONSTRAINT id_not_null;
SET client_min_messages = debug1;
ALTER TABLE orders_live ADD CONSTRAINT orders_live_pkey PRIMARY KEY USING INDEX orders_live_id;
RESET client_min_messages;
ALTER TABLE orders_live DROP CONSTRAINT id_not_null;
\d orders_live
\q
EOF

fence $L/expand-and-contract.md '-- expand.sql' | lab as 'cat > expand.sql'
fence $L/expand-and-contract.md '-- backfill.sql' | lab as 'cat > backfill.sql'
block expand
on 'psql shop -f expand.sql'
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
UPDATE orders_live SET total_cents = total_cents + 1 WHERE id = 5 RETURNING id, total_cents, total_cents_new;
SELECT id, total_cents, total_cents_new FROM orders_live WHERE id IN (5, 6);
\q
EOF

block backfill
on 'psql shop -f backfill.sql'
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
\timing on
CALL backfill_total_cents(100000);
SELECT count(*) FROM orders_live WHERE total_cents_new IS DISTINCT FROM total_cents;
\q
EOF

block notnull
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
ALTER TABLE orders_live ADD CONSTRAINT total_cents_new_not_null CHECK (total_cents_new IS NOT NULL) NOT VALID;
ALTER TABLE orders_live VALIDATE CONSTRAINT total_cents_new_not_null;
SET client_min_messages = debug1;
ALTER TABLE orders_live ALTER COLUMN total_cents_new SET NOT NULL;
RESET client_min_messages;
ALTER TABLE orders_live DROP CONSTRAINT total_cents_new_not_null;
\q
EOF

fence $L/expand-and-contract.md '-- switch.sql' | lab as 'cat > switch.sql'
block switch
on 'psql shop -f switch.sql'

block contract
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
\timing on
ALTER TABLE orders_live DROP COLUMN total_cents_old;
\d orders_live
\q
EOF

block tidy
printf 'ana@db:~$ psql shop\n'
session shop <<'EOF'
DROP TABLE orders_live;
DROP FUNCTION orders_live_sync();
DROP PROCEDURE backfill_total_cents(bigint);
\dt
\q
EOF

lab as 'rm -f retry-ddl.sh expand.sql backfill.sql switch.sql'
lab down
