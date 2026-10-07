#!/usr/bin/env bash
# The machine every transcript in prompt-engineering was recorded on, built the
# way lesson 1 teaches a student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE. Lesson 1 gives them the commands (section
# `your-machine`) and the workbench (section `the-workbench`), and each program
# in ~/pe/bin is printed whole in the lesson that first uses it. This script
# runs those same commands, and it does NOT keep its own copy of any program
# or data file: it reads them out of the lessons' own fences, so the program
# a transcript ran is the program the student saves. A fence that goes missing
# or turns into two fails the build here rather than drifting.
#
# ONE LINUX COMPUTER, ONE PERSON, ONE DIRECTORY. ana works in ~/pe:
#
#   bin/ask       a client for a language model's chat-completions API; with
#                 nothing set it asks llama3.2:3b, served by Ollama on the
#                 same machine                               (lesson 1)
#   bin/toylm     a trigram model of corpus.txt, with the sampling controls
#                 a model API has                            (lesson 1)
#   bin/tok       the o200k_base and cl100k_base tokenizers   (lesson 3)
#   bin/retrieve  BM25 over handbook/                         (lesson 5)
#   bin/agent     the loop that runs tools for a model        (lesson 6)
#   bin/validate  JSON Schema validation                      (lesson 15)
#   bin/repair    recovering an object from a wrapped reply   (lesson 19)
#   bin/vote      majority voting over sampled answers        (lesson 27)
#   bin/tot       the Game of 24 as a tree of thoughts        (lesson 28)
#   bin/ape       scoring prompt templates                    (lesson 31)
#   corpus.txt    (lesson 1), handbook/ (lesson 4), reviews/ (lesson 7)
#
#   sudo bash lab.sh tools           once: Ubuntu's packages, Ollama, the model,
#                                    the user ana, ~/pe with its two libraries
#   sudo bash lab.sh reset           ~/pe's files made afresh from the lessons;
#                                    the libraries are kept
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/pe, the way the
#                                    transcripts were recorded
#
# THE MODEL. llama3.2:3b (digest a80c4f17acd5), served by Ollama 0.40.0 on the
# CPU of a 4-core machine with 16 GB of memory and no graphics card. Every
# capture of a model's reply was taken on 7 October 2026, and each lesson's
# captures.sh says which of its blocks are a model's.
#
# Recorded on Ubuntu 24.04 with Ubuntu's own Python 3.12 and Node.js 18.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The model server
# started here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L=$HERE/lessons
PE=/home/ana/pe
MODEL=llama3.2:3b

# Where each program and each data file is printed, by name.
PROGRAMS="
ask       le-n8c2w2rc/the-workbench.md
toylm     le-n8c2w2rc/the-workbench.md
tok       le-6r9rh3fv/pieces.md
retrieve  le-jqavjkbj/reducing-it.md
agent     le-zhr50zec/tool-calls.md
validate  le-ex820q0d/the-limit.md
repair    le-5kva9pc6/repair.md
vote      le-n26va6ac/sample-and-vote.md
tot       le-2jht1krj/search-not-a-line.md
ape       le-fps5k0kg/generate-and-score.md
"
DATA="
le-n8c2w2rc/the-workbench.md
le-5xxmsmkr/strategies.md
le-zhr50zec/tool-calls.md
le-fmghh3as/what-it-is.md
"

# Ubuntu 24.04's python3 is 3.12. The machine this was recorded on had a 3.13
# installed as an alternative and a Node 22 on its PATH, so both are pointed
# back at the stock ones, which are what a student's fresh machine has.
STOCK=/usr/local/lib/pe-stock
stock() {
  mkdir -p $STOCK && ln -sfn /usr/bin/python3.12 $STOCK/python3
  for n in node npm npx; do ln -sfn /usr/bin/$n $STOCK/$n; done
}

# The one fence in FILE that is the program NAME: its second line opens with
# """NAME (Python) or // NAME (JavaScript), followed by a space or a colon.
program() {
  python3 - "$L/$2" "$1" <<'PY'
import re, sys
text, name = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
fences = re.findall(r"^```[^\n]*\n(.*?)^```$", text, re.S | re.M)
found = [f for f in fences if re.match(r'#!.*\n("""|// )' + re.escape(name) + r"[ :]", f)]
if len(found) != 1:
    sys.exit("%s has %d fences that are the program %s, and lab.sh needs one" % (sys.argv[1], len(found), name))
sys.stdout.write(found[0])
PY
}

