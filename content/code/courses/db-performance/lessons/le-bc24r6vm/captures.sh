#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset: market as ~/reset-market.sh
# leaves it). ~/nightly-job.sql is taken out of this lesson's advisory.md and
# run as it is printed there.
#
# SEVERAL WINDOWS AT ONCE. The lesson has the student open two or three
# terminals, each with `psql market`, and type into them in turn. Here the
# windows are psql processes on pseudo-terminals, driven by the small program
# below (MULTI), which types each line into the window named before the colon,
# waits for that window's prompt, and if no prompt comes within a few seconds
# leaves the window waiting, which is exactly what a blocked statement does,
# and goes on to the next line. `show NAME A` prints what window A gained since
# it was last shown; a window shown while it was still waiting is shown again
# from the waiting command. Each fence in the lesson is one window at one
# moment, and the `Time:` lines are psql's own, including the long ones that
# measure a wait. `wait N` is the author's pause between steps, standing in for
# the seconds a person takes to move to the other window.
#
# STAGED: `pg_sleep` stands in for a slow report and for a nightly job's work,
# and the lesson says so where it uses it.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
windows() { lab as 'python3 /tmp/multi.py'; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
lab as 'cat > /tmp/multi.py' <<'MULTI'
#!/usr/bin/env python3
"""Drive several interactive psql sessions at once; print what each window showed.

    python3 multi.py < script

Script lines:
  open A [psql args...]     start window A (psql -n -P pager=off ARGS), e.g. `open A market`
  A: text                   type `text` at A's prompt; wait up to 3 s for the next prompt.
                            No prompt by then: A is left waiting (blocked) and the script goes on.
  A~20: text                the same, waiting up to 20 s
  A!: text                  type it and do not wait at all
  wait N                    sleep N seconds, collecting output meanwhile
  show NAME A               print `##### NAME` and the lines window A gained since its last show;
                            if A was waiting at its last show, start again from the waiting command
  sh NAME command           print `##### NAME` and the output of a shell command (not a window)
Lines starting with # are comments. Layout is lab/session.py's: a blank line between one
command's output and the next prompt.
"""
import os, pty, re, select, subprocess, sys, time

PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] )$')
S = {}

class Win:
    def __init__(self, name, args):
        env = dict(os.environ, PAGER='', PSQL_PAGER='', COLUMNS='400', LINES='400')
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.execvpe('psql', ['psql', '-n', '-P', 'pager=off'] + args, env)
        self.raw = b''; self.lines = []; self.shown = 0; self.prompt = None
        self.busy = False; self.cmdstart = 0; self.reshow = None; self.gap = False; self.cmd = ''
        end = time.time() + 20
        while time.time() < end and not self.finish(start=True):
            self.pump(0.2)
        if self.prompt is None: sys.exit('no prompt from ' + name)

    def pump(self, t):
        r, _, _ = select.select([self.fd], [], [], t)
        if r:
            try: c = os.read(self.fd, 65536)
            except OSError: c = b''
            self.raw += c
            return bool(c)
        return False

    def finish(self, start=False):
        m = PROMPT.search(self.raw)
        if not m: return False
        out = self.raw[:m.start(1)]; self.raw = b''
        if not start:
            text = out.replace(b'\r\n', b'\n').decode()
            echo = self.cmd + '\n'
            if text.startswith(echo): text = text[len(echo):]
            text = text.rstrip('\n')
            if text: self.lines += text.split('\n')
            self.gap = bool(text)
        self.prompt = m.group(1).decode(); self.busy = False
        return True

    def poll(self):
        while self.pump(0.05): pass
        if self.busy: self.finish()

    def type(self, text, timeout):
        if self.busy: sys.exit('window busy: ' + text)
        if self.gap: self.lines.append('')
        self.cmdstart = len(self.lines)
        self.lines.append(self.prompt + text)
        self.cmd = text; self.busy = True
        os.write(self.fd, text.encode() + b'\n')
        end = time.time() + timeout
        while time.time() < end:
            self.pump(0.1)
            m = PROMPT.search(self.raw)
            if m:
                time.sleep(0.3); self.pump(0)
                if self.finish(): return
        # still waiting: left busy

def pollall(t=0.0):
    end = time.time() + t
    while True:
        for w in S.values(): w.poll()
        if time.time() >= end: break
        time.sleep(0.05)

for line in sys.stdin.read().split('\n'):
    if not line.strip() or line.startswith('#'): continue
    m = re.match(r'^([A-Z])(~(\d+)|!)?: (.*)$', line)
    if m:
        pollall(0.2)
        w = S[m.group(1)]
        t = 0 if m.group(2) == '!' else (int(m.group(3)) if m.group(3) else 3)
        w.type(m.group(4), t)
        continue
    parts = line.split(' ')
    if parts[0] == 'open':
        S[parts[1]] = Win(parts[1], parts[2:])
    elif parts[0] == 'wait':
        pollall(float(parts[1]))
    elif parts[0] == 'show':
        pollall(0.5)
        w = S[parts[2]]
        start = w.shown if w.reshow is None else w.reshow
        sys.stdout.write('##### %s\n' % parts[1])
        sys.stdout.write('\n'.join(l for l in w.lines[start:]).strip('\n') + '\n')
        w.shown = len(w.lines)
        w.reshow = w.cmdstart if w.busy else None
        sys.stdout.flush()
    elif parts[0] == 'sh':
        pollall(0.2)
        sys.stdout.write('##### %s\n' % parts[1])
        sys.stdout.write(subprocess.run(' '.join(parts[2:]), shell=True, capture_output=True, text=True).stdout)
        sys.stdout.flush()
    else:
        sys.exit('bad line: ' + line)

