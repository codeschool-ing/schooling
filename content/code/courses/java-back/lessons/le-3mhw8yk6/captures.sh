#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as this lesson leaves it (the
# stage of le-3mhw8yk6: RequestIdFilter, the correlation pattern, the log line
# in OrderService and application-json.properties, each shown whole in the
# lesson and checked below with `shown`), and a fresh bookshop database, so
# the order ids start at 1 where a student's do not. BOOKSHOP_JWT_SECRET is a
# fixed value here; the student exported a random one in lesson 15.
#
# "The second terminal" is the application started by `launch` below exactly
# as the lesson prints the command, `java -jar ... > app.log`, in the
# background and stopped by its pid. The prompt line printed for it is the
# command that ran.
#
# ~/logging-look is written from the two fences of facade-and-backend.md. Its
# first `mvn dependency:build-classpath` for the log4j2 and tinylog profiles
# downloads those jars (quietly, -q) through the lab's mirror of Central.
#
# TOKEN is fetched once and kept between commands in /tmp/l16-token, as a
# shell keeps a variable (see runt). It lives fifteen minutes, and every
# restart below uses the same secret, so it stays valid across them.
#
# Timestamps, pids, request ids made up by the filter, and thread names differ
# on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

JWT='BOOKSHOP_JWT_SECRET=captures-only-secret-at-least-32-bytes-long'
TOKEN="TOKEN=\$(curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"accessToken\"])')"

# A shell keeps TOKEN between two commands and `run` starts a new one each
# time, so the value is kept in a file: printed as typed, run with it loaded.
runt() {
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  lab exec "cd $(dir) && export PAGER=cat COLUMNS=100 && TOKEN=\$(cat /tmp/l16-token 2>/dev/null || true); { $1 ; } && echo \"\$TOKEN\" > /tmp/l16-token" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
}

# The second terminal: the command as the lesson prints it, then wait for it.
launch() {
  printf 'ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar%s > app.log\n' "${1:+ $1}"
  quiet "rm -f app.log; export $JWT; setsid java -jar target/bookshop-0.1.0.jar ${1:-} > app.log 2>/tmp/l16-stderr < /dev/null & echo \$! > /tmp/l16-app.pid"
  for _ in $(seq 90); do
    grep -q 'Started BookshopApplication' /home/ana/bookshop/app.log 2>/dev/null && break
    sleep 1
  done
  sleep 2
  [ -s /tmp/l16-stderr ] && { echo '!!! the application wrote to stderr:'; cat /tmp/l16-stderr; }
}
halt() {
  quiet 'p=$(cat /tmp/l16-app.pid); kill $p; while kill -0 $p 2>/dev/null; do sleep 0.5; done; rm -f /tmp/l16-app.pid'
}

stage le-3mhw8yk6
db

# ---------------------------------------------------------------- the facade
at '~/bookshop'
block build
run 'mvn -q package'
block tree
run 'mvn dependency:tree -Dincludes=org.slf4j,ch.qos.logback,org.apache.logging.log4j,commons-logging,org.jboss.logging'

block look
quiet 'rm -rf ~/logging-look'
take facade-and-backend.md '<?xml' logging-look/pom.xml
take facade-and-backend.md 'import org.slf4j.Logger;' logging-look/Hello.java
at '~/logging-look'
run 'mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt'
run 'cat cp.txt; echo'
run 'java -cp "$(cat cp.txt)" Hello.java'
block logback
run 'mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P logback'
run "tr ':' '\n' < cp.txt; echo"
run 'java -cp "$(cat cp.txt)" Hello.java'

# ------------------------------------------------------- levels in the bookshop
at '~/bookshop'
block default
launch
run "grep -E 'Starting Bookshop|Started|Catalogue' app.log"
halt
block warn
launch '--logging.level.root=warn'
run 'cat app.log'
halt
block warn-ours
launch '--logging.level.root=warn --logging.level.com.example.bookshop=info'
run 'grep INFO app.log'
halt

# ---------------------------------------------------------------- request ids
block ids
launch
run "curl -si localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'"
run "curl -si -H 'X-Request-Id: checkout-41' localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'"
run "curl -si -H 'X-Request-Id: two words' localhost:8080/books/1 | grep -iE '^(HTTP|X-Request-Id)'"
run "curl -si -X POST localhost:8080/orders | grep -iE '^(HTTP|X-Request-Id)'"
block order
runt "$TOKEN"
runt "curl -s -H \"Authorization: Bearer \$TOKEN\" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-42' -d '{\"lines\":[{\"bookId\":2,\"quantity\":1}]}' localhost:8080/orders; echo"
run 'grep checkout-42 app.log'
halt

# ------------------------------------------------------------- structured logs
block json
launch '--spring.profiles.active=json'
runt "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$TOKEN\" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-43' -d '{\"lines\":[{\"bookId\":4,\"quantity\":2}]}' localhost:8080/orders"
run 'grep checkout-43 app.log'
run 'grep checkout-43 app.log | python3 -m json.tool'
run "grep -c '\"tags\":\[\"COMMONS-LOGGING\"\]' app.log"
halt
block logstash
launch '--spring.profiles.active=json --logging.structured.format.console=logstash'
runt "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$TOKEN\" -H 'Content-Type: application/json' -H 'X-Request-Id: checkout-44' -d '{\"lines\":[{\"bookId\":5,\"quantity\":1}]}' localhost:8080/orders"
run 'grep checkout-44 app.log | python3 -m json.tool'
halt

block masked
launch '--spring.profiles.active=dev'
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'Authorization: Bearer not-a-real-token' localhost:8081/books/1"
run "grep -c not-a-real-token app.log"
run 'grep masked app.log'
halt

# ---------------------------------------------------------- the other backends
block others
at '~/logging-look'
run 'mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P log4j2'
run 'java -cp "$(cat cp.txt)" Hello.java'
run 'mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P tinylog'
run 'java -cp "$(cat cp.txt)" Hello.java'
block sizes
run "for p in logback log4j2 tinylog; do mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P \$p; printf '%-8s ' \$p; du -ch \$(tr ':' ' ' < cp.txt) | tail -n 1; done"

# ------------------------------------------------- what the lesson shows, byte for byte
block shown
#SHOWN
