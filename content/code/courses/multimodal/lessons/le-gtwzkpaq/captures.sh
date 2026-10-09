#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of multimodal, as a script that
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
# NO IMAGE GENERATOR RUNS IN THIS LESSON. images_server.py, which the lesson
# prints whole, speaks OpenAI's Images API and returns a card that says no model
# drew it; what is real is the request, what the SDK sent, and what the server
# logged. lab.sh serve starts it from the fence in one-axis-at-a-time.md, as
# the student starts it in a second terminal. The noise in noise.py is real
# arithmetic on the course's cover, and Tesseract is the real Tesseract. Prices
# are LiteLLM's sheet at the commit prices.py pins.
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

put noise.py <<'PY'
"""What a diffusion model learns to undo: the cover, drowned in noise step by step."""
import subprocess

import numpy as np
from PIL import Image

T = 1000
betas = np.linspace(1e-4, 0.02, T)          # the linear schedule of the first diffusion papers
kept = np.cumprod(1 - betas)                 # how much of the picture survives after t steps

cover = np.asarray(Image.open("media/cover-b39.png").convert("L"), dtype=np.float32) / 127.5 - 1
noise = np.random.default_rng(39).standard_normal(cover.shape)
for t in (0, 50, 100, 200, 400, 999):
    a = kept[t]
    x = np.sqrt(a) * cover + np.sqrt(1 - a) * noise
    Image.fromarray(((x.clip(-1, 1) + 1) * 127.5).astype(np.uint8)).save(f"/tmp/noisy-{t}.png")
    words = subprocess.run(["tesseract", f"/tmp/noisy-{t}.png", "-", "--psm", "6"],
                           capture_output=True, text=True).stdout.split()
    title = "DOM CASMURRO" in " ".join(words)
    print(f"step {t:4}  picture {np.sqrt(a):5.1%}  noise {np.sqrt(1 - a):5.1%}  "
          f"Tesseract reads the title: {'yes' if title else 'no'}")
PY

put axes.py <<'PY'
"""A banner prompt as named parts, and a grid that changes one part at a time."""
import json
import sys

BASE = {
    "subject": "a stack of second-hand books on a café table",
    "medium": "watercolour illustration",
    "style": "loose brushwork, soft edges",
    "composition": "wide banner, books on the left third, empty space on the right",
    "light": "late afternoon sun from the left",
    "palette": "warm ochre and deep green",
}
TRIES = {
    "medium": ["watercolour illustration", "linocut print", "photograph, 35 mm lens"],
    "light": ["late afternoon sun from the left", "overcast daylight", "a single desk lamp at night"],
}


def prompt(parts):
    return ", ".join(parts[k] for k in BASE)


rows = [{"axis": "base", "value": "", "prompt": prompt(BASE)}]
for axis, values in TRIES.items():
    for v in values:
        if v != BASE[axis]:
            rows.append({"axis": axis, "value": v, "prompt": prompt(dict(BASE, **{axis: v}))})
json.dump(rows, open("grid.json", "w"), indent=1)
for r in rows:
    print(f"{r['axis']:7} {r['value'] or '(as above)':36} {len(r['prompt'])} characters")
print(rows[0]["prompt"], file=sys.stderr)
PY

put grid.py <<'PY'
"""Send every prompt in grid.json, twice, and keep each picture with what asked for it."""
import base64
import csv
import json
import os

from openai import OpenAI

client = OpenAI(base_url="http://localhost:8800/v1")   # the stand-in; OpenAI is https://api.openai.com/v1
os.makedirs("grid", exist_ok=True)
with open("grid/log.csv", "w", newline="") as f:
    log = csv.writer(f)
    log.writerow(["file", "axis", "value", "prompt"])
    for i, row in enumerate(json.load(open("grid.json"))):
        result = client.images.generate(model="gpt-image-1", prompt=row["prompt"], size="1536x1024", n=2)
        for k, image in enumerate(result.data):
            name = f"grid/{i:02}-{k}.png"
            open(name, "wb").write(base64.b64decode(image.b64_json))
            log.writerow([name, row["axis"], row["value"], row["prompt"]])
print(open("grid/log.csv").read().count("\n") - 1, "pictures,", len(os.listdir("grid")) - 1, "files")
PY

put stamp.py <<'PY'
"""A note written into a PNG, and what happens to it when the picture is edited."""
from PIL import Image, PngImagePlugin

card = Image.open("grid/00-0.png")
info = PngImagePlugin.PngInfo()
info.add_text("Source", "images_server stand-in, gpt-image-1, 2026-10-07")
card.save("stamped.png", pnginfo=info)
print("saved:  ", Image.open("stamped.png").text)

edited = Image.open("stamped.png").resize((768, 512))
edited.save("edited.png")
print("edited: ", Image.open("edited.png").text)
PY

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

block noise
on 'python noise.py'

block axes
on 'python axes.py'

block grid
lab serve images
on 'python grid.py'
on 'tail -n 2 images_server.log'

block stamp
on 'python stamp.py'

block price
on 'python prices.py show gemini/gemini-2.5-flash-image | grep -E "output_cost_per_image|deprecation|source"'
on 'python -c "print(round(0.039 * 4, 3), round(0.039 * 12, 3))"'
lab down
