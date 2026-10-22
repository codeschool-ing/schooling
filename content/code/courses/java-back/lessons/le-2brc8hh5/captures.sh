#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the bookshop as lesson 22 left it, and a fresh bookshop database;
#   - BOOKSHOP_JWT_SECRET, in the environment of every command, with a FIXED
#     value (a student sets it with `export BOOKSHOP_JWT_SECRET=$(openssl rand
#     -base64 32)`, as lesson 15 teaches); SPRING_DATASOURCE_PASSWORD is added
#     to it from the moment the lesson types `export`, because each command
#     here runs in a shell of its own;
#   - before anything else, as root: any bookshop compose project and image
#     left by an earlier run are removed, the eclipse-temurin image is removed
#     so the first `docker run` really downloads it (through mirror.gcr.io,
#     Google's cache of Docker Hub, as lab.sh's header says; the names, tags
#     and digests are Docker Hub's), and Docker's build cache is emptied so the
#     first `docker build` really builds. postgres:16-alpine and the
#     Testcontainers images are left alone: other lessons use them;
#   - every file the lesson asks the student to write (application.properties,
#     .dockerignore, Dockerfile, .gitignore, compose.yaml) is taken from the
#     lesson's own fences, and at the end compared with this lesson's stage,
#     byte for byte. The two detours (the log message changed and changed
#     back; the shell-form ENTRYPOINT) are applied here, run, and undone;
#   - lines quoted from "the second terminal" are lines of the application's
#     log (/tmp/bookshop.log, where `start` writes what `java -jar` prints),
#     never edited.
#
# Run as root. PIDs, timestamps, durations, sizes on disk, digests and the
# generated .env values differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4.1, Maven 3.8.7, PostgreSQL 16.15,
# Docker Engine 29.8.2, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
STAGE=$COURSE/lab/stages/le-2brc8hh5
BS=/home/ana/bookshop
LOG=/tmp/bookshop.log
JWT='BOOKSHOP_JWT_SECRET=captures-only-secret-of-at-least-32-bytes'
export EXTRA_ENV="$JWT"

# the code of the schooling-example whose "file" is $2, in $1, written to ~/bookshop/$2
example_to() { python3 - "$1" "$2" > "$BS/$2" <<'PY'
import json, re, sys
md, name = sys.argv[1:]
text = open(md, encoding='utf-8').read()
hits = [json.loads(b) for b in re.findall(r'```schooling-example\n(.*?)\n```', text, re.S)]
hits = [h for h in hits if h.get('file') == name]
assert len(hits) == 1, (md, name, len(hits))
print('\n'.join(p['code'] for p in hits[0]['parts']))
PY
chown ana:ana "$BS/$2"; }
same_as_stage() { for f in "$@"; do cmp -s "$STAGE/$f" "$BS/$f" || { echo "!!! $f differs from the stage" >&2; exit 1; }; done; }
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

# --- a clean machine for this lesson -------------------------------------------
stop
asroot "cd $BS 2>/dev/null && docker compose down -v"
asroot 'docker rm -f bookshop-app-1 bookshop-db-1; docker volume rm bookshop_db-data; docker network rm bookshop_default'
asroot 'docker rmi bookshop:0.1.0 eclipse-temurin:25-jre-noble'
asroot 'docker builder prune -af'
stage le-p1p8dt26
db
at '~/bookshop'
quiet 'rm -rf /tmp/extracted /tmp/layers-before.txt /tmp/layers-after.txt'

# --- the executable jar ----------------------------------------------------------
block package
run 'mvn -q package -DskipTests'
run 'ls -lh target/bookshop-0.1.0.jar*'
block original
run 'java -jar target/bookshop-0.1.0.jar.original'
block inside
run "jar tf target/bookshop-0.1.0.jar | grep -v '/\$' | cut -d/ -f1-2 | sort | uniq -c"
run "jar tf target/bookshop-0.1.0.jar | grep '^BOOT-INF/lib/' | head -n 5"
block manifest
run 'unzip -p target/bookshop-0.1.0.jar META-INF/MANIFEST.MF'
block stored
run "unzip -v target/bookshop-0.1.0.jar | grep -E 'hibernate-core|BookshopApplication.class'"
block launcher
run "jar tf target/bookshop-0.1.0.jar | grep 'loader/launch/.*Launcher.class'"

# --- configuration from the environment ----------------------------------------
take from-the-environment.md 'spring.application.name' bookshop/src/main/resources/application.properties
same_as_stage src/main/resources/application.properties
block no-password
run 'mvn -q package -DskipTests'
run "java -jar target/bookshop-0.1.0.jar | grep -m 1 '^Message'"
block export
run 'export SPRING_DATASOURCE_PASSWORD=bookshop'
export EXTRA_ENV="$JWT SPRING_DATASOURCE_PASSWORD=bookshop"
start
block started
grep -E 'Started BookshopApplication|Catalogue opened' $LOG
block curl
run 'curl -s localhost:8080/books/1'
echo
stop

# --- layers ----------------------------------------------------------------------
block layers
run 'java -Djarmode=tools -jar target/bookshop-0.1.0.jar list-layers'
run 'unzip -p target/bookshop-0.1.0.jar BOOT-INF/layers.idx'
block extract
run 'java -Djarmode=tools -jar target/bookshop-0.1.0.jar extract --layers --launcher --destination /tmp/extracted'
run 'du -sh /tmp/extracted/*'
run 'ls /tmp/extracted/application /tmp/extracted/spring-boot-loader/org/springframework/boot/loader'
quiet 'rm -rf /tmp/extracted'

