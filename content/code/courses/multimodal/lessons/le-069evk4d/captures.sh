#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of multimodal, as a script that
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
# WHERE THE NUMBERS COME FROM. Prices are LiteLLM's sheet at the commit lesson
# 3's prices.py pins; they are the sheet's, not a bill. Image token counts are
# the published rules in lesson 4's tokens.py (lesson 8): OpenAI's tile rule for
# GPT-4o and Google's 768-pixel tiles for Gemini. Sizes are the files' own
# bytes, the OCR is Tesseract 5, the transcripts are Whisper base through lesson
# 10's audio_server.py, and the cached replies are qwen2.5vl:3b's through Ollama
# 0.40.0, at the default temperature, taken on 2026-10-07. The phone photo is
# cat_and_dog.jpg scaled up to 4032 by 3024 by the command the lesson shows.
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
SHOWN="../le-gtwzkpaq/judging-results.md ../le-pggpkpr2/summarising.md"   # prices.py is lesson 3's, tokens.py lesson 4's


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

put tokens.py <<'PY'
"""What a picture costs a vision model, by the rules OpenAI published for GPT-4o and Google for Gemini."""
import math


def gpt4o_tokens(w, h, detail="high"):
    """85 for the picture, plus 170 for every 512-pixel tile after two resizes: (tokens, tiles)."""
    if detail == "low":                       # one small copy of the picture, whatever its size
        return 85, 0
    if max(w, h) > 2048:                      # first, fit inside 2048 x 2048
        s = 2048 / max(w, h)
        w, h = int(w * s), int(h * s)
    if min(w, h) > 768:                       # then shrink until the short side is 768
        s = 768 / min(w, h)
        w, h = int(w * s), int(h * s)
    tiles = math.ceil(w / 512) * math.ceil(h / 512)
    return 85 + 170 * tiles, tiles


def gemini_tokens(w, h):
    """258 for a picture with both sides at most 384, otherwise 258 for every 768-pixel tile."""
    if w <= 384 and h <= 384:
        return 258
    return 258 * math.ceil(w / 768) * math.ceil(h / 768)
PY

put picture_cost.py <<'PY'
"""What one picture costs to send, by the token rules of lesson 8 and the sheet's input prices."""
import sys

from tokens import gemini_tokens, gpt4o_tokens
from PIL import Image

GPT4O = 2.5e-06          # sheet: gpt-4o input_cost_per_token
FLASH = 3e-07            # sheet: gemini/gemini-2.5-flash input_cost_per_token

print("%-22s %11s %7s %8s %7s %9s" % ("file", "pixels", "detail", "tokens", "$/1000", "gemini $/1000"))
for path in sys.argv[1:]:
    w, h = Image.open(path).size
    for detail in ("low", "high"):
        t, _ = gpt4o_tokens(w, h, detail)
        g = gemini_tokens(w, h) if detail == "high" else None
        line = "%-22s %11s %7s %8d %7.2f %9s" % (path.split("/")[-1], f"{w}x{h}", detail, t, t * GPT4O * 1000,
                                                "%.2f" % (g * FLASH * 1000) if g else "")
        print(line.rstrip())
PY

put shrink.py <<'PY'
"""The invoice, made smaller three ways: does Tesseract still read it, and what does each copy cost?"""
import io
import re
import subprocess
from collections import Counter

from tokens import gpt4o_tokens
from PIL import Image

truth = open("media/truth/invoice-0931.txt").read()
amounts = re.findall(r"\d+\.\d\d", truth)                  # the 11 money values on the page
page = Image.open("media/invoice-0931.png")


def read(data):
    return subprocess.run(["tesseract", "-", "-"], input=data, capture_output=True).stdout.decode()


def copy(img, fmt, **kw):
    buf = io.BytesIO()
    img.save(buf, fmt, **kw)
    return buf.getvalue()


print("%-26s %9s %7s %7s %8s" % ("copy", "bytes", "tokens", "words", "amounts"))
for name, short, fmt, kw in (("original png", 1240, "PNG", {}),
                             ("png, short side 768", 768, "PNG", {}),
                             ("jpeg q75, short side 768", 768, "JPEG", {"quality": 75}),
                             ("jpeg q75, short side 512", 512, "JPEG", {"quality": 75})):
    s = short / page.width
    img = page.resize((round(page.width * s), round(page.height * s)), Image.LANCZOS)
    data = copy(img.convert("RGB"), fmt, **kw) if short < 1240 else open("media/invoice-0931.png", "rb").read()
    tokens, _ = gpt4o_tokens(img.width, img.height, "high")
    text = read(data)
    found = sum((Counter(truth.split()) & Counter(text.split())).values()) / len(truth.split())
    print("%-26s %9d %7d %6.0f%% %5d/%d" % (name, len(data), tokens, 100 * found,
                                           sum(a in text for a in amounts), len(amounts)))
PY

put audio_sizes.py <<'PY'
"""One call in four encodings: the bytes, how many minutes fit under 25 MB, and what Whisper heard."""
import os
import subprocess

import jiwer
from openai import OpenAI

LIMIT = 25 * 1024 * 1024
truth = open("media/truth/call-1042.txt").read()
norm = jiwer.Compose([jiwer.ToLowerCase(), jiwer.RemovePunctuation(), jiwer.RemoveMultipleSpaces(),
                      jiwer.Strip(), jiwer.ReduceToListOfListOfWords()])
