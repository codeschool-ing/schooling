#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 9 > out.txt
#
# It starts from the tag lesson-8 and leaves lesson-9. Tests and the two
# small scripts are taken from the lesson's own listings by lab/extract.py;
# the note feature, its fix, the Trusted Types experiment and the Origin
# check are exact replacements, shown by `git diff`.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - safeLink in dom-sinks.md is not a file of the project. It is checked
#     here, unprinted, with Node's own TypeScript stripping, against four
#     addresses, so the lines the lesson shows are known to work.
#   - The preview and dev servers run in the background, started by serve().
#   - The only markup used to show the flaw is <b>; no script is injected.
#   - The commits carry fixed dates, so their hashes repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 8
day() { export GIT_AUTHOR_DATE="2026-10-22 $1:00 -0300" GIT_COMMITTER_DATE="2026-10-22 $1:00 -0300"; }

fix src/planner.ts '  done: boolean;
}' '  done: boolean;
  note?: string;
}'
fix src/planner.ts 'export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {' 'export function addSession(plan: Plan, course: string, date: string, minutes: number, note = ""): Plan {'
fix src/planner.ts '  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };' '  const session = { id, course, date, minutes, done: false, ...(note ? { note } : {}) };
  return { ...plan, sessions: [...plan.sessions, session] };'
fix src/view.ts '      item.append(tick);
    }
' '      item.append(tick);
    }
    if (s.note) {
      const note = el("p", "", "note");
      note.innerHTML = s.note.replace(/\n/g, "<br>");
      item.append(note);
    }
'
fix src/view.ts '    <button>Add session</button>`;' '    <label>Note <textarea name="note"></textarea></label>
    <button>Add session</button>`;'
fix src/view.ts '    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes"))));' '    const note = String(data.get("note") ?? "");
    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes")), note));'
block feature
run $P 'git diff src/planner.ts src/view.ts'

python3 "$FQ_LAB/extract.py" "$LESSON/the-note.md" "src/view.test.ts, below what is there" | sed 1d | sed '1s/^/\n/' >> $P/src/view.test.ts
block red
run $P 'npx vitest run src/view.test.ts 2>&1 | grep -E -A3 "^ FAIL|Unable to find|class=\"note\""'
block commit-flawed
day 13:30
run $P 'git add -A'
run $P 'git commit -q -m "A note on each session"'

fix src/view.ts '      note.innerHTML = s.note.replace(/\n/g, "<br>");' '      note.textContent = s.note;'
printf '.note { white-space: pre-line; margin: 0.2rem 0 0; }\n' >> $P/src/style.css
block diff
run $P 'git diff'
block green
run $P 'npx vitest run src/view.test.ts'
block all
run $P 'npm run check 2>&1 | grep -E "Tests |[0-9] (passed|failed)"'
block commit
day 14:00
run $P 'git add -A'
run $P 'git commit -q -m "Write the note as text"'

# safeLink, checked and not printed.
python3 - "$LESSON/dom-sinks.md" > /var/tmp/front-quality-safelink.ts <<'PY'
import re, sys
code = re.search(r"```typescript\n(.*?)```", open(sys.argv[1]).read(), re.S).group(1)
print("const location = { href: 'http://localhost:5173/' };\n" + code +
      "const got = ['https://example.org/a', 'http://example.org/', 'javascript:alert(1)', '/courses.json'].map(safeLink);\n"
      "const want = ['https://example.org/a', 'http://example.org/', undefined, 'http://localhost:5173/courses.json'];\n"
      "if (JSON.stringify(got) !== JSON.stringify(want)) { console.error(got); process.exit(1); }")
PY
node --experimental-strip-types --no-warnings /var/tmp/front-quality-safelink.ts || { echo "safeLink does not do what the lesson says" >&2; exit 1; }

fix vite.config.ts "    \"frame-ancestors 'none'\"," "    \"frame-ancestors 'none'\",
    \"require-trusted-types-for 'script'\","
block tt-diff
run $P 'git diff vite.config.ts'
run $P 'npm run build > /dev/null'
serve 4173 $P 'npx vite preview --port 4173 --strictPort'
block tt-look
run $P "node server/look.mjs 'http://localhost:4173/#/course/javascript' 'document.querySelectorAll(\"form\").length'"
unserve 4173
block tt-undo
run $P 'git checkout vite.config.ts'
( cd $P && npm run build >/dev/null 2>&1 )

python3 "$FQ_LAB/extract.py" "$LESSON/csrf.md" "server/api.test.mjs, below what is there" | sed 1d | sed '1s/^/\n/' >> $P/server/api.test.mjs
block csrf-red
run $P 'npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError| Test Files|      Tests)"'
fix server/api.mjs 'const allowed = new Set(["http://localhost:5173"]);' 'const allowed = new Set(["http://localhost:5173", "http://localhost:4173"]);'
fix server/api.mjs '      return res.end();
    }
' '      return res.end();
    }
    const origin = req.headers.origin;
    if (req.method === "POST" && origin !== undefined && !allowed.has(origin)) {
      return send(res, 403, { error: "cross-site request refused" });
    }
'
block csrf-diff
run $P 'git diff server/api.mjs'
block csrf-green
run $P 'npx vitest run server/api.test.mjs'
block csrf-commit
day 14:30
run $P 'git add -A'
run $P 'git commit -q -m "Refuse a POST whose Origin is not the planner'"'"'s"'

put clickjacking.md e2e/frame.spec.ts $P/e2e/frame.spec.ts
block frame
run $P 'npx playwright test e2e/frame.spec.ts --reporter=list'
block frame-commit
day 15:00
run $P 'git add -A'
run $P 'git commit -q -m "Test that no other site can frame the built planner"'

block count
run $P 'npm ls --all --parseable | wc -l'
block audit
run $P 'npm audit'
leave 9
