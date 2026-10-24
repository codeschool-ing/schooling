#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 12 > out.txt
#
# It starts from the tag lesson-11 and leaves lesson-12. server/tree.mjs and
# the tests are taken from the lesson's own listings by lab/extract.py; every
# change to an existing file is an exact replacement, shown by `git diff`.
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
resume 11
F='2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"'
append() {   # append MD FILE: the "below what is there" listing of FILE in MD
  python3 "$FQ_LAB/extract.py" "$LESSON/$1" "$2, below what is there" | sed 1d | sed '1s/^/\n/' >> "$P/$2"
}
TREE="node server/tree.mjs 'http://localhost:5173/#/course/javascript'"

put the-tree.md server/tree.mjs $P/server/tree.mjs
serve 5173 $P 'npm run dev'
block tree-before
run $P "node server/tree.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'"

put names.md e2e/screen-reader.spec.ts $P/e2e/screen-reader.spec.ts
block names-red
run $P "npx playwright test e2e/screen-reader.spec.ts $F"
fix src/view.ts '  const back = el("a", "←", "back");' '  const back = el("a", " All courses", "back");
  const arrow = el("span", "←");
  arrow.setAttribute("aria-hidden", "true");
  back.prepend(arrow);'
block back-diff
run $P 'git diff src/view.ts'
block names-green
run $P "npx playwright test e2e/screen-reader.spec.ts e2e/keyboard.spec.ts $F"
fix e2e/keyboard.spec.ts '  expect(await tabThrough(page, 9)).toEqual([
    "a ←",' '  expect(await tabThrough(page, 9)).toEqual([
    "a ← All courses",'
block walk-again
run $P "npx playwright test e2e/screen-reader.spec.ts e2e/keyboard.spec.ts $F"

fix server/axe.mjs 'new AxeBuilder({ page }).withTags(wcag22aa)' 'new AxeBuilder({ page }).withTags(process.env.AXE_TAGS?.split(",") ?? wcag22aa)'
block tags-diff
run $P 'git diff server/axe.mjs'
block bp-before
run $P "AXE_TAGS=best-practice node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'"
append landmarks.md e2e/screen-reader.spec.ts
block main-red
run $P "npx playwright test e2e/screen-reader.spec.ts -g 'main landmark' $F"
fix index.html '    <div id="app"></div>' '    <main>
      <div id="app"></div>
    </main>'
block main-diff
run $P 'git diff index.html'
block bp-after
run $P "AXE_TAGS=best-practice node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'"
block main-green
run $P "npx playwright test e2e/screen-reader.spec.ts $F"

append live-regions.md e2e/screen-reader.spec.ts
block status-red
run $P "npx playwright test e2e/screen-reader.spec.ts -g 'says so' $F"
fix src/view.ts 'update: (next: Plan) => void' 'update: (next: Plan, said?: string) => void'
fix src/view.ts '    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes")), note));' '    const date = String(data.get("date"));
    const minutes = Number(data.get("minutes"));
    update(addSession(plan, course.id, date, minutes, note), `Session added: ${date}, ${minutes} min`);
    root.querySelector<HTMLInputElement>(`input[name="date"]`)?.focus();'
fix src/app.ts '  let plan: Plan = await response.json();
  const draw = (): void =>
    render(root, plan, today(), location.hash, (next) => {
      plan = next;
      draw();
    });
  window.addEventListener("hashchange", () => {
    draw();' '  let plan: Plan = await response.json();
  const status = document.createElement("p");
  status.setAttribute("role", "status");
  root.after(status);
  const draw = (): void =>
    render(root, plan, today(), location.hash, (next, said = "") => {
      plan = next;
      draw();
      status.textContent = said;
    });
  window.addEventListener("hashchange", () => {
    status.textContent = "";
    draw();'
block status-diff
run $P 'git diff src'
block status-green
run $P "npx playwright test e2e/screen-reader.spec.ts $F"

block tree-after
run $P "$TREE"
append the-snapshot.md e2e/screen-reader.spec.ts
block snapshot-green
run $P "npx playwright test e2e/screen-reader.spec.ts $F"
block all
run $P 'npx tsc --noEmit && npx vitest run 2>&1 | grep -E "Test Files|Tests "'
run $P "npx playwright test 2>&1 | tail -1"
unserve 5173
block commit
export GIT_AUTHOR_DATE='2026-10-25 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-25 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "What a screen reader is told: a named back link, a main landmark, a status line"'
leave 12