# Every fence in FILE that writes a file under ~/pe with a here-document: the
# commands the student pastes, run exactly as printed.
data() {
  python3 - "$L/$1" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
fences = re.findall(r"^```sh\n(.*?)^```$", text, re.S | re.M)
found = [f for f in fences if re.search(r"^cat > ~/pe/\S+ <<'EOF'$", f, re.M)]
if not found:
    sys.exit("%s has no fence that writes a file under ~/pe" % sys.argv[1])
sys.stdout.write("".join(found))
PY
}

as_ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash TERM=dumb \
    LC_ALL=C.UTF-8 COLUMNS=100 TZ=America/Sao_Paulo \
    PATH=$STOCK:/usr/local/bin:/usr/bin:/bin \
    bash -c 'eval "$(sed -n "/^# prompt-engineering$/,\$p" ~/.bashrc)"; '"$1"
}

# In a machine with systemd the installer leaves a service running. This one
# has none, so the server is started by hand, the way lesson 1's failure
# section starts it.
serve() {
  curl -fsS http://127.0.0.1:11434/api/version >/dev/null 2>&1 && return
  (nohup ollama serve >/var/tmp/pe-ollama.log 2>&1 &)
  for _ in $(seq 30); do
    curl -fsS http://127.0.0.1:11434/api/version >/dev/null 2>&1 && return
    sleep 1
  done
  echo "ollama serve did not start; see /var/tmp/pe-ollama.log" >&2; exit 1
}

tools() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q python3-venv nodejs npm curl zstd >/dev/null
  command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
  serve
  ollama pull $MODEL >/dev/null
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  stock
  grep -q '^# prompt-engineering$' /home/ana/.bashrc || cat >> /home/ana/.bashrc <<'EOF'
# prompt-engineering
export PATH="$HOME/pe/bin:$HOME/pe/.venv/bin:$PATH"
EOF
  # The machine this ran on reaches PyPI and npm through a proxy; a student's
  # does not need one, so the variables are passed to this step and no other.
  # Its CA bundle lives under /root, which ana cannot read, so a copy is made.
  local ca=""
  if [ -n "${SSL_CERT_FILE:-}" ]; then ca=/var/tmp/pe-ca.crt; cp "$SSL_CERT_FILE" $ca; chmod 644 $ca; fi
  local net="HTTPS_PROXY=${HTTPS_PROXY:-} https_proxy=${https_proxy:-} NO_PROXY=${NO_PROXY:-}"
  net="$net SSL_CERT_FILE=$ca PIP_CERT=$ca NODE_EXTRA_CA_CERTS=$ca npm_config_cafile=$ca"
  net="$net npm_config_https_proxy=${npm_config_https_proxy:-}"
  as_ana "export $net; mkdir -p ~/pe/bin && cd ~/pe && python3 -m venv .venv &&
    .venv/bin/pip install -q jsonschema==4.26.0 &&
    npm install --no-audit --no-fund gpt-tokenizer@4.0.0 >/dev/null"
  echo "tools ready; ~/pe has its libraries"
}

reset() {
  [ -d $PE/node_modules ] || { echo "run: bash $0 tools" >&2; exit 1; }
  serve
  # Everything but the two libraries goes, then the lessons' files come back.
  find $PE -mindepth 1 -maxdepth 1 ! -name .venv ! -name node_modules ! -name package.json \
    ! -name package-lock.json -exec rm -rf {} +
  mkdir -p $PE/bin
  # A here-string, not a pipe: a fence that cannot be found stops the reset
  # instead of leaving an empty program behind.
  while read -r name file; do
    [ -n "$name" ] || continue
    program "$name" "$file" > $PE/bin/$name
  done <<< "$PROGRAMS"
  chmod +x $PE/bin/*
  chown -R ana:ana $PE
  while read -r file; do
    [ -n "$file" ] || continue
    as_ana "$(data "$file")"
  done <<< "$DATA"
  echo "workbench ready in $PE"
}

case "${1:-}" in
tools) tools ;;
reset) reset ;;
exec)
  shift
  as_ana "cd ~/pe && $1" ;;
*)
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//' | head -n -1; exit 2 ;;
esac
