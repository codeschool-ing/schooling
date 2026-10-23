#!/usr/bin/env bash
# The machine every transcript in java-back was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER AND ONE PERSON. ana is the student and her prompt
# is printed as ana@vm, the names lesson 1's setup gives the virtual machine it
# recommends. Everything she runs comes from Ubuntu's own archive, installed
# the way lesson 1 (the JDK and Maven, as `java` installs them), lesson 9
# (PostgreSQL 16, as `sql-databases` installs it) and lesson 19 (Docker Engine,
# as `docker` installs it) tell the student to.
#
# WHAT IS REAL AND WHAT IS STAGED.
#
#   real      OpenJDK 25.0.4 (openjdk-25-jdk) and Maven 3.8.7 (maven), both
#             Ubuntu's; PostgreSQL 16.15; Docker Engine 29.8; every library
#             Maven downloads, at the versions the lessons' pom.xml pin.
#   staged    1. ~/.m2/settings.xml names this sandbox's HTTPS proxy, because
#                the machine reaches the internet only through it, and points
#                Maven at Google's public mirror of Maven Central
#                (maven-central.storage-download.googleapis.com), because
#                Central answers this machine's downloads with "429 Too Many
#                Requests". The artifacts and their checksums are Central's;
#                only the server that hands over the bytes differs. A
#                student's machine needs neither and no lesson shows the file.
#                A transcript that shows a download names the mirror, and the
#                lesson says why.
#             2. Maven's colours are stripped from captures (sed, in each
#                captures.sh). The text is byte for byte what Maven printed.
#             3. Docker pulls Docker Hub images through mirror.gcr.io, Google's
#                public cache of Docker Hub, as the `docker` course's lab does.
#                The names, tags and digests are Docker Hub's.
#             4. ~/.m2/repository is warmed by building every stage once, so a
#                transcript is a build and not a download log. A lesson that
#                shows a download says so and empties what it needs first.
#   written   the bookshop. lab/stages/<lesson-id>/ holds the files lesson N
#             adds or changes, and `stage` lays them over each other in course
#             order. Each lesson's captures.sh compares every file it shows
#             with its stage, byte for byte, so the file a student copies is
#             the file that was built.
#
#   sudo bash lab.sh up                  install, create ana, start PostgreSQL
#                                        and dockerd
#   sudo bash lab.sh stage LESSON-ID     ~/bookshop as it is at the END of that
#                                        lesson (empty argument: no project)
#   sudo bash lab.sh db                  drop and recreate the bookshop role
#                                        and database, as lesson 9 makes them
#   sudo bash lab.sh exec 'COMMAND'      run COMMAND as ana, in ~ (a captures.sh
#                                        holds the lock for its whole run)
#   sudo bash lab.sh start [ARGS]        java -jar ~/bookshop/target/*.jar ARGS
#                                        in the background, as ana; waits for
#                                        "Started"; log in /tmp/bookshop.log
#   sudo bash lab.sh stop                stop it, by pid
#
# Recorded on Ubuntu 24.04, 4 cores, 15 GB of memory, TZ=America/Sao_Paulo.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LOCK=/var/tmp/java-back.lock
PIDFILE=/tmp/java-back-app.pid

# Course order: the lessons whose stage directory exists are applied in this
# order, up to and including the one asked for.
ORDER=(le-phqecvsy le-3mq63qfr le-3prxerev le-djnvk025 le-1gxw12xb le-3jfvd9zx
  le-k1349km8 le-797zzsne le-e6we03q0 le-qxajq2s8 le-95z47qtq le-7b4atbwk
  le-gb0yefh1 le-82xkn72m le-pgz0jxe9 le-3mhw8yk6 le-fw3rxvms le-8ep384dn
  le-7zncse9p le-q3854jqh le-fzjrd3nz le-p1p8dt26 le-2brc8hh5)

locked() { [ "${JB_LOCKED:-}" = 1 ]; }
withlock() { if locked; then "$@"; else ( exec 9>"$LOCK"; flock 9; JB_LOCKED=1 "$@" ); fi; }

as_ana() { runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana \
  PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 \
  ${EXTRA_ENV:-} "$@" 9>&-; }   # a daemon a command starts must not keep the lock

