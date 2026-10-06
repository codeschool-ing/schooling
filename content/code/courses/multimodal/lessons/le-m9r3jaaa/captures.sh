#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of multimodal, as a script that
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
# (lab.sh reset), the files ana wrote (put below), whose contents the lesson
# shows in full, and the two failures of the last section, which stop labmm and
# damage a copy of a model on purpose.
#
# Every model in this lesson is a real one run on this machine. Timings are
# this machine's, on four cores, and will differ on yours.
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

put inventory.py <<'PY'
"""What is in ~/mm/media: one line per file, and what a model would be handed."""
import json
import os
import subprocess

for name in sorted(os.listdir("media")):
    path = os.path.join("media", name)
    if not os.path.isfile(path):
        continue
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", path],
                           capture_output=True, text=True, check=True)
    info = json.loads(probe.stdout)
    kinds, timed = [], False
    for s in info["streams"]:
        if s["codec_type"] == "video" and s["codec_name"] in ("png", "mjpeg"):
            kinds.append(f"image {s['width']}x{s['height']}")
        elif s["codec_type"] == "video":
            kinds.append(f"video {s['width']}x{s['height']} {s['codec_name']}")
            timed = True
        elif s["codec_type"] == "audio":
            kinds.append(f"audio {s['sample_rate']} Hz {s['codec_name']}")
            timed = True
    seconds = f"{float(info['format']['duration']):6.1f} s" if timed else "       -"
    print(f"{name:22} {os.path.getsize(path):>10,} B {seconds}  " + " + ".join(kinds))
PY

put listen.py <<'PY'
"""The first eight seconds of the support call, through Whisper base."""
import mmlab

samples = mmlab.read_audio("media/call-1042.wav")
text, lang = mmlab.transcribe(mmlab.whisper("base"), samples[: 8 * mmlab.RATE])
print(lang, "|", text)
PY

put look.py <<'PY'
"""What MediaPipe's object detector finds in each picture named on the command line."""
import sys

import mediapipe as mp

import mmlab

with mmlab.detector() as det:
    for path in sys.argv[1:]:
        found = det.detect(mp.Image.create_from_file(path)).detections
        print(path, [(d.categories[0].category_name, round(d.categories[0].score, 2)) for d in found] or "nothing")
PY

block inventory
on 'python inventory.py'

block taste
on 'python listen.py'
on 'tesseract media/invoice-0931.png - 2>/dev/null | head -4'
on 'python look.py media/cat_and_dog.jpg media/invoice-0931.png'

block lab-check
on 'curl -s http://127.0.0.1:8700/; echo'
on 'ls media media/truth'
on 'du -sh /opt/multimodal/share /opt/multimodal/lib /opt/multimodal/media'
on 'python -c "import mmlab; print([n for n in dir(mmlab) if callable(getattr(mmlab, n)) and not n.startswith(\"_\") and n[0].islower() and n not in (\"np\", \"os\", \"subprocess\", \"sherpa_onnx\")])"'

block sizes
on 'cd /opt/multimodal/share && du -sh sherpa-onnx-whisper-* vits-piper-* *.onnx *.tflite all-MiniLM-L6-v2 | sort -h'

block fail-down
lab down >/dev/null
on 'curl -sS http://127.0.0.1:8700/'
lab reset >/dev/null
on 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8700/'

block fail-hash
lab exec 'cp /opt/multimodal/share/gtcrn_simple.onnx /tmp/gtcrn.onnx && printf x >> /tmp/gtcrn.onnx'
on 'echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /tmp/gtcrn.onnx" | sha256sum -c'
on 'echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /opt/multimodal/share/gtcrn_simple.onnx" | sha256sum -c'
lab exec 'rm -f /tmp/gtcrn.onnx'
