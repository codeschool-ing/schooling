#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of multimodal, as a script that
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
# NO IMAGE MODEL RUNS IN THIS LESSON. labmm's lab-image-1 speaks OpenAI's
# Images API and lab-flash-image speaks the Gemini API, and both return cards
# that say no model drew them; the text part of a Gemini reply is labmm's own
# sentence saying it has no rule for the request. Their error messages are
# labmm's, modelled on the providers' and not copied from them. What is real:
# the openai and google-genai SDKs and what they sent, Pillow, and the prices
# and dates in LiteLLM's sheet at the commit lab.sh pins. The Gemini commands
# send stderr to /dev/null, where google-genai prints a warning about automatic
# function calling that has nothing to do with images.
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

put banner.py <<'PY'
"""Ask the Images API for one banner and keep it, with a record of what asked for it."""
import base64
import json
import sys
from datetime import datetime

from openai import OpenAI
from PIL import Image

PROMPT = ("a stack of second-hand books on a café table, watercolour illustration, loose brushwork, "
          "wide banner, books on the left third, empty space on the right")
size = sys.argv[1] if len(sys.argv) > 1 else "1536x1024"
client = OpenAI()
try:
    result = client.images.generate(model="lab-image-1", prompt=PROMPT, size=size, quality="medium",
                                    output_format="png", n=1)
except Exception as e:
    sys.exit(f"{type(e).__name__}: {e}")
raw = base64.b64decode(result.data[0].b64_json)
open("banner.png", "wb").write(raw)
json.dump({"model": "lab-image-1", "prompt": PROMPT, "size": size, "quality": "medium",
           "made": datetime.now().isoformat(timespec="seconds"), "approved_by": None},
          open("banner.json", "w"), indent=1)
print(f"banner.png: {len(raw):,} bytes, {Image.open('banner.png').size[0]}x{Image.open('banner.png').size[1]}")
PY

put mask.py <<'PY'
"""A mask for the edits endpoint: opaque where the picture stays, transparent where it may change."""
from PIL import Image, ImageDraw

banner = Image.open("banner.png")
w, h = banner.size
mask = Image.new("RGBA", (w, h), (0, 0, 0, 255))
ImageDraw.Draw(mask).rectangle([w * 2 // 3, 0, w, h], fill=(0, 0, 0, 0))
mask.save("mask.png")
wrong = Image.new("RGBA", (1024, 1024), (0, 0, 0, 255))
wrong.save("mask-wrong-size.png")
print("mask.png", mask.size, mask.mode, "| mask-wrong-size.png", wrong.size)
PY

put edit.py <<'PY'
"""Repaint only the masked part of the banner."""
import base64
import sys

from openai import OpenAI

client = OpenAI()
try:
    result = client.images.edit(model="lab-image-1", image=open("banner.png", "rb"), mask=open(sys.argv[1], "rb"),
                                prompt="the same café table, with a small pot of basil on the right")
except Exception as e:
    print(type(e).__name__, e)
else:
    open("banner-edited.png", "wb").write(base64.b64decode(result.data[0].b64_json))
    print("banner-edited.png written")
PY

put nano.py <<'PY'
"""Gemini's image model: words in, and a picture and words out, in one call."""
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()
reply = client.models.generate_content(
    model="lab-flash-image",
    contents=["A poster for a second-hand book fair in a library courtyard, warm afternoon light"],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
)
for part in reply.candidates[0].content.parts:
    if part.inline_data:
        open("poster.png", "wb").write(part.inline_data.data)
        print("image:", part.inline_data.mime_type, len(part.inline_data.data), "bytes", Image.open("poster.png").size)
    elif part.text:
        print("text: ", part.text)
u = reply.usage_metadata
print(f"tokens in {u.prompt_token_count}, out {u.candidates_token_count}")
PY

put nano_edit.py <<'PY'
"""The same model with a picture in the request: an edit described in words, with no mask."""
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client()
reply = client.models.generate_content(
    model="lab-flash-image",
    contents=[Image.open("media/cover-b39.png"), "Make the moon a thin crescent and keep everything else."],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
)
u = reply.usage_metadata
images = [p for p in reply.candidates[0].content.parts if p.inline_data]
print(f"{len(images)} image back; tokens in {u.prompt_token_count}, out {u.candidates_token_count}")
PY

put price.py <<'PY'
"""What one accepted banner costs, from the sheet's per-image prices, when one in four is accepted."""
PRICES = {"gpt-image-1, low": 0.011, "gpt-image-1, medium": 0.042, "gpt-image-1, high": 0.167,
          "gemini-2.5-flash-image": 0.039, "gemini-3.1-flash-image": 0.045}
for name, each in PRICES.items():
    print(f"{name:24} ${each:.3f} each   ${each * 4:.3f} per accepted   ${each * 4 * 52:6.2f} for a year of weekly banners")
PY

block generate
on 'python banner.py'
on 'python banner.py 1792x1024'
on 'cat banner.json; echo'

block edit
on 'python mask.py'
on 'python edit.py mask.png'
on 'python edit.py mask-wrong-size.png'
on 'python edit.py banner.png'

block nano
on 'python nano.py 2>/dev/null'

block nano-edit
on 'python nano_edit.py 2>/dev/null'

block sheet-openai
on 'sheet provider openai --mode image_generation | grep -vE "^(low|medium|high|standard|[0-9])" '
on 'sheet show gpt-image-1 | grep -E "deprecation|supported_endpoints"'
on 'for q in low medium high; do printf "%-7s" $q; sheet show $q/1024-x-1024/gpt-image-1 | grep input_cost_per_image; done'

block sheet-gemini
on 'sheet where flash-image | grep -E "^(gemini|vertex_ai)/"'
on 'for m in gemini/gemini-2.5-flash-image gemini/gemini-3.1-flash-image; do echo "$m"; sheet show $m | grep -E "output_cost_per_image |deprecation"; done'

block price
on 'python price.py'
