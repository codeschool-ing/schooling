#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME, so nothing of yours
# is touched (/home/ana, so that a path in a message reads as a student's
# would). lab.sh builds it from the fences of the lessons themselves, so
# surface.py, ask.py, bin/guard and data/surface.json are exactly what this
# lesson prints. It prints each command after a prompt, ana@lab:~$ or
# ana@lab:~/guard$, followed by what it printed.
#
# THE MODEL: llama3.2:3b (a80c4f17acd5), served by Ollama 0.40.0, captured on
# 2026-10-07 on a machine with no graphics card. It needs `ollama serve`
# running with that model pulled, and llama3.2:1b removed, so that `ollama
# list` shows what a student following the lesson has. The "nothing answers"
# block stops the server and starts it again (this machine has no systemd;
# OLLAMA_OWNER_HOME is the home whose ~/.ollama holds the models).
#
# NOT CAPTURED HERE: the installer's zstd error in when-it-fails.md, which is
# the installer's own output from the first time this course was set up, on
# this machine, copied from its log.
#
# Recorded with Python 3.12.3 (Ubuntu 24.04's), TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
owner=${OLLAMA_OWNER_HOME:-$HOME}
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/home/ana}
mkdir -p "$HOME/.py"
ln -sf "$(command -v python3.12)" "$HOME/.py/python3"
export PATH=$HOME/.py:$PATH
GUARD_HOME=$HOME bash "$here/../../lab.sh" reset >/dev/null || exit 1
base=$PATH
export PATH=$HOME/guard/bin:$base
at() { printf 'ana@lab:%s$ %s\n' "$1" "$2"; bash -c "$2" 2>&1; }
on() { cd "$HOME/guard" && at '~/guard' "$*"; }
home() { cd "$HOME" && at '~' "$*"; }
block() { printf '##### %s\n' "$1"; }
serving() { curl -s localhost:11434/ >/dev/null; }

block setup
home 'python3 --version; ollama --version'
home 'ollama list'
printf 'ana@lab:~$ %s\n' 'ollama run llama3.2:3b "Say hello in five words."'
ollama run llama3.2:3b "Say hello in five words." </dev/null 2>/dev/null | sed "s/\x1b\[[0-9;?]*[a-zA-Z]//g"
home 'ollama ps'

block ask
on 'guard ask "Say hello in five words."'
on 'guard ask "Say hello in five words."'
on 'guard ask "Say hello in five words." --temperature 0.8 --seed 3'
on 'guard ask "Say hello in five words." --temperature 0.8 --seed 4'

block inventory
on 'head -3 data/surface.json'
on 'guard surface'

block gaps
on 'guard surface --gaps'

block down
pkill -x ollama; while serving; do sleep 1; done
home 'ollama list'
on 'guard ask "Say hello in five words."'
(HOME=$owner nohup ollama serve >/dev/null 2>&1 &)
until serving; do sleep 1; done
home 'ollama list'

block typo
on 'ASK_MODEL=lama3.2:3b guard ask "Say hello in five words."'

block guard
export PATH=$base
on 'guard surface'
export PATH=$HOME/guard/bin:$base
chmod -x "$HOME/guard/bin/guard"
on 'guard surface'
chmod +x "$HOME/guard/bin/guard"
on 'guard sufrace'
