#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of multimodal, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the models, labmm
#   sudo bash captures.sh
#
# A line that starts with ana@lab:~/mm$ is what ana typed and what it printed.
# What is STAGED rather than typed, and not shown in the lesson: the lab itself
# (lab.sh reset) and the files ana wrote (put below), whose contents the lesson
# shows in full.
#
# THE TRANSCRIPTS ARE REAL, AND THEY ARE NOT OPENAI'S. labmm answers OpenAI's
# audio routes with Whisper base or tiny run on this machine (the ONNX export
# sherpa-onnx publishes), after cutting the audio at silences with Silero VAD.
# OpenAI's whisper-1 is a larger Whisper and would make different mistakes.
# The 413 refusal and its message are labmm's, enforcing the 25 MB limit OpenAI
# documents. Prices are LiteLLM's sheet at the commit lab.sh pins.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/mm, and what it printed.
on() { printf 'ana@lab:~/mm$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/mm, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/mm from nothing.
exec 9>/var/tmp/multimodal-capture.lock; flock 9
lab reset >/dev/null

put transcribe.py <<'PY'
"""Send a recording to the transcriptions endpoint and print what comes back."""
import sys

from openai import OpenAI

path = sys.argv[1]
fmt = sys.argv[2] if len(sys.argv) > 2 else "json"
client = OpenAI()
with open(path, "rb") as audio:
    result = client.audio.transcriptions.create(model="lab-whisper-base", file=audio, response_format=fmt)
print(result.text if fmt == "json" else result)
PY

put verbose.py <<'PY'
"""verbose_json: the text, the language, the length, and every segment with its times."""
from openai import OpenAI

client = OpenAI()
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(model="lab-whisper-base", file=audio,
                                                response_format="verbose_json")
print(f"language {result.language}, {result.duration} s, {len(result.segments)} segments")
for s in result.segments[:4]:
    print(f"  {s.start:6.2f} {s.end:6.2f}  {s.text}")
PY

put translate.py <<'PY'
"""The Portuguese voicemail, transcribed as it was said and translated into English."""
from openai import OpenAI

client = OpenAI()
with open("media/voicemail-pt.wav", "rb") as audio:
    said = client.audio.transcriptions.create(model="lab-whisper-base", file=audio)
with open("media/voicemail-pt.wav", "rb") as audio:
    english = client.audio.translations.create(model="lab-whisper-base", file=audio)
print("transcribed:", said.text)
print("translated: ", english.text)
PY

put hint.py <<'PY'
"""The prompt parameter: text the model is told came before the audio."""
from openai import OpenAI

client = OpenAI()
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(
        model="lab-whisper-base", file=audio, language="en",
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
client = OpenAI()
try:
    with open(src, "rb") as audio:
        client.audio.transcriptions.create(model="lab-whisper-tiny", file=audio)
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

client = OpenAI()
segments = []
for i, (a, b) in enumerate(cuts):
    piece = f"/tmp/piece-{i}.mp3"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-ss", str(a), "-to", str(b), "-i", src,
                    "-ac", "1", "-ar", "16000", "-b:a", "32k", piece], check=True)
    with open(piece, "rb") as audio:
        r = client.audio.transcriptions.create(model="lab-whisper-tiny", file=audio, language="en",
                                               response_format="verbose_json")
    segments += [(a + s.start, a + s.end, s.text) for s in r.segments]   # the piece's times, moved to the file's
    size = subprocess.run(["stat", "-c", "%s", piece], capture_output=True, text=True).stdout.strip()
    print(f"piece {i}: {a:7.1f} to {b:7.1f} s, {int(size):,} bytes, {len(r.segments)} segments")
print(f"{len(segments)} segments; the last: {segments[-1][0]:.1f}-{segments[-1][1]:.1f} s {segments[-1][2]!r}")
PY

block json
on 'python transcribe.py media/call-1042.wav | cut -c1-160'
on 'tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print({k: r[k] for k in (\"model\", \"file\", \"bytes\", \"duration\", \"segments\", \"seconds\")})"'

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
on 'tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print(r[\"prompt\"])"'

block long
on 'for i in $(seq 32); do echo "file '"'"'$PWD/media/call-1042.wav'"'"'"; done > /tmp/list.txt && ffmpeg -nostdin -loglevel error -y -f concat -safe 0 -i /tmp/list.txt -c copy long.wav && ffprobe -v error -show_entries format=duration -of csv=p=0 long.wav'
on 'python long.py long.wav'
on 'ffmpeg -nostdin -loglevel error -y -i long.wav -ac 1 -ar 16000 -b:a 32k long.mp3 && stat -c "%s %n" long.mp3'

block pieces
on 'python pieces.py long.wav'

block prices
on 'sheet compare whisper-1 gpt-4o-transcribe gpt-4o-mini-transcribe'
on 'for m in whisper-1 gpt-4o-transcribe gpt-4o-mini-transcribe; do printf "%-24s" $m; sheet show $m | grep -E "input_cost_per_second|deprecation" | tr -s " " | tr "\n" " "; echo; done'
