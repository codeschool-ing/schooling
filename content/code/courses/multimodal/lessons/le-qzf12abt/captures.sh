#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of multimodal, as a script that
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
# The three Piper voices and Whisper base are real models run on this machine,
# and espeak-ng 1.51 is the program whose rules and data Piper uses to turn
# text into phonemes (each voice carries its own copy of espeak-ng's data).
# Timings are this machine's, on four cores, and will differ on yours.
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

put say.py <<'PY'
"""Speak a text with one of the lab's Piper voices and save it as a WAV."""
import sys
import time

import soundfile as sf

import mmlab

voice, text, out = sys.argv[1], sys.argv[2], sys.argv[3]
speed = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
tts = mmlab.piper(voice)
started = time.time()
audio = tts.generate(text, sid=0, speed=speed)
took = time.time() - started
seconds = len(audio.samples) / audio.sample_rate
sf.write(out, audio.samples, audio.sample_rate)
print(f"{out}: {seconds:.2f} s of audio at {audio.sample_rate} Hz, made in {took:.2f} s")
PY

put twice.py <<'PY'
"""The same sentence spoken twice, with Piper's own noise and without it."""
import hashlib

import numpy as np

import mmlab

TEXT = "Your order has shipped."
for noise in (True, False):
    tts = mmlab.piper("en_US-lessac-medium", noise=noise)
    takes = [tts.generate(TEXT, sid=0, speed=1.0) for _ in range(2)]
    sums = [hashlib.sha256(np.asarray(t.samples).tobytes()).hexdigest()[:12] for t in takes]
    lengths = [f"{len(t.samples) / t.sample_rate:.2f} s" for t in takes]
    print(f"noise {'on ' if noise else 'off'}  {sums[0]} {lengths[0]}   {sums[1]} {lengths[1]}   "
          f"{'the same' if sums[0] == sums[1] else 'different'}")
PY

put roundtrip.py <<'PY'
"""Say each sentence with a Piper voice, then let Whisper write down what it heard in that voice's language."""
import sys

import soundfile as sf

import mmlab

voice = sys.argv[2] if len(sys.argv) > 2 else "en_US-lessac-medium"
tts = mmlab.piper(voice)
whisper = mmlab.whisper("base", language=voice[:2])
for line in open(sys.argv[1]):
    text = line.strip()
    audio = tts.generate(text, sid=0, speed=1.0)
    sf.write("/tmp/roundtrip.wav", audio.samples, audio.sample_rate)
    heard, _ = mmlab.transcribe(whisper, mmlab.read_audio("/tmp/roundtrip.wav"))
    print(f"said:  {text}\nheard: {heard}")
PY

put spoken.py <<'PY'
"""Rewrite the things a voice reads badly into the words a person would say."""
import re
import sys

DIGITS = "zero one two three four five six seven eight nine".split()
MONTHS = ("January February March April May June July August September October November "
          "December").split()
ORDINAL = {1: "first", 2: "second", 3: "third", 21: "twenty-first", 22: "twenty-second",
           23: "twenty-third", 24: "twenty-fourth", 30: "thirtieth", 31: "thirty-first"}


def order_id(m):                        # M-1042 -> "M, one zero four two"
    return m[1] + ", " + " ".join(DIGITS[int(d)] for d in m[2])


def date(m):                            # 24/09/2026 -> "the twenty-fourth of September"
    day, month = int(m[1]), int(m[2])
    return f"the {ORDINAL.get(day, str(day) + 'th')} of {MONTHS[month - 1]}"


def reais(m):                           # R$ 34,80 -> "34 reais and 80 centavos"
    return f"{int(m[1])} reais" + (f" and {int(m[2])} centavos" if int(m[2]) else "")


RULES = [(r"\b([A-Z])-(\d{4})\b", order_id),
         (r"\b(\d{1,2})/(\d{1,2})/\d{4}\b", date),
         (r"R\$ ?(\d+),(\d\d)\b", reais)]


def spoken(text):
    for pattern, rewrite in RULES:
        text = re.sub(pattern, rewrite, text)
    return text


if __name__ == "__main__":
    for line in open(sys.argv[1]):
        print(spoken(line.strip()))
PY

put latency.py <<'PY'
"""How long a caller waits before the first word: the whole reply at once, or sentence by sentence."""
import re
import time

import mmlab

REPLY = ("Your order M, one zero four two, was delivered on the twenty-fourth of September. "
         "It can be returned until the twenty-fourth of October, free of charge. "
         "We will e-mail you a prepaid label in the next few minutes. "
         "Print it, tape it over the old address, and drop the parcel at any post office. "
         "Your refund of 34 reais and 80 centavos will reach your card once the parcel arrives.")
