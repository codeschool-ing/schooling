#!/usr/bin/env bash
# The machine every transcript in this course was recorded on.
#
# IT IS THE STUDENT'S OWN SETUP, RUN BY A SCRIPT. ana is a developer with a
# small Python project, ~/shop, and the lessons are what she types at it. What
# she installed is what lesson 1 tells the student to install, and this file
# does not keep a copy of it: the steps are read out of lesson 1's fences with
# lab/fences.py and run as written, so the lesson and the lab cannot drift
# apart. The same goes for ~/shop, which is built by the script lesson 1 shows
# whole.
#
#   /home/ana/aidev      Python 3.12 in a virtual environment, with the SDKs
#                        the lessons import, and the four variables lesson 1
#                        appends to its activate script
#   /home/ana/shop       the project, as lesson 1 builds it
#   127.0.0.1:11434      Ollama, serving llama3.2:3b (and llama3.2:1b, the
#                        smaller model lesson 1 names for a weaker computer)
#
# WHAT THIS MACHINE HAS THAT A STUDENT'S DOES NOT, AND THE OTHER WAY ROUND.
#
#   No systemd. The recording machine is a container, so the Ollama installer
#   cannot register its service, and this file starts `ollama serve` itself.
#   Lesson 1's section on a failing setup shows the message that leaves, and
#   the same fix.
#
#   No GPU. Every timing in the course is a CPU's: 4 cores, 15 GB of memory.
#
#   Two hosts refused. The network the course was recorded on refuses
#   openaipublic.blob.core.windows.net (where tiktoken downloads its encodings
#   on first use) and huggingface.co (where WordLlama downloads its tokenizer).
#   A student's machine reaches both; this one rebuilds the two files where
#   the first download would have put them:
#
#     o200k_base   the npm package js-tiktoken ships the same table in its own
#     cl100k_base  format, and build_tokenizer writes it back out. tiktoken
#                  checks the file against the SHA-256 it ships with, so a
#                  reconstruction off by one byte is refused rather than used.
#     WordLlama    the pip package carries its tokenizer config and looks for
#                  it in ~/.cache/wordllama, where it is copied.
#
#   Lesson 1's failure section shows the message a refused host produces,
#   recorded on this machine before the rebuild.
#
#   sudo bash lab.sh up              build it (installs Ollama and pulls the models)
#   sudo bash lab.sh reset           rebuild ~/shop and make sure Ollama answers
#   sudo bash lab.sh purge           remove Ollama, its models, ana and her files
#   sudo bash lab.sh STEP            one step of up, for lesson 1's capture
#   sudo bash lab.sh exec USER 'command'
#                                    in ~/shop with the environment active;
#                                    IN_HOME=1 runs it in ~, BARE=1 without
#                                    the environment, as a new terminal would
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1=$HERE/lessons/le-qwbpg736
FENCES="python3 $HERE/lab/fences.py"
TZ_LAB=America/Sao_Paulo
JSLIBS="js-tiktoken@1.0.21"
NODEDIR=/opt/aidev-capture/node
# The recording machine's python3 is 3.13 and Ubuntu 24.04's is 3.12, so ana
# finds a python3 that is 3.12 before the system's.
SHIM=/opt/aidev-capture/bin
ANA_PATH=$SHIM:/usr/local/bin:/usr/bin:/bin
# The recording network re-signs TLS with its own authority, whose bundle sits
# in root's home; ana gets a copy she can read. A student's machine has none.
CA=/opt/aidev-capture/ca-bundle.crt

# The first line of each fence of lesson 1 this file runs. Each must start
# exactly one fence, or fences.py refuses.
INSTALL_FIRST='sudo apt update'
OLLAMA_FIRST='curl -fsSL https://ollama.com/install.sh -o install-ollama.sh'
VENV_FIRST='python3 -m venv ~/aidev'
ENV_FIRST="cat >> ~/aidev/bin/activate <<'EOF'"

