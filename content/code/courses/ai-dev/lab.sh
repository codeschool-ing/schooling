#!/usr/bin/env bash
# The machine every transcript in this course was recorded on.
#
# IT IS ONE LINUX COMPUTER AND ONE PERSON. ana is a developer with a small
# Python project, ~/shop, and the lessons are what she types at it. There is no
# network to build here, unlike the networks courses: what this course needs
# that a laptop does not have is a model provider, and that is the part below
# worth reading.
#
#   /home/ana/shop       the project: a shop's cart and pricing, with tests,
#                        in git, and the support handbook lesson 6 searches
#   /opt/aidev           Python 3.11 in a virtual environment, with the
#                        providers' SDKs and everything the lessons import
#   127.0.0.1:8400       labllm, the stand-in provider (lab/labllm.py)
#   /opt/aidev/bin/assist  an editor assistant small enough to read (lab/assist.py)
#   /var/log/labllm      every request labllm received, one JSON line each
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE. No model API was reachable
# from the machine this was recorded on, and an API key is a bill that a
# course cannot hand out. So:
#
#   real       the three providers' Python SDKs (anthropic, openai,
#              google-genai), the MCP SDK, tiktoken with OpenAI's o200k_base
#              encoding, WordLlama's embedding model, numpy, pytest and
#              hypothesis. Their versions are pinned in PYLIBS.
#   the lab's  labllm, which speaks the wire format of the Anthropic, OpenAI
#              and Gemini APIs closely enough that the SDKs talk to it
#              unmodified, and serves two models that are not language
#              models at all:
#                tiny-1      tinylm (lab/tinylm.py): a table of which token
#                            followed which, counted over the docstrings of
#                            fifty modules of Python's standard library. It
#                            generates for real, and what it writes is real
#                            output of a very small model.
#                scripted-1  replies WRITTEN BY THE COURSE, in
#                            lab/scripted.json, chosen by simple rules. It is
#                            there so the code AROUND a model can run: the
#                            tool loop, validation, retrieval, streaming.
#              Every lesson that shows a reply from scripted-1 says it was
#              written by the course.
#
# TWO THINGS ARE REBUILT RATHER THAN DOWNLOADED, because their usual source
# was out of reach (huggingface.co and openaipublic.blob.core.windows.net):
#
#   o200k_base   tiktoken downloads its encoding on first use. The npm package
#                js-tiktoken ships the same table in its own format, and
#                build_tokenizer writes it back out as a .tiktoken file.
#                tiktoken checks that file against the SHA-256 it ships with
#                (446a9538…2d), so a reconstruction that was off by one byte
#                would be refused rather than used.
#   WordLlama    the pip package carries its weights AND its tokenizer, but
#                looks for the tokenizer in a directory it does not install it
#                in, and then tries the network. build_embeddings copies it to
#                ~/.cache/wordllama, where the first download would have put it.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           restore ~/shop and restart labllm
#   sudo bash lab.sh down
#   sudo bash lab.sh exec USER 'command'
#
# Recorded on Ubuntu 24.04 with Python 3.11 and Node.js 22, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=/opt/aidev
SHARE=$VENV/share
NODEDIR=/opt/aidev/node
LOGDIR=/var/log/labllm
TZ_LAB=America/Sao_Paulo
PYLIBS="anthropic==1.11.0 openai==3.23.0 google-genai==2.27.0 mcp==2.2.0 numpy==2.4.6
  wordllama==0.4.0.post1 tiktoken==0.14.0 pytest==9.1.1 hypothesis==6.168.3 jsonschema==4.26.0"
JSLIBS="js-tiktoken@1.0.21"

# The environment every command of ana's runs in. The keys are the lab's and
# open nothing anywhere else; the base URLs are what point each SDK at labllm.
ENVFILE=/etc/aidev.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=$TZ_LAB
LANG=C.UTF-8
LC_ALL=C.UTF-8
TIKTOKEN_CACHE_DIR=$SHARE/tiktoken
ANTHROPIC_BASE_URL=http://127.0.0.1:8400
ANTHROPIC_API_KEY=lab-anthropic-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8400/v1
OPENAI_API_KEY=lab-openai-key-0001
GEMINI_BASE_URL=http://127.0.0.1:8400
GEMINI_API_KEY=lab-google-key-0001
PYTHONDONTWRITEBYTECODE=1
EOF
}

need() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  command -v npm >/dev/null || { echo "npm is required (Node.js 22)" >&2; exit 1; }
  command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $PYLIBS
  mkdir -p $SHARE
  install_lab
}

# The lab's own programs: the two that make up labllm, and assist (lesson 3).
install_lab() {
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/lab/tinylm.py" "$HERE/lab/labllm.py" "$site/"
  install -m 0755 "$HERE/lab/assist.py" $VENV/bin/assist
}

build_tokenizer() {
  mkdir -p $NODEDIR $SHARE/tiktoken
  ( cd $NODEDIR && [ -f package.json ] || npm init -y >/dev/null; npm install --silent $JSLIBS )
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
    }' $SHARE/tiktoken )
  # tiktoken refuses a file whose hash is not the one it ships with, so this
  # line is the check that the reconstruction is exact.
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $VENV/bin/python -c \
    'import tiktoken; [tiktoken.get_encoding(n) for n in ("o200k_base", "cl100k_base")]'
}

build_tinylm() {
  $VENV/bin/python "$HERE/lab/corpus.py" > $SHARE/corpus.txt
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $VENV/bin/python -c "
import tinylm
tinylm.TinyLM.train(open('$SHARE/corpus.txt').read()).save('$SHARE/tiny.json')"
  install -m 0644 "$HERE/lab/scripted.json" $SHARE/scripted.json
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  id labllm >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin labllm
  mkdir -p $LOGDIR && chown labllm:labllm $LOGDIR && chmod 0755 $LOGDIR
}

build_embeddings() {
  local pkg
  pkg=$($VENV/bin/python -c 'import wordllama, os; print(os.path.dirname(wordllama.__file__))')
  runuser -u ana -- mkdir -p /home/ana/.cache/wordllama/tokenizers
  install -o ana -m 0644 "$pkg/tokenizers/l2_supercat_tokenizer_config.json" \
    /home/ana/.cache/wordllama/tokenizers/
}

# The project, as it stands before lesson 1: five commits, dated, by ana.
build_shop() {
  rm -rf /home/ana/shop
  runuser -u ana -- bash "$HERE/lab/shop.sh" /home/ana/shop
}

start_llm() {
  stop_llm
  : > $LOGDIR/requests.jsonl; chown labllm:labllm $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  install -m 0644 "$HERE/lab/scripted.json" $SHARE/scripted.json
  setsid runuser -u labllm -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=$TZ_LAB \
    TIKTOKEN_CACHE_DIR=$SHARE/tiktoken LABLLM_SHARE=$SHARE LABLLM_LOG=$LOGDIR \
    $VENV/bin/python -m labllm > /run/labllm.out 2>&1 < /dev/null &
  echo $! > /run/labllm.pid
  for _ in $(seq 50); do
    curl -s -o /dev/null http://127.0.0.1:8400/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "labllm did not start; see /run/labllm.out" >&2; return 1
}

stop_llm() {
  if [ -f /run/labllm.pid ]; then
    kill "$(cat /run/labllm.pid)" 2>/dev/null || true
    rm -f /run/labllm.pid
    sleep 0.3
  fi
}

exec_as() {  # exec_as USER COMMAND: in ~/shop, with the lab's environment and nothing else
  local u=$1; shift
  local dir=/home/$u/shop
  [ -d "$dir" ] || dir=/home/$u
  # shellcheck disable=SC2046
  runuser -u "$u" -- env -i HOME=/home/$u USER="$u" $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $dir && $*"
}

case ${1:-} in
  up)
    need; build_user; write_env; build_venv; build_tokenizer; build_tinylm
    build_embeddings; build_shop; start_llm ;;
  reset)
    write_env; install_lab; build_tinylm; build_shop; start_llm ;;
  down)
    stop_llm ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: $0 up|reset|down|exec USER COMMAND" >&2; exit 2 ;;
esac
