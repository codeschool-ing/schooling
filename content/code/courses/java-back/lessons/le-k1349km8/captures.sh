#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as lesson 6 left it, then as
# this lesson leaves it (the files the lesson shows, compared byte for byte at
# the end). The application runs in the background where the student runs
# `java -jar target/bookshop-0.1.0.jar` in a second terminal; the lines the
# lesson quotes from that terminal are printed here from its log, unedited.
# Three detours are applied by this script and undone by restaging: the
# service's exceptions with no handler yet, a second handler for
# MethodArgumentNotValidException, and a repository whose findById throws a
# stand-in for a database failure (with Boot's default answer, then a
# catch-all handler that leaks it). Each detour's code is taken from the
# lesson's own fence. curl -i prints its header lines with CRLF; the carriage
# returns are stripped here, which is what a terminal shows anyway. Dates,
# PIDs and timestamps differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
SRC=/home/ana/bookshop/src/main/java/com/example/bookshop
J="-H 'Content-Type: application/json'"
DUP='{"isbn": "9786500000016", "title": "Dom Casmurro", "author": "Machado de Assis", "priceCents": 3990}'
BAD='{"isbn": "9786500000017", "title": "", "priceCents": -1}'
runr() { run "$1" | tr -d '\r'; }
# Replace OLD (a literal) in FILE with the fence of MD that starts with PREFIX,
# or insert that fence before OLD when the fifth argument is "before".
detour() {
  python3 - "$COURSE/lab/fence.py" "$1" "$2" "$3" "$4" "${5:-}" <<'PY'
import subprocess, sys
fence, md, prefix, path, old, mode = sys.argv[1:7]
new = subprocess.run(['python3', fence, 'extract', md, prefix],
                     check=True, capture_output=True, text=True).stdout.rstrip('\n')
text = open(path).read()
assert text.count(old) == 1, 'detour: the original text is not in ' + path
text = text.replace(old, new + '\n\n' + old if mode == 'before' else new)
open(path, 'w').write(text)
PY
}
# ---------------------------------------------------------------- lesson 6
stage le-3jfvd9zx
at '~/bookshop'
quiet 'mvn -B -q package -DskipTests'
start
block before
runr "curl -si localhost:8080/books/99 -w '\n'"
runr "curl -si localhost:8080/books $J -d '$BAD' -w '\n'"
runr "curl -si localhost:8080/books $J -d '$DUP' -w '\n'"
block before-spring
runr "curl -si localhost:8080/books $J -d '{\"isbn\": \"9786500000016\", \"title\": ' -w '\n'"
runr "curl -si localhost:8080/nope -w '\n'"
stop

# ------------------------------------- the exceptions, and no handler yet
stage le-k1349km8
asroot "rm $SRC/web/ApiErrorHandler.java && rmdir $SRC/web"
block no-handler
run 'mvn -q package'
start
runr "curl -si localhost:8080/books/99 -w '\n'"
stop
block no-handler-log
grep -m1 -A2 ' ERROR ' /tmp/bookshop.log

# -------------------------------------------------------- the whole stage
stage le-k1349km8
block problem
run 'mvn -q package'
start
runr "curl -si localhost:8080/books/99 -w '\n'"
runr "curl -si localhost:8080/books $J -d '$DUP' -w '\n'"
block spring
runr "curl -si localhost:8080/books $J -d '{\"isbn\": \"9786500000016\", \"title\": ' -w '\n'"
runr "curl -si localhost:8080/books $J -d '{\"isbn\": \"9786500000016\", \"priceCents\": \"cheap\"}' -w '\n'"
runr "curl -si localhost:8080/books/abc -w '\n'"
runr "curl -si localhost:8080/nope -w '\n'"
runr "curl -si -X DELETE localhost:8080/books/1 -w '\n'"
runr "curl -si localhost:8080/books -H 'Content-Type: text/plain' -d 'hello' -w '\n'"
block validation-1
run "curl -s localhost:8080/books $J -d '$BAD' | python3 -m json.tool"
block validation-2
run "curl -s localhost:8080/books $J -H 'Accept-Language: pt-BR' -d '$BAD' | python3 -m json.tool"
block validation-3
run "python3 -c 'import json; print(json.dumps({\"isbn\": \"9786500000078\", \"title\": \" \" * 201, \"author\": \"Jane Austen\", \"priceCents\": 2500}))' | curl -s localhost:8080/books $J -d @- | python3 -m json.tool"
stop

# The dev profile (lesson 4) logs which exception each answer came from.
block resolved
start --spring.profiles.active=dev
quiet "curl -s localhost:8081/books $J -d '{\"isbn\": \"9786500000016\", \"title\": '"
quiet "curl -s localhost:8081/books/abc"
quiet "curl -s localhost:8081/nope"
quiet "curl -s -X DELETE localhost:8081/books/1"
quiet "curl -s localhost:8081/books -H 'Content-Type: text/plain' -d 'hello'"
stop
grep 'Resolved \[' /tmp/bookshop.log

# ----------------------------------- detour: a second handler, ambiguous
block ambiguous
detour "$LESSON/validation-errors.md" '    @ExceptionHandler(MethodArgumentNotValidException.class)' \
  "$SRC/web/ApiErrorHandler.java" '    @Override
    protected' before
quiet 'mvn -q package'
start
grep -m1 'Caused by: java.lang.IllegalStateException' /tmp/bookshop.log
stop
stage le-k1349km8

# ------------------------------------ detour: a failure nobody expected
block unexpected
detour "$LESSON/what-not-to-leak.md" '    @Override
    public Optional<Book> findById' "$SRC/catalogue/InMemoryBookRepository.java" '    @Override
    public Optional<Book> findById(long id) {
        return Optional.ofNullable(books.get(id));
    }'
run 'mvn -q package'
start
runr "curl -si localhost:8080/books/1 -w '\n'"
stop
block unexpected-log
grep -m1 -A2 ' ERROR ' /tmp/bookshop.log
block include-message-1
start --server.error.include-message=always
run "curl -s localhost:8080/books/1 -w '\n'"
stop
block include-message-2
start --spring.web.error.include-message=always
run "curl -s localhost:8080/books/1 -w '\n'"
stop
block include-message-3
start --spring.web.error.include-stacktrace=always
run "curl -s localhost:8080/books/1 | python3 -m json.tool | head -n 7"
stop
block catch-all
detour "$LESSON/what-not-to-leak.md" '    @ExceptionHandler(Exception.class)' \
  "$SRC/web/ApiErrorHandler.java" '    @Override
    protected' before
run 'mvn -q package'
start
runr "curl -si localhost:8080/books/1 -w '\n'"
runr "curl -si localhost:8080/nope -w '\n'"
stop
block catch-all-log
echo "(ERROR lines in the log: $(grep -c ' ERROR ' /tmp/bookshop.log))"
sed -n '/Started BookshopApplication/,$p' /tmp/bookshop.log

# --------------------------------------------- what the student is given
stage le-k1349km8
shown domain-exceptions.md \
  src/main/java/com/example/bookshop/catalogue/BookNotFoundException.java \
  src/main/java/com/example/bookshop/catalogue/DuplicateIsbnException.java \
  src/main/java/com/example/bookshop/catalogue/BookService.java \
  src/main/java/com/example/bookshop/catalogue/BookController.java
shown problem-details.md src/main/java/com/example/bookshop/web/ApiErrorHandler.java
echo '##### every file shown is the file built'
