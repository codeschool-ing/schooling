#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It builds ~/triage under its own HOME with `lab.sh files 1`, which writes
# every file this lesson tells the student to save, read out of the lesson's
# own fences, and prints each command after a prompt, ana@lab:~/triage$,
# followed by what it printed. `pl` is the alias the-harness.md defines.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, 4 cores and 15 GB of memory, captured on 2026-10-07. Temperature 0
# and seed 1, which the harness sets by default, make a rerun on this machine
# print the same replies; a different machine or Ollama version may not, and
# the lesson says so.
#
# STAGED: the block `down` stops the Ollama server and starts it again
# afterwards; `elsewhere` starts it under another HOME, where it finds no
# model; and `nomodel` removes llama3.2:1b first so that asking for it
# fails the way a model nobody pulled does. The zstd failure in
# when-setup-fails.md is NOT produced here: it is the first install on this
# machine, copied from the terminal, and reproducing it needs a machine
# without zstd.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat COLUMNS=100 PYTHONDONTWRITEBYTECODE=1 TERM=dumb
REAL_HOME=$HOME
export HOME=${LAB_HOME:-/var/tmp/prompt-reliability}
rm -rf "$HOME/triage"
mkdir -p "$HOME/bin" "$HOME/triage/runs"
bash "$here/../../lab.sh" check
bash "$here/../../lab.sh" files 1 2>/dev/null
ln -sf /usr/bin/python3.12 "$HOME/bin/python3"
printf '#!/bin/sh\nexec python3 "$HOME/triage/pl.py" "$@"\n' > "$HOME/bin/pl"
chmod +x "$HOME/bin/pl"
export PATH=$HOME/bin:$PATH
cd "$HOME/triage"
on() { printf 'ana@lab:~/triage$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
# The server keeps its models under the HOME it was started with, so it is
# started with the real one; `elsewhere` starts it with this script's HOME on
# purpose, which is the failure when-setup-fails.md shows.
serve() {
  for p in $(pgrep -x ollama); do kill "$p"; done
  sleep 2
  if [ "${1:-}" != down ]; then
    local h=$REAL_HOME
    [ "$1" = elsewhere ] && h=$HOME
    (HOME=$h nohup ollama serve >/dev/null 2>&1 &)
    until curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; do sleep 1; done
  fi
}

ollama rm llama3.2:1b >/dev/null 2>&1

block versions
on 'python3 --version'
on 'ollama --version'
on 'ollama list'
on 'du -sh /usr/local/lib/ollama'

block layout
on 'ls'
on 'wc -l cases/dev.jsonl'
on 'pl render prompts/v1-bare.txt --cases cases/dev.jsonl --case t01'

block down
serve down
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
serve up

block elsewhere
serve elsewhere
on 'ollama list'
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
serve up
rm -rf "$HOME/.ollama"

block nomodel
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl --set model=llama3.2:1b'
ollama pull llama3.2:1b >/dev/null 2>&1
on 'ollama list'

block bare
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
on 'ollama ps'
on 'pl show runs/v1.jsonl t01'
on 'pl show runs/v1.jsonl t02'
on 'pl check runs/v1.jsonl'

block json
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl check runs/v2.jsonl --failures'
on 'pl show runs/v2.jsonl t38'

block examples
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl'
on 'pl check runs/v3.jsonl --failures'
on 'pl compare runs/v2.jsonl runs/v3.jsonl'

block choose
on 'pl show runs/v2.jsonl t01'
on 'pl show runs/v3.jsonl t01'
on 'pl show runs/v2.jsonl t22'
on 'pl show runs/v3.jsonl t22'

block leak
on 'grep -n order prompts/v3-leaky.txt'
on 'pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl'
on 'pl check runs/leaky.jsonl --failures'
on 'grep -c 4471 runs/leaky.jsonl'
on 'pl show runs/leaky.jsonl t16'

block small
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3-1b.jsonl --set model=llama3.2:1b'
on 'ollama ps'
on 'pl check runs/v3-1b.jsonl'