up() {
  command -v mvn >/dev/null && dpkg -s openjdk-25-jdk >/dev/null 2>&1 \
    || { apt-get update -q; apt-get install -y -q openjdk-25-jdk maven postgresql; }
  update-java-alternatives -s java-1.25.0-openjdk-amd64 2>/dev/null || true
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  getent group docker >/dev/null && usermod -aG docker ana
  # The one line lesson 1 adds, so Maven on Java 25 does not warn on every run.
  echo 'MAVEN_OPTS="--sun-misc-unsafe-memory-access=allow"' > /home/ana/.mavenrc
  mkdir -p /home/ana/.m2
  local port=${HTTPS_PROXY##*:}; port=${port%%/*}
  cat > /home/ana/.m2/settings.xml <<XML
<settings>
  <mirrors>
    <mirror><id>google-maven-central</id><mirrorOf>central</mirrorOf>
      <url>https://maven-central.storage-download.googleapis.com/maven2/</url></mirror>
  </mirrors>
  <proxies>
    <proxy><id>sandbox</id><active>true</active><protocol>https</protocol>
      <host>127.0.0.1</host><port>$port</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts></proxy>
  </proxies>
</settings>
XML
  chown -R ana:ana /home/ana/.mavenrc /home/ana/.m2
  pg_lsclusters -h | grep -q '^16 *main' || pg_createcluster 16 main >/dev/null
  pg_ctlcluster 16 main start 9>&- >/dev/null 2>&1 || true
  mkdir -p /etc/docker
  echo '{"registry-mirrors": ["https://mirror.gcr.io"]}' > /etc/docker/daemon.json
  if ! docker info >/dev/null 2>&1; then
    setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null 9>&- &
    for _ in $(seq 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
  fi
  chmod 666 /var/run/docker.sock
}

stage() {
  local want=${1:-} dir=/home/ana/bookshop
  rm -rf "$dir"
  [ -z "$want" ] && return 0
  mkdir -p "$dir"
  local id found=
  for id in "${ORDER[@]}"; do
    if [ -d "$HERE/lab/stages/$id" ]; then
      cp -a "$HERE/lab/stages/$id/." "$dir/"
      if [ -f "$dir/.removed" ]; then
        while read -r f; do [ -n "$f" ] && rm -rf "${dir:?}/$f"; done < "$dir/.removed"
        rm -f "$dir/.removed"
      fi
    fi
    [ "$id" = "$want" ] && { found=1; break; }
  done
  [ -n "$found" ] || { echo "no lesson $want" >&2; exit 1; }
  chown -R ana:ana "$dir"
}

db() {
  pg_ctlcluster 16 main start 9>&- >/dev/null 2>&1 || true
  runuser -u postgres -- psql -qX -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
DROP DATABASE IF EXISTS bookshop WITH (FORCE);
DROP ROLE IF EXISTS bookshop;
CREATE ROLE bookshop LOGIN PASSWORD 'bookshop';
CREATE DATABASE bookshop OWNER bookshop;
SQL
}

start() {
  stop
  rm -f "$PIDFILE"; : > /tmp/bookshop.log; chmod 666 /tmp/bookshop.log
  as_ana setsid bash -c 'echo $$ > '"$PIDFILE"'; cd ~/bookshop && exec java -jar target/bookshop-0.1.0.jar "$@"' _ "$@" \
    >/tmp/bookshop.log 2>&1 </dev/null 9>&- &
  for _ in $(seq 60); do
    grep -q 'Started BookshopApplication' /tmp/bookshop.log && return 0
    grep -q 'APPLICATION FAILED TO START\|Application run failed' /tmp/bookshop.log && return 0
    sleep 1
  done
  echo "the application did not start; see /tmp/bookshop.log" >&2; return 1
}

stop() {
  [ -s "$PIDFILE" ] || return 0
  local pid; pid=$(cat "$PIDFILE"); rm -f "$PIDFILE"
  kill -TERM "$pid" 2>/dev/null || true
  for _ in $(seq 60); do kill -0 "$pid" 2>/dev/null || return 0; sleep 0.5; done
  kill -KILL "$pid" 2>/dev/null || true
}

case "${1:-}" in
  up)    withlock up ;;
  stage) shift; withlock stage "${1:-}" ;;
  db)    withlock db ;;
  exec)  shift; cd /home/ana; withlock as_ana bash -c "$*" ;;
  start) shift; withlock start "$@" ;;
  stop)  withlock stop ;;
  *) sed -n '2,50p' "$0"; exit 1 ;;
esac
