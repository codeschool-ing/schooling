#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 13 > out.txt
#
# It starts from the tag lesson-12 and leaves lesson-13. src/contrast.ts, the
# stylesheet and the tests are taken from the lesson's own listings by
# lab/extract.py; every other change is an exact replacement, shown by
# `git diff`.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The dev server runs in the background, started by serve(), as from
#     another terminal.
#   - Playwright's report is filtered with grep to the lines the lesson reads:
#     each test's verdict and the lines of each failure that say why.
#   - The commits carry a fixed date, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 12
F='2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"'
append() {   # append MD FILE: the "below what is there" listing of FILE in MD
  python3 "$FQ_LAB/extract.py" "$LESSON/$1" "$2, below what is there" | sed 1d | sed '1s/^/\n/' >> "$P/$2"
}

put contrast.md src/contrast.ts $P/src/contrast.ts
put contrast.md src/contrast.test.ts $P/src/contrast.test.ts
block math-green
run $P "npx vitest run src/contrast.test.ts"

put dark-theme.md src/style.css $P/src/style.css
put dark-theme.md e2e/palette.spec.ts $P/e2e/palette.spec.ts
serve 5173 $P 'npm run dev'
block pairs-red
run $P "npx playwright test e2e/palette.spec.ts $F"
fix e2e/a11y.spec.ts 'for (const [name, address] of pages) {
  test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
    await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
    await page.goto(address);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
    expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
  });
}' 'for (const colorScheme of ["light", "dark"] as const) {
  test.describe(`${colorScheme} theme`, () => {
    test.use({ colorScheme });
    for (const [name, address] of pages) {
      test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
        await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
        await page.goto(address);
        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
        const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
        expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
      });
    }
  });
}'
block scheme-diff
run $P 'git diff e2e/a11y.spec.ts'
block axe-red
run $P "npx playwright test e2e/a11y.spec.ts $F"
fix src/style.css '    --page: #161616;' '    --page: #161616;
    --link: #6fc596;'
block link-diff
run $P "sed -n '/prefers-color-scheme: dark/,/^}/p' src/style.css"
block dark-green
run $P "npx playwright test e2e/palette.spec.ts e2e/a11y.spec.ts $F"
export GIT_AUTHOR_DATE='2026-10-26 08:30:00 -0300' GIT_COMMITTER_DATE='2026-10-26 08:30:00 -0300'
run $P 'git add -A && git commit -qm "A dark theme, its palette and its pages tested in both schemes"'

put target-size.md e2e/display.spec.ts $P/e2e/display.spec.ts
block target-red
run $P "npx playwright test e2e/display.spec.ts $F"
fix src/style.css '.tick { font-size: 0.7rem; padding: 1px 4px; }' '.tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }'
block target-diff
run $P 'git diff src/style.css'
block target-green
run $P "npx playwright test e2e/display.spec.ts $F"
export GIT_AUTHOR_DATE='2026-10-26 08:40:00 -0300' GIT_COMMITTER_DATE='2026-10-26 08:40:00 -0300'
run $P 'git add -A && git commit -qm "A Done button at least 24 pixels square"'

append reduced-motion.md e2e/display.spec.ts
block motion-red
run $P "npx playwright test e2e/display.spec.ts -g 'reduced motion' $F"
fix src/style.css '.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }' '.week { font-weight: bold; }
@media (prefers-reduced-motion: no-preference) {
  .week { animation: pulse 1s ease-in-out 3; }
}'
block motion-diff
run $P 'git diff src/style.css'
block motion-green
run $P "npx playwright test e2e/display.spec.ts $F"
export GIT_AUTHOR_DATE='2026-10-26 08:50:00 -0300' GIT_COMMITTER_DATE='2026-10-26 08:50:00 -0300'
run $P 'git commit -qam "No pulse for somebody who asked for less motion"'

append reflow.md e2e/display.spec.ts
block reflow-red
run $P "npx playwright test e2e/display.spec.ts -g '320' $F"
fix src/style.css '.add { display: flex; gap: 0.5rem; margin: 1rem 0; }' '.add { display: flex; flex-wrap: wrap; gap: 0.5rem; margin: 1rem 0; }'
block reflow-diff
run $P 'git diff src/style.css'
block reflow-green
run $P "npx playwright test e2e/display.spec.ts $F"
fix src/style.css '.tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }' 'button { min-width: 24px; min-height: 24px; }
.tick { font-size: 0.7rem; padding: 2px 8px; }'
block floor-diff
run $P 'git diff src/style.css'
block floor-green
run $P "npx playwright test e2e/display.spec.ts $F"

block all
run $P 'npx tsc --noEmit && npx vitest run 2>&1 | grep -E "Test Files|Tests "'
run $P "npx playwright test 2>&1 | tail -1"
unserve 5173
block commit
export GIT_AUTHOR_DATE='2026-10-26 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-26 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "A page that reflows at 320 pixels, and a size floor for every button"'
run $P 'git log --oneline | wc -l'
leave 13
