#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of multimodal, as a script that
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
# shows in full. The three versions of the call were built by
# lab/build_media.py: call-1042.wav is two Piper voices reading a script, with
# the silences the script asks for; call-1042-noisy.wav is the same file with
# pink noise (seed 1042, amplitude 0.35) and a 60 Hz hum mixed in;
# call-1042-phone.wav is the clean file band-limited to 300-3400 Hz at 8 kHz.
# media/truth/call-1042.json says who spoke from when to when.
#
# Silero VAD, GTCRN, pyannote's segmentation 3.0, 3D-Speaker's ERes2Net and
# Whisper base are real models run on this machine. Timings are this machine's.
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

put measure.py <<'PY'
"""Two measurements the audio lessons share: words wrong, and speech found."""
import jiwer

import mmlab


def words(text):
    """Lower case, no punctuation, one space: what a word error rate should compare."""
    return " ".join(jiwer.RemovePunctuation()(text.lower()).split())


def transcript(samples, whisper):
    """Cut at silences, transcribe each piece, join them: the pipeline of lesson 4."""
    pieces = mmlab.speech_segments(samples)
    text = " ".join(mmlab.transcribe(whisper, samples[int(s * mmlab.RATE):int(e * mmlab.RATE)])[0] for s, e in pieces)
    return text, pieces


def wer(truth, heard):
    return jiwer.wer(words(truth), words(heard))
PY

put noise.py <<'PY'
"""How loud the noise is against the voices, and where in the spectrum it sits."""
import numpy as np

import mmlab

clean = mmlab.read_audio("media/call-1042.wav")
noise = mmlab.read_audio("media/call-1042-noisy.wav") - clean
db = lambda x: 10 * np.log10((x ** 2).mean())
print(f"signal-to-noise ratio: {db(clean) - db(noise):.1f} dB")

freqs = np.fft.rfftfreq(len(clean), 1 / mmlab.RATE)
for name, x in (("voices", clean), ("noise", noise)):
    power = np.abs(np.fft.rfft(x)) ** 2
    bands = [(0, 100), (100, 300), (300, 1000), (1000, 3400), (3400, 8000)]
    share = [power[(freqs >= a) & (freqs < b)].sum() / power.sum() for a, b in bands]
    print(f"{name:7}", "  ".join(f"{a}-{b} Hz {s:5.1%}" for (a, b), s in zip(bands, share)))
print(f"loudest single frequency in the noise: {freqs[np.argmax(np.abs(np.fft.rfft(noise)))]:.0f} Hz")
PY

put clean.py <<'PY'
"""The noisy call cleaned three ways, each one transcribed and scored against the script."""
import subprocess
import time

import numpy as np
import soundfile as sf

import mmlab
from measure import transcript, wer

TRUTH = open("media/truth/call-1042.txt").read()
noisy = mmlab.read_audio("media/call-1042-noisy.wav")


def ffmpeg(audio_filter, out):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/call-1042-noisy.wav",
                    "-af", audio_filter, out], check=True)
    return mmlab.read_audio(out)


started = time.time()
denoised = np.asarray(mmlab.denoiser()(noisy, mmlab.RATE).samples, dtype=np.float32)
print(f"GTCRN took {time.time() - started:.1f} s for {len(noisy) / mmlab.RATE:.1f} s of audio")
sf.write("call-gtcrn.wav", denoised, mmlab.RATE)

versions = {
    "clean (the truth)": mmlab.read_audio("media/call-1042.wav"),
    "noisy, as recorded": noisy,
    "high-pass at 120 Hz": ffmpeg("highpass=f=120", "/tmp/hp.wav"),
    "high-pass + afftdn": ffmpeg("highpass=f=120,afftdn=nf=-25", "/tmp/fftdn.wav"),
    "GTCRN": denoised,
}
whisper = mmlab.whisper("base", language="en")
for name, samples in versions.items():
    text, pieces = transcript(samples, whisper)
    print(f"{name:20} WER {wer(TRUTH, text):6.1%}   {len(pieces):2} stretches of speech found")
PY

