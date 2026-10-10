#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where every lesson from 5 starts: shop loaded, ana a superuser.
#
# STAGED, AND WHY:
#   - The lesson tells the student to edit pg_hba.conf with an editor (one
#     line gains ` map=shop`) and to put that line back afterwards. Here the
#     edit is made with sed and undone by copying the backup back; what the
#     lesson shows is the file afterwards, read with grep, and the server's
#     own view of it.
#   - The pg_ident.conf lines and ~/.pgpass are taken out of the lesson's .md
#     and written as printed; the student types them into an editor.
#   - \password asks for the password twice on the terminal. lab/session.py
#     waits for psql's prompt, which a password prompt is not, so the session
#     that sets passwords goes through pw.py below: the same layout, plus an
#     answer to each password prompt that is typed and not shown, as on a
#     terminal.
export LAB_NAME=${LAB_NAME:-db}
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

lab reset 11

# session.py, taught to answer a password prompt: a line '#pw SECRET' is
# typed at the pending password prompt and not printed.
lab root 'cat > /usr/local/lib/lab/pw.py' <<'PY'
import os, pty, re, select, sys, time
PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] |Enter new password for user "[^"]+": |Enter it again: )$')
def until(fd):
    buf = b''
    while True:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: c = os.read(fd, 65536)
            except OSError: return buf, None
            if not c: return buf, None
            buf += c
            m = PROMPT.search(buf)
            if m and not select.select([fd], [], [], 0.3)[0]:
                return buf[:m.start(1)], m.group(1).decode()
lines = sys.stdin.read().rstrip('\n').split('\n')
pid, fd = pty.fork()
if pid == 0:
    os.execvpe('psql', ['psql', '-n', '-P', 'pager=off'] + sys.argv[1:], dict(os.environ, PAGER=''))
out, prompt = until(fd)
gap = False
for line in lines:
    if line.startswith('#pw '):
        sys.stdout.write(prompt + '\n')
        os.write(fd, line[4:].encode() + b'\n')
        out, prompt = until(fd)
        text = out.replace(b'\r\n', b'\n').decode().strip('\n')
        if text: sys.stdout.write(text + '\n')
        gap = bool(text)
        continue
    if gap: sys.stdout.write('\n')
    os.write(fd, line.encode() + b'\n')
    out, nprompt = until(fd)
    text = out.replace(b'\r\n', b'\n').decode()
    if text.startswith(line + '\n'): text = text[len(line) + 1:]
    text = text.rstrip('\n')
    sys.stdout.write(prompt + line + '\n')
    if text: sys.stdout.write(text + '\n')
    gap = bool(text) and not nprompt.startswith('Enter')
    prompt = nprompt
os.write(fd, b'\\q\n')
os.waitpid(pid, 0)
PY
pwsession() { lab as "python3 /usr/local/lib/lab/pw.py $*"; }

block roles-not-users
on 'id bruno'
cat <<'EOF' | session shop
SELECT rolname FROM pg_roles WHERE rolname !~ '^pg_';
CREATE ROLE reporting;
CREATE USER bruno;
CREATE USER app;
\du
EOF

block shared
cat <<'EOF' | session shop
SELECT relname, relisshared FROM pg_class WHERE relname IN ('pg_authid', 'pg_database', 'pg_class', 'customers');
\c ana
SELECT rolname FROM pg_roles WHERE rolname = 'bruno';
EOF

block createrole
cat <<'EOF' | session shop
CREATE ROLE steward LOGIN CREATEROLE;
SET ROLE steward;
CREATE ROLE intern LOGIN;
ALTER ROLE bruno CREATEDB;
ALTER ROLE intern SUPERUSER;
GRANT pg_read_all_data TO intern;
RESET ROLE;
\drg
EOF

block dropsteward
cat <<'EOF' | session shop
SET ROLE steward;
DROP ROLE intern;
RESET ROLE;
DROP ROLE steward;
EOF

