#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the bookshop at the end of lesson 13, built and started once so that
#     Flyway leaves the database at version 2, and then this lesson's files
#     laid over it;
#   - the application runs in the background (lab.sh start) where the lesson
#     has the student run it in a second terminal. A fence quoting that
#     terminal prints the java -jar command with the grep the fence shows, and
#     its lines are that grep over the log the same command wrote;
#   - the psql of the "third terminal" in the pool section runs in the
#     background while the curls run, and its output is printed after them;
#   - the two detours (OrderService calling itself, and OrderService reading
#     with findById) are written over the stage's file, built and run, and the
#     stage's file is put back; `shown` checks it at the end.
# Timestamps, PIDs, object hashes, curl's timings and which of two parallel
# orders wins change on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

SVC=src/main/java/com/example/bookshop/ordering/OrderService.java
STAGED=$(realpath "$COURSE/lab/stages/le-82xkn72m/$SVC")
P='psql postgresql://bookshop:bookshop@localhost/bookshop'
J='-H "Content-Type: application/json"'
TX='--logging.level.org.springframework.orm.jpa.JpaTransactionManager=debug'
order() { echo "curl -s -i -w '\n' $J -d '{\"customer\":\"$1\",\"lines\":[$2]}' localhost:8080/orders"; }
line() { echo "{\"bookId\":$1,\"quantity\":$2}"; }
# The second terminal: what `java -jar ... ARGS | grep -E PATTERN` prints, read off the log.
applog() {
  printf 'ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar%s | grep -E '"'"'%s'"'"'\n' "${1:+ $1}" "$2"
  grep -aE "$2" /tmp/bookshop.log | sed 's/\x1b\[[0-9;]*m//g'
}
# Two orders for one copy of Frankenstein, sent at the same moment.
both() {
  run "for c in ana bia; do curl -s -o /dev/null -w \"\$c %{http_code}\n\" $J -d \"{\\\"customer\\\":\\\"\$c\\\",\\\"lines\\\":[{\\\"bookId\\\":3,\\\"quantity\\\":1}]}\" localhost:8080/orders & done; wait"
}
# lab.sh db drops the database; it cannot while another process holds a
# connection, so wait until the drop really happened.
freshdb() {
  for _ in $(seq 60); do
    db
    [ "$(runuser -u postgres -- psql -qXAt bookshop -c "select count(*) from pg_tables where schemaname = 'public'" 2>/dev/null)" = 0 ] && return 0
    sleep 10
  done
  echo '!!! the bookshop database could not be recreated' >&2; exit 1
}
build() { quiet 'mvn -B -q package -DskipTests'; [ -f /home/ana/bookshop/target/bookshop-0.1.0.jar ] || { echo '!!! build failed' >&2; exit 1; }; }

# ---------------------------------------------------------------- lesson 13's end
stage le-gb0yefh1
freshdb
at '~/bookshop'
build
start
stop

# ---------------------------------------------------------------- all or nothing
stage le-82xkn72m
block build
run 'mvn -B -q package -DskipTests'
start
block startup
applog '' 'Flyway|DbMigrate|Started Bookshop'
block hikari
applog '' 'hikari'

block fail
run "$(order ana "$(line 1 1),$(line 3 2)")"
run "curl -s -w '\n' localhost:8080/books/1"

block ok
run "$(order ana "$(line 1 1),$(line 2 2)")"
run "curl -s -w '\n' localhost:8080/books/1"
run "curl -s -w '\n' localhost:8080/books/2"
stop

# ---------------------------------------------------------------- the proxy
start --spring.profiles.active=sql "$TX"
block txorder
run "$(order ana "$(line 1 1),$(line 3 2)")"
sleep 1
block txlog
applog "--spring.profiles.active=sql $TX" 'Creating new|Participating|rollback|Committing|org.hibernate.SQL'
stop

# the detour: self-invocation
python3 - "$(realpath the-proxy.md)" <<'PY' | put "bookshop/$SVC"
import json, sys
body = open(sys.argv[1]).read().split('```schooling-example\n')[1].split('\n```')[0]
print('\n'.join(p['code'] for p in json.loads(body)['parts']))
PY
build
start "$TX"
block selfcall
run "$(order ana "$(line 1 1)")"
run "curl -s -w '\n' localhost:8080/books/1"
sleep 1
block selflog
applog "$TX" 'Creating new|Participating|rollback|Committing|TransactionRequired'
stop
put "bookshop/$SVC" < "$STAGED"
build

