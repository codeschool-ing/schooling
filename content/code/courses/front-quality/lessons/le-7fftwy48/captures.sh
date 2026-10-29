#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 11 > out.txt
#
# It starts from the tag lesson-10 and leaves lesson-11. The test file and
# its additions are taken from the lesson's own listings by lab/extract.py;
# the corrected expectation and the three fixes are exact replacements, shown
# by `git diff`.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The dev server runs in the background, started by serve(), as from
#     another terminal.
#   - Playwright's report is filtered with grep to the lines the lesson reads:
#     each test's verdict and the lines of each failure that say why.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 10
F='2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"'
append() {   # append MD FILE: the "below what is there" listing of FILE in MD
  python3 "$FQ_LAB/extract.py" "$LESSON/$1" "$2, below what is there" | sed 1d | sed '1s/^/\n/' >> "$P/$2"
}

put the-walk.md e2e/keyboard.spec.ts $P/e2e/keyboard.spec.ts
serve 5173 $P 'npm run dev'
block walk-red
run $P "npx playwright test e2e/keyboard.spec.ts $F"
fix e2e/keyboard.spec.ts '  expect(await tabThrough(page, 6)).toEqual([
    "a ←",
    "button Done",
    "input date",' '  expect(await tabThrough(page, 9)).toEqual([
    "a ←",
    "button Done",
    "input date",
    "input date",
    "input date",
    "input date",'
block walk-green
run $P "npx playwright test e2e/keyboard.spec.ts $F"

append focus-visible.md e2e/keyboard.spec.ts
block outline-red
run $P "npx playwright test e2e/keyboard.spec.ts -g 'can be seen' $F"
fix src/style.css 'button:focus { outline: none; }' ':focus-visible { outline: 3px solid #2f6f4e; outline-offset: 2px; }'
block css-diff
run $P 'git diff src/style.css'
block outline-green
run $P "npx playwright test e2e/keyboard.spec.ts $F"

append lost-focus.md e2e/keyboard.spec.ts
block done-red
run $P "npx playwright test e2e/keyboard.spec.ts -g 'after Done' $F"
fix src/view.ts '    const item = el("li", `${s.date} · ${s.minutes} min `, s.done ? "session done" : "session");' '    const item = el("li", `${s.date} · ${s.minutes} min `, s.done ? "session done" : "session");
    item.dataset.session = String(s.id);
    item.tabIndex = -1;'
fix src/view.ts '      tick.addEventListener("click", () => update(markDone(plan, s.id)));' '      tick.addEventListener("click", () => {
        update(markDone(plan, s.id));
        root.querySelector<HTMLElement>(`[data-session="${s.id}"]`)?.focus();
      });'
block view-diff
run $P 'git diff src/view.ts'
block done-green
run $P "npx playwright test e2e/keyboard.spec.ts $F"

append navigation.md e2e/keyboard.spec.ts
block nav-red
run $P "npx playwright test e2e/keyboard.spec.ts -g 'link followed|first page' $F"
fix src/app.ts '  window.addEventListener("hashchange", draw);' '  window.addEventListener("hashchange", () => {
    draw();
    const heading = root.querySelector("h1");
    if (heading) {
      heading.tabIndex = -1;
      heading.focus();
    }
  });'
block app-diff
run $P 'git diff src/app.ts'
block nav-green
run $P "npx playwright test $F"
block commit
export GIT_AUTHOR_DATE='2026-10-24 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-24 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "Keyboard: a focus that can be seen, and that stays where it makes sense"'

append in-jsdom.md src/view.test.ts
block unit
run $P 'npx vitest run src/view.test.ts'
run $P 'git commit -qam "Test in jsdom that Done keeps the focus"'
unserve 5173
leave 11
