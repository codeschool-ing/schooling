#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of multimodal, as a script that
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
# shows in full, and product.html, a page of the shop's written for the alt
# text check, also shown in full.
#
# WHAT IS REAL. Every recognised word is Whisper base, run by labmm on this
# machine; the speech segments are Silero VAD; the speakers are pyannote's
# segmentation with 3D-Speaker's embeddings; the on-screen text is Tesseract 5
# reading frames ffmpeg cut; the spoken descriptions are the Piper voice
# en_US-lessac-medium. The narration script and the slide texts are the ones
# lab/media/returns.json declares, which the lab's video was made from. The
# descriptions themselves were written by the course, as a describer would
# write them.
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

put cues.py <<'PY'
"""The three rules every caption cue is held to, and the two helpers both caption programs share."""
LINE, LINES, CPS = 42, 2, 20       # characters per line, lines per cue, characters per second


def stamp(t):
    return "%02d:%02d:%06.3f" % (t // 3600, t % 3600 // 60, t % 60)


def wrap(text):
    """Greedy wrap at LINE characters."""
    lines, cur = [], ""
    for word in text.split():
        if cur and len(cur) + 1 + len(word) > LINE:
            lines.append(cur)
            cur = word
        else:
            cur = (cur + " " + word).strip()
    return lines + [cur]
PY

put captions.py <<'PY'
"""Captions for the returns video, straight from recognition, then checked against the cue rules."""
import json

from cues import CPS, LINES, stamp, wrap
from openai import OpenAI

with open("media/returns.mp4", "rb") as f:
    r = OpenAI().audio.transcriptions.create(model="lab-whisper-base", file=f, response_format="verbose_json")
cues = [(s.start, s.end, s.text.strip()) for s in r.segments]
json.dump(cues, open("recognised.json", "w"))

with open("returns.vtt", "w") as out:
    out.write("WEBVTT\n")
    for start, end, text in cues:
        out.write(f"\n{stamp(start)} --> {stamp(end)}\n" + "\n".join(wrap(text)) + "\n")

for start, end, text in cues:
    lines, cps = wrap(text), len(text) / (end - start)
    faults = [f"{len(lines)} lines"] * (len(lines) > LINES) + [f"{cps:.1f} chars/s"] * (cps > CPS)
    print("%5.2f %5.2f  %-28s %s" % (start, end, ", ".join(faults) or "ok", text[:34]))
PY

put recut.py <<'PY'
"""Cut each recognised segment into cues that obey the rules, sharing its time out by characters."""
import json

from cues import CPS, LINE, LINES, stamp, wrap

cues = []
for start, end, text in json.load(open("recognised.json")):
    lines = wrap(text)
    groups = [lines[i:i + LINES] for i in range(0, len(lines), LINES)]
    if len(groups) > 1 and len(groups[-1]) == 1:          # never leave one short line alone at the end
        words = text.split()
        half = len(words) // 2
        groups = [wrap(" ".join(words[:half])), wrap(" ".join(words[half:]))]
    total, t = sum(len(" ".join(g)) for g in groups), start
    for g in groups:
        span = (end - start) * len(" ".join(g)) / total
        cues.append((t, t + span, g))
        t += span

for a, b, g in cues:
    cps = len(" ".join(g)) / (b - a)
    print("%s --> %s  %4.1f/s  %s" % (stamp(a)[3:], stamp(b)[3:], cps, " / ".join(g)))
print(len(cues), "cues,", sum(len(" ".join(g)) / (b - a) > CPS for a, b, g in cues), "over", CPS, "chars/s,",
      sum(any(len(x) > LINE for x in g) for a, b, g in cues), "lines over", LINE)
PY

put script_captions.py <<'PY'
"""Timings from recognition, words from the script: each segment takes the script line it is closest to."""
import json

import jiwer
from cues import stamp

said = [s["said"] for s in json.load(open("media/truth/returns.json"))["slides"] if s["said"]]
heard = json.load(open("recognised.json"))

print("recognised against the script: WER %.1f%%" % (100 * jiwer.wer(" ".join(said).lower(), " ".join(t for _, _, t in heard).lower())))
for start, end, text in heard:
    line = min(said, key=lambda s: jiwer.cer(s.lower(), text.lower()))
    print("%s  cer %4.1f%%  %s" % (stamp(start)[3:], 100 * jiwer.cer(line.lower(), text.lower()), line[:52]))
PY

put missing.py <<'PY'
"""What the video SHOWS that its narration never SAYS: OCR a frame from the middle of each slide."""
import json
import re
import subprocess

slides = json.load(open("media/truth/returns.json"))["slides"]
spoken = set(re.findall(r"[a-z0-9]+", " ".join(s["said"] for s in slides).lower()))

for s in slides:
    mid = (s["start"] + s["end"]) / 2
    png = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-ss", f"{mid:.2f}", "-i", "media/returns.mp4",
                          "-frames:v", "1", "-f", "image2pipe", "-vcodec", "png", "-"], capture_output=True).stdout
    text = subprocess.run(["tesseract", "-", "-"], input=png, capture_output=True).stdout.decode()
    for line in filter(None, (l.strip() for l in text.splitlines())):
        words = re.findall(r"[a-z0-9]+", line.lower())
        unsaid = [w for w in words if w not in spoken]
        if len(unsaid) * 2 >= len(words):              # half or more of the line is never said
            print("%5.2f-%5.2f  %-38s never said: %s" % (s["start"], s["end"], line, " ".join(unsaid)))
