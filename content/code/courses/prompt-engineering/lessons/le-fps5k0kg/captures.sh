#!/usr/bin/env bash
# The terminal sessions quoted in lesson 31 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged with put, and shown in the lesson with cat: the meta-prompt, five
# candidate templates, the four test examples, the three held-out ones, and
# best.txt. ape is read out of generate-and-score.md.
#
# THE MODEL'S REPLIES in meta (sampled at 0.8, seeds 1 to 5) and in ape-ask
# (temperature 0, through ape) are llama3.2:3b served by Ollama 0.40.0,
# captured on 7 October 2026.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/pe, and what it printed.
on() { printf 'ana@lab:~/pe$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/pe, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/pe from nothing.
exec 9>/var/tmp/pe-capture.lock; flock 9
lab reset >/dev/null

put candidates.txt <<'T'
Describe the {x} in one word:
question : what is the {x} like ? answer :
{x}
it is a cold day and the {x} is
the {x} is
T
printf 'coffee\thot\ntea\thot\nbread\tfresh\nterrace\topen\n' | put tests.tsv
printf 'café\tfull\nsoup\ttomato\ncake\tgone\n' | put held.tsv
put prompts/meta.txt <<'T'
I gave a friend an instruction and four inputs. The friend read the
instruction and wrote one output for each input. Here are the pairs:

Input: coffee     Output: hot
Input: tea        Output: hot
Input: bread      Output: fresh
Input: terrace    Output: open

What was the instruction? Reply with the instruction alone, in one line.
T
put best.txt <<'T'
the {x} is
T

block meta
on 'cat prompts/meta.txt'
on 'ask - --temperature 0.8 --seed 1 --samples 5 --max-tokens 40 < prompts/meta.txt'
block generate-and-score
on 'cat candidates.txt'
on 'cat tests.tsv'
on 'ape candidates.txt tests.tsv'
on 'toylm next "describe the coffee in one word :"'
block ape-ask
on 'ape candidates.txt tests.tsv --ask'

block keeping-it-honest
on 'cat held.tsv'
on 'ape best.txt held.tsv'
