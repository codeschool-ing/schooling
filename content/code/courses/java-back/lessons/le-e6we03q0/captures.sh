#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - PostgreSQL 16 itself. The lab installed it with `apt-get install
#     postgresql` when it was built; the lesson shows `sudo apt install -y
#     postgresql` and nothing here runs it again. Everything after the install
#     is real: the role and the database are dropped first (WITH (FORCE), as
#     root) so that the lesson's own commands create them.
#   - sudo. ana has no password-less sudo in the lab, so the two commands the
#     lesson types as `sudo -u postgres ...`, and the `sudo grep` of the
#     server's log, are run by root, as typed, from /home/ana.
#   - an interactive psql is typed at line by line in a pseudo-terminal (the
#     small program below); the prompts and every word printed are psql's.
#   - the bookshop starts as lesson 7 left it; the one deletion is typed, and
#     the files this lesson shows are copied from its stage and then checked
#     against the lesson, byte for byte. Jdbc.java and Unsafe.java are taken
#     out of the lesson's own .md files.
#   - the application runs in the background (`start`); the lesson presents
#     its log as the second terminal a student would see it in.
#
# Times, pids, process ids in the logs and connection hashes differ per run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
STAGE=$COURSE/lab/stages/le-e6we03q0
JAR='~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar'
URI='postgresql://bookshop:bookshop@localhost:5432/bookshop'

sudorun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; ( cd /home/ana && bash -c "$1" ) 2>&1 9>&- || true; }

cat > /tmp/le-e6we03q0-session.py <<'PY'
import os, pty, re, select, sys, time
PROMPT = re.compile(rb'(?:^|\n)([A-Za-z0-9_]+[=\-*(\'"!]*\*?[#>] )$')
def read_until_prompt(fd, timeout=120):
    buf = b''; end = time.time() + timeout
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: chunk = os.read(fd, 65536)
            except OSError: return buf, None
            if not chunk: return buf, None
            buf += chunk
            m = PROMPT.search(buf)
            if m:
                r, _, _ = select.select([fd], [], [], 0.3)
                if not r: return buf[:m.start(1)], m.group(1).decode()
    raise SystemExit('session: no prompt; got:\n' + buf.decode(errors='replace'))
args = sys.argv[1:]
lines = sys.stdin.read().split('\n')
if lines and lines[-1] == '': lines.pop()
env = dict(os.environ, PAGER='', PSQL_PAGER='', COLUMNS='400', LINES='400')
pid, fd = pty.fork()
if pid == 0:
    os.execvpe('psql', ['psql', '-n', '-P', 'pager=off'] + args, env)
out, prompt = read_until_prompt(fd)
sys.stdout.write(out.replace(b'\r\n', b'\n').decode())
gap = False
for line in lines:
    if gap: sys.stdout.write('\n')
    os.write(fd, line.encode() + b'\n')
    out, nprompt = read_until_prompt(fd)
    text = out.replace(b'\r\n', b'\n').decode()
    if text.startswith(line + '\n'): text = text[len(line) + 1:]
    text = text.rstrip('\n')
    sys.stdout.write(prompt + line + '\n')
    if text: sys.stdout.write(text + '\n')
    gap = bool(text); prompt = nprompt
    if prompt is None: break
if prompt is not None: os.write(fd, b'\\q\n')
os.waitpid(pid, 0)
PY
chmod 644 /tmp/le-e6we03q0-session.py
session() { printf 'ana@vm:%s$ psql %s\n' "$HERE" "$1"; lab exec "cd $(dir) && python3 /tmp/le-e6we03q0-session.py $1" 2>&1 || true; }
example() { python3 -c 'import json,sys,re
t=open(sys.argv[1]).read()
for b in re.findall(r"```schooling-example\n(.*?)\n```", t, re.S):
    e=json.loads(b)
    if e.get("file")==sys.argv[2]: print("\n".join(p["code"] for p in e["parts"]))' "$1" "$2"; }

stage le-k1349km8
asroot "runuser -u postgres -- psql -qX -c 'DROP DATABASE IF EXISTS bookshop WITH (FORCE)' -c 'DROP ROLE IF EXISTS bookshop'"
quiet 'rm -f ~/Jdbc.java ~/Unsafe.java'

block versions
run 'psql --version'
run 'pg_lsclusters'
block no-role
run 'psql'
block role
sudorun "sudo -u postgres psql -c \"CREATE ROLE bookshop LOGIN PASSWORD 'bookshop'\""
sudorun 'sudo -u postgres createdb -O bookshop bookshop'
block peer
run 'psql -U bookshop bookshop'
block connect
session "$URI" <<'EOF'
SELECT current_user, current_database();
EOF

block sql
session "$URI" <<'EOF'
CREATE TABLE book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author      text      NOT NULL,
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
INSERT INTO book (isbn, title, author, price_cents) VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000047', 'The War of the Worlds', 'H. G. Wells', 3200),
    ('9786500000054', 'Wise Blood', 'Flannery O''Connor', 4100);
SELECT * FROM book;
SELECT title, price_cents FROM book WHERE author = 'H. G. Wells';
INSERT INTO book (isbn, title, author, price_cents) VALUES ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950);
INSERT INTO book (isbn, title, author, price_cents) VALUES ('9786500000030', 'Frankenstein', 'Mary Shelley', -1);
EOF