block membership
cat <<'EOF' | session shop
GRANT SELECT ON customers TO reporting;
GRANT reporting TO bruno;
\drg
SET ROLE bruno;
SELECT current_user, session_user;
SELECT count(*) FROM customers;
SELECT count(*) FROM orders;
RESET ROLE;
EOF

block noinherit
cat <<'EOF' | session shop
GRANT reporting TO bruno WITH INHERIT FALSE;
SET ROLE bruno;
SELECT count(*) FROM customers;
RESET ROLE;
EOF

block thelie
cat <<'EOF' | session shop
GRANT reporting TO bruno WITH INHERIT TRUE, SET FALSE;
\drg
SET ROLE bruno;
SET ROLE reporting;
SELECT current_user, session_user;
RESET ROLE;
EOF

block peer-refused
on 'psql -U bruno shop'

block backup
on 'sudo cp -p /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf.orig'
on 'sudo cp -p /etc/postgresql/16/main/pg_ident.conf /etc/postgresql/16/main/pg_ident.conf.orig'
lab root "sed -i 's/^\(local   all             all                                     peer\)\$/\1 map=shop/' /etc/postgresql/16/main/pg_hba.conf"
fence le-374xktzk/os-and-db.md '# pg_ident.conf' | lab root 'cat >> /etc/postgresql/16/main/pg_ident.conf'

block edited
on "sudo grep -n '^local' /etc/postgresql/16/main/pg_hba.conf"
cat <<'EOF' | session shop
SELECT map_name, sys_name, pg_username, error FROM pg_ident_file_mappings;
SELECT line_number, user_name, auth_method, options, error FROM pg_hba_file_rules WHERE type = 'local';
SELECT pg_reload_conf();
EOF

block asbruno
on 'psql -U reporting shop'
printf 'ana@db:~$ psql -U bruno shop\n'
cat <<'EOF' | session -U bruno shop
SELECT current_user, session_user;
SELECT count(*) FROM customers;
SET ROLE reporting;
EOF

block restore
on 'sudo mv /etc/postgresql/16/main/pg_hba.conf.orig /etc/postgresql/16/main/pg_hba.conf'
on 'sudo mv /etc/postgresql/16/main/pg_ident.conf.orig /etc/postgresql/16/main/pg_ident.conf'
on 'sudo ls -l /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_ident.conf'
on 'psql -c "SELECT pg_reload_conf();"'
on 'psql -U bruno shop'
cat <<'EOF' | session shop
REVOKE SELECT ON customers FROM reporting;
GRANT reporting TO bruno WITH SET TRUE;
EOF

block password
cat <<'EOF' | pwsession shop
SHOW password_encryption;
\password bruno
#pw bruno-lab-only
#pw bruno-lab-only
\password app
#pw app-lab-only
#pw app-lab-only
SELECT rolname, split_part(rolpassword, ':', 1) AS stored FROM pg_authid WHERE rolname IN ('bruno', 'app');
EOF

fence le-374xktzk/passwords.md '# ~/.pgpass' | lab as 'cat > ~/.pgpass'

block pgpass
on 'ls -l ~/.pgpass'
on 'psql -w -h localhost -U app shop -c "SELECT current_user;"'
on 'chmod 600 ~/.pgpass'
on 'psql -w -h localhost -U app shop -c "SELECT current_user;"'
on 'psql -w -h localhost -U bruno shop -c "SELECT current_user;"'

block leak
cat <<'EOF' | session shop
ALTER ROLE brunno PASSWORD 'bruno-lab-only';
EOF
on 'sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log'

block expired
cat <<'EOF' | session shop
ALTER ROLE app VALID UNTIL '2026-01-01';
\du app
EOF
on 'psql -w -h localhost -U app shop'
on 'sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log'
cat <<'EOF' | session shop
ALTER ROLE app VALID UNTIL 'infinity';
\du
\drg
EOF

lab down
