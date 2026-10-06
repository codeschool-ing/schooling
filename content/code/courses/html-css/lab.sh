#!/usr/bin/env bash
# The machine every transcript in this course was recorded on.
#
# IT IS ONE LAPTOP AND ONE BROWSER. ana is building a small site in ~/site, and
# what this course needs that a laptop does not already have is a way to ask
# the browser what it did with a page, as text. That is lab/probe.mjs: it opens
# a page in Chromium and prints boxes, computed values, the accessibility tree
# and what a form sends. It answers the same questions DevTools answers when
# you click on an element, so a lesson can quote the answer instead of
# describing a screenshot.
#
#   bash lab.sh          # installs into ~/.cache/html-css-lab, once
#
# After it runs, three commands are on the PATH the captures use:
#
#   probe          lab/probe.mjs, against Chromium through Playwright
#   html-validate  the HTML checker of lesson 1
#   tailwindcss    the Tailwind CLI of lesson 13
#
# WHAT IS PINNED, because a different version prints different numbers:
#
#   playwright 1.56.0, which drives Chromium 141 (the build Playwright
#              downloads for that version, chromium-1194)
#   axe-core 4.13.0, the same version this repository's own a11y test uses
#   html-validate 11.16.2
#   tailwindcss and @tailwindcss/cli 4.3.3
#
# THE PAGES are in lab/pages/<lesson id>/, one directory per lesson, and every
# page a lesson shows is a file there that a student can open in a browser by
# double-clicking. Each lesson's captures.sh runs probe against them and prints
# the transcripts the lesson quotes. The pages fetch nothing from a network;
# probe answers anything that is not a file on disk with an empty response and
# lists it, which is how lesson 3 shows what a form would have sent.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Node 22.22.0, TZ=America/Sao_Paulo.
# The window is 1024×768 at a device pixel ratio of 1 unless a command says
# otherwise with --width, --height or --dpr.

set -euo pipefail
LAB="${HTML_CSS_LAB:-$HOME/.cache/html-css-lab}"
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$LAB/bin"
cat > "$LAB/package.json" <<'JSON'
{
  "name": "html-css-lab",
  "private": true,
  "type": "module",
  "dependencies": {
    "@tailwindcss/cli": "4.3.3",
    "axe-core": "4.13.0",
    "html-validate": "11.16.2",
    "playwright": "1.56.0",
    "tailwindcss": "4.3.3"
  }
}
JSON
(cd "$LAB" && npm install --no-audit --no-fund --loglevel=error)
cp "$HERE/lab/probe.mjs" "$LAB/probe.mjs"

cat > "$LAB/bin/probe" <<SH
#!/bin/sh
exec node "$LAB/probe.mjs" "\$@"
SH
chmod +x "$LAB/bin/probe"
ln -sf "$LAB/node_modules/.bin/html-validate" "$LAB/bin/html-validate"
ln -sf "$LAB/node_modules/.bin/tailwindcss" "$LAB/bin/tailwindcss"

# Chromium itself. Where PLAYWRIGHT_BROWSERS_PATH already holds the build this
# version wants, nothing is downloaded.
(cd "$LAB" && npx playwright install chromium >/dev/null 2>&1 || true)
echo "lab ready: PATH=$LAB/bin:\$PATH"