build_user() {
  mkdir -p $SHIM && ln -sf /usr/bin/python3.12 $SHIM/python3
  if [ -n "${SSL_CERT_FILE:-}" ]; then cp "$SSL_CERT_FILE" $CA; fi
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # The proxy variables survive sudo because the recording network needs them;
  # a student's machine has nothing to keep.
  printf '%s\n' 'ana ALL=(ALL) NOPASSWD: ALL' \
    'Defaults:ana env_keep += "https_proxy HTTPS_PROXY no_proxy NO_PROXY SSL_CERT_FILE REQUESTS_CA_BUNDLE"' \
    > /etc/sudoers.d/ana
  chmod 0440 /etc/sudoers.d/ana
}

as_ana() {  # as_ana DIR: run stdin as ana's login-less bash, in DIR
  local dir=$1
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana TZ=$TZ_LAB \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=$ANA_PATH \
    HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${https_proxy:-}" \
    NO_PROXY="${NO_PROXY:-}" no_proxy="${no_proxy:-}" \
    SSL_CERT_FILE="${SSL_CERT_FILE:+$CA}" REQUESTS_CA_BUNDLE="${REQUESTS_CA_BUNDLE:+$CA}" \
    PYTHONDONTWRITEBYTECODE=1 bash -c "cd $dir && exec bash -e -s"
}

# Lesson 1's steps, as the student types them, in three parts so that lesson
# 1's capture can stop between them and record what fails.
install_ollama() {
  { $FENCES block "$L1/installing.md" "$INSTALL_FIRST"
    $FENCES block "$L1/installing.md" "$OLLAMA_FIRST"
  } | as_ana /home/ana
}
install_models() {
  serve
  $FENCES block "$L1/installing.md" 'ollama pull llama3.2:3b' | as_ana /home/ana
}
pull_small() {
  serve
  $FENCES block "$L1/your-machine.md" 'ollama pull llama3.2:1b' | as_ana /home/ana
}
install_python() {
  { $FENCES block "$L1/installing.md" "$VENV_FIRST"
    $FENCES block "$L1/installing.md" "$ENV_FIRST"
  } | as_ana /home/ana
}

# The container has no systemd, so nothing started the service the installer
# registered. This starts the same program as the same user the service would,
# with the service's home, which is where the models are kept. Lesson 1's
# failure section gives the student `ollama serve` in a terminal of its own,
# which is the same thing in the foreground.
serve() {
  curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
  setsid nohup runuser -u ollama -- env HOME=/usr/share/ollama \
    HTTPS_PROXY="${HTTPS_PROXY:-}" NO_PROXY="${NO_PROXY:-}" SSL_CERT_FILE="${SSL_CERT_FILE:+$CA}" \
    /usr/local/bin/ollama serve > /var/log/ollama-capture.log 2>&1 < /dev/null &
  for _ in $(seq 100); do
    curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
    sleep 0.2
  done
  echo "ollama did not start; see /var/log/ollama-capture.log" >&2; return 1
}

