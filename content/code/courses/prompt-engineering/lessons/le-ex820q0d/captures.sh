#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged with put, and shown in the lesson with cat: review.schema.json (what a
# reply has to look like) and request.txt (the text of one request). reply.json
# and cut.json are the model's replies to it, the second cut by --max-tokens.
# validate is read out of the-limit.md.
#
# THE MODEL'S REPLIES in ask-json and save are llama3.2:3b served by Ollama
# 0.40.0, at temperature 0, captured on 7 October 2026.
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

put review.schema.json <<'PE_FILE'
{
  "type": "object",
  "required": ["sentiment", "topic", "summary"],
  "properties": {
    "sentiment": {"enum": ["positive", "neutral", "negative"]},
    "topic": {"type": "string"},
    "summary": {"type": "string"}
  }
}
PE_FILE
put request.txt <<'PE_FILE'
You read customer reviews of Café Aurora. For the review below, reply with
one JSON object with three fields: "sentiment" (positive, neutral or
negative), "topic" (two or three words) and "summary" (one sentence).
Reply with the object and nothing else.

Review:
Waited fifteen minutes for a tea at noon. The staff were kind about it.
PE_FILE

block the-limit
on 'toylm generate "the menu has" --temperature 0'
on 'toylm generate "the menu has" --temperature 0 --max-tokens 3'
on 'toylm generate "the cat" --temperature 0 --max-tokens 20'
block files
on 'cat request.txt review.schema.json'
block ask-json
on 'ask - --json --temperature 0 < request.txt'
on 'ask - --json --temperature 0 --max-tokens 20 < request.txt'
block save
on 'ask - --json --temperature 0 --plain < request.txt > reply.json'
on 'ask - --json --temperature 0 --max-tokens 20 --plain < request.txt > cut.json'
block validate
on 'validate review.schema.json reply.json'
on 'validate review.schema.json cut.json'

block cost-control
on 'cat request.txt'
on 'tok count request.txt'
on 'tok cost request.txt -o 40 -i 2 -p 8'
on 'tok cost request.txt -o 400 -i 2 -p 8'
