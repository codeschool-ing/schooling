#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of multimodal, as a script that
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
# shows in full. returns.mp4 was made by lab/build_media.py from
# lab/media/returns-video.json: seven slides drawn by Pillow, a narration spoken
# by Piper's en_US-lessac-medium voice, and a 0.4-second card between slides 4
# and 5 that the narration never mentions, put there on purpose.
#
# Whisper base, Silero VAD and Tesseract are real models run on this machine.
# Image tokens are counted with labmm's gpt4o_tokens, the lab's implementation
# of the tile rule OpenAI published for GPT-4o; no image was sent anywhere.
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

put frames.py <<'PY'
"""Pull frames out of a video with one of five rules, and read the title on each."""
import os
import re
import shutil
import subprocess
import sys

RULES = {
    "every 5 s": ["-vf", "fps=1/5,showinfo"],
    "every 1 s": ["-vf", "fps=1,showinfo"],
    "scene > 0.3": ["-vf", r"select=gt(scene\,0.3),showinfo", "-vsync", "vfr"],
    "scene > 0.03": ["-vf", r"select=gt(scene\,0.03),showinfo", "-vsync", "vfr"],
    "keyframes": ["-skip_frame", "nokey", "-vf", "showinfo", "-vsync", "vfr"],
}


def title(png):
    """The first line Tesseract reads that has four letters or more and is not the shop's name."""
    out = subprocess.run(["tesseract", png, "-", "--psm", "6"], capture_output=True, text=True).stdout
    lines = [x for x in out.splitlines() if len(re.findall(r"\w", x)) >= 4 and x != "Marginalia"]
    return lines[0] if lines else "?"


def sample(video, rule, out):
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    args = RULES[rule][:2] if rule == "keyframes" else []
    rest = RULES[rule][2:] if rule == "keyframes" else RULES[rule]
    log = subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", *args, "-i", video, *rest, f"{out}/%03d.png"],
                         capture_output=True, text=True).stderr
    times = [float(t) for t in re.findall(r"pts_time:([0-9.]+)", log)]
    return [(t, os.path.join(out, f"{i:03}.png")) for i, t in enumerate(times, 1)]


if __name__ == "__main__":
    for rule in (sys.argv[2:] or RULES):
        frames = sample(sys.argv[1], rule, "/tmp/frames")
        titles = [title(p) for _, p in frames]
        print(f"{rule:13} {len(frames):3} frames  {len(set(titles)):2} different titles  "
              f"the 0.4 s card seen: {'yes' if any(t.startswith('Code:') for t in titles) else 'no'}")
PY

put soundtrack.py <<'PY'
"""The video's soundtrack, cut at its silences and transcribed piece by piece."""
import json
import sys

import mmlab

samples = mmlab.read_audio(sys.argv[1])
whisper = mmlab.whisper("base", language="en")
said = []
for start, end in mmlab.speech_segments(samples):
    text, _ = mmlab.transcribe(whisper, samples[int(start * mmlab.RATE):int(end * mmlab.RATE)])
    said.append({"start": round(start, 2), "end": round(end, 2), "text": text})
    print(f"{start:6.2f} {end:6.2f}  {text}")
json.dump(said, open("said.json", "w"), indent=1)
PY

put timeline.py <<'PY'
"""One timeline from both streams: what was on screen, and what was said while it was."""
import json
import subprocess

from frames import sample, title

VIDEO, LENGTH = "media/returns.mp4", 32.6
said = json.load(open("said.json"))
cuts = sample(VIDEO, "scene > 0.03", "/tmp/scenes")
subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", VIDEO, "-frames:v", "1", "/tmp/scenes/000.png"])
scenes = [(0.0, "/tmp/scenes/000.png")] + cuts

timeline = []
for (start, png), end in zip(scenes, [t for t, _ in cuts] + [LENGTH]):
    words = " ".join(s["text"] for s in said if start <= (s["start"] + s["end"]) / 2 < end)
    timeline.append({"from": start, "to": end, "shown": title(png), "said": words})
    print(f"{start:6.2f}-{end:5.2f}  shown: {timeline[-1]['shown']}")
    print(f"{'':12}  said:  {words or '(nothing)'}")
json.dump(timeline, open("timeline.json", "w"), indent=1)
PY

put budget.py <<'PY'
"""What each way of handing this video to a model would cost, in input tokens."""
import json

import tiktoken
from labmm import gpt4o_tokens

high, _ = gpt4o_tokens(1280, 720, "high")
low, _ = gpt4o_tokens(1280, 720, "low")
text = json.dumps(json.load(open("timeline.json")))
enc = tiktoken.get_encoding("o200k_base")
print(f"one 1280x720 frame: {high} tokens at high detail, {low} at low")
for name, frames in (("every frame", 815), ("one a second", 33), ("one per scene", 7)):
    print(f"{name:14} {frames:4} frames  {frames * high:7,} tokens high  {frames * low:6,} low")
print(f"{'the timeline':14} as text      {len(enc.encode(text)):7,} tokens")
PY

block probe
on 'ffprobe -v error -show_entries stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames,sample_rate -show_entries format=duration,size -of compact=nk=0 media/returns.mp4'

block sample
on 'python frames.py media/returns.mp4'

block at21
on 'ffmpeg -nostdin -loglevel error -y -ss 21 -i media/returns.mp4 -frames:v 1 /tmp/at21.png && tesseract /tmp/at21.png - --psm 6 2>/dev/null | head -2'

block missed
on 'python -c "import json; [print(s[\"slide\"], s[\"start\"], s[\"end\"], s[\"title\"]) for s in json.load(open(\"media/truth/returns.json\"))[\"slides\"]]"'

block soundtrack
on 'python soundtrack.py media/returns.mp4'

block timeline
on 'python timeline.py'

block budget
on 'python budget.py'

block truth-gaps
on 'python -c "import json; s = json.load(open(\"media/truth/returns.json\"))[\"slides\"]; [print(x[\"slide\"], \"shown:\", x[\"shown\"], \"| said:\", x[\"said\"] or \"-\") for x in s if x[\"slide\"] in (3, 5, 7)]"'
