#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed: ~/bookshop as lesson 14 left it, then with
# this lesson's pom.xml only (the first transcript), then as this lesson leaves
# it; a fresh bookshop database before each. The application started in the
# background is what the student starts in a second terminal with
# `java -jar target/bookshop-0.1.0.jar`, with BOOKSHOP_JWT_SECRET set to the
# FIXED value below rather than to a fresh `openssl rand -base64 32`, so that
# reruns sign with the same key; the lesson never prints it. Two detours are
# applied and undone: the starter without SecurityConfig, and TokenController
# without its FACTOR_ filter. Tokens, timestamps, hashes and timings differ on
# every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
STAGES="$COURSE/lab/stages"
SECRET='BOOKSHOP_JWT_SECRET=q3Lw0n7c1V9bR2xT8yK4mP6sD5fG1hJ0aZ3uE7iO9wQ='
TOKEN="python3 -c 'import json,sys; print(json.load(sys.stdin)[\"accessToken\"])'"
BOOK='{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}'

# --- the starter on its own, before any configuration of ours -------------
stage le-82xkn72m
asroot "cp $STAGES/le-pgz0jxe9/pom.xml /home/ana/bookshop/pom.xml && chown ana:ana /home/ana/bookshop/pom.xml"
db
at '~/bookshop'
block starter-only
run 'mvn -B -q package -DskipTests'
start
run "curl -si -w '\n' localhost:8080/books/1"
stop

# --- the lesson's bookshop ---------------------------------------------------
stage le-pgz0jxe9
db
quiet 'mvn -B -q package -DskipTests'

block missing-secret
run "java -jar target/bookshop-0.1.0.jar | grep -A 10 'APPLICATION FAILED'"
block short-secret
run "BOOKSHOP_JWT_SECRET=too-short java -jar target/bookshop-0.1.0.jar | grep -A 10 'APPLICATION FAILED'"
block new-secret
run 'export BOOKSHOP_JWT_SECRET=$(openssl rand -base64 32); echo ${#BOOKSHOP_JWT_SECRET}'

block filter-list
EXTRA_ENV="$SECRET" run "timeout 40 java -jar target/bookshop-0.1.0.jar --logging.level.org.springframework.security.web.DefaultSecurityFilterChain=debug | grep -o 'Will secure .*' | tr ',' '\\n' | sed 's/^ *//'"
EXTRA_ENV="$SECRET" start
block wrong-password
run "curl -s -o /dev/null -w '%{http_code}\n' -u ana:wrong -X POST localhost:8080/auth/token"
run "curl -si -w '\n' -u ana:ana-reads-books -X POST localhost:8080/auth/token"

block timing
run "for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{time_total}\n' -u ana:ana-reads-books -X POST localhost:8080/auth/token; done"
run "curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | $TOKEN > ana.token"
run "for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{time_total}\n' -H \"Authorization: Bearer \$(cat ana.token)\" localhost:8080/books/1; done"

block decode
run "curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | $TOKEN > ana.token"
run 'cat ana.token'
run 'cut -d. -f1 ana.token | basenc -d --base64url; echo'
run 'cut -d. -f2 ana.token | basenc -d --base64url; echo'
run 'cut -d. -f3 ana.token | basenc -d --base64url | wc -c'

block forged
run "cut -d. -f2 ana.token | basenc -d --base64url | sed 's/\"orders\"/\"catalogue:write orders\"/' | basenc --base64url -w0 | tr -d = > payload"
run 'echo "$(cut -d. -f1 ana.token).$(cat payload).$(cut -d. -f3 ana.token)" > forged.token'
run 'cut -d. -f2 forged.token | basenc -d --base64url; echo'
run "curl -si -H \"Authorization: Bearer \$(cat forged.token)\" -H 'Content-Type: application/json' -d '$BOOK' localhost:8080/books"
quiet 'rm -f payload forged.token'

block four-answers
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/books/1"
run 'curl -si localhost:8080/orders/1'
run "curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | $TOKEN > clerk.token"
run 'cut -d. -f2 clerk.token | basenc -d --base64url; echo'
run "curl -si -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '$BOOK' localhost:8080/books"
run "curl -s -w '\n' -H \"Authorization: Bearer \$(cat clerk.token)\" -H 'Content-Type: application/json' -d '$BOOK' localhost:8080/books"

block no-session
run "curl -s -D - -o /dev/null -u ana:ana-reads-books -X POST localhost:8080/auth/token"

block orders
run "curl -s -w '\n' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '{\"lines\":[{\"bookId\":1,\"quantity\":1}]}' localhost:8080/orders"
run "curl -s -w '\n' -H \"Authorization: Bearer \$(cat ana.token)\" -H 'Content-Type: application/json' -d '{\"customer\":\"clerk\",\"lines\":[{\"bookId\":2,\"quantity\":1}]}' localhost:8080/orders"
run "curl -s -w '\n' -H \"Authorization: Bearer \$(cat clerk.token)\" localhost:8080/orders/1"
run "curl -s -w '\n' -H \"Authorization: Bearer \$(cat clerk.token)\" localhost:8080/orders/99"
run "curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat ana.token)\" localhost:8080/orders/1"
stop

block expiry
EXTRA_ENV="$SECRET" start --bookshop.jwt.lifetime=2s
run "curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | $TOKEN > ana.token"
run 'cut -d. -f2 ana.token | basenc -d --base64url; echo'
run "sleep 5; curl -s -o /dev/null -w '%{http_code}\n' -H \"Authorization: Bearer \$(cat ana.token)\" localhost:8080/books/1"
run "sleep 60; curl -si -H \"Authorization: Bearer \$(cat ana.token)\" localhost:8080/books/1 | head -2"
stop

# --- detour: the token controller without its FACTOR_ filter -----------------
block factor
asroot "sed -i '/startsWith(\"FACTOR_\")/d' /home/ana/bookshop/src/main/java/com/example/bookshop/security/TokenController.java"
quiet 'mvn -B -q package -DskipTests'
EXTRA_ENV="$SECRET" start
run "curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | $TOKEN | cut -d. -f2 | basenc -d --base64url; echo"
stop

# --- the program that made the two hashes ------------------------------------
stage le-pgz0jxe9
block hash
run 'mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt'
run 'cd'
at '~'
take passwords.md 'import org.springframework.security.crypto' HashPassword.java
run 'java -cp "$(cat bookshop/cp.txt)" HashPassword.java ana-reads-books'
run "java -cp \"\$(cat bookshop/cp.txt)\" HashPassword.java ana-reads-books '\$2a\$10\$ZGOqa4SybKybYWez.kObuOlRJidwtH0M8N11oKrIWVxl4mA422MiG'"
quiet 'rm -f bookshop/cp.txt HashPassword.java bookshop/ana.token bookshop/clerk.token'

shown the-filter-chain.md pom.xml src/main/java/com/example/bookshop/security/SecurityConfig.java
shown tokens.md src/main/java/com/example/bookshop/security/TokenController.java \
  src/main/java/com/example/bookshop/security/TokenResponse.java \
  src/main/java/com/example/bookshop/security/JwtProperties.java \
  src/main/resources/application.properties
shown whose-order.md src/main/java/com/example/bookshop/ordering/OrderRequest.java \
  src/main/java/com/example/bookshop/ordering/OrderController.java \
  src/main/java/com/example/bookshop/ordering/OrderService.java
echo '##### all shown files match the stage'