# ---------------------------------------------------------------- isolation
block isolation
run "$P -c 'SHOW transaction_isolation' -c 'SHOW max_connections'"
block rr
run "$P -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT stock FROM book WHERE id = 4' -c 'SELECT pg_sleep(2)' -c 'UPDATE book SET stock = stock - 1 WHERE id = 4' -c 'COMMIT' &
sleep 0.5
$P -c 'UPDATE book SET stock = stock - 1 WHERE id = 4'
wait"
run "$P -c 'SELECT stock FROM book WHERE id = 4'"

# ---------------------------------------------------------------- the lost update
quiet "sed -i 's/books.findByIdForUpdate(line.bookId())/books.findById(line.bookId())/' $SVC"
build
start --spring.profiles.active=sql
block nolock
both
run "curl -s -w '\n' localhost:8080/books/3"
run "$P -c 'SELECT o.id, o.customer, l.quantity FROM customer_order o JOIN order_line l ON l.order_id = o.id WHERE l.book_id = 3'"
sleep 1
block nolocklog
applog '--spring.profiles.active=sql' 'from book b1_0 where|update book'
stop
put "bookshop/$SVC" < "$STAGED"
build

start --spring.profiles.active=sql
block locked
run "$P -c 'UPDATE book SET stock = 1 WHERE id = 3'"
both
run "curl -s -w '\n' localhost:8080/books/3"
sleep 1
block locklog
applog '--spring.profiles.active=sql' 'for no key update'
stop

# ---------------------------------------------------------------- the pool
start --spring.datasource.hikari.maximum-pool-size=2
block poolstart
applog '--spring.datasource.hikari.maximum-pool-size=2' 'hikari'
quiet "( $P -c 'BEGIN' -c 'SELECT title, stock FROM book WHERE id = 2 FOR UPDATE' -c 'SELECT pg_sleep(8)' -c 'COMMIT' > /tmp/le-82xkn72m-psql.out 2>&1 & )"
sleep 1
block exhaust
run "for c in ana bia cris; do curl -s -o /dev/null -w \"\$c %{http_code} %{time_total}s\n\" $J -d \"{\\\"customer\\\":\\\"\$c\\\",\\\"lines\\\":[{\\\"bookId\\\":2,\\\"quantity\\\":1}]}\" localhost:8080/orders & done; wait"
sleep 3
block exhaustpsql
printf 'ana@vm:~$ %s\n' "$P -c 'BEGIN' -c 'SELECT title, stock FROM book WHERE id = 2 FOR UPDATE' -c 'SELECT pg_sleep(8)' -c 'COMMIT'"
cat /tmp/le-82xkn72m-psql.out
block exhaustlog
applog '--spring.datasource.hikari.maximum-pool-size=2' 'Connection is not available'
stop
block end

# ---------------------------------------------------------------- what the lesson shows is what was built
shown orders.md \
  src/main/resources/db/migration/V3__stock_and_orders.sql \
  src/main/java/com/example/bookshop/catalogue/Book.java \
  src/main/java/com/example/bookshop/catalogue/OutOfStockException.java \
  src/main/java/com/example/bookshop/catalogue/BookRequest.java \
  src/main/java/com/example/bookshop/catalogue/BookResponse.java \
  src/main/java/com/example/bookshop/catalogue/BookService.java \
  src/main/java/com/example/bookshop/catalogue/BookRepository.java \
  src/main/java/com/example/bookshop/ordering/Order.java \
  src/main/java/com/example/bookshop/ordering/OrderLine.java \
  src/main/java/com/example/bookshop/ordering/OrderRepository.java \
  src/main/java/com/example/bookshop/ordering/OrderRequest.java \
  src/main/java/com/example/bookshop/ordering/OrderResponse.java \
  src/main/java/com/example/bookshop/ordering/OrderNotFoundException.java \
  src/main/java/com/example/bookshop/ordering/OrderController.java \
  src/main/java/com/example/bookshop/web/ApiErrorHandler.java \
  src/main/resources/application.properties
shown all-or-nothing.md "$SVC"
echo '##### shown: every file the lesson prints is the file that was built'