example plain-jdbc.md Jdbc.java | put Jdbc.java
take parameters.md 'import java.sql' Unsafe.java

block jar
run 'mvn -q dependency:get -Dartifact=org.postgresql:postgresql:42.7.13'
run 'ls ~/.m2/repository/org/postgresql/postgresql/42.7.13/'
block nodriver
run "java Jdbc.java 'H. G. Wells' 2>&1 | head -n 3"
block jdbc
run "java -cp $JAR Jdbc.java 'H. G. Wells'"
run "java -cp $JAR Jdbc.java \"Flannery O'Connor\""
run "java -cp $JAR Jdbc.java 'Mary Shelley'"
block unsafe
run "java -cp $JAR Unsafe.java 'H. G. Wells'"
run "java -cp $JAR Unsafe.java \"Flannery O'Connor\" 2>&1 | head -n 4"

block boot
at '~/bookshop'
asroot "cp -a $STAGE/pom.xml /home/ana/bookshop/ && cp -a $STAGE/src/. /home/ana/bookshop/src/ && chown -R ana:ana /home/ana/bookshop"
shown the-bookshop-gets-a-database.md pom.xml src/main/resources/application.properties src/main/resources/schema.sql src/main/resources/data.sql
shown jdbc-client.md src/main/java/com/example/bookshop/catalogue/JdbcBookRepository.java
run "mvn dependency:tree | grep -E 'jdbc|postgresql|Hikari'"
run "psql $URI -c 'DROP TABLE book'"
block build
run 'rm src/main/java/com/example/bookshop/catalogue/InMemoryBookRepository.java'
run 'mvn -q package'
start
block log
cat /tmp/bookshop.log
block curl
run 'curl -s localhost:8080/books | python3 -m json.tool'
run "curl -si -w '\\n' localhost:8080/books -H 'Content-Type: application/json' -d '{\"isbn\": \"9786500000054\", \"title\": \"Wise Blood\", \"author\": \"Flannery O'\\''Connor\", \"priceCents\": 4100}'"
run "psql $URI -c 'SELECT id, title, author FROM book'"
block pool
run "psql $URI -c \"SELECT application_name, state, count(*) FROM pg_stat_activity WHERE usename = 'bookshop' GROUP BY 1, 2\""
stop
block restart
start
grep 'Catalogue opened' /tmp/bookshop.log
stop

block fail
run 'java -jar target/bookshop-0.1.0.jar --spring.datasource.url=jdbc:postgresql://localhost:5433/bookshop 2>&1 | grep "Caused by: org.postgresql"'
run 'java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | grep "Caused by: org.postgresql"'
run 'java -jar target/bookshop-0.1.0.jar --spring.datasource.username=bookshp 2>&1 | grep "Caused by: org.postgresql"'
run 'java -jar target/bookshop-0.1.0.jar --spring.datasource.url=jdbc:postgresql://localhost:5432/bookshp 2>&1 | grep "Caused by: org.postgresql"'
sudorun "sudo grep bookshp /var/log/postgresql/postgresql-16-main.log | tail -n 3"
block failsize
run 'java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | wc -l'
run 'java -jar target/bookshop-0.1.0.jar --spring.datasource.password=wrong 2>&1 | grep -E "ERROR|Caused by" | cut -c1-110'

block end
quiet 'rm -f ~/Jdbc.java ~/Unsafe.java'
