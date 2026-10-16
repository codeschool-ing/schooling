#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset: market as ~/reset-market.sh
# leaves it). Lesson 2's workload files are written again from lesson 2's own
# a-workload.md, as the student already has them in ~/workload;
# ~/workload/price-bump.sql is taken out of this lesson's read-committed.md,
# and ~/bump.py is put together from the parts of the annotated example in
# retrying.md, exactly as its copy button hands it over.
#
# SEVERAL WINDOWS AT ONCE, as in lessons 12 and 13: psql processes on
# pseudo-terminals driven by the small program below (MULTI). `getnum P A`
# remembers the number window A last printed on a line of its own (a price),
# and `{P+100}` in a later line is that number plus 100: it is what a person
# reading the price and typing the new one would type.
#
# STAGED: python3-psycopg is installed when the lab is built, so the apt line
# shown reports it as already installed. The pgbench runs use PGOPTIONS to set
# each run's isolation level, as the lesson shows.
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
                            lines is replaced by it, and {A+100} by it plus 100
  getnum X A                the same, remembered as X
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
    line = re.sub(r'\{(\w+)(\+\d+)?\}',
                  lambda m: str(int(VARS[m.group(1)]) + int(m.group(2) or 0)), line)
    m = re.match(r'^([A-Z])(~(\d+)|!)?: (.*)$', line)
    if m:
        pollall(0.2)
        w = S[m.group(1)]
        t = 0 if m.group(2) == '!' else (int(m.group(3)) if m.group(3) else 3)
        w.type(m.group(4), t)
        continue
    parts = line.split(' ')
    if parts[0] in ('getpid', 'getnum'):
        name, w = parts[1], S[parts[-1]]
        VARS[name] = next(l.strip() for l in reversed(w.lines) if l.strip().isdigit())
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
python3 "$FENCE" ../le-9kwvr0x4/a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null
python3 "$FENCE" read-committed.md 'cat > ~/workload/price-bump.sql' | lab as 'bash'
python3 - retrying.md <<'PY' | lab as 'cat > ~/bump.py'
import json, sys
s = open(sys.argv[1]).read()
i = s.index('```schooling-example\n') + len('```schooling-example\n')
sys.stdout.write(''.join(p['code'] for p in json.loads(s[i:s.index('\n```', i)])['parts']))
PY

# ---- read committed: the lost update, by hand
windows <<'W'
open A market
open B market
A: BEGIN;
A: SELECT price_cents FROM products WHERE id = 1;
getnum P A
show rc-a1 A
B: BEGIN;
B: SELECT price_cents FROM products WHERE id = 1;
show rc-b1 B
A: UPDATE products SET price_cents = {P+100} WHERE id = 1;
show rc-a2 A
B: UPDATE products SET price_cents = {P+100} WHERE id = 1;
show rc-b2 B
wait 2
A: COMMIT;
show rc-a3 A
B: COMMIT;
B: SELECT price_cents FROM products WHERE id = 1;
show rc-b3 B
A: BEGIN;
A: UPDATE products SET price_cents = price_cents + 100 WHERE id = 1;
B: BEGIN;
B: UPDATE products SET price_cents = price_cents + 100 WHERE id = 1;
wait 1
A: COMMIT;
show at-a A
B: COMMIT;
B: SELECT price_cents FROM products WHERE id = 1;
show at-b B
A: BEGIN;
A: SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
getnum Q A
show fu-a1 A
B: BEGIN;
B: SELECT price_cents FROM products WHERE id = 1 FOR UPDATE;
show fu-b1 B
A: UPDATE products SET price_cents = {Q+100} WHERE id = 1;
A: COMMIT;
show fu-a2 A
getnum R B
B: UPDATE products SET price_cents = {R+100} WHERE id = 1;
B: COMMIT;
B: SELECT price_cents FROM products WHERE id = 1;
show fu-b2 B
W

MEASURE() { # $1 = PGOPTIONS, $2 = extra pgbench flags
cat <<S
SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \\gset
\\! ${1:+PGOPTIONS='$1' }pgbench -n -c 8 -j 4 -T 10 $2 -f ~/workload/price-bump.sql market
SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
S
}
block bench-rc
MEASURE '' '' | lab psql market

# ---- repeatable read
windows <<'W'
open A market
open B market
A: BEGIN;
A: SELECT price_cents FROM products WHERE id = 2;
show nr-a A
B: UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
show nr-b B
A: SELECT price_cents FROM products WHERE id = 2;
A: COMMIT;
show nr-a2 A
A: BEGIN ISOLATION LEVEL REPEATABLE READ;
A: SELECT price_cents FROM products WHERE id = 2;
show rr-a1 A
B: UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
show rr-b1 B
A: SELECT price_cents FROM products WHERE id = 2;
A: UPDATE products SET price_cents = price_cents + 100 WHERE id = 2;
A: ROLLBACK;
show rr-a2 A
W

block bench-rr
MEASURE '-c default_transaction_isolation=repeatable\ read' '' | lab psql market

# ---- serializable: write skew
SKEW_COUNT="SELECT count(*) FROM orders WHERE customer_id = 7 AND status = 'pending';"
SKEW_INSERT="INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (7, 2, now(), 'pending', 1000);"
windows <<W
open A market
open B market
A: BEGIN ISOLATION LEVEL REPEATABLE READ;
A: $SKEW_COUNT
B: BEGIN ISOLATION LEVEL REPEATABLE READ;
B: $SKEW_COUNT
show ws-a1 A
show ws-b1 B
A: $SKEW_INSERT
B: $SKEW_INSERT
A: COMMIT;
B: COMMIT;
show ws-a2 A
show ws-b2 B
A: $SKEW_COUNT
show ws-check A
A: DELETE FROM orders WHERE customer_id = 7 AND status = 'pending';
show skip A
B: \\set VERBOSITY verbose
A: BEGIN ISOLATION LEVEL SERIALIZABLE;
A: $SKEW_COUNT
B: BEGIN ISOLATION LEVEL SERIALIZABLE;
B: $SKEW_COUNT
show sr-a1 A
show sr-b1 B
A: $SKEW_INSERT
B: $SKEW_INSERT
A: COMMIT;
B: COMMIT;
show sr-a2 A
show sr-b2 B
A: $SKEW_COUNT
show sr-check A
W

# ---- retrying
block bench-ser
MEASURE '-c default_transaction_isolation=serializable' '--max-tries=10' | lab psql market

block apt
on 'sudo apt install -y python3-psycopg'

block run
lab psql market <<'S'
SELECT price_cents FROM products WHERE id = 1;
\! python3 ~/bump.py 500 & python3 ~/bump.py 500 & wait
SELECT price_cents FROM products WHERE id = 1;
S