# --- an image ----------------------------------------------------------------------
block base
run 'docker run --rm eclipse-temurin:25-jre-noble java -version'
run "docker run --rm eclipse-temurin:25-jre-noble bash -c 'grep PRETTY_NAME /etc/os-release; command -v java curl wget'"
take an-image.md '*' bookshop/.dockerignore
example_to an-image.md Dockerfile
same_as_stage .dockerignore Dockerfile
block build
run 'docker build -t bookshop:0.1.0 .'
block images
run 'docker images bookshop'
run 'docker run --rm --entrypoint id bookshop:0.1.0'
run "docker history --format '{{.Size}}\t{{.CreatedBy}}' bookshop:0.1.0 | head -n 9"
block rebuild
asroot "cp $BS/src/main/java/com/example/bookshop/catalogue/CatalogueReport.java /tmp/CatalogueReport.java.orig"
run "docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' bookshop:0.1.0 > /tmp/layers-before.txt"
run "sed -i 's/with {} books/with {} titles/' src/main/java/com/example/bookshop/catalogue/CatalogueReport.java"
run 'mvn -q package -DskipTests'
run "docker build -t bookshop:0.1.0 . 2>&1 | grep --no-group-separator -A 1 -E '^#[0-9]+ \\[(layers|stage-1)'"
run "docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' bookshop:0.1.0 > /tmp/layers-after.txt"
run 'diff /tmp/layers-before.txt /tmp/layers-after.txt'
block undo
run "sed -i 's/with {} titles/with {} books/' src/main/java/com/example/bookshop/catalogue/CatalogueReport.java"
run 'mvn -q package -DskipTests && docker build -q -t bookshop:0.1.0 .'
cmp -s /tmp/CatalogueReport.java.orig $BS/src/main/java/com/example/bookshop/catalogue/CatalogueReport.java \
  || { echo '!!! CatalogueReport was not restored' >&2; exit 1; }

# --- compose -------------------------------------------------------------------------
take compose.md 'target/' bookshop/.gitignore
example_to compose.md compose.yaml
same_as_stage .gitignore compose.yaml
block env
run 'echo "BOOKSHOP_DB_PASSWORD=$(openssl rand -hex 16)" > .env'
run 'echo "BOOKSHOP_JWT_SECRET=$(openssl rand -base64 32)" >> .env'
run 'chmod 600 .env'
run 'cut -d= -f1 .env'
block no-env
run 'docker compose --env-file /dev/null up -d'
block up
run 'docker compose up -d --wait'
run 'docker compose ps'
block try
run 'curl -s localhost:8080/books/1'
echo
run 'curl -s 127.0.0.1:8081/actuator/health/readiness'
echo
run "docker compose logs app | grep -E 'Successfully applied|Started BookshopApplication|Catalogue opened'"
run 'docker compose exec app ps -o pid,user,args'
block again
run 'docker compose down'
run 'docker compose up -d --wait'
run "docker compose logs app | grep -E 'Schema|Started BookshopApplication'"
block management
edit compose.yaml '      MANAGEMENT_SERVER_ADDRESS: 0.0.0.0
' ''
run 'docker compose up -d --wait 2>&1 | tail -n 1'
run "docker compose ps --format '{{.Name}}  {{.Status}}' app"
run 'curl -sS 127.0.0.1:8081/actuator/health/readiness'
asroot "cp $STAGE/compose.yaml $BS/compose.yaml && chown ana:ana $BS/compose.yaml"
block management-back
run 'docker compose up -d --wait 2>&1 | tail -n 1'
run 'curl -sS 127.0.0.1:8081/actuator/health/readiness'
echo

# --- stopping, and memory --------------------------------------------------------
block stop
run 'time docker compose stop app'
run "docker compose logs app | grep -E 'graceful|Shutdown'"
run "docker inspect --format '{{.State.ExitCode}}' bookshop-app-1"
block shell-form
SHELLFORM=$(python3 "$COURSE/lab/fence.py" extract stopping-and-memory.md 'ENTRYPOINT java')
edit Dockerfile 'ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "org.springframework.boot.loader.launch.JarLauncher"]' "$SHELLFORM"
run 'docker compose up -d --build --wait 2>&1 | tail -n 3'
run 'docker compose exec app ps -o pid,user,args'
run 'time docker compose stop app'
run "docker compose logs app | grep -E 'graceful|Shutdown'"
run "docker inspect --format '{{.State.ExitCode}}' bookshop-app-1"
asroot "cp $STAGE/Dockerfile $BS/Dockerfile && chown ana:ana $BS/Dockerfile"
block restored
run 'docker compose up -d --build --wait 2>&1 | tail -n 3'
block memory
run "docker run --rm eclipse-temurin:25-jre-noble java -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | UseG1GC | UseSerialGC '"
run "docker run --rm --memory=1g eclipse-temurin:25-jre-noble java -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize | UseG1GC | UseSerialGC '"
run "docker run --rm --memory=1g eclipse-temurin:25-jre-noble java -XX:MaxRAMPercentage=75 -XX:+PrintFlagsFinal -version | grep -E ' MaxHeapSize '"
run "docker stats --no-stream --format '{{.Name}}  {{.MemUsage}}' bookshop-app-1"
run "curl -s '127.0.0.1:8081/actuator/metrics/jvm.memory.max?tag=area:heap' | python3 -m json.tool"
block down
run 'docker compose down -v'

# --- what the lesson shows is what the stage holds -------------------------------
block check
for f in $(cd $STAGE && find . -type f ! -name .removed | sed 's|^\./||'); do same_as_stage "$f"; done
shown from-the-environment.md src/main/resources/application.properties
shown an-image.md .dockerignore Dockerfile
shown compose.md .gitignore compose.yaml
echo 'every file shown is the file the stage holds'
quiet 'rm -f .env /tmp/layers-before.txt /tmp/layers-after.txt'
asroot "cd $BS && docker compose down -v"
db
stage le-2brc8hh5
