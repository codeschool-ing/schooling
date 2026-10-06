#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of multimodal, as a script that
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
# shows in full. measure.py is lesson 5's, written again here.
#
# The Hugging Face Hub could not be reached from the machine this course was
# recorded on, so nothing here downloads from it; the models measured are the
# ones lab.sh fetched from sherpa-onnx's releases and MediaPipe's bucket, which
# are conversions of models published on the Hub. The transformers code in the
# lesson was not run. Timings are this machine's, on four cores.
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

put precision.py <<'PY'
"""The same Whisper at full precision and at int8: size on disk, time to load, time to transcribe, words wrong."""
import os
import time

import mmlab
from measure import transcript, wer

TRUTH = open("media/truth/call-1042.txt").read()
samples = mmlab.read_audio("media/call-1042.wav")
for size in ("tiny", "base"):
    for int8 in (False, True):
        q = ".int8" if int8 else ""
        d = os.path.join(mmlab.SHARE, f"sherpa-onnx-whisper-{size}")
        mb = sum(os.path.getsize(f"{d}/{size}-{part}{q}.onnx") for part in ("encoder", "decoder")) / 1e6
        started = time.time()
        model = mmlab.whisper(size, language="en", int8=int8)
        loaded = time.time() - started
        started = time.time()
        text, _ = transcript(samples, model)
        ran = time.time() - started
        print(f"{size:4} {'int8' if int8 else 'fp32':4}  {mb:6.1f} MB  load {loaded:4.1f} s  "
              f"transcribe {ran:5.1f} s  WER {wer(TRUTH, text):6.1%}")
PY

block cards
on 'grep -H -E "Language|License|URL" /opt/multimodal/share/vits-piper-*/MODEL_CARD'
on 'head -3 /opt/multimodal/share/sherpa-onnx-pyannote-segmentation-3-0/LICENSE; sed -n "3,4p" /opt/multimodal/share/sherpa-onnx-pyannote-segmentation-3-0/README.md'

block sizes
on 'cd /opt/multimodal/share && ls -l sherpa-onnx-whisper-base/*.onnx | awk "{print \$5, \$9}"'

block precision
on 'python precision.py'

block inventory
on 'cd /opt/multimodal/share && for f in silero_vad.onnx gtcrn_simple.onnx efficientdet_lite0.tflite 3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx sherpa-onnx-pyannote-segmentation-3-0/model.onnx vits-piper-en_US-lessac-medium/en_US-lessac-medium.onnx sherpa-onnx-whisper-tiny/tiny-encoder.int8.onnx; do printf "%10s  %s\n" $(stat -c %s $f) $f; done'

block hub
on 'curl -sS -m 10 -o /dev/null -w "%{http_code}\n" https://huggingface.co/api/models/openai/whisper-base'
