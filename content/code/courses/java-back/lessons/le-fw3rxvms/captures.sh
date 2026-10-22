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
# bookshop database; every file the lesson shows, written here as ana: the
# Javadoc-only BookController (the schooling-example of javadoc.md, its parts
# joined), the <build> element of javadoc.md spliced into lesson 16's pom, and
# ~/oapi.py from api-docs.md, each taken from the lesson itself; the final
# files copied from this lesson's stage and compared with the lesson byte for
# byte by `shown`. Edits the student makes in an editor (an @param renamed and
# put back, the doclint line changed and put back) are made here with sed and
# not shown. The application runs in the background where the student runs it
# in a second terminal, restarted after each build where the student presses
# Ctrl+C and starts it again; the lines quoted from that terminal are read out
# of its log. BOOKSHOP_JWT_SECRET is a FIXED value here; the student exported a
# random one in lesson 15. Request ids, PIDs, tokens, dates and durations
# differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"

STAGE="$COURSE/lab/stages/le-fw3rxvms"
PKG=src/main/java/com/example/bookshop/catalogue
SECRET='BOOKSHOP_JWT_SECRET=q3Lw0n7c1V9bR2xT8yK4mP6sD5fG1hJ0aZ3uE7iO9wQ='
BOOK='{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}'
final() { for f in "$@"; do install -o ana -g ana -m 644 -D "$STAGE/$f" "/home/ana/bookshop/$f"; done; }
app() { stop; EXTRA_ENV="$SECRET ${ENVX:-}" start "$@"; }
build() { quiet 'mvn -B -q package -DskipTests'; }
# The code of the one schooling-example in an .md file, as the copy button
# hands it over.
example() {
  python3 - "$1" <<'PY'
import json, sys
text = open(sys.argv[1], encoding='utf-8').read()
body = text.split('```schooling-example\n', 1)[1].split('\n```', 1)[0]
print('\n'.join(p['code'] for p in json.loads(body)['parts']))
PY
}

stage le-3mhw8yk6            # the bookshop as lesson 16 left it
db
at '~/bookshop'

########################################################### javadoc.md
example javadoc.md | put bookshop/$PKG/BookController.java
python3 "$COURSE/lab/fence.py" extract javadoc.md '  <build>' > /tmp/l17-build.xml
python3 - > /tmp/l17-pom.xml <<'PY'
import re
pom = open('/home/ana/bookshop/pom.xml').read()
block = open('/tmp/l17-build.xml').read().rstrip('\n')
print(re.sub(r'  <build>.*?</build>', lambda m: block, pom, flags=re.S), end='')
PY
put bookshop/pom.xml < /tmp/l17-pom.xml
block JAVADOC
run 'mvn javadoc:javadoc'
block LS
run 'ls target/reports/apidocs'
run 'ls target/reports/apidocs/com/example/bookshop/catalogue'
block STALE
quiet "sed -i 's/@param q the text/@param query the text/' $PKG/BookController.java"
run 'mvn -q javadoc:javadoc'
block CLEAN
run 'mvn -q clean javadoc:javadoc | head -6'
quiet "sed -i 's/@param query the text/@param q the text/' $PKG/BookController.java"
block MISSING
quiet "sed -i 's/<doclint>all,-missing</<doclint>all</' pom.xml"
run "mvn javadoc:javadoc | grep 'warning: no comment' > ~/missing.txt"
run 'wc -l < ~/missing.txt'
run 'head -3 ~/missing.txt'
run 'grep BookController ~/missing.txt'
quiet "sed -i 's/<doclint>all</<doclint>all,-missing</' pom.xml"
quiet 'rm -f ~/missing.txt'

########################################################### api-docs.md
final pom.xml
build
app
block WARNINGS
grep SpringDocAppInitializer /tmp/bookshop.log
block 401
run "curl -si -w '\n' localhost:8080/v3/api-docs"
final src/main/java/com/example/bookshop/security/SecurityConfig.java
build
app
block FIRST
run 'curl -s localhost:8080/v3/api-docs | python3 -m json.tool | head -14'
block SAVE
run 'curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json'
run 'wc -l ~/api.json'
run "python3 -c 'import json; [print(m.upper(), p) for p, ops in json.load(open(\"/home/ana/api.json\"))[\"paths\"].items() for m in ops]'"
take api-docs.md 'import json' oapi.py
block GET
run 'python3 ~/oapi.py ~/api.json paths /books/{id} get'
block SCHEMA
run 'python3 ~/oapi.py ~/api.json components schemas BookRequest'
block PAGEABLE
run 'python3 ~/oapi.py ~/api.json paths /books get parameters'
block ORDERS
run 'python3 ~/oapi.py ~/api.json paths /orders post responses'
block YAML
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs.yaml"

########################################################### annotations.md
final $PKG/BookController.java src/main/java/com/example/bookshop/web/OpenApiConfig.java
build
app
block JAVAP
run "javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep -c 'One page of the catalogue'"
run "javap -v target/classes/com/example/bookshop/catalogue/BookController.class | grep 'List the catalogue'"
block SAVE2
run 'curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api.json'
block INFO
run 'python3 ~/oapi.py ~/api.json info'
block GETFINAL
run 'python3 ~/oapi.py ~/api.json paths /books/{id} get responses'
block PROBLEM
run 'python3 ~/oapi.py ~/api.json components schemas ProblemDetail'
block PARAMS
run 'python3 ~/oapi.py ~/api.json paths /books get parameters'
block SECURITY
run 'python3 ~/oapi.py ~/api.json paths /books post security'
run 'python3 ~/oapi.py ~/api.json components securitySchemes'

########################################################### swagger-ui.md
block REDIRECT
run 'curl -si localhost:8080/swagger-ui.html | head -3'
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui/index.html"
block CONFIG
run "curl -s -w '\n' localhost:8080/v3/api-docs/swagger-config"
block TOKEN
run "curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)[\"accessToken\"])' > clerk.token"
block POST
run "curl -s -w '\n%{http_code}\n' -H \"Authorization: Bearer \$(cat clerk.token)\" -H 'Content-Type: application/json' -d '$BOOK' localhost:8080/books"
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d '$BOOK' localhost:8080/books"
quiet 'rm -f clerk.token'
block DISABLED
app --springdoc.api-docs.enabled=false
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui.html"
block DISABLED_LOG
echo "(SpringDocAppInitializer lines in the log: $(grep -c SpringDocAppInitializer /tmp/bookshop.log))"
block ENV
ENVX='SPRINGDOC_APIDOCS_ENABLED=false' app
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs"
block ENV_LOG
echo "(SpringDocAppInitializer lines in the log: $(grep -c SpringDocAppInitializer /tmp/bookshop.log))"
app

########################################################### contract-first.md
block RENAME
run "sed -i 's/String q)/String text)/; s/search(q)/search(text)/; s/@param q the/@param text the/' $PKG/BookController.java && grep -n 'text' $PKG/BookController.java"
build
app
block DIFF
run 'curl -s localhost:8080/v3/api-docs | python3 -m json.tool > ~/api-renamed.json'
run 'diff ~/api.json ~/api-renamed.json'
block BROKEN
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
shown api-docs.md pom.xml src/main/java/com/example/bookshop/security/SecurityConfig.java
shown annotations.md src/main/java/com/example/bookshop/web/OpenApiConfig.java $PKG/BookController.java
echo 'all shown files match the stage'