build_tokenizer() {
  local cache=/home/ana/.cache/tiktoken
  mkdir -p $NODEDIR "$cache"
  ( cd $NODEDIR && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent $JSLIBS )
  ( cd $NODEDIR && node -e '
    const fs = require("fs"), crypto = require("crypto");
    for (const n of ["o200k_base", "cl100k_base"]) {
      const r = require("js-tiktoken/ranks/" + n), rows = [];
      for (const line of r.bpe_ranks.split("\n").filter(Boolean)) {
        const [, offset, ...tokens] = line.split(" ");
        tokens.forEach((t, i) => rows.push([parseInt(offset, 10) + i, t]));
      }
      rows.sort((a, b) => a[0] - b[0]);
      const url = "https://openaipublic.blob.core.windows.net/encodings/" + n + ".tiktoken";
      const name = crypto.createHash("sha1").update(url).digest("hex");
      fs.writeFileSync(process.argv[1] + "/" + name, rows.map(([k, t]) => t + " " + k).join("\n") + "\n");
    }' "$cache" )
  chown -R ana:ana /home/ana/.cache
  # tiktoken looks in $TIKTOKEN_CACHE_DIR, then a temporary directory; ana's
  # activate script points it at the rebuilt files. This line is the check that
  # the reconstruction is exact: tiktoken refuses a file whose hash is wrong.
  grep -q TIKTOKEN_CACHE_DIR /home/ana/aidev/bin/activate ||
    echo "export TIKTOKEN_CACHE_DIR=$cache  # the capture machine's, see lab.sh" >> /home/ana/aidev/bin/activate
  as_ana /home/ana <<'SH'
source ~/aidev/bin/activate
python -c 'import tiktoken; [tiktoken.get_encoding(n) for n in ("o200k_base", "cl100k_base")]'
SH
}

build_embeddings() {
  as_ana /home/ana <<'SH'
source ~/aidev/bin/activate
pkg=$(python -c 'import wordllama, os; print(os.path.dirname(wordllama.__file__))')
mkdir -p ~/.cache/wordllama/tokenizers
cp "$pkg/tokenizers/l2_supercat_tokenizer_config.json" ~/.cache/wordllama/tokenizers/
SH
}

# The project, as lesson 1 builds it: the script it shows, run as it says.
build_shop() {
  rm -rf /home/ana/shop /home/ana/make-shop.sh
  $FENCES block "$L1/the-project.md" '# make-shop.sh DIR: the shop project as the course starts it' \
    > /home/ana/make-shop.sh
  chown ana:ana /home/ana/make-shop.sh
  echo 'bash make-shop.sh ~/shop' | as_ana /home/ana
}

purge() {
  pkill -f 'ollama serve' 2>/dev/null || true
  sleep 1
  rm -rf /usr/local/bin/ollama /usr/local/lib/ollama /usr/share/ollama /root/.ollama \
    /etc/systemd/system/ollama.service
  id ollama >/dev/null 2>&1 && userdel ollama 2>/dev/null || true
  getent group ollama >/dev/null && groupdel ollama 2>/dev/null || true
  id ana >/dev/null 2>&1 && userdel -r ana 2>/dev/null || true
  rm -f /etc/sudoers.d/ana
}

exec_as() {  # exec_as USER COMMAND: in ~/shop, with the activated environment
  local u=$1; shift
  local dir=/home/$u/shop act="source ~/aidev/bin/activate 2>/dev/null || true"
  [ -d "$dir" ] || dir=/home/$u
  [ -n "${IN_HOME:-}" ] && dir=/home/$u
  [ -n "${BARE:-}" ] && act=":"
  runuser -u "$u" -- env -i HOME=/home/$u USER="$u" LOGNAME="$u" TZ=$TZ_LAB \
      LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=$ANA_PATH \
      HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${https_proxy:-}" \
      NO_PROXY="${NO_PROXY:-}" no_proxy="${no_proxy:-}" \
      SSL_CERT_FILE="${SSL_CERT_FILE:+$CA}" REQUESTS_CA_BUNDLE="${REQUESTS_CA_BUNDLE:+$CA}" \
      PYTHONDONTWRITEBYTECODE=1 bash -c "cd $dir && $act
$*"
}

case ${1:-} in
  up)
    build_user; install_ollama; install_models; pull_small; install_python
    build_tokenizer; build_embeddings; build_shop ;;
  user|install_ollama|install_models|pull_small|install_python|build_tokenizer|build_embeddings|build_shop)
    [ "$1" = user ] && build_user || "$1" ;;
  reset)
    serve; build_shop ;;
  serve)
    serve ;;
  purge)
    purge ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: $0 up|reset|serve|purge|exec USER COMMAND" >&2; exit 2 ;;
esac
