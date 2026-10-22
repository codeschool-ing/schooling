#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the bookshop as this lesson leaves it (the stage le-p1p8dt26), against a
#     fresh database that Flyway fills on the first start. Every file the
#     lesson shows is compared with the stage, byte for byte, at the end;
#   - the application runs with `java -jar` in the background, which is the
#     student's "second terminal"; BOOKSHOP_JWT_SECRET is a fixed value here,
#     where the student uses `openssl rand -base64 32` (lesson 15);
#   - the readiness loop the lesson runs in "a third terminal" is started in
#     the background just before the application, exactly as typed, and its
#     output is printed when it has finished;
#   - ana has no sudo in the lab, so a command the lesson shows with `sudo` is
#     printed with ana's prompt and run by root, exactly as written;
#   - the detours are applied by this script, run, and undone: SecurityConfig
#     without its EndpointRequest line, and lesson 4's application-dev.properties
#     as it was before this lesson gave the management server port 8082;
#   - 192.0.2.2 is the lab machine's own address (a documentation range).
#
# Run as root. PIDs, timestamps, durations, request ids, disk sizes and Date
# headers differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, PostgreSQL 16,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
STAGE=$COURSE/lab/stages/le-p1p8dt26
BS=/home/ana/bookshop
LOG=/tmp/bookshop.log
SECRET='BOOKSHOP_JWT_SECRET=Hn4uX0b9kQ2wZ7eT1rY5pL8sV3cJ6mA0dF2gK4hN7qE='
TOKEN="python3 -c 'import json,sys; print(json.load(sys.stdin)[\"accessToken\"])'"
SEC=src/main/java/com/example/bookshop/security/SecurityConfig.java

sudorun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; ( cd /home/ana && bash -c "$1" ) 2>&1 9>&- || true; }
mark() { MARK=$(wc -l < $LOG); }
since() { tail -n +$((MARK + 1)) $LOG; }
ready() { for _ in $(seq 60); do grep -q 'Catalogue opened\|Application run failed' $LOG && return 0; sleep 1; done; echo '!!! no catalogue report' >&2; exit 1; }
build() { quiet 'mvn -B -q package -DskipTests'; [ -s $BS/target/bookshop-0.1.0.jar ] || { echo '!!! build failed' >&2; exit 1; }; }
edit() { python3 - "$BS/$1" "$2" "$3" <<'PY' || { echo "!!! edit of $1 did not apply" >&2; exit 1; }
import sys
path, old, new = sys.argv[1:]
text = open(path, encoding='utf-8').read()
if text.count(old) != 1:
    sys.exit(1)
open(path, 'w', encoding='utf-8').write(text.replace(old, new))
PY
}
restore() { asroot "cp $STAGE/$1 $BS/$1 && chown ana:ana $BS/$1"; }

stage le-p1p8dt26
db
at '~/bookshop'

# --- endpoints ---------------------------------------------------------------
block build
run 'mvn -q package'
run 'unzip -p target/bookshop-0.1.0.jar META-INF/build-info.properties'

EXTRA_ENV="$SECRET" start
ready
block startup-log
grep -E "Tomcat started on port|Exposing" $LOG

block index
run 'curl -s localhost:8081/actuator | python3 -m json.tool'

block public-port
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/books'
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/actuator/health'
run 'curl -s -o /dev/null -w "%{http_code}\n" 192.0.2.2:8080/books'
run 'curl -s -o /dev/null -w "%{http_code}\n" 192.0.2.2:8081/actuator/health'
run 'curl -sS 192.0.2.2:8081/actuator/health'

block not-exposed
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/actuator/health'
run "curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | $TOKEN > ana.token"
run 'curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $(cat ana.token)" localhost:8080/actuator/health'
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/actuator/env'

block info
run 'curl -s localhost:8081/actuator/info | python3 -m json.tool'

# --- health --------------------------------------------------------------------
block health
run 'curl -s localhost:8081/actuator/health | python3 -m json.tool'
block groups
run 'curl -s -w "\n" localhost:8081/actuator/health/liveness'
run 'curl -s -w "\n" localhost:8081/actuator/health/readiness'

block db-down
sudorun "sudo -u postgres psql -c 'ALTER ROLE bookshop NOLOGIN'"
sudorun "sudo -u postgres psql -c \"SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE usename = 'bookshop'\""
run 'curl -s -w "%{http_code} after %{time_total} s\n" -o health.json localhost:8081/actuator/health'
run 'python3 -m json.tool health.json | head -9'
run 'curl -s -w " %{http_code}\n" localhost:8081/actuator/health/liveness'
run 'curl -s -w " %{http_code}\n" localhost:8081/actuator/health/readiness'
run 'curl -s -o /dev/null -w "%{http_code} after %{time_total} s\n" localhost:8080/books'
run 'curl -s localhost:8081/actuator/prometheus | grep "^http_server_requests_seconds_count" | grep "status=\"401\""'
block db-down-log
grep -E 'WARN|ERROR' $LOG | tail -n 3
block db-back
sudorun "sudo -u postgres psql -c 'ALTER ROLE bookshop LOGIN'"
run 'curl -s -w "\n" localhost:8081/actuator/health/db'
quiet 'rm -f health.json'
stop

