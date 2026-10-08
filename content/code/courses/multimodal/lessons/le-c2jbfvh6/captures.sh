#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of multimodal, as a script that
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
# shows in full. The invoice and its scan were drawn by lab/build_media.py, and
# the scan's damage (a turn of 1.8 degrees, a blur, noise and a JPEG at quality
# 45) is written there; media/truth/invoice-0931.txt is the text it was drawn
# from.
#
# Tesseract 5.3.4 and MediaPipe's EfficientDet-Lite0 are real models run on this
# machine. No vision-language model runs in this lesson.
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

put score.py <<'PY'
"""How far an OCR reading is from the truth: the character error rate, per setting."""
import subprocess
import sys

import jiwer

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())


def read(path, psm, lang):
    out = subprocess.run(["tesseract", path, "-", "--psm", psm, "-l", lang],
                         capture_output=True, text=True, check=True).stdout
    return " ".join(out.split())


for path in sys.argv[1:]:
    for psm, lang in (("3", "eng"), ("6", "eng"), ("6", "eng+por")):
        cer = jiwer.cer(TRUTH, read(path, psm, lang))
        print(f"{path:28} psm {psm}  {lang:8} CER {cer:6.1%}")
PY

put shrink.py <<'PY'
"""The clean invoice made smaller and smaller, and read each time."""
import subprocess

import jiwer
from PIL import Image

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())
page = Image.open("media/invoice-0931.png")
for width in (1240, 620, 413, 310):
    small = page.resize((width, round(page.height * width / page.width)), Image.LANCZOS)
    small.save(f"/tmp/invoice-{width}.png")
    out = subprocess.run(["tesseract", f"/tmp/invoice-{width}.png", "-", "--psm", "6"],
                         capture_output=True, text=True, check=True).stdout
    print(f"{width:5} px wide ({width * 150 // 1240:3} dpi)  CER {jiwer.cer(TRUTH, ' '.join(out.split())):6.1%}")
PY

put tidy.py <<'PY'
"""Two cures people reach for on a bad scan: make it bigger, and turn it straight."""
import subprocess

import jiwer
from PIL import Image

TRUTH = " ".join(open("media/truth/invoice-0931.txt").read().split())
scan = Image.open("media/invoice-0931-scan.jpg")
tries = {
    "as scanned": scan,
    "twice the size": scan.resize((scan.width * 2, scan.height * 2), Image.LANCZOS),
    "turned 1.8 degrees back": scan.rotate(-1.8, resample=Image.BICUBIC, fillcolor=255),
}
for name, img in tries.items():
    img.save("/tmp/try.png")
    out = subprocess.run(["tesseract", "/tmp/try.png", "-", "--psm", "6", "-l", "eng+por"],
                         capture_output=True, text=True, check=True).stdout
    print(f"{name:24} CER {jiwer.cer(TRUTH, ' '.join(out.split())):6.1%}")
PY

put doubt.py <<'PY'
"""Every word Tesseract read with less than 90% confidence, and where it is on the page."""
import csv
import io
import subprocess
import sys

lang = sys.argv[2] if len(sys.argv) > 2 else "eng+por"
tsv = subprocess.run(["tesseract", sys.argv[1], "-", "--psm", "6", "-l", lang, "tsv"],
                     capture_output=True, text=True, check=True).stdout
rows = list(csv.DictReader(io.StringIO(tsv), delimiter="\t", quoting=csv.QUOTE_NONE))
words = [r for r in rows if r["text"].strip()]
print(f"{len(words)} words")
for r in words:
    if float(r["conf"]) < 90:
        print(f"  {r['text']:14} conf {float(r['conf']):5.1f}  at x={r['left']:>4} y={r['top']:>4}")
PY

put extract.py <<'PY'
"""The invoice's lines and totals as data, and the arithmetic that checks them."""
import json
import re
import subprocess
import sys

lang = sys.argv[2] if len(sys.argv) > 2 else "eng+por"
text = subprocess.run(["tesseract", sys.argv[1], "-", "--psm", "6", "-l", lang],
                      capture_output=True, text=True, check=True).stdout
MONEY = r"(\d+[.,]\d\d)"


def cents(s):
    return int(s.replace(",", "").replace(".", ""))