PY

put describe.py <<'PY'
"""Audio description: speak what is shown and not said, in the pauses of the narration, if it fits."""
import subprocess

import mmlab
import soundfile

# Written by the course, as a describer would write them: short, and only what the narration leaves out.
DESCRIPTIONS = [(11.64, "Reasons: damaged, wrong book, changed my mind."),
                (20.72, "Code: RETURN30."),
                (26.44, "The label is valid for seven days.")]

speech = mmlab.speech_segments(mmlab.read_audio("media/returns.mp4"))
gaps = [(a[1], b[0]) for a, b in zip(speech, speech[1:])] + [(speech[-1][1], 32.6)]
tts = mmlab.piper("en_US-lessac-medium")

inputs, filters = [], []
for shown, text in DESCRIPTIONS:
    gap = next((g for g in gaps if g[1] > shown), None)            # the first pause that ends after it appears
    audio = tts.generate(text, sid=0, speed=1.0)
    seconds = len(audio.samples) / audio.sample_rate
    fits = gap[1] - gap[0] >= seconds + 0.2                      # a tenth of a second of air either side
    print("%5.2f  %-48s %.2f s into a %.2f s pause at %.2f: %s" % (shown, text, seconds, gap[1] - gap[0], gap[0],
                                                                 "fits" if fits else "does NOT fit"))
    if fits:
        name = f"ad{len(inputs)}.wav"
        soundfile.write(name, audio.samples, audio.sample_rate)
        filters.append(f"[{len(inputs) + 1}]adelay={int((gap[0] + 0.1) * 1000)}:all=1[d{len(inputs)}]")
        inputs.append(name)

mix = ";".join(filters) + ";[0]" + "".join(f"[d{i}]" for i in range(len(inputs))) + \
      f"amix=inputs={len(inputs) + 1}:normalize=0"
subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/returns.mp4",
                *sum((["-i", n] for n in inputs), []), "-filter_complex", mix, "-ac", "1", "described.wav"], check=True)
print("described.wav:", len(inputs), "of", len(DESCRIPTIONS), "descriptions mixed in")
PY

put transcript.py <<'PY'
"""A transcript of the call for someone who cannot hear it: who spoke, when, and what Whisper heard."""
from mmlab import diarizer, read_audio
from openai import OpenAI

turns = diarizer(speakers=2).process(read_audio("media/call-1042.wav")).sort_by_start_time()
with open("media/call-1042.wav", "rb") as f:
    heard = OpenAI().audio.transcriptions.create(model="lab-whisper-base", file=f, response_format="verbose_json")


def speaker(start, end):
    """The diarized speaker who overlaps this segment the most."""
    return max(turns, key=lambda t: min(end, t.end) - max(start, t.start)).speaker


last = None
for s in heard.segments:
    who = speaker(s.start, s.end)
    if who != last:
        print("\n[%d:%02d] Speaker %d:" % (s.start // 60, s.start % 60, who + 1), end="")
        last = who
    print(" " + s.text.strip(), end="")
print()
PY

put alt_check.py <<'PY'
"""The alt text a machine can judge: present, not a file name, not 'image of', empty only when decorative."""
import re
import sys
from html.parser import HTMLParser


class Images(HTMLParser):
    def __init__(self):
        super().__init__()
        self.found = []

    def handle_starttag(self, tag, attrs):
        if tag == "img":
            self.found.append((self.getpos()[0], dict(attrs)))


page = Images()
page.feed(open(sys.argv[1]).read())
for line, a in page.found:
    alt, src = a.get("alt"), a.get("src", "")
    if alt is None:
        verdict = "MISSING: many screen readers fall back to the file name"
    elif alt == "":
        verdict = "empty: right only if the picture is decoration" + ("" if a.get("role") == "presentation" else "; is it?")
    elif re.fullmatch(r"[\w-]+\.(jpe?g|png|gif|webp)", alt, re.I):
        verdict = "a file name, not a description"
    elif re.match(r"(image|picture|photo) of", alt, re.I):
        verdict = "starts with 'image of': the reader already says it is an image"
    else:
        verdict = "ok to a machine; whether it says the right thing is a person's call"
    print("line %d  %-22s %s" % (line, src, verdict))
PY

put product.html <<'HTML'
<main>
  <h1>Dom Casmurro</h1>
  <img src="cover-b39.png" alt="Cover of Dom Casmurro: a moon over a dark house with two lit windows">
  <img src="back-cover.jpg" alt="IMG_2041.jpg">
  <img src="size-chart.png">
  <img src="divider.svg" alt="" role="presentation">
  <img src="author.jpg" alt="Image of Machado de Assis">
  <p>Machado de Assis's novel of 1899, in a new English translation.</p>
</main>
HTML

block captions
on 'python captions.py'
on 'head -n 8 returns.vtt'
block recut
on 'python recut.py'

block script
on 'python script_captions.py'

block missing
on 'python missing.py'

block describe
on 'python describe.py'
on 'python -c "from openai import OpenAI; print(OpenAI().audio.transcriptions.create(model=\"lab-whisper-base\", file=open(\"described.wav\", \"rb\"), response_format=\"text\"))" | cut -c1-400'

block transcript
on 'python transcript.py | cut -c1-110'

block alt
on 'python alt_check.py product.html'
