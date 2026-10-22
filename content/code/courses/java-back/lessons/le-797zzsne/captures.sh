#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/javalin-hello's pom.xml and HelloApp.java
# are written from the fences of javalin-by-hand.md (the pom first without
# jackson-databind, then with the <dependencies> block the lesson shows), and
# ~/first-answer.sh from measured.md. ~/bookshop is the stage of lesson 7.
# The application in "the first terminal" runs in the background with its
# output in ~/javalin-hello/run.log, which is printed after the prompt line the
# student would have typed; it is stopped by its pid. Readiness is read from
# that log rather than probed with a request, so the first terminal shows the
# one request the lesson makes. Startup times, Jetty's
# object ids and dates differ on every run. Maven's cache is warm, so no
# transcript shows a download.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
MD=$PWD/javalin-by-hand.md

# The class, as the example's copy button hands it over: its parts joined.
example() { python3 - "$MD" <<'PY'
import json, sys
blocks, cur, info = [], None, ""
for line in open(sys.argv[1], encoding="utf-8").read().split("\n"):
    if line.startswith("```"):
        if cur is None:
            cur, info = [], line[3:].strip()
        else:
            blocks.append((info, "\n".join(cur)))
            cur = None
    elif cur is not None:
        cur.append(line)
ex = [json.loads(b) for i, b in blocks if i == "schooling-example"]
assert len(ex) == 1
sys.stdout.write("\n".join(p["code"] for p in ex[0]["parts"]) + "\n")
PY
}
# The pom with its <dependencies> block replaced by the one the lesson shows.
withdeps() { python3 "$COURSE/lab/fence.py" extract "$MD" '  <dependencies>' > /tmp/le-797zzsne-deps
  python3 - "$1" /tmp/le-797zzsne-deps <<'PY'
import re, sys
pom = open(sys.argv[1], encoding="utf-8").read()
deps = open(sys.argv[2], encoding="utf-8").read()
new, n = re.subn(r"  <dependencies>.*?</dependencies>\n", lambda m: deps, pom, flags=re.S)
assert n == 1
sys.stdout.write(new)
PY
  rm -f /tmp/le-797zzsne-deps
}
app_start() { quiet "cd ~/javalin-hello && { java -jar target/javalin-hello-0.1.0.jar > run.log 2>&1 & echo \$! > app.pid; }"; quiet 'for i in $(seq 100); do grep -q "Listening on" ~/javalin-hello/run.log && break; sleep 0.1; done'; }
app_stop() { quiet 'kill $(cat ~/javalin-hello/app.pid)'; sleep 1; }
terminal1() { printf 'ana@vm:~/javalin-hello$ java -jar target/javalin-hello-0.1.0.jar\n'; cat /home/ana/javalin-hello/run.log; }

asroot 'rm -rf /home/ana/javalin-hello /home/ana/jl-try /home/ana/first-answer.sh'
take "$MD" '<?xml' javalin-hello/pom.xml
example | put javalin-hello/src/main/java/com/example/hello/HelloApp.java

block tree
at '~/javalin-hello'
run 'find . -type f | sort'
block build1
run 'mvn -B -q package'
run 'ls -l target/*.jar'
app_start
block curl1
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:7070/books"
sleep 1
block terminal1-first
terminal1
app_stop

withdeps /home/ana/javalin-hello/pom.xml > /tmp/le-797zzsne-pom.xml
put javalin-hello/pom.xml < /tmp/le-797zzsne-pom.xml
rm -f /tmp/le-797zzsne-pom.xml
block build2
run 'mvn -B -q package'
run 'ls -l target/javalin-hello-0.1.0.jar'
app_start
block curl2
run 'curl -s localhost:7070/books | python3 -m json.tool'
run "curl -si -w '\\n' localhost:7070/books/2"
run "curl -si -w '\\n' localhost:7070/books/9"
run 'curl -s localhost:7070/books/two'
echo
block terminal1-second
terminal1
app_stop

block measure
take measured.md '#!/usr/bin/env bash' first-answer.sh
stage le-k1349km8
at '~/bookshop'
run 'mvn -B -q package'
run 'ls -l target/bookshop-0.1.0.jar ~/javalin-hello/target/javalin-hello-0.1.0.jar'
at '~'
run 'for i in 1 2 3; do bash first-answer.sh javalin-hello/target/javalin-hello-0.1.0.jar localhost:7070/books; done'
run 'for i in 1 2 3; do bash first-answer.sh bookshop/target/bookshop-0.1.0.jar localhost:8080/books; done'
block counts
at '~/bookshop'
run 'unzip -l target/bookshop-0.1.0.jar | grep -c "BOOT-INF/lib/.*\.jar$"'
