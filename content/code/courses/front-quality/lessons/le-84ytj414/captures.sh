#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 3 > out.txt
#
# It starts from the tag lesson-2 and leaves lesson-3. Every file is taken
# from the lesson's own listings by lab/extract.py; the label fix is the
# change labels.md shows, applied by an exact replacement.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The `within` example of when-nothing-fits is not a file of the
#     project. It is run here, unprinted, inside a throwaway test, so the
#     lines the lesson shows are known to work, and then removed.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 2

block install
run $P 'npm install --save-exact -D @testing-library/dom@10.4.2 @testing-library/user-event@14.6.8 @testing-library/jest-dom@7.0.1'

put rewrite.md src/view.test.ts $P/src/view.test.ts
block red
run $P 'npx vitest run src/view.test.ts 2>&1 | head -n 30'

fix src/view.ts '  form.innerHTML = `<input name="date" type="date" placeholder="Date">
    <input name="minutes" type="number" placeholder="Minutes">
    <button>Add session</button>`;' '  form.innerHTML = `<label>Date <input name="date" type="date"></label>
    <label>Minutes <input name="minutes" type="number" min="1" max="600"></label>
    <button>Add session</button>`;'
block diff
run $P 'git diff src/view.ts'
block green
run $P 'npx vitest run src/view.test.ts'
block commit
export GIT_AUTHOR_DATE='2026-10-20 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-20 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "Label the form fields, and test by role and label"'

put user-event.md src/scratch.test.ts $P/src/scratch.test.ts
block scratch
run $P 'npx vitest run src/scratch.test.ts'
run $P 'rm src/scratch.test.ts'

put waiting.md src/app.ts $P/src/app.ts
put waiting.md src/main.ts $P/src/main.ts
put waiting.md src/app.test.ts $P/src/app.test.ts
block async
run $P 'npx vitest run src/app.test.ts'
run $P 'npx tsc --noEmit'

# The `within` lines of when-nothing-fits, checked and not printed.
python3 - "$LESSON/when-nothing-fits.md" > $P/src/within.test.ts <<'PY'
import re, sys
text = open(sys.argv[1]).read()
code = re.search(r"```typescript\n(.*?)```", text, re.S).group(1)
print('// @vitest-environment jsdom\nimport { expect, test } from "vitest";\nimport { screen, within } from "@testing-library/dom";\nimport "@testing-library/jest-dom/vitest";\nimport { render } from "./view";\nimport type { Plan } from "./planner";\nimport data from "../public/courses.json";\ntest("within", () => {\n  document.body.innerHTML = \'<div id="app"></div>\';\n  render(document.querySelector<HTMLElement>("#app")!, data as Plan, "2026-10-21", "", () => {});\n' + code + '});')
PY
( cd $P && npx vitest run src/within.test.ts >/dev/null 2>&1 ) || { echo "the within example failed" >&2; exit 1; }
rm $P/src/within.test.ts

block all
run $P 'npm test'
block commit2
export GIT_AUTHOR_DATE='2026-10-20 09:30:00 -0300' GIT_COMMITTER_DATE='2026-10-20 09:30:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "Start the app from a function a test can call"'
leave 3
