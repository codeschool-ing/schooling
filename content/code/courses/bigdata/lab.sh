#!/usr/bin/env bash
# The machine every transcript in bigdata was recorded on. AUTHORING ONLY: the
# student never receives this file, and no lesson names it.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Ponto Final,
# the chain of bookshops that does not exist from warehouse-modeling and
# pipelines-etl. In this course the shop's website clickstream outgrows the
# tools she has, and she learns to process it on a cluster. ~/big is her
# working directory, and the machine is called `lab`.
#
# IT IS BUILT THE WAY LESSON 1 TELLS THE STUDENT TO BUILD THEIRS: Ubuntu's
# openjdk-17-jre-headless, Apache Spark 4.1.3 from the binary release
# downloaded from downloads.apache.org and checked against its SHA-512, the
# three configuration files lesson 1 shows, and the cluster lesson 1 starts:
# one master and three workers of one core and 1 GB each, on this one machine.
# Every file a lesson shows is taken OUT of the lesson's .md by `extract`, so
# what ran is what the student reads, byte for byte.
#
# WHAT IS STAGED, and why.
#   - The machine has Java 21 as well, which the student's does not; java is
#     pointed at 17 with update-alternatives so the transcripts show 17.
#   - The Spark tarball is downloaded once into /var/cache/bigdata and copied
#     from there on every rebuild, because it is 573 MB.
#   - The hostname is set to `lab` with `hostname`, as Multipass names the
#     machine the student creates.
#   - Every row of data is written by lesson 1's generate.py: 24,000,000
#     clickstream events in 2025 and 3,000 books, drawn from hashes of the row
#     number. Nothing is real and nothing is random.
#
#   sudo bash lab.sh up               build it (idempotent)
#   sudo bash lab.sh wipe             undo lesson 1, so it can be done on camera
#   sudo bash lab.sh start | stop     the standalone cluster
#   sudo bash lab.sh data             generate the data if it is not there
#   sudo bash lab.sh exec 'COMMAND'   run COMMAND as ana, in ~/big
#   sudo bash lab.sh extract MD FILE  the code of the example named FILE in MD
#   sudo bash lab.sh fence MD N       the body of the Nth fence of MD (from 1)
#
# Recorded on Ubuntu 24.04, OpenJDK 17, Python 3.12, 4 cores, 15 GB,
# TZ=America/Sao_Paulo.
set -euo pipefail
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1="$HERE/lessons/le-aptkd6hk"
TGZ=spark-4.1.3-bin-hadoop3.tgz
CACHE=/var/cache/bigdata

as_ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana TERM=dumb LANG=C.UTF-8 \
    PATH=/usr/local/bin:/usr/bin:/bin bash -c \
    "[ -f ~/.sparkrc ] && . ~/.sparkrc; mkdir -p ~/big; cd ~/big && $1"
}

extract() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
md, name = sys.argv[1], sys.argv[2]
text = open(md, encoding='utf-8').read()
for m in re.finditer(r'```schooling-example\n(.*?)\n```', text, re.S):
    ex = json.loads(m.group(1))
    if ex.get('file') == name:
        sys.stdout.write(''.join(p['code'] for p in ex['parts']))
        sys.exit(0)
sys.exit(f'{md}: no example named {name}')
PY
}

fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
md, n = sys.argv[1], int(sys.argv[2])
blocks = re.findall(r'^```[^\n]*\n(.*?)^```$', open(md, encoding='utf-8').read(), re.S | re.M)
sys.stdout.write(blocks[n - 1])
PY
}

# The sandbox forgets both on a restart; Multipass sets them on the student's.
[ "$(hostname)" = lab ] || hostname lab
grep -q ' lab$' /etc/hosts || echo '127.0.1.1 lab' >> /etc/hosts

case "${1:-}" in
  up)
    id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
    apt-get install -y -qq openjdk-17-jre-headless python3 >/dev/null
    update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
    mkdir -p "$CACHE"
    [ -f "$CACHE/$TGZ" ] || curl -sS -o "$CACHE/$TGZ" "https://downloads.apache.org/spark/spark-4.1.3/$TGZ"
    if [ ! -d /home/ana/spark ]; then
      cp "$CACHE/$TGZ" /home/ana/ && chown ana:ana /home/ana/$TGZ
      # the install block of the-lab.md, as the student types it, without the download
      as_ana "cd ~ && $(fence "$L1/the-lab.md" 2 | grep -v '^curl ')"
      as_ana "$(fence "$L1/the-cluster.md" 1)"
    fi ;;
  wipe)
    as_ana 'stop-worker.sh; stop-master.sh' >/dev/null 2>&1 || true
    rm -rf /home/ana/spark /home/ana/spark-4.1.3-bin-hadoop3 /home/ana/$TGZ* /home/ana/.sparkrc \
      /home/ana/spark-events
    sed -i '/\.sparkrc/d' /home/ana/.bashrc ;;
  start)
    as_ana 'start-master.sh && start-worker.sh spark://localhost:7077' >/dev/null
    for _ in $(seq 30); do
      n=$(curl -s http://localhost:8080/json/ | grep -c '"state" : "ALIVE"' || true)
      [ "$n" = 3 ] && exit 0; sleep 1
    done; echo 'workers did not come up' >&2; exit 1 ;;
  stop)
    as_ana 'stop-worker.sh; stop-master.sh' >/dev/null 2>&1 || true ;;
  data)
    as_ana '[ -f data/raw/clicks/_SUCCESS ] || spark-submit generate.py >/dev/null 2>&1' ;;
  exec) as_ana "$2" ;;
  extract) extract "$2" "$3" ;;
  fence) fence "$2" "$3" ;;
  *) sed -n '2,40p' "$0"; exit 2 ;;
esac
