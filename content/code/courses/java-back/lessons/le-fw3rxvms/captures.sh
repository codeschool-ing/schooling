#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as lesson 16 left it and a fresh
# bookshop database; every file the lesson shows, written here as ana (the
# Javadoc-only BookController and the pom's <build> block taken from
# javadoc.md, ~/oapi.py from api-docs.md, the final files copied from this
# lesson's stage) and compared with the lesson byte for byte by `shown`; the
# application, started with java -jar in the background where the student runs
# it in a second terminal, and restarted after each build where the student
# presses Ctrl+C and starts it again. BOOKSHOP_JWT_SECRET is a FIXED value
# here; the student exported a random one in lesson 15. Three detours are
# applied, run and undone: an @param naming no parameter, doclint with
# `missing` switched back on, and the search parameter renamed from q to text.
# Request ids, PIDs, dates and durations differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

STAGE="$COURSE/lab/stages/le-fw3rxvms"
PKG=src/main/java/com/example/bookshop/catalogue
SCR=/tmp/claude-0/-home-user-schooling/de0b3e38-40aa-5c50-8649-e4d9fa4061af/scratchpad/l17
SECRET='BOOKSHOP_JWT_SECRET=q3Lw0n7c1V9bR2xT8yK4mP6sD5fG1hJ0aZ3uE7iO9wQ='
final() { for f in "$@"; do install -o ana -g ana -m 644 -D "$STAGE/$f" "/home/ana/bookshop/$f"; done; }
app() { stop; EXTRA_ENV="$SECRET" start "$@"; }
build() { quiet 'mvn -B -q package -DskipTests'; }

stage le-3mhw8yk6            # the bookshop as lesson 16 left it
db
at '~/bookshop'

########################################################### javadoc.md
put bookshop/$PKG/BookController.java < "$SCR/BookController.v1.java"
python3 - "$SCR/build-block.xml" > /tmp/l17-pom.xml <<'PY'
import re, sys
pom = open('/home/ana/bookshop/pom.xml').read()
block = open(sys.argv[1]).read().rstrip('\n')
print(re.sub(r'  <build>.*?</build>', lambda m: block, pom, flags=re.S), end='')
PY
put bookshop/pom.xml < /tmp/l17-pom.xml
block javadoc
run 'mvn javadoc:javadoc'
run 'ls target/reports/apidocs'
run 'ls target/reports/apidocs/com/example/bookshop/catalogue'
block doclint-error
quiet "sed -i 's/@param q the text/@param query the text/' $PKG/BookController.java"
run 'mvn -q javadoc:javadoc'
quiet "sed -i 's/@param query the text/@param q the text/' $PKG/BookController.java"
block missing
quiet "sed -i 's/<doclint>all,-missing</<doclint>all</' pom.xml"
run "mvn javadoc:javadoc | grep -c 'warning: no comment'"
run "mvn javadoc:javadoc | grep 'warning: no comment' | head -4"
quiet "sed -i 's/<doclint>all</<doclint>all,-missing</' pom.xml"

########################################################### api-docs.md
final pom.xml
build
app
block docs-401
run "curl -si -w '\n' localhost:8080/v3/api-docs"
final src/main/java/com/example/bookshop/security/SecurityConfig.java
build
app
block docs-first
run "curl -s localhost:8080/v3/api-docs | python3 -m json.tool | head -20"
run "curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json; wc -l ~/api.json"
quiet "cp $SCR/oapi.py ~/oapi.py"
run "python3 -c 'import json; [print(m.upper(), p) for p, ops in json.load(open(\"/home/ana/api.json\"))[\"paths\"].items() for m in ops]'"
block docs-pieces
run "python3 ~/oapi.py ~/api.json paths /books/{id} get"
run "python3 ~/oapi.py ~/api.json paths /books get parameters"
run "python3 ~/oapi.py ~/api.json components schemas BookRequest"
run "python3 ~/oapi.py ~/api.json paths /orders post responses"
run "python3 ~/oapi.py ~/api.json paths /orders post"
block yaml
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs.yaml"
block warnings
grep SpringDocAppInitializer /tmp/bookshop.log

########################################################### annotations.md
final $PKG/BookController.java src/main/java/com/example/bookshop/web/OpenApiConfig.java
build
app
block docs-final
run "curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json"
run "python3 ~/oapi.py ~/api.json info"
run "python3 ~/oapi.py ~/api.json paths /books/{id} get"
run "python3 ~/oapi.py ~/api.json paths /books get parameters"
run "python3 ~/oapi.py ~/api.json components schemas ProblemDetail"
run "python3 ~/oapi.py ~/api.json paths /books post security"
run "python3 ~/oapi.py ~/api.json components securitySchemes"
run "python3 ~/oapi.py ~/api.json paths /books post responses 400"
block javap
run "javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep -c 'One page of the catalogue'"
run "javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep 'List the catalogue'"

########################################################### swagger-ui.md
block swagger
run "curl -si localhost:8080/swagger-ui.html | head -3"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui/index.html"
run "curl -s -w '\n' localhost:8080/v3/api-docs/swagger-config"
block token
run "curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"accessToken\"])' > clerk.token"
run "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat clerk.token)\" -H 'Content-Type: application/json' -d '{\"isbn\":\"9786500000078\",\"title\":\"Emma\",\"author\":\"Jane Austen\",\"priceCents\":3300,\"stock\":2}' localhost:8080/books"
quiet 'rm -f clerk.token'
block disabled
app --springdoc.api-docs.enabled=false
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui.html"
grep -c SpringDocAppInitializer /tmp/bookshop.log
app

########################################################### contract-first.md
block rename
run "sed -i 's/String q)/String text)/; s/search(q)/search(text)/; s/@param q the/@param text the/' $PKG/BookController.java && grep -n 'text' $PKG/BookController.java"
build
app
run "curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api-renamed.json"
run 'diff ~/api.json ~/api-renamed.json'
run "curl -s -o /dev/null -w '%{http_code}\n' 'localhost:8080/books/search?q=time'"
run "curl -s -w '\n' 'localhost:8080/books/search?text=time'"
final $PKG/BookController.java
build
stop
quiet 'rm -f ~/api-renamed.json'

########################################################### the end state is the stage
block end-state
rm -rf /tmp/l17-built && mkdir -p /tmp/l17-built && cp -a /home/ana/bookshop/pom.xml /home/ana/bookshop/src /tmp/l17-built/
stage le-fw3rxvms
diff -r /tmp/l17-built/src /home/ana/bookshop/src && diff /tmp/l17-built/pom.xml /home/ana/bookshop/pom.xml \
  && echo 'the lesson ends where the stage ends' || echo '!!! the lesson does not end at the stage'
