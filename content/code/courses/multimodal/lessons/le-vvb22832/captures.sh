#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of multimodal, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: setup.sh from lesson 1, as ana
#   sudo bash captures.sh
#
# A line that starts with ana@lab:~/mm$ is what ana typed and what it printed.
# What is STAGED rather than typed, and not shown in the lesson: the lab itself
# (lab.sh reset) and the files ana wrote (put below), whose contents the lesson
# shows in full.
#
# THE TRANSCRIPTS ARE REAL, AND THEY ARE NOT OPENAI'S. audio_server.py, which
# the lesson prints whole, answers OpenAI's audio routes with Whisper base or
# tiny run on this machine (the ONNX export sherpa-onnx publishes), after
# cutting the audio at silences with Silero VAD. lab.sh serve starts it from the
# fence in the-transcriptions-endpoint.md, as the student starts it in a second
# terminal. OpenAI's whisper-1 is a larger Whisper and would make different
# mistakes. The 413 refusal and its message are the server's, enforcing the
# 25 MB limit OpenAI documents. Prices are LiteLLM's sheet at the commit
# lesson 3's prices.py pins.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/mm, and what it printed.
on() { printf 'ana@lab:~/mm$ %s\n' "$*"; lab exec "$*" </dev/null 2>&1 || true; }
# put PATH: a file ana wrote in ~/mm, from stdin, which a fence in this lesson
# (or in $SHOWN, another lesson's .md) must show byte for byte.
put() {
  local tmp; tmp=$(mktemp)
  cat >"$tmp"
  python3 ../../lab/shown.py check ./*.md ${SHOWN:-} <"$tmp" || { echo "put $1: not shown" >&2; exit 1; }
  lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'" <"$tmp"
  rm -f "$tmp"
}
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/mm from nothing.
exec 9>/var/tmp/multimodal-capture.lock; flock 9
lab reset >/dev/null
SHOWN=../le-gtwzkpaq/judging-results.md   # prices.py is lesson 3's

put prices.py <<'PY'
"""prices: what LiteLLM's price sheet says about a model, read at one pinned commit.

    python prices.py show NAME                every field of one entry
    python prices.py find TEXT [MODE]         every entry whose name contains TEXT

LiteLLM is an open-source library that calls a hundred providers through one
interface, and it keeps one JSON file of every model's prices to do it. It is a
third party's copy of the providers' pages, so every number this course takes
from it says so. The commit is pinned, so the same file comes out next year.
"""
import json
import os
import sys
import urllib.request

COMMIT = "21881c571181fc0e409dd717b8a277e5b43152a7"
URL = f"https://raw.githubusercontent.com/BerriAI/litellm/{COMMIT}/model_prices_and_context_window.json"
CACHE = os.path.expanduser(f"~/mm/data/litellm-{COMMIT[:8]}.json")

if not os.path.exists(CACHE):                       # downloaded once, then read from disk
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    urllib.request.urlretrieve(URL, CACHE)
sheet = json.load(open(CACHE))

if sys.argv[1] == "show":
    for key, value in sorted(sheet[sys.argv[2]].items()):
        print(f"{key:42} {value}")
elif sys.argv[1] == "find":
    mode = sys.argv[3] if len(sys.argv) > 3 else None
    for name, entry in sorted(sheet.items()):
        if sys.argv[2] in name and mode in (None, entry.get("mode")):
            print(f"{name:44} {entry.get('litellm_provider', ''):26} {entry.get('deprecation_date', '')}")
PY

put transcribe.py <<'PY'
"""Send a recording to the transcriptions endpoint and print what comes back."""
import sys

from openai import OpenAI

path = sys.argv[1]
fmt = sys.argv[2] if len(sys.argv) > 2 else "json"
client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open(path, "rb") as audio:
    result = client.audio.transcriptions.create(model="whisper-base", file=audio, response_format=fmt)
print(result.text if fmt == "json" else result)
PY

put verbose.py <<'PY'
"""verbose_json: the text, the language, the length, and every segment with its times."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(model="whisper-base", file=audio,
                                                response_format="verbose_json")
print(f"language {result.language}, {result.duration} s, {len(result.segments)} segments")
for s in result.segments[:4]:
    print(f"  {s.start:6.2f} {s.end:6.2f}  {s.text}")
PY

put translate.py <<'PY'
"""The Portuguese voicemail, transcribed as it was said and translated into English."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/voicemail-pt.wav", "rb") as audio:
    said = client.audio.transcriptions.create(model="whisper-base", file=audio)
with open("media/voicemail-pt.wav", "rb") as audio:
    english = client.audio.translations.create(model="whisper-base", file=audio)
print("transcribed:", said.text)
print("translated: ", english.text)
PY

put hint.py <<'PY'
"""The prompt parameter: text the model is told came before the audio."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(
        model="whisper-base", file=audio, language="en",
        prompt="Marginalia support. Caio. Order M-1042: Dom Casmurro, by Machado de Assis.")
print(result.text[:150])
PY

put long.py <<'PY'
"""An hour-long recording is too big to upload whole; cut it at silences and send the pieces."""
import subprocess
import sys

from openai import OpenAI, APIStatusError

LIMIT = 25 * 1024 * 1024
src = sys.argv[1]
size = int(subprocess.run(["stat", "-c", "%s", src], capture_output=True, text=True).stdout)
print(f"{src}: {size:,} bytes, the limit is {LIMIT:,}")
client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
try:
    with open(src, "rb") as audio:
        client.audio.transcriptions.create(model="whisper-tiny", file=audio)
except APIStatusError as e:
    print(f"whole file: {e.status_code} {e.body['message'] if isinstance(e.body, dict) else e.body}")
PY

put pieces.py <<'PY'
"""Transcribe a long recording in pieces cut at silences, and put the times back together."""
import subprocess
import sys

from openai import OpenAI

import mmlab

src, LIMIT = sys.argv[1], 600.0                    # pieces of at most ten minutes
samples = mmlab.read_audio(src)
cuts, start, last = [], 0.0, 0.0
for s, e in mmlab.speech_segments(samples):
    if e - start > LIMIT and last > start:
        cuts.append((start, (last + s) / 2))
        start = (last + s) / 2
    last = e
cuts.append((start, len(samples) / mmlab.RATE))

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
segments = []
for i, (a, b) in enumerate(cuts):
    piece = f"/tmp/piece-{i}.mp3"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-ss", str(a), "-to", str(b), "-i", src,
                    "-ac", "1", "-ar", "16000", "-b:a", "32k", piece], check=True)
    with open(piece, "rb") as audio:
        r = client.audio.transcriptions.create(model="whisper-tiny", file=audio, language="en",
                                               response_format="verbose_json")
    segments += [(a + s.start, a + s.end, s.text) for s in r.segments]   # the piece's times, moved to the file's
    size = subprocess.run(["stat", "-c", "%s", piece], capture_output=True, text=True).stdout.strip()
    print(f"piece {i}: {a:7.1f} to {b:7.1f} s, {int(size):,} bytes, {len(r.segments)} segments")
print(f"{len(segments)} segments; the last: {segments[-1][0]:.1f}-{segments[-1][1]:.1f} s {segments[-1][2]!r}")
PY

block json
lab serve audio
on 'python transcribe.py media/call-1042.wav | cut -c1-160'
on 'tail -n 1 audio_server.log'

block text
on 'python transcribe.py media/voicemail-pt.wav text'

block verbose
on 'python verbose.py'

block srt
on 'python transcribe.py media/call-1042.wav srt | head -8'

block vtt
on 'python transcribe.py media/call-1042.wav vtt | head -8'

block translate
on 'python translate.py'

block hint
on 'python hint.py'
on 'tail -n 1 audio_server.log | python -c "import json, sys; print(json.load(sys.stdin)[\"prompt\"])"'

block long
on 'for i in $(seq 32); do echo "file '"'"'$PWD/media/call-1042.wav'"'"'"; done > /tmp/list.txt && ffmpeg -nostdin -loglevel error -y -f concat -safe 0 -i /tmp/list.txt -c copy long.wav && ffprobe -v error -show_entries format=duration -of csv=p=0 long.wav'
on 'python long.py long.wav'
on 'ffmpeg -nostdin -loglevel error -y -i long.wav -ac 1 -ar 16000 -b:a 32k long.mp3 && stat -c "%s %n" long.mp3'

block pieces
on 'python pieces.py long.wav'

block prices
on 'python prices.py find transcribe | grep " openai "'
on 'for m in whisper-1 gpt-4o-transcribe gpt-4o-mini-transcribe; do printf "%-24s" $m; python prices.py show $m | grep -E "input_cost_per_second|input_cost_per_token|deprecation" | tr -s " " | tr "\n" " "; echo; done'
lab down
