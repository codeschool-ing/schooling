#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the bookshop as lesson 9 left it, built and started once against a fresh
#     database, so that the database holds lesson 9's `book` table, as a
#     student's does when this lesson begins;
#   - then the files of this lesson's stage, with JpaBookRepository replaced by
#     the version entity-manager.md shows (findAll WITHOUT `join fetch`), taken
#     from that file. The fix in n-plus-one.md is applied from that file too,
#     and the result is compared with the stage, byte for byte;
#   - the detours (the reprice method and RepriceOnce from
#     persistence-context.md; EAGER in Book; BookService.get without
#     @Transactional; application.properties without its open-in-view line)
#     are applied by this script, run, and undone. Each one the lesson asks
#     the student to type is extracted from the lesson's own fence;
#   - ana has no sudo in the lab, so a command the lesson shows with `sudo` is
#     printed with ana's prompt and run by root, as written;
#   - lines quoted from "the second terminal" are lines of the application's
#     log (/tmp/bookshop.log, where `start` writes what `java -jar` prints),
#     cut from the start of a request or of a start-up, never edited.
#
# Run as root. PIDs, timestamps, durations and Date headers differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
STAGE=$COURSE/lab/stages/le-qxajq2s8
BS=/home/ana/bookshop
CAT=src/main/java/com/example/bookshop/catalogue
LOG=/tmp/bookshop.log

sudorun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; ( cd /home/ana && bash -c "$1" ) 2>&1 9>&- || true; }
# the log, from the line after the mark: what the second terminal printed since
mark() { MARK=$(wc -l < $LOG); }
since() { tail -n +$((MARK + 1)) $LOG; }
# lines from the last start-up's "Started" line to the first line matching $1
startup_until() { awk -v end="$1" '/Started BookshopApplication/ {on = 1} on {print} on && $0 ~ end {exit}' $LOG; }
ready() { for _ in $(seq 60); do grep -q 'Catalogue opened\|Application run failed' $LOG && return 0; sleep 1; done; echo '!!! no catalogue report' >&2; exit 1; }
build() { quiet 'mvn -B -q package -DskipTests'; [ -s $BS/target/bookshop-0.1.0.jar ] || { echo '!!! build failed' >&2; exit 1; }; }
# replace, in a file of ~/bookshop, one exact piece of text with another
edit() { python3 - "$BS/$1" "$2" "$3" <<'PY' || { echo "!!! edit of $1 did not apply" >&2; exit 1; }
import sys
path, old, new = sys.argv[1:]
text = open(path, encoding='utf-8').read()
if text.count(old) != 1:
    sys.exit(1)
open(path, 'w', encoding='utf-8').write(text.replace(old, new))
PY
}
# the code of the one schooling-example in an .md, written to a file of ~/bookshop
example_to() { python3 - "$1" > "$BS/$2" <<'PY'
import json, re, sys
md = open(sys.argv[1], encoding='utf-8').read()
ex = re.findall(r'```schooling-example\n(.*?)\n```', md, re.S)
assert len(ex) == 1, len(ex)
print('\n'.join(p['code'] for p in json.loads(ex[0])['parts']))
PY
chown ana:ana "$BS/$2"; }
fence() { python3 "$COURSE/lab/fence.py" extract "$1" "$2"; }
same_as_stage() { for f in "$@"; do cmp -s "$STAGE/$f" "$BS/$f" || { echo "!!! $f differs from the stage" >&2; exit 1; }; done; }

# --- lesson 9's bookshop and database, as the student has them -------------
stage le-e6we03q0
db
at '~/bookshop'
build
start
stop

# --- this lesson's files, with the N+1 findAll the student writes first ------
stage le-qxajq2s8
example_to entity-manager.md $CAT/JpaBookRepository.java
grep -q 'select b from Book b order by b.id' $BS/$CAT/JpaBookRepository.java || { echo '!!! not the N+1 version' >&2; exit 1; }

block tree
run "mvn dependency:tree | grep -E 'starter-data-jpa|starter-jdbc|HikariCP|persistence-api|hibernate-core|spring-data-jpa'"

block build
run 'mvn -q package'

block stale
run "java -jar target/bookshop-0.1.0.jar | grep -E 'Application run failed|PSQLException'"

block recreate
sudorun 'sudo -u postgres dropdb bookshop'
sudorun 'sudo -u postgres createdb -O bookshop bookshop'

block report
start
ready
grep 'Catalogue opened' $LOG

block books
run 'curl -s localhost:8080/books | python3 -m json.tool'
stop

block one-book
start --spring.profiles.active=sql
ready
quiet 'curl -s -o /dev/null localhost:8080/books'
mark
run 'curl -s localhost:8080/books/2'
echo
block one-book-log
since
block hibernate-version
grep 'Hibernate ORM core version' $LOG
stop

