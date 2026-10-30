#!/usr/bin/env bash
# Every checker the brief names, with the course's own lines picked out.
cd /home/user/schooling
export PATH=/usr/local/go1.25.1/bin:$PATH GOTOOLCHAIN=local
echo "== validate-content"; go run ./tools/validate-content 2>&1 | tail -15
echo "== check-exercises"; go run ./tools/check-exercises 2>&1 | grep -E "mobile-offline" | grep -E "^ - |exam" ; true
echo "== check-design"; go run ./tools/check-design 2>&1 | grep -iE "mobile-offline|refuse|problem" | head; true
echo "== check-figures"; go run ./tools/check-figures 2>&1 | tail -5
echo "== check-highlight"; node tools/check-highlight/check-highlight.mjs content 2>&1 | tail -3
echo "== figure-fit"; PLAYWRIGHT_BROWSERS_PATH=/var/tmp/pwb node tools/figure-fit/figure-fit.mjs content/code/courses/mobile-offline 2>&1 | tail -5
