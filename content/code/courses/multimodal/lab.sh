#!/usr/bin/env bash
# The machine every transcript in multimodal was recorded on, built the way
# lesson 1 tells the student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE. It is how this repository proves a capture
# was run (C-38, C-40). Everything the student does is READ OUT OF THE LESSONS
# by lab/shown.py and run as written, so a lesson and its capture cannot drift:
#
#   lesson 1, the-lab.md      setup.sh: packages, /opt/multimodal, the models, Ollama
#   lesson 1, the-media.md    mmlab.py and make_media.py, which make ~/mm/media
#   lesson 3, one-axis-...md  images_server.py, the course's stand-in image API
#   lesson 10, the-trans...md audio_server.py, Whisper behind OpenAI's audio routes
#
# ONE PERSON, ana, on one Ubuntu 24.04 machine called lab, working in ~/mm.
#
# What this file adds that the student does not do, and why:
#   - creates ana, with sudo, because setup.sh is run as an ordinary user;
#   - passes PIP_CERT through when the caller sets it: the machine this course
#     was recorded on reaches PyPI through a proxy with its own certificate;
#   - puts tiktoken's o200k_base where tiktoken looks for it, rebuilt from the
#     npm package js-tiktoken, because the machine could not reach the address
#     tiktoken downloads it from. tiktoken checks the file's SHA-256, so what
#     lesson 4 counts with is the same file a student's tiktoken downloads;
#   - starts `ollama serve` itself: the machine has no systemd;
#   - puts Ubuntu's own Python 3.12 first as `python3`, because this machine's
#     `python3` was pointed at a 3.13 that a stock Ubuntu 24.04 does not have.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           ~/mm from nothing: lesson 1's files, then its media
#   sudo bash lab.sh serve images|audio   start a stand-in from the lesson that shows it
#   sudo bash lab.sh down            stop the stand-ins
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/mm
#
# Recorded on Ubuntu 24.04 (Python 3.12, ffmpeg 6.1), four cores, no graphics
# card, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9; nothing started here may inherit it.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L=$HERE/lessons
WORK=/home/ana/mm
AUTHOR=/opt/mm-author
shown() { python3 "$HERE/lab/shown.py" get "$@"; }

declare -A SERVER=(
  [images]="$L/le-gtwzkpaq/one-axis-at-a-time.md images_server.py 8800"
  [audio]="$L/le-vvb22832/the-transcriptions-endpoint.md audio_server.py 8700"
)

as_ana() {  # COMMAND: as ana, in ~/mm, with what her ~/.bashrc adds and nothing else
  local env
  env=$(sed -n '/^# multimodal/,$p' /home/ana/.bashrc)
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana TZ=America/Sao_Paulo LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 PATH=/usr/local/bin:/usr/bin:/bin PYTHONDONTWRITEBYTECODE=1 \
    TIKTOKEN_CACHE_DIR=$AUTHOR/tiktoken \
    bash -c "$env
cd $WORK || exit 1
$*"
}

ollama_up() {
  curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
  setsid runuser -u ana -- env HOME=/home/ana nohup ollama serve >/var/log/mm-ollama.log 2>&1 </dev/null &
  for _ in $(seq 50); do curl -s -o /dev/null http://127.0.0.1:11434/ && return 0; sleep 0.2; done
  echo "ollama did not start; see /var/log/mm-ollama.log" >&2; return 1
}

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  echo "ana ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/ana
  command -v ollama >/dev/null && ollama_up
  shown "$L/le-m9r3jaaa/the-lab.md" setup.sh >/tmp/mm-setup.sh
  local cert=
  if [ -n "${PIP_CERT:-}" ]; then  # a copy ana can read
    cert=/etc/ssl/mm-pip-ca.crt
    install -m 0644 "$PIP_CERT" $cert
  fi
  install -d $AUTHOR/bin && ln -sf /usr/bin/python3.12 $AUTHOR/bin/python3
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana PATH=$AUTHOR/bin:/usr/local/bin:/usr/bin:/bin \
    LANG=C.UTF-8 ${HTTPS_PROXY:+HTTPS_PROXY=$HTTPS_PROXY} ${NO_PROXY:+NO_PROXY=$NO_PROXY} \
    ${cert:+PIP_CERT=$cert} sh /tmp/mm-setup.sh
  ollama_up
  tokenizer
}

tokenizer() {  # o200k_base, under the name tiktoken looks for, from js-tiktoken
  local node=$AUTHOR/node
  [ -n "$(ls $AUTHOR/tiktoken 2>/dev/null)" ] && return 0
  mkdir -p $node $AUTHOR/tiktoken
  ( cd $node && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent js-tiktoken@1.0.21 )
  ( cd $node && node -e '
    const fs = require("fs"), crypto = require("crypto");
    const r = require("js-tiktoken/ranks/o200k_base"), rows = [];
    for (const line of r.bpe_ranks.split("\n").filter(Boolean)) {
      const [, offset, ...tokens] = line.split(" ");
      tokens.forEach((t, i) => rows.push([parseInt(offset, 10) + i, t]));
    }
    rows.sort((a, b) => a[0] - b[0]);
    const url = "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken";
    const name = crypto.createHash("sha1").update(url).digest("hex");
    fs.writeFileSync(process.argv[1] + "/" + name, rows.map(([k, t]) => t + " " + k).join("\n") + "\n");' $AUTHOR/tiktoken )
  chmod -R a+rX $AUTHOR
  TIKTOKEN_CACHE_DIR=$AUTHOR/tiktoken /opt/multimodal/bin/python -c 'import tiktoken; tiktoken.get_encoding("o200k_base")'
}

reset() {
  down
  ollama_up
  rm -rf $WORK
  install -d -o ana -g ana $WORK
  shown "$L/le-m9r3jaaa/the-media.md" mmlab.py >$WORK/mmlab.py
  shown "$L/le-m9r3jaaa/the-media.md" make_media.py >$WORK/make_media.py
  chown ana:ana $WORK/*.py
  as_ana "python make_media.py >/dev/null"
}

serve() {  # images|audio
  local md name port
  read -r md name port <<<"${SERVER[$1]}"
  shown "$md" "$name" >$WORK/$name && chown ana:ana $WORK/$name
  as_ana "setsid nohup python $name >/tmp/$name.log 2>&1 </dev/null &"
  for _ in $(seq 100); do curl -s -o /dev/null http://127.0.0.1:$port/ && return 0; sleep 0.2; done
  echo "$name did not start; see /tmp/$name.log" >&2; return 1
}

down() {
  pkill -u ana -f "python (images|audio)_server.py" 2>/dev/null || true
  sleep 0.3
}

case ${1:-} in
  up) up ;;
  reset) reset ;;
  serve) serve "$2" ;;
  down) down ;;
  exec) shift; as_ana "$@" ;;
  *) echo "usage: sudo bash lab.sh up|reset|serve images|audio|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