lines, totals = [], {}
for row in text.splitlines():
    m = re.match(rf"(.+?) (\d+) {MONEY} {MONEY}$", row.strip())
    if m:
        lines.append({"title": m[1], "qty": int(m[2]), "unit": cents(m[3]), "amount": cents(m[4])})
        continue
    m = re.match(rf"(Subtotal|Shipping|Total BRL) {MONEY}$", row.strip())
    if m:
        totals[m[1]] = cents(m[2])

problems = [f"{x['title']}: {x['qty']} x {x['unit']} is not {x['amount']}"
            for x in lines if x["qty"] * x["unit"] != x["amount"]]
if sum(x["amount"] for x in lines) != totals.get("Subtotal"):
    problems.append(f"the lines add up to {sum(x['amount'] for x in lines)}, not {totals.get('Subtotal')}")
if totals.get("Subtotal", 0) + totals.get("Shipping", 0) != totals.get("Total BRL"):
    problems.append("subtotal and shipping do not make the total")
print(json.dumps({"lines": lines, "totals": totals}, ensure_ascii=False))
print("checks:", "; ".join(problems) or "every line and total agrees")
PY

put detect.py <<'PY'
"""Every object MediaPipe's detector reports above a threshold, with its box in pixels."""
import sys

import mediapipe as mp

import mmlab

threshold = float(sys.argv[1])
with mmlab.detector(score=threshold) as det:
    for path in sys.argv[2:]:
        found = det.detect(mp.Image.create_from_file(path)).detections
        print(f"{path}: {len(found)} above {threshold}")
        for d in found:
            c, b = d.categories[0], d.bounding_box
            print(f"  {c.category_name:10} {c.score:.2f}  x={b.origin_x} y={b.origin_y} w={b.width} h={b.height}")
PY

put ask.py <<'PY'
"""Ask the course's vision model one question about one picture, with the randomness turned down."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
kind = "png" if path.endswith(".png") else "jpeg"
picture = f"data:image/{kind};base64," + base64.b64encode(open(path, "rb").read()).decode()
reply = OpenAI().chat.completions.create(
    model="qwen2.5vl:3b", temperature=0, seed=1,
    messages=[{"role": "user", "content": [{"type": "text", "text": question},
                                           {"type": "image_url", "image_url": {"url": picture}}]}])
print(reply.choices[0].message.content)
PY

block psm3-clean
on 'tesseract media/invoice-0931.png - 2>/dev/null | sed -n "9,20p"'

block psm6-clean
on 'tesseract media/invoice-0931.png - --psm 6 2>/dev/null | sed -n "8,13p"'

block score
on 'python score.py media/invoice-0931.png media/invoice-0931-scan.jpg'

block scan-psm3
on 'tesseract media/invoice-0931-scan.jpg - 2>/dev/null | sed -n "/Qty/,/Total/p"'

block scan-psm6
on 'tesseract media/invoice-0931-scan.jpg - --psm 6 2>/dev/null | sed -n "6,16p"'

block scan-por
on 'tesseract media/invoice-0931-scan.jpg - --psm 6 -l eng+por 2>/dev/null | sed -n "6,16p"'

block shrink
on 'python shrink.py'

block tidy
on 'python tidy.py'

block doubt
on 'python doubt.py media/invoice-0931-scan.jpg'
on 'python doubt.py media/invoice-0931-scan.jpg eng | grep -E "15|222|713|words"'

block extract
on 'python extract.py media/invoice-0931.png'
on 'python extract.py media/invoice-0931-scan.jpg'
on 'python extract.py media/invoice-0931-scan.jpg eng | tail -1'

block detect
on 'python detect.py 0.3 media/cat_and_dog.jpg media/cover-b39.png media/invoice-0931.png 2>/dev/null'
on 'python detect.py 0.05 media/cat_and_dog.jpg media/cover-b39.png 2>/dev/null'

block labels
on 'unzip -p /opt/multimodal/share/efficientdet_lite0.tflite labels.txt | grep -vc "^???"'
on 'unzip -p /opt/multimodal/share/efficientdet_lite0.tflite labels.txt | grep -v "^???" | sed -n "62,76p" | tr "\n" " "; echo'

block vlm-cover
on 'python ask.py media/cover-b39.png "Describe this book cover."'
on 'python ask.py media/cover-b39.png "List every piece of text on the cover, exactly as written."'
