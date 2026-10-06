#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of multimodal, as a script that
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
# shows in full. measure.py is lesson 5's, written again here because every
# lesson starts from a fresh ~/mm.
#
# Whisper tiny and base, Silero VAD and the Piper voices that spoke the
# recordings are real models run on this machine. Timings are this machine's,
# on four cores, and will differ on yours.
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

put score.py <<'PY'
"""Whisper tiny and base on three versions of the call: errors by kind, and the time each took."""
import time

import jiwer

import mmlab
from measure import transcript, words

TRUTH = words(open("media/truth/call-1042.txt").read())
for size in ("tiny", "base"):
    whisper = mmlab.whisper(size, language="en")
    for name in ("call-1042", "call-1042-phone", "call-1042-noisy"):
        started = time.time()
        text, _ = transcript(mmlab.read_audio(f"media/{name}.wav"), whisper)
        took = time.time() - started
        o = jiwer.process_words(TRUTH, words(text))
        print(f"{size:4} {name:16} WER {o.wer:6.1%}  substituted {o.substitutions:2}  deleted {o.deletions:2}  "
              f"inserted {o.insertions:2}  {took:4.1f} s")
PY

put turns.py <<'PY'
"""Each turn of the call cut out by the script's own times and transcribed alone, aligned with what was said."""
import json
import sys

import jiwer

import mmlab
from measure import words

turns = json.load(open("media/truth/call-1042.json"))["turns"]
samples = mmlab.read_audio("media/call-1042.wav")
whisper = mmlab.whisper(sys.argv[1], language="en")
pick = [int(n) for n in sys.argv[2:]]
said, heard = [], []
for i in pick:
    t = turns[i]
    text, _ = mmlab.transcribe(whisper, samples[int(t["start"] * mmlab.RATE):int(t["end"] * mmlab.RATE)])
    said.append(words(t["text"]))
    heard.append(words(text))
print(jiwer.visualize_alignment(jiwer.process_words(said, heard), show_measures=False))
PY

put fairly.py <<'PY'
"""The same transcript scored three ways: as written, without case and punctuation, and with numbers as words."""
import re
import sys

import jiwer
from num2words import num2words

import mmlab
from measure import transcript, words

truth = open("media/truth/call-1042.txt").read()
heard, _ = transcript(mmlab.read_audio("media/call-1042.wav"), mmlab.whisper(sys.argv[1], language="en"))


def spelled(text):
    """24th -> twenty-fourth, 10 -> ten: numbers written as the words they were spoken as."""
    text = re.sub(r"\b(\d+)(st|nd|rd|th)\b", lambda m: num2words(int(m[1]), to="ordinal"), text)
    return re.sub(r"(?<![\w-])\d+(?![\w-])", lambda m: num2words(int(m[0])), text)


print(f"as written:                  WER {jiwer.wer(truth, heard):6.1%}")
print(f"no case, no punctuation:     WER {jiwer.wer(words(truth), words(heard)):6.1%}")
print(f"and numbers spelled out:     WER {jiwer.wer(words(spelled(truth)), words(spelled(heard))):6.1%}")
PY

put language.py <<'PY'
"""The Portuguese voicemail, with the language left to Whisper, set right, and set wrong."""
import mmlab

samples = mmlab.read_audio("media/voicemail-pt.wav")
for language in ("", "pt", "en"):
    text, detected = mmlab.transcribe(mmlab.whisper("base", language=language), samples)
    print(f"asked {language or 'nothing':7} -> {detected}: {text}\n")
PY

put lexicon.py <<'PY'
"""Correct a transcript against the words this shop knows: its name, its staff, its books and their authors."""
import difflib
import json
import re

books = [json.loads(line) for line in open("data/books.jsonl")]
KNOWN = sorted({"Marginalia", "Caio"} | {b["title"] for b in books} | {b["author"] for b in books}, key=len, reverse=True)


def correct(text, cutoff=0.75):
    """Replace any run of words that is spelt like a known name, but is not it, with the name."""
    fixes = []
    tokens = text.split()
    for name in KNOWN:
        n, i = len(name.split()), 0
        while i < len(tokens):
            best = None
            for size in {max(1, n - 1), n, n + 1}:
                window = " ".join(tokens[i:i + size])
                bare = re.sub(r"[^\w ]", "", window).lower()
                if name.lower() in bare:                 # the name is already there, spelt right
                    best = None
                    break
                first = bare.split()[0] if bare else ""
                if difflib.SequenceMatcher(None, first, name.lower().split()[0]).ratio() < 0.5:
                    continue                             # a window must start where the name starts
                score = difflib.SequenceMatcher(None, bare, name.lower()).ratio()
                if score >= cutoff and (best is None or score > best[0]):
                    best = (score, size, window)
            if best:
                score, size, window = best
                tail = window[len(window.rstrip(",.?!")):]
                tokens[i:i + size] = (name + tail).split()
                fixes.append(f"{window!r} -> {name!r} ({score:.2f})")
                i += n                                   # carry on after the name just written
            else:
                i += 1
    text = " ".join(tokens)
    text, n = re.subn(r"\bM ?(\d{4})\b", r"M-\1", text)             # an order number has a hyphen
    fixes += ["M nnnn -> M-nnnn"] * n
    return text, fixes
PY

put fix.py <<'PY'
"""The base transcript, before and after the shop's lexicon, scored against the script."""
import mmlab
from lexicon import correct
from measure import transcript, wer

truth = open("media/truth/call-1042.txt").read()
heard, _ = transcript(mmlab.read_audio("media/call-1042.wav"), mmlab.whisper("base", language="en"))
fixed, fixes = correct(heard)
for f in fixes:
    print("  ", f)
print(f"WER before {wer(truth, heard):6.1%}   after {wer(truth, fixed):6.1%}")
PY

put names.py <<'PY'
"""How many of the shop's own words came out exactly right, which a word error rate does not say."""
import mmlab
from lexicon import correct
from measure import transcript, words

TERMS = ["Marginalia", "Caio", "M-1042", "Dom Casmurro", "Machado de Assis"]
truth = words(open("media/truth/call-1042.txt").read())
samples = mmlab.read_audio("media/call-1042.wav")
for size in ("tiny", "base"):
    heard, _ = transcript(samples, mmlab.whisper(size, language="en"))
    for label, text in (("as heard", heard), ("corrected", correct(heard)[0])):
        got = sum(min(words(text).count(words(t)), truth.count(words(t))) for t in TERMS)
        want = sum(truth.count(words(t)) for t in TERMS)
        print(f"{size:4} {label:9} {got} of {want} mentions of the shop's terms right")
PY

block score
on 'python score.py'

block align
on 'python turns.py base 1 2'

block fairly
on 'python fairly.py base'

block language
on 'python language.py'

block fix
on 'python fix.py'

block names
on 'python names.py'
