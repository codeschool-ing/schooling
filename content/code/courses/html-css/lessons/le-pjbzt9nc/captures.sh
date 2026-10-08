#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-pjbzt9nc are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site.
#
# THE PICTURES AND THE VIDEO ARE MADE BY THE PAGE THE LESSON SHOWS. pictures.html
# is taken out of the fence in alt-text.md, not out of a copy, opened in
# Chromium, and every link it offers is clicked and saved into ~/site, which is
# what the student does by hand. They are flat colour with their size written
# on them, so a screenshot says which file the browser chose. The fonts on
# another machine draw that size differently, so the byte counts in
# picture-element are this machine's, and the lesson says so.
# Every file is on disk, so no timing here is a network's: --hold-images is
# what keeps the pictures from arriving until the `release` step.
#
# Recorded 2026-10-07 on Ubuntu 24.04 with Node 22.22.0, Chromium 141 through
# Playwright 1.56.0, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="${HTML_CSS_LAB:-$HOME/.cache/html-css-lab}"
export PATH="$LAB/bin:$PATH"
[ -x "$LAB/bin/probe" ] || { echo "run lab.sh first" >&2; exit 1; }
# The lesson's pages, copied to where ana keeps her site.
SITE=/home/ana/site
rm -rf "$SITE" && mkdir -p "$SITE"
cp -r "$HERE/../../lab/pages/$(basename "$HERE")/." "$SITE/"
cd "$SITE" || exit 1
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/site$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# pictures.html, out of the lesson, and what it offers, saved the student's way.
awk '/`pictures\.html`/{p=1} p&&/^```html$/{f=1;next} f&&/^```$/{exit} f' "$HERE/alt-text.md" > pictures.html
[ -s pictures.html ] || { echo "no pictures.html fence in alt-text.md" >&2; exit 1; }
cat > "$LAB/save-pictures.mjs" <<'JS'
import { chromium } from 'playwright';
const [page_, out] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ acceptDownloads: true });
const page = await context.newPage();
await page.goto('file://' + page_);
await page.locator('#files a').nth(7).waitFor({ timeout: 15000 });
for (const link of await page.locator('#files a').all()) {
  const [download] = await Promise.all([page.waitForEvent('download'), link.click()]);
  await download.saveAs(out + '/' + download.suggestedFilename());
}
await browser.close();
JS
(cd "$LAB" && node save-pictures.mjs "$SITE/pictures.html" "$SITE") || { echo "pictures.html made nothing" >&2; exit 1; }

block hours
run 'probe hours.html tree'
block spans
run "probe spans.html box td box 'th[scope=row]'"
block alt
run 'probe alt.html tree axe'
block shift
run 'probe --hold-images shift.html box img box p release box img box p'
block srcset-narrow
run 'probe --width 360 --dpr 1 srcset.html img img'
run 'probe --width 360 --dpr 2 srcset.html img img'
run 'probe --width 360 --dpr 3 srcset.html img img'
block srcset-wide
run 'probe --width 1280 --dpr 1 srcset.html img img'
run 'probe --width 1280 --dpr 2 srcset.html img img'
block picture
run 'probe --width 390 picture.html img img'
run 'probe --width 1024 picture.html img img'
block formats
run 'probe formats.html img img'
run 'wc -c shelves-960.png shelves-960.webp'
block lazy
run 'probe lazy.html fetched box img'
run 'probe lazy.html scroll 2000 fetched'
run 'probe lazy.html scroll 6000 fetched'
block figure
run 'probe figure.html tree'
block video
run 'probe video.html fetched'
run 'probe video-metadata.html fetched'