for w in S.values():
    w.poll()
    try: os.write(w.fd, b'\\q\n')
    except OSError: pass
MULTI
python3 "$FENCE" advisory.md 'cat > ~/nightly-job.sql' | lab as 'bash'

PEEK="SELECT relation::regclass AS relation, mode, granted FROM pg_locks WHERE locktype = 'relation' AND pid <> pg_backend_pid() ORDER BY 1;"

# ---- table-locks
windows <<W
open A market
open B market
A: BEGIN;
A: SELECT count(*) FROM orders WHERE seller_id = 42;
show tl-a1 A
B: $PEEK
show tl-b1 B
A: UPDATE orders SET status = 'shipped' WHERE id = 1;
show tl-a2 A
B: $PEEK
show tl-b2 B
B: CREATE INDEX orders_status_idx ON orders (status);
show tl-b3 B
wait 4
A: ROLLBACK;
show tl-a3 A
wait 3
show tl-b4 B
B: DROP INDEX orders_status_idx;
W

# ---- row-locks
windows <<W
open A market
open B market
A: BEGIN;
A: UPDATE orders SET status = 'shipped' WHERE id = 1;
show rl-a1 A
B: BEGIN;
B: UPDATE orders SET status = 'shipped' WHERE id = 2;
B: SELECT status FROM orders WHERE id = 1;
B: SELECT status FROM orders WHERE id = 1 FOR UPDATE NOWAIT;
B: ROLLBACK;
B: BEGIN;
B: SELECT status FROM orders WHERE id = 1 FOR UPDATE;
show rl-b1 B
wait 3
A: COMMIT;
show rl-a2 A
show rl-b2 B
B: ROLLBACK;
show skip B
A: BEGIN;
A: SELECT status FROM orders WHERE id = 3 FOR SHARE;
show sh-a1 A
B: BEGIN;
B: SELECT status FROM orders WHERE id = 3 FOR SHARE;
B: UPDATE orders SET status = 'cancelled' WHERE id = 3;
show sh-b1 B
wait 2
A: ROLLBACK;
show sh-a2 A
show sh-b2 B
B: ROLLBACK;
W

# ---- the job queue
QUEUE="UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE SKIP LOCKED) RETURNING id;"
WAITQ="UPDATE orders SET status = 'packing' WHERE id IN (SELECT id FROM orders WHERE status = 'pending' ORDER BY id LIMIT 3 FOR UPDATE) RETURNING id;"
windows <<W
open A market
open B market
A: BEGIN;
A: $WAITQ
B: BEGIN;
B: $WAITQ
show jq-a1 A
show jq-b1 B
wait 3
A: COMMIT;
show jq-a2 A
show jq-b2 B
B: ROLLBACK;
show skip B
A: BEGIN;
A: $QUEUE
B: BEGIN;
B: $QUEUE
show jq-a3 A
show jq-b3 B
A: ROLLBACK;
B: ROLLBACK;
W

# ---- the queue behind an ALTER
windows <<W
open A market
open B market
open C market
A!: SELECT pg_sleep(15), status FROM orders WHERE id = 1;
wait 1
B!: ALTER TABLE orders ADD COLUMN gift_note text;
wait 1
C!: SELECT status FROM orders WHERE id = 2;
wait 2
show q-a1 A
show q-b1 B
show q-c1 C
wait 13
show q-a2 A
show q-b2 B
show q-c2 C
B: ALTER TABLE orders DROP COLUMN gift_note;
A!: SELECT pg_sleep(10), status FROM orders WHERE id = 1;
wait 1
B: SET lock_timeout = '2s';
B!: ALTER TABLE orders ADD COLUMN gift_note text;
wait 0.5
C!: SELECT status FROM orders WHERE id = 2;
wait 4
show lt-b B
show lt-c C
wait 6
W

# ---- advisory locks
windows <<W
open A market
open B market
A: SELECT pg_try_advisory_lock(42);
B: SELECT pg_try_advisory_lock(42);
B: SELECT pg_advisory_lock(42);
show ad-a1 A
show ad-b1 B
wait 2
A: SELECT pg_advisory_unlock(42);
show ad-a2 A
show ad-b2 B
B: SELECT pg_advisory_unlock(42);
W

block nightly
on 'psql -qX market -f nightly-job.sql & sleep 1; psql -qX market -f nightly-job.sql; wait'

# ---- deadlock
windows <<W
open A market
open B market
A: BEGIN;
A: UPDATE orders SET status = 'shipped' WHERE id = 1;
B: BEGIN;
B: UPDATE orders SET status = 'shipped' WHERE id = 2;
A: UPDATE orders SET status = 'shipped' WHERE id = 2;
show dl-a1 A
show dl-b1 B
B: UPDATE orders SET status = 'shipped' WHERE id = 1;
show dl-b2 B
show dl-a2 A
B: ROLLBACK;
A: ROLLBACK;
W

block deadlock-log
on 'sudo tail -n 8 /var/log/postgresql/postgresql-16-main.log'

# ---- the cure: one order for everybody
windows <<W
open A market
open B market
A: BEGIN;
A: SELECT id FROM orders WHERE id IN (2, 1) ORDER BY id FOR UPDATE;
B: BEGIN;
B: SELECT id FROM orders WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
show or-a1 A
show or-b1 B
A: UPDATE orders SET status = 'shipped' WHERE id = 2;
A: UPDATE orders SET status = 'shipped' WHERE id = 1;
A: COMMIT;
show or-a2 A
show or-b2 B
B: ROLLBACK;
W
