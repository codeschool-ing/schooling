#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the bookshop database as lesson 11 leaves
# it. A fresh database, then the bookshop of lesson 11 built and started once
# and stopped, so its schema.sql and data.sql fill the tables exactly as they
# did for the student. The lesson does not touch ~/bookshop. ~/jdbi-look/pom.xml
# and Titles.java are taken from jdbi.md, the second one by joining the code
# parts of its example, so what runs is what the lesson shows. The detour's edit
# (b.price_cents to b.price) is made with sed and undone the same way.
#
# The EBean, jOOQ and MyBatis code in this lesson is shown as a sketch and was
# NOT run here: the lesson says so beside each one.
#
# The first build downloads JDBI and the dependency plugin through the lab's
# mirror of Maven Central; -q, which the student types too, prints nothing of it.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, PostgreSQL 16,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

# Titles.java is an example in jdbi.md: its code parts joined with newlines.
example() {
  python3 - "$1" "$2" <<'PY'
import json, sys
md, name = sys.argv[1], sys.argv[2]
blocks, cur, info = [], None, ''
for line in open(md, encoding='utf-8').read().split('\n'):
    if line.startswith('```'):
        if cur is None:
            cur, info = [], line[3:].strip()
        else:
            blocks.append((info, '\n'.join(cur))); cur = None
    elif cur is not None:
        cur.append(line)
hits = [json.loads(b) for i, b in blocks if i == 'schooling-example' and json.loads(b).get('file') == name]
assert len(hits) == 1, hits
sys.stdout.write('\n'.join(p['code'] for p in hits[0]['parts']) + '\n')
PY
}

stage le-95z47qtq           # the bookshop as lesson 11 left it
db                          # a fresh bookshop database
at '~/bookshop'
quiet 'mvn -B -q package -DskipTests'
start                       # schema.sql and data.sql fill the database
stop
grep -q 'Started BookshopApplication' /tmp/bookshop.log || echo '!!! the bookshop did not start'
asroot 'rm -rf /home/ana/jdbi-look'

at '~'
block mkdir
run 'mkdir -p jdbi-look/src/main/java/com/example/look'
take jdbi.md '<?xml' jdbi-look/pom.xml
example jdbi.md Titles.java | put jdbi-look/src/main/java/com/example/look/Titles.java

block run
run 'cd jdbi-look'
at '~/jdbi-look'
run 'mvn -q compile dependency:build-classpath -Dmdep.outputFile=cp.txt'
run "tr ':' '\n' < cp.txt"
run "java -cp \"target/classes:\$(cat cp.txt)\" com.example.look.Titles 'Machado de Assis'"
run "java -cp \"target/classes:\$(cat cp.txt)\" com.example.look.Titles 'H. G. Wells'"

block typo
quiet "sed -i 's/SELECT b.title, b.price_cents/SELECT b.title, b.price/' src/main/java/com/example/look/Titles.java"
grep -q 'SELECT b.title, b.price$' /home/ana/jdbi-look/src/main/java/com/example/look/Titles.java \
  || echo '!!! the detour edit did not apply'
run 'mvn -q compile'
run "java -cp \"target/classes:\$(cat cp.txt)\" com.example.look.Titles 'Machado de Assis' 2>&1 | head -n 3"
quiet "sed -i 's/SELECT b.title, b.price\$/SELECT b.title, b.price_cents/' src/main/java/com/example/look/Titles.java && mvn -q compile"

block restored
run "java -cp \"target/classes:\$(cat cp.txt)\" com.example.look.Titles 'Machado de Assis'"
example jdbi.md Titles.java > /tmp/l12-titles.java
cmp -s /tmp/l12-titles.java /home/ana/jdbi-look/src/main/java/com/example/look/Titles.java \
  || echo '!!! Titles.java was not restored to the lesson text'