tts = mmlab.piper("en_US-lessac-medium")
tts.generate("Warm up.", sid=0, speed=1.0)            # the first call pays for loading; leave it out

started = time.time()
whole = tts.generate(REPLY, sid=0, speed=1.0)
wait = time.time() - started
audio = len(whole.samples) / whole.sample_rate
print(f"all at once:     first sound after {wait:.2f} s, {audio:.1f} s of speech, real-time factor {wait / audio:.3f}")

sentences = re.split(r"(?<=\.) ", REPLY)
started = time.time()
first = tts.generate(sentences[0], sid=0, speed=1.0)
print(f"one sentence:    first sound after {time.time() - started:.2f} s, "
      f"{len(first.samples) / first.sample_rate:.1f} s of speech to play while the next {len(sentences) - 1} are made")
PY

put pitch.py <<'PY'
"""The voice's pitch over the first half of a sentence and over its last word."""
import sys

import numpy as np
import soundfile as sf


def pitch(frame, rate):
    """One frame's fundamental frequency, by autocorrelation, or None when it is not voiced."""
    frame = frame - frame.mean()
    ac = np.correlate(frame, frame, "full")[len(frame) - 1:]
    lo, hi = rate // 400, rate // 70                     # look for a pitch between 70 and 400 Hz
    lag = lo + int(np.argmax(ac[lo:hi]))
    return rate / lag if ac[lag] > 0.3 * ac[0] else None


for path in sys.argv[1:]:
    x, rate = sf.read(path)
    step = int(0.03 * rate)
    f0 = [(i / rate, pitch(x[i:i + step], rate)) for i in range(0, len(x) - step, step)]
    voiced = [(t, f) for t, f in f0 if f]
    end = voiced[-1][0]
    early = np.median([f for t, f in voiced if t < end / 2])
    late = np.median([f for t, f in voiced if t > end - 0.35])
    print(f"{path}: {early:5.0f} Hz in the first half, {late:5.0f} Hz over the last word")
PY

put formats.py <<'PY'
"""One sentence from labmm's speech route in every format it offers, and what each one weighs."""
from openai import OpenAI

client = OpenAI()
TEXT = "Your order has shipped. It should arrive on Thursday."
for fmt in ("wav", "flac", "mp3", "aac", "opus"):
    audio = client.audio.speech.create(model="lab-tts-1", voice="lessac", input=TEXT, response_format=fmt)
    print(f"{fmt:5} {len(audio.content):7,} bytes")
PY

put said.txt <<'TXT'
Your order M-1042 arrived on 24/09/2026.
Your refund of R$ 34,80 is on its way.
Dom Casmurro, by Machado de Assis.
TXT

block espeak
on 'espeak-ng -q -x -v en-us "Your order M-1042 arrived on 24/09/2026."'
on 'espeak-ng -q -x -v en-us "Your refund of R\$ 34,80 is on its way."'
on 'espeak-ng -q -x -v en-us "Dom Casmurro, by Machado de Assis."'
on 'espeak-ng -q -x -v pt-br "Dom Casmurro, de Machado de Assis."'

block voices
on 'python say.py en_US-lessac-medium "Your order has shipped. It should arrive on Thursday." lessac.wav'
on 'python say.py en_GB-alan-medium "Your order has shipped. It should arrive on Thursday." alan.wav'
on 'python say.py pt_BR-faber-medium "Seu pedido foi enviado. Deve chegar na quinta-feira." faber.wav'
on 'grep -E "Language|Samplerate|URL|License" /opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD'

block twice
on 'python twice.py'

block roundtrip
on 'python roundtrip.py said.txt'

block spoken
on 'python spoken.py said.txt | tee said-spoken.txt'
on 'python roundtrip.py said-spoken.txt'

put titulo.txt <<'TXT'
Dom Casmurro, de Machado de Assis.
TXT

block titulo
on 'python roundtrip.py titulo.txt pt_BR-faber-medium'

block pace
on 'python say.py en_US-lessac-medium "Your order has shipped." /tmp/a.wav 1.0'
on 'python say.py en_US-lessac-medium "Your order has shipped?" /tmp/b.wav 1.0'
on 'python say.py en_US-lessac-medium "Your order has shipped!" /tmp/c.wav 1.0'
on 'python say.py en_US-lessac-medium "Your order has shipped." /tmp/d.wav 0.8'
on 'python say.py en_US-lessac-medium "Your order has shipped." /tmp/e.wav 1.25'

block pitch
on 'python pitch.py /tmp/a.wav /tmp/b.wav'

block latency
on 'python latency.py'

block formats
on 'python formats.py'
