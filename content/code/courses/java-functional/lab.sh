#!/usr/bin/env bash
# The machine every transcript in java-functional was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER AND ONE PERSON. ana is the student; her prompt is
# printed as ana@vm, the name the java course gives the virtual machine its
# setup lesson recommends. The JDK is OpenJDK 25 and the build tool Maven,
# both Ubuntu's own packages (openjdk-25-jdk, maven 3.8.7), installed the way
# lesson 1 section 02 shows: the same toolchain the java course installs and
# java-back continues with, so a student who takes the three in order
# installs nothing twice.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      the JDK, Maven, and everything they printed.
#   written   every program and every data file. Each lesson's captures.sh
#             takes them out of the lesson's own English .md (lab/fences.py)
#             and writes them into ana's home, so the file a student copies
#             is the file that was run.
#   staged    ~ana/.m2/settings.xml, which points Maven at this sandbox's
#             outbound proxy. A student's machine reaches Maven Central
#             directly and has no such file; nothing Maven printed depends on
#             it.
#
#   sudo bash lab.sh setup              install the JDK and Maven, create ana
#   sudo bash lab.sh fresh DIR          empty ~ana/DIR and leave it, owned by ana
#   sudo bash lab.sh exec DIR 'CMD'     run CMD as ana in ~ana/DIR
#   sudo bash lab.sh put DIR/FILE       write stdin to ~ana/DIR/FILE, as ana
#
# THE ENVIRONMENT IS FIXED: HOME, PATH=/usr/local/bin:/usr/bin:/bin,
# TZ=America/Sao_Paulo, LANG=LC_ALL=C.UTF-8, TERM=dumb. Nothing else leaks in
# from whoever runs this; in particular no JAVA_TOOL_OPTIONS, which would make
# every JVM print a line about it.
#
# Recorded on Ubuntu 24.04, 4 cores, 15 GB of memory.
set -euo pipefail
STUDENT=ana
HOME_DIR=/home/$STUDENT

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }

as_student() {
  runuser -u "$STUDENT" -- env -i HOME="$HOME_DIR" USER="$STUDENT" LOGNAME="$STUDENT" \
    SHELL=/bin/bash PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=dumb bash -c "$1"
}

setup() {
  need_root
  if ! dpkg -s openjdk-25-jdk maven >/dev/null 2>&1; then
    apt-get update -q
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q openjdk-25-jdk maven
  fi
  id "$STUDENT" >/dev/null 2>&1 || useradd -m -s /bin/bash "$STUDENT"
  if [ -n "${HTTPS_PROXY:-}" ]; then
    local hp=${HTTPS_PROXY#*://}; hp=${hp%/}
    as_student "mkdir -p ~/.m2 && cat > ~/.m2/settings.xml" <<XML
<settings>
  <proxies>
    <proxy><id>lab</id><active>true</active><protocol>https</protocol><host>${hp%:*}</host><port>${hp##*:}</port><nonProxyHosts>localhost|127.0.0.1</nonProxyHosts></proxy>
  </proxies>
</settings>
XML
  fi
  as_student 'java -version 2>&1 | head -1; mvn -B -v | head -1'
}

case "${1:-}" in
  setup) setup ;;
  fresh)
    need_root
    [ -n "${2:-}" ] || { echo "usage: lab.sh fresh DIR" >&2; exit 2; }
    rm -rf "${HOME_DIR:?}/$2"
    as_student "mkdir -p ~/'$2'" ;;
  exec)
    need_root
    [ $# -ge 3 ] || { echo "usage: lab.sh exec DIR 'CMD'" >&2; exit 2; }
    as_student "cd ~/'$2' && $3" ;;
  put)
    need_root
    [ -n "${2:-}" ] || { echo "usage: lab.sh put DIR/FILE < content" >&2; exit 2; }
    as_student "mkdir -p \"\$(dirname ~/'$2')\" && cat > ~/'$2'" ;;
  *) sed -n '2,32p' "$0" >&2; exit 2 ;;
esac