seconds = 55.38

print("%-24s %9s %10s %6s" % ("encoding", "bytes", "min/25MB", "WER"))
for name, args, ext in (("wav 16 kHz 16-bit", ["-ar", "16000", "-ac", "1"], "wav"),
                        ("mp3 64 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "64k"], "mp3"),
                        ("mp3 32 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "32k"], "mp3"),
                        ("opus 16 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "16k"], "ogg")):
    out = f"call.{name.split()[0]}{name.split()[1]}.{ext}"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/call-1042.wav", *args, out], check=True)
    size = os.path.getsize(out)
    with open(out, "rb") as f:
        heard = OpenAI(base_url="http://localhost:8700/v1").audio.transcriptions.create(
            model="whisper-base", file=f, response_format="text")
    wer = jiwer.wer(truth, heard, reference_transform=norm, hypothesis_transform=norm)
    print("%-24s %9d %10.0f %5.1f%%" % (name, size, LIMIT / size * seconds / 60, 100 * wer))
PY

put base64_size.py <<'PY'
"""How much bigger a picture gets on its way into a JSON request."""
import base64
import json
import sys

for path in sys.argv[1:]:
    raw = open(path, "rb").read()
    body = json.dumps({"model": "qwen2.5vl:3b", "messages": [{"role": "user", "content": [
        {"type": "text", "text": "Read the total."},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + base64.b64encode(raw).decode()}}]}]})
    print("%-22s file %9d   request %9d   x%.3f" % (path.split("/")[-1], len(raw), len(body), len(body) / len(raw)))
PY

put cached.py <<'PY'
"""Ask about a picture once; the second time, answer from disk. The key is everything that shapes the reply."""
import base64
import hashlib
import json
import os
import sys

from openai import OpenAI

CACHE = "cache"


def describe(path, prompt, model="qwen2.5vl:3b", detail="high"):
    raw = open(path, "rb").read()
    key = hashlib.sha256(json.dumps([hashlib.sha256(raw).hexdigest(), prompt, model, detail]).encode()).hexdigest()
    hit = os.path.join(CACHE, key + ".json")
    if os.path.exists(hit):
        return json.load(open(hit)), "cache"
    url = "data:image/png;base64," + base64.b64encode(raw).decode()
    r = OpenAI().chat.completions.create(model=model, messages=[{"role": "user", "content": [
        {"type": "text", "text": prompt}, {"type": "image_url", "image_url": {"url": url, "detail": detail}}]}])
    out = {"text": r.choices[0].message.content, "tokens": r.usage.prompt_tokens}
    os.makedirs(CACHE, exist_ok=True)
    json.dump(out, open(hit, "w"))
    return out, "provider"


for prompt in sys.argv[2:]:
    out, source = describe(sys.argv[1], prompt)
    print("%-8s %4d tokens  %s" % (source, out["tokens"], out["text"][:48]))
PY

put budget.py <<'PY'
"""A monthly allowance per user, in integer cents, checked BEFORE the call rather than after."""
from decimal import ROUND_CEILING, Decimal

PER_SECOND = Decimal("0.0001")   # sheet: whisper-1 input_cost_per_second, in dollars
ALLOWANCE = 50           # cents a user may spend in a month

spent = {"ana": 47}


def charge_cents(seconds):
    cents = Decimal(str(seconds)) * PER_SECOND * 100
    return int(cents.to_integral_value(rounding=ROUND_CEILING))   # UP: an estimate that undercharges is a leak


def transcribe(user, seconds):
    cost = charge_cents(seconds)
    if spent.get(user, 0) + cost > ALLOWANCE:
        return f"refused: {seconds} s costs {cost} cents and {user} has {ALLOWANCE - spent.get(user, 0)} left"
    spent[user] = spent.get(user, 0) + cost
    return f"sent: {seconds} s for {cost} cents, {user} has {ALLOWANCE - spent[user]} left"


for seconds in (55.38, 600, 1800):
    print(transcribe("ana", seconds))
PY

block prices
on 'python prices.py show gpt-4o | grep -E "^(input|output)_cost_per_token "'
on 'python prices.py show gemini/gemini-2.5-flash | grep -E "^(input_cost_per_token|input_cost_per_audio_token|output_cost_per_token) "'
on 'python prices.py show whisper-1 | grep -E "cost_per_second"'
on 'python prices.py show tts-1 | grep -E "cost_per_character"'
on 'python prices.py show gpt-image-1 | grep -E "^(input|output)_cost_per_(image_)?token "; python prices.py show high/1024-x-1024/gpt-image-1 | grep input_cost_per_image'

block phone
on 'python -c "from PIL import Image; Image.open(\"media/cat_and_dog.jpg\").resize((4032, 3024)).save(\"media/phone.jpg\", quality=90)"; stat -c "%s %n" media/phone.jpg'

block picture
on 'python picture_cost.py media/cover-b39.png media/invoice-0931.png media/phone.jpg'

block shrink
on 'python shrink.py'

block audio
lab serve audio
on 'python audio_sizes.py'

block base64
on 'python base64_size.py media/invoice-0931-scan.jpg media/phone.jpg'

block cache
on 'python cached.py media/invoice-0931.png "What is the total?" "What is the total?" "What is the total of this invoice?"'
on 'ls cache | wc -l'

block budget
on 'python -c "print(600 * 0.0001 * 100)"'
on 'python budget.py'
lab down