# --- the persistence context: a change nobody saved ---------------------------
python3 - "$BS/$CAT/Book.java" "$LESSON/persistence-context.md" "$COURSE/lab/fence.py" <<'PY' || { echo '!!! the reprice method did not apply' >&2; exit 1; }
import subprocess, sys
path, md, fence = sys.argv[1:]
method = subprocess.run(['python3', fence, 'extract', md, '    public void reprice'],
                        check=True, capture_output=True, text=True).stdout
anchor = '    public int getPriceCents() {\n        return priceCents;\n    }\n'
text = open(path, encoding='utf-8').read()
assert text.count(anchor) == 1
open(path, 'w', encoding='utf-8').write(text.replace(anchor, anchor + '\n' + method))
PY
fence persistence-context.md 'package' | put bookshop/$CAT/RepriceOnce.java
build
start --spring.profiles.active=sql
ready
block reprice-log
startup_until 'Catalogue opened'
block reprice-psql
run "psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'SELECT id, title, price_cents FROM book WHERE id = 3'"
stop
start --spring.profiles.active=sql
ready
block reprice-again
startup_until 'Catalogue opened'
stop
block reprice-undo
run "rm $CAT/RepriceOnce.java"
asroot "cp $STAGE/$CAT/Book.java $BS/$CAT/Book.java && chown ana:ana $BS/$CAT/Book.java"
run "psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'UPDATE book SET price_cents = 3500 WHERE id = 3'"

# --- N+1, EAGER, and the fix ---------------------------------------------------
build
start --spring.profiles.active=sql
ready
quiet 'curl -s -o /dev/null localhost:8080/books/1'
block nplus1
mark
run 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/books'
block nplus1-log
since
stop

edit $CAT/Book.java 'FetchType.LAZY' 'FetchType.EAGER'
build
start --spring.profiles.active=sql
ready
quiet 'curl -s -o /dev/null localhost:8080/books/1'
mark
quiet 'curl -s -o /dev/null localhost:8080/books'
block eager-list-log
since
mark
quiet 'curl -s -o /dev/null localhost:8080/books/2'
block eager-one-log
since
stop
edit $CAT/Book.java 'FetchType.EAGER' 'FetchType.LAZY'

python3 - "$BS/$CAT/JpaBookRepository.java" "$(fence n-plus-one.md '    @Override')" <<'PY' || { echo '!!! the fix did not apply' >&2; exit 1; }
import re, sys
path, method = sys.argv[1:]
text = open(path, encoding='utf-8').read()
old = re.search(r'    @Override\n    public List<Book> findAll\(\) \{\n.*?\n    \}\n', text, re.S)
open(path, 'w', encoding='utf-8').write(text[:old.start()] + method + '\n' + text[old.end():])
PY
same_as_stage $CAT/JpaBookRepository.java $CAT/Book.java
build
start --spring.profiles.active=sql
ready
block fetch-startup
startup_until 'Catalogue opened'
quiet 'curl -s -o /dev/null localhost:8080/books/1'
mark
quiet 'curl -s -o /dev/null localhost:8080/books'
block fetch-log
since
stop

# --- open in view --------------------------------------------------------------
edit $CAT/BookService.java "$(printf '    @Transactional(readOnly = true)\n    public BookResponse get')" '    public BookResponse get'
build
start --spring.profiles.active=sql
ready
quiet 'curl -s -o /dev/null localhost:8080/books'
mark
block lazy-curl
run 'curl -s -i localhost:8080/books/1'
echo
block lazy-log
since | awk '/^\tat / {exit} {print}'
stop
start --spring.profiles.active=sql --spring.jpa.open-in-view=true
ready
quiet 'curl -s -o /dev/null localhost:8080/books'
mark
block osiv-curl
run 'curl -s -i localhost:8080/books/1'
echo
block osiv-log
since
stop
asroot "cp $STAGE/$CAT/BookService.java $BS/$CAT/BookService.java && chown ana:ana $BS/$CAT/BookService.java"

edit src/main/resources/application.properties "$(printf 'spring.jpa.open-in-view=false\n')" ''
build
start
ready
block osiv-warning
grep 'open-in-view' $LOG
stop
asroot "cp $STAGE/src/main/resources/application.properties $BS/src/main/resources/ && chown ana:ana $BS/src/main/resources/application.properties"

# --- what the lesson shows is what the stage holds -----------------------------
block check
for f in $(cd $STAGE && find . -type f ! -name .removed | sed 's|^\./||'); do same_as_stage "$f"; done
[ ! -e $BS/$CAT/JdbcBookRepository.java ] && [ ! -e $BS/$CAT/RepriceOnce.java ] || { echo '!!! leftover file' >&2; exit 1; }
shown a-new-schema.md pom.xml src/main/resources/schema.sql src/main/resources/data.sql src/main/resources/application.properties
shown entities.md $CAT/Author.java $CAT/Book.java
shown entity-manager.md $CAT/AuthorRepository.java $CAT/JpaAuthorRepository.java $CAT/BookService.java \
  $CAT/BookResponse.java $CAT/BookController.java src/main/resources/application-sql.properties
echo 'every file shown is the file the stage holds'
db
stage le-qxajq2s8