block readiness-loop
LOOP="for i in \$(seq 1500); do echo \$(for p in health/liveness health/readiness health; do curl -s -o /dev/null -w '%{http_code} ' localhost:8081/actuator/\$p; done); done | uniq -c"
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin LC_ALL=C.UTF-8 bash -c "cd ~/bookshop && $LOOP" > /tmp/l22-loop.txt 2>&1 9>&- &
LOOPPID=$!
sleep 1
EXTRA_ENV="$SECRET" start
ready
wait $LOOPPID
printf 'ana@vm:%s$ %s\n' '~/bookshop' "$LOOP"
cat /tmp/l22-loop.txt
rm -f /tmp/l22-loop.txt
block readiness-log
grep -E 'Started BookshopApplication|Catalogue opened' $LOG
block ready-times
run 'curl -s localhost:8081/actuator/prometheus | grep -E "^application_(started|ready)_time"'

# --- metrics ---------------------------------------------------------------------
block metrics-names
run "curl -s localhost:8081/actuator/metrics | python3 -c 'import json,sys; print(len(json.load(sys.stdin)[\"names\"]))'"
run "curl -s localhost:8081/actuator/metrics | python3 -c 'import json,sys; print(*json.load(sys.stdin)[\"names\"], sep=\"\\n\")' | grep -E '^(http|hikaricp|jvm.memory|bookshop)'"

block requests
quiet 'curl -s -o /dev/null localhost:8080/books'
quiet 'curl -s -o /dev/null localhost:8080/books/2'
quiet 'curl -s -o /dev/null localhost:8080/books/99'
run 'for path in /books /books /books/1 /books/2 /books/99; do curl -s -o /dev/null -w "%{http_code} $path\n" localhost:8080$path; done'
run 'curl -s localhost:8081/actuator/metrics/http.server.requests | python3 -m json.tool'
run 'curl -s -g "localhost:8081/actuator/metrics/http.server.requests?tag=uri:/books/{id}&tag=status:404" | python3 -m json.tool | tail -n 16'

block pool
run 'for m in active idle pending max; do printf "%-8s" $m; curl -s localhost:8081/actuator/metrics/hikaricp.connections.$m | python3 -c "import json,sys; print(json.load(sys.stdin)[\"measurements\"][0][\"value\"])"; done'

# --- the counter ---------------------------------------------------------------------
block orders
run "curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | $TOKEN > ana.token"
run "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '{\"lines\":[{\"bookId\":3,\"quantity\":1}]}' localhost:8080/orders"
run "curl -s -w '\n' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '{\"lines\":[{\"bookId\":3,\"quantity\":1}]}' localhost:8080/orders"
run "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '{\"lines\":[{\"bookId\":1,\"quantity\":2},{\"bookId\":2,\"quantity\":1}]}' localhost:8080/orders"
run "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '{\"lines\":[{\"bookId\":99,\"quantity\":1}]}' localhost:8080/orders"
block counter
run 'curl -s localhost:8081/actuator/metrics/bookshop.orders | python3 -m json.tool'
run 'curl -s "localhost:8081/actuator/metrics/bookshop.orders?tag=outcome:out-of-stock" | python3 -m json.tool | tail -n 8'

# --- prometheus ------------------------------------------------------------------------
block prometheus
run 'curl -s localhost:8081/actuator/prometheus | wc -l'
run 'curl -s localhost:8081/actuator/prometheus | grep -E "bookshop_orders|^hikaricp_connections_(active|pending)"'
run 'curl -s localhost:8081/actuator/prometheus | grep -E "^http_server_requests_seconds_(count|sum)" | grep "/books\""'
block rate
run 'curl -s localhost:8081/actuator/prometheus | grep "^bookshop_orders_total"; date +%T'
run "for book in 4 4 4 4 4 4 3 3; do curl -s -o /dev/null -w '%{http_code} ' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d \"{\\\"lines\\\":[{\\\"bookId\\\":\$book,\\\"quantity\\\":1}]}\" localhost:8080/orders; done; echo"
run 'sleep 15; curl -s localhost:8081/actuator/prometheus | grep "^bookshop_orders_total"; date +%T'
stop

# --- detour: the actuator behind the API's security ------------------------------------
block no-permit
edit $SEC '                        .requestMatchers(EndpointRequest.toAnyEndpoint()).permitAll()
' ''
build
EXTRA_ENV="$SECRET" start
ready
run 'curl -s -i localhost:8081/actuator/health | head -n 3'
stop
restore $SEC

# --- detour: lesson 4's dev profile, before and after this lesson's line ---------------
DEV=src/main/resources/application-dev.properties
asroot "cp $COURSE/lab/stages/le-djnvk025/$DEV $BS/$DEV && chown ana:ana $BS/$DEV"
build
block dev-broken
EXTRA_ENV="$SECRET" run "java -jar target/bookshop-0.1.0.jar --spring.profiles.active=dev | grep -o 'IllegalStateException: .*'"
restore $DEV
build
block dev-fixed
EXTRA_ENV="$SECRET" start --spring.profiles.active=dev
ready
grep -E "Tomcat started on port" $LOG
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8082/actuator/health'
stop

# --- what the lesson shows is what the stage holds -----------------------------------
block check
for f in $(cd $STAGE && find . -type f ! -name .removed | sed 's|^\./||'); do
  cmp -s "$STAGE/$f" "$BS/$f" || { echo "!!! $f differs from the stage" >&2; exit 1; }
done
if [ -f endpoints.md ]; then
  shown endpoints.md pom.xml src/main/resources/application.properties $SEC src/main/resources/application-dev.properties
  shown counting-orders.md src/main/java/com/example/bookshop/ordering/OrderService.java \
    src/test/java/com/example/bookshop/ordering/OrderServiceTest.java src/test/resources/application-test.properties
  echo 'every file shown is the file the stage holds'
fi
quiet 'rm -f ana.token'
db
