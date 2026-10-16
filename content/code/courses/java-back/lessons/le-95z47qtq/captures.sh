#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - ~/bookshop as lesson 10 left it (its stage), and a fresh bookshop
#     database; the `rm` of lesson 10's two repository classes is typed, and
#     the files this lesson changes are then laid down from this lesson's
#     stage, which `shown` proves are the files the lesson prints.
#   - THE SECOND TERMINAL. The lesson has the student start the application in
#     a second terminal as `java -jar target/bookshop-0.1.0.jar
#     --spring.profiles.active=sql | grep -E 'interfaces|hibernate.SQL|Catalogue'`.
#     Here the lab starts the same jar with the same argument in the
#     background, writing its whole log to /tmp/bookshop.log, and the lines a
#     fence quotes from the second terminal are that log through the same
#     grep: the startup fence prints the command and every matching line so
#     far, and each later "second terminal" block is the matching lines that
#     appeared since the previous block.
#   - The three detours (a misspelt derived query, the entity graph removed, a
#     JPQL path that does not exist) are edits the lesson describes in prose;
#     here python3 makes the same edit to the stage's file, and the stage is
#     laid down again afterwards.
# Timestamps, PIDs and the ids PostgreSQL hands out differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
CAT=src/main/java/com/example/bookshop/catalogue
LOG=/tmp/bookshop.log
PAT='interfaces|hibernate.SQL|Catalogue'
SEEN=0

# the application, started as the student starts it in the second terminal
up() {
  start --spring.profiles.active=sql
  for _ in $(seq 50); do grep -q 'Catalogue opened' $LOG && break; sleep 0.2; done
  SEEN=0
}
second() {
  printf 'ana@vm:%s$ %s\n' "$HERE" "java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E '$PAT'"
  grep -E "$PAT" $LOG
  SEEN=$(grep -cE "$PAT" $LOG)
}
since() {
  sleep 0.5
  block "$1"
  grep -E "$PAT" $LOG | tail -n +$((SEEN + 1))
  SEEN=$(grep -cE "$PAT" $LOG)
}
# an edit the lesson describes, made to the file in ~/bookshop
edit() { python3 - "/home/ana/bookshop/$CAT/$1" "$2" "$3" <<'PY'
import sys
p, old, new = sys.argv[1:]
s = open(p).read()
assert s.count(old) == 1, 'edit: %r not found once in %s' % (old, p)
open(p, 'w').write(s.replace(old, new))
PY
}

stage le-qxajq2s8           # the bookshop as lesson 10 left it
db
at '~/bookshop'

block remove
run "rm $CAT/JpaBookRepository.java $CAT/JpaAuthorRepository.java"
stage le-95z47qtq           # the files this lesson shows

block javap
run 'javap -cp ~/.m2/repository/org/springframework/data/spring-data-commons/4.1.1/spring-data-commons-4.1.1.jar org.springframework.data.repository.CrudRepository'
block javap-jpa
run 'javap -cp ~/.m2/repository/org/springframework/data/spring-data-jpa/4.1.1/spring-data-jpa-4.1.1.jar org.springframework.data.jpa.repository.JpaRepository | head -n 2'

block build
run 'mvn -q package'
up
block startup
second

block search-run
run 'curl -s "localhost:8080/books/search?q=the" | python3 -m json.tool'
since search-sql
block percent-run
run 'curl -s "localhost:8080/books/search?q=%25"; echo'
since percent-sql

block add-run
run "curl -s -i -H 'Content-Type: application/json' -d '{\"isbn\": \"9786500000078\", \"title\": \"Triste Fim de Policarpo Quaresma\", \"author\": \"Lima Barreto\", \"priceCents\": 3450}' localhost:8080/books; echo"
since add-sql
stop

edit BookRepository.java '    Optional<Book> findByIsbn(String isbn);
' '    Optional<Book> findByIsbn(String isbn);

    List<Book> findByTitel(String titel);
'
block misspelt
run 'mvn -q package'
run "java -jar target/bookshop-0.1.0.jar | grep 'Caused by' | tail -n 1"
stage le-95z47qtq

edit BookRepository.java '    @EntityGraph(attributePaths = "author")
    Page<Book> findAllBy' '    Page<Book> findAllBy'
block nplus1-build
run 'mvn -q package'
up
block nplus1-run
run 'curl -s localhost:8080/books > /dev/null'
since nplus1-sql
stop
stage le-95z47qtq
block graph-build
run 'mvn -q package'
up
block graph-run
run 'curl -s localhost:8080/books > /dev/null'
since graph-sql
block byid-run
run 'curl -s localhost:8080/books/2; echo'
since byid-sql

block author-run
run 'curl -s "localhost:8080/books/by-author?name=H.%20G.%20Wells"; echo'
since author-sql
stop

edit BookRepository.java 'b.priceCents as priceCents' 'b.price as priceCents'
block badjpql
run 'mvn -q package'
run "java -jar target/bookshop-0.1.0.jar | grep 'Caused by' | tail -n 1"
stage le-95z47qtq
quiet 'cd ~/bookshop && mvn -q package'
up
SEEN=$(grep -cE "$PAT" $LOG)

block page-run
run 'curl -s "localhost:8080/books?size=2&page=1&sort=title,desc" | python3 -m json.tool'
since page-sql
block nested-run
run 'curl -s "localhost:8080/books?size=3&sort=author.name" | python3 -m json.tool | grep -E "title|author|total"'
since nested-sql
block big-run
run 'curl -s "localhost:8080/books?size=5000" | python3 -m json.tool | tail -n 7'
since big-sql
block unknown-run
run 'curl -s "localhost:8080/books?sort=price"; echo'
since unknown-sql
stop

shown "$LESSON/repositories.md" $CAT/AuthorRepository.java
shown "$LESSON/the-change.md" $CAT/BookRepository.java $CAT/TitleAndPrice.java \
  $CAT/BookService.java $CAT/BookController.java $CAT/CatalogueReport.java