put vad.py <<'PY'
"""Where Silero hears speech, against where the script says somebody was speaking."""
import json
import sys

import mmlab

path, silence = sys.argv[1], float(sys.argv[2])
turns = json.load(open("media/truth/call-1042.json"))["turns"]
found = mmlab.speech_segments(mmlab.read_audio(path), min_silence=silence)
print(f"{path}, silences under {silence} s ignored: {len(found)} stretches for {len(turns)} turns")
for start, end in found:
    inside = [t["who"] for t in turns if t["start"] < end and t["end"] > start]
    print(f"  {start:6.2f} {end:6.2f}  {'+'.join(inside)}")
PY

put who.py <<'PY'
"""Who spoke when, by pyannote and ERes2Net, scored against who really did."""
import json
import sys
from collections import Counter

import mmlab

path, threshold = sys.argv[1], float(sys.argv[2])
known = [int(a) for a in sys.argv[3:] if a.isdigit()]   # how many speakers, if somebody knows
turns = json.load(open("media/truth/call-1042.json"))["turns"]
samples = mmlab.read_audio(path)
found = mmlab.diarizer(threshold=threshold, speakers=known[0] if known else -1).process(samples).sort_by_start_time()
segments = [(s.start, s.end, f"speaker_{s.speaker}") for s in found]


def overlap(a, b, c, d):
    return max(0.0, min(b, d) - max(a, c))


votes = Counter()  # seconds each found label spent over each real speaker
for s, e, label in segments:
    for t in turns:
        votes[label, t["who"]] += overlap(s, e, t["start"], t["end"])
names = {label: max(("caio", "bia"), key=lambda w: votes[label, w]) for _, _, label in segments}
right = sum(v for (label, who), v in votes.items() if names[label] == who)
speech = sum(t["end"] - t["start"] for t in turns)
print(f"{path} at {threshold}: {len(names)} speakers found, {len(segments)} segments, "
      f"{right / speech:.1%} of the speech given to the right person")
if "show" in sys.argv:
    for s, e, label in segments:
        print(f"  {s:6.2f} {e:6.2f}  {label} -> {names[label]}")
PY

put chunks.py <<'PY'
"""Cut a recording into pieces of at most 30 seconds, and only at a silence."""
import sys

import mmlab

LIMIT = 30.0
samples = mmlab.read_audio(sys.argv[1])
chunks, start, last_end = [], 0.0, 0.0
for s, e in mmlab.speech_segments(samples):
    if e - start > LIMIT and last_end > start:
        cut = (last_end + s) / 2          # the middle of the silence before this stretch
        chunks.append((start, cut))
        start = cut
    last_end = e
chunks.append((start, len(samples) / mmlab.RATE))
for a, b in chunks:
    print(f"{a:6.2f} -> {b:6.2f}  ({b - a:4.1f} s)")
PY

block numbers
on 'python -c "import soundfile as sf; [print(f, sf.info(f).samplerate, sf.info(f).channels, sf.info(f).subtype, round(sf.info(f).duration, 2)) for f in (\"media/call-1042.wav\", \"media/call-1042-phone.wav\")]"'
on 'python -c "print(16000 * 2 * 55.3835, 8000 * 1 * 55.3835)"'
on 'stat -c "%s %n" media/call-1042.wav media/call-1042-phone.wav'

block noise
on 'python noise.py'

block clean
on 'python clean.py'

block vad
on 'python vad.py media/call-1042.wav 0.25'
on 'python vad.py media/call-1042.wav 1.0 | head -4'
on 'python vad.py media/call-1042-noisy.wav 0.25'
on 'python vad.py call-gtcrn.wav 0.25 | head -1'

block who
on 'python who.py media/call-1042.wav 0.5 show'
on 'python who.py media/call-1042-noisy.wav 0.5'
on 'python who.py call-gtcrn.wav 0.5'
on 'python who.py media/call-1042-phone.wav 0.5'
on 'python who.py media/call-1042-noisy.wav 0.5 2'

block threshold
on 'for t in 0.3 0.5 0.7 0.9; do python who.py media/call-1042.wav $t; done'

block chunks
on 'python chunks.py media/call-1042.wav'
