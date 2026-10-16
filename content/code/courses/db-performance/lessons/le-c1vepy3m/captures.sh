#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset: market as ~/reset-market.sh
# leaves it). ~/blocked.sql and ~/lock-tree.sql are taken out of this
# lesson's blocking-pids.md and the-chain.md and run as they are printed there.
#
# SEVERAL WINDOWS AT ONCE, as in lesson 12: four psql processes on
# pseudo-terminals (windows A, B and C make the blocking chain, window D looks
# at it), driven by the small program below (MULTI). It types each line into
# the window named before the colon and waits a few seconds for the prompt;
# with no prompt, the window is left waiting, as a blocked statement leaves
# it. `show NAME A` prints what window A gained since it was last shown.
# `getpid A` remembers the backend pid window A printed, so that window D can
# be told to cancel or terminate that pid, as a person would type the number
# they read. `wait N` is the author's pause between steps.
#
# STAGED: log_lock_waits is switched on with ALTER SYSTEM, as the lesson
# shows, and reset at the end of the script.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
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
  getpid A                  remember the number A last printed alone on a line; {A} in later
                            lines is replaced by it
  sh NAME command           print `##### NAME` and the output of a shell command (not a window)
Lines starting with # are comments. Layout is lab/session.py's: a blank line between one
command's output and the next prompt.
"""
import os, pty, re, select, subprocess, sys, time

PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] )$')
S = {}
VARS = {}

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
    for k, v in VARS.items():
        line = line.replace('{%s}' % k, v)
    m = re.match(r'^([A-Z])(~(\d+)|!)?: (.*)$', line)
    if m:
        pollall(0.2)
        w = S[m.group(1)]
        t = 0 if m.group(2) == '!' else (int(m.group(3)) if m.group(3) else 3)
        w.type(m.group(4), t)
        continue
    parts = line.split(' ')
    if parts[0] == 'getpid':
        w = S[parts[1]]
        VARS[parts[1]] = next(l.strip() for l in reversed(w.lines) if l.strip().isdigit())
    elif parts[0] == 'open':
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
python3 "$FENCE" blocking-pids.md 'cat > ~/blocked.sql' | lab as 'bash'
python3 "$FENCE" the-chain.md 'cat > ~/lock-tree.sql' | lab as 'bash'

windows <<'W'
open A market
open B market
open C market
open D market
A: SELECT pg_backend_pid();
getpid A
show pid-a A
B: SELECT pg_backend_pid();
getpid B
show pid-b B
C: SELECT pg_backend_pid();
getpid C
show pid-c C
A: BEGIN;
A: UPDATE orders SET status = 'shipped' WHERE id = 1;
show a1 A
B: BEGIN;
B: UPDATE orders SET status = 'shipped' WHERE id = 2;
B: UPDATE orders SET status = 'shipped' WHERE id = 1;
show b1 B
C: UPDATE orders SET status = 'cancelled' WHERE id = 2;
show c1 C
wait 20
D: SELECT pid, locktype, relation::regclass, page, tuple, transactionid, mode, granted FROM pg_locks WHERE pid <> pg_backend_pid() AND locktype IN ('relation', 'transactionid', 'tuple') AND (relation IS NULL OR relation = 'orders'::regclass) ORDER BY pid, granted DESC, locktype;
show locks D
D: SELECT pid, pg_blocking_pids(pid) FROM pg_stat_activity WHERE wait_event_type = 'Lock';
show who D
D: \i ~/blocked.sql
show blocked D
D: \i ~/lock-tree.sql
show tree D
D: SELECT pg_cancel_backend({A});
D: \i ~/lock-tree.sql
show cancel-idle D
D: SELECT pg_terminate_backend({A});
D: \i ~/lock-tree.sql
show terminate D
show b2 B
A: SELECT status FROM orders WHERE id = 1;
show a2 A
D: SELECT pg_cancel_backend({C});
show cancel-c D
show c2 C
B: SELECT 1;
show b3 B
B: ROLLBACK;
show b4 B
W

block log-on
lab psql market <<'S'
ALTER SYSTEM SET log_lock_waits = on;
SELECT pg_reload_conf();
SHOW deadlock_timeout;
S

windows <<'W'
open A market
open B market
A: BEGIN;
A: UPDATE orders SET status = 'shipped' WHERE id = 3;
B: UPDATE orders SET status = 'cancelled' WHERE id = 3;
wait 4
A: COMMIT;
show lw-a A
show lw-b B
W

block log-lines
on 'sudo tail -n 8 /var/log/postgresql/postgresql-16-main.log'

lab as "psql -qX market -c 'ALTER SYSTEM RESET log_lock_waits' -c 'SELECT pg_reload_conf()'" >/dev/null
