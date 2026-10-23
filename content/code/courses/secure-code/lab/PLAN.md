# secure-code — the plan every writer follows

Course dir: `content/code/courses/secure-code/` (C below). Lesson 1 (`le-68g441zs`) is written,
checked and pushed: READ ALL OF IT FIRST (its .md, .pt.md, lesson.json, captures.sh,
`lab/figures/l01.py`, `/tmp/claude-0/sc/ex/l01.py`) and copy its voice, its shape and its tools.

## The settled facts (do not change)

- Language: Python 3 + Flask 3.1.3 + Jinja2 + SQLite (stdlib `sqlite3`) + pytest 9.1.1. Named on
  the first page (lesson 1 `one-language`). British English in EN, Brazilian Portuguese in PT.
- Story: Vereda Fisioterapia, four clinics in São Paulo, patient portal + staff console; ana is the
  developer. Patients: `lucia`, `rafael`, `marta` (add others by first name only). Staff: e.g.
  `bruno` (receptionist), `carla` (physiotherapist). Domains end `.example`. Dates in Nov 2026.
- Workspace: `~/sc` with `~/sc/.venv` (lesson 1 built it). EVERY LESSON = ONE FOLDER `~/sc/<name>`,
  a git repo of its own (`mkdir`, `cd`, `git init -b main` — a short line pointing at lesson 1),
  holding `app.py` (one small Flask app, inline templates with `render_template_string` so it is
  one file) and `test_app.py` (pytest, Flask test client, fixtures as in lesson 1). Other files only
  when the lesson needs them. Every file the student runs is printed WHOLE in the lesson (or as a
  whole file + a captured `git diff` of the fix). The fix is shown as a `git diff` capture, applied
  in captures.sh by an exact string replacement (see lesson 1).
- The loop in every lesson: test states the rule → red (pytest output shows the defect) → commit
  flawed → fix → `git diff` → green → commit. Not every section needs it, but every lesson's main
  flaw is shown this way.
- Apps listen on 127.0.0.1:5000 only. Never 0.0.0.0.
- Prompt in transcripts: `(.venv) ana@vm:~/sc/<folder>$` (printed by `run`).
- Extra packages (pin exact versions, install shown with `pip install --progress-bar off X==v`
  the first time a lesson needs one; before that block, captures.sh silently
  `pip uninstall -y X` so the install output is a first install): argon2-cffi 25.1.0,
  bcrypt 5.0.0, pip-audit 2.10.1, bandit 1.9.4, detect-secrets 1.5.0, ldap3 2.9.1,
  playwright 1.56.0 (its Chromium build 141.0.7390.37 is ALREADY at /opt/pw-browsers, which
  PLAYWRIGHT_BROWSERS_PATH points at; so `playwright install chromium` is shown in the lesson as a
  step the student runs and marked NOT RUN in the recording, and the header of captures.sh says
  so). SQLAlchemy if lesson 5 wants it: pin the current 2.0.x from PyPI.

## Folder names (unique, one per lesson)

| # | id | folder |
|---|---|---|
| 1 | le-68g441zs | cancel (done) |
| 2 | le-25cfsy7p | booking |
| 3 | le-yhfav3b0 | signup |
| 4 | le-bfgmmaet | profile |
| 5 | le-bp3ghn71 | search |
| 6 | le-zszn64bg | exams-convert (command, LDAP and template injection; may use more than one file) |
| 7 | le-avwxys9x | messages |
| 8 | le-xf83y36w | csp |
| 9 | le-v4x3d52j | csrf |
| 10 | le-jwdn0rpj | sessions |
| 11 | le-vh4r25c9 | passwords |
| 12 | le-mejv15jv | console |
| 13 | le-8mzfjgd0 | exams |
| 14 | le-1v7r1m1r | upload |
| 15 | le-yjgqx8gk | errors |
| 16 | le-xnq72q6s | secrets |
| 17 | le-v1dk6m5z | deps |
| 18 | le-h49g40vt | review |
| 19 | le-1jck8793 | checks |
| 20 | le-aw4sxnj6 | asvs |

## Shape of a lesson

- 6 to 7 sections (budget ~129 for 20 lessons; lesson 1 has 8): `intro` (video, 60–90 s script
  with `{{cue}}` marks, short spoken sentences, median ~13 words, no bold), 4–5 `reading`
  sections, `drill` (practice; its .md is front matter only: "Putting it together" /
  "Juntando tudo").
- Reading sections: lead with the shape; name the wrong idea first; concrete instances; bold
  signposts (house style, ~15 per 1000 words); median sentence ~19 words; British spelling;
  forward references as "lesson N". Headings in sentence case.
- 2–4 figures per lesson where they earn their place (sequence, boundary, count, two axes), drawn
  with `lab/fig.py` from `lab/figures/lNN.py` in both languages. The sheet asks for: escaping by
  context shown four ways (l4), a CSRF token flow (l9), a session lifecycle (l10), an IDOR drawn as
  two requests (l13). Look at every figure with `node tools/figure-shot/figure-shot.mjs FILE.md IDX
  /tmp/claude-0/sc/<name>` and the Read tool.
- Consider `schooling-example` wherever a program is walked through piece by piece (the owner
  asks for it). Notes are prose and translate; code is identical (blocks.py guarantees it).
- `::: track devsecops` / `::: track security` / `::: track *` only where a sentence truly differs
  (e.g. what comes next in the track). security: … git, secure-code, networks-security,
  defense-hardening, soc-response, cloud, cloud-security, python … (no threat-modeling, no
  secure-pipeline). devsecops: … secure-code, threat-modeling, docker, kubernetes, testing-cicd,
  secure-pipeline …
- Exercises: ~22–28 per lesson, attached to the reading sections and the drill; mostly `quiz`,
  plus `multiple-choice`, `ordering`, `matching`, `cloze`, `numeric` (numbers from captures).
  Written with `/tmp/claude-0/sc/exgen.py` in `/tmp/claude-0/sc/ex/lNN.py` (see l01.py).
  check-exercises rules: the key's length rank ≤45% at ANY one rank, per lesson, EN and PT
  separately (use `ranks()` in exgen); hedges (EN usually/often/can/may/tends to/generally/
  sometimes/typically/frequently; PT pode/podem/geralmente/normalmente/costuma/às vezes…) must not
  sit only in the correct option INCLUDING its `why`; the key must not echo the prompt's long
  words more than other options; a cloze must not accept a word of its own prompt (3+ letters,
  inside backticks excepted); key position not >60% in one place; no "all/none of the above".
  Every `why` written, including the correct one's.

## The tools (all exist)

- `C/lab/capture-lib.sh` — sourced by every `captures.sh`: `run DIR 'cmd'`, `block NAME`,
  `put MD FILE [N] DEST` (extracts the listing the lesson prints: a `schooling-example` with that
  `file`, or a plain fence whose first line is `# FILE` / `<!-- FILE -->` / `// FILE`),
  `serve DIR 'cmd'` + `unserve` (port 5000, locked across lessons), `fresh_repo DIR`,
  `commit DIR 'YYYY-MM-DD HH:MM' 'msg'`. `VENV=1` default. pip commands take a lock.
- `C/lab/fill.py LESSON_DIR OUT` pastes blocks into fences whose body is `@@name@@` (and refreshes
  transcript fences by their first line); `--check` must pass before committing.
- `C/lab/blocks.py LESSON_DIR C/lab/figures/lNN.py` writes figures (`@@fig NAME@@` placeholder
  fences or existing data-fig) and annotated examples (`@@ex@@` placeholder fences, Kth example of
  a section = Kth entry of EXAMPLES[section]).
- `C/lab/syncfences.py LESSON_DIR` copies every plain/code fence of X.md into X.pt.md (write the
  PT fences as "```\n@@\n```" placeholders, same count and order).
- `/tmp/claude-0/sc/newid.py PREFIX N` — fresh repo-unique ids (se, vd, ex).
- `/tmp/claude-0/sc/add-lesson.py LESSON_ID` — inserts it into course.json `lessons` (locked).
- `. /tmp/claude-0/goenv.sh` before any `go run` (Go 1.25.1, GOTOOLCHAIN=local).
- Run captures: `bash C/lessons/<id>/captures.sh > /tmp/claude-0/sc/lNN.out` (it re-execs inside
  a mount namespace where /home/ana is the lab home).

## The order of work, per lesson

1. Plan sections; ids with newid.py; write `lesson.json`.
2. EN `.md` files with `@@name@@` capture fences, `@@fig NAME@@` figure fences, `@@ex@@` example
   fences; `lab/figures/lNN.py` (figures + EXAMPLES); `captures.sh` (header says what is staged).
3. `python3 lab/blocks.py …`, run captures, `python3 lab/fill.py …`; read the output and make the
   prose agree with every number and message it quotes.
4. PT `.pt.md` (prose translated; fences as placeholders) → syncfences → blocks → fill → `--check`.
5. Exercises (EN+PT) via exgen; balance ranks.
6. `add-lesson.py`; then `go run ./tools/validate-content`, `go run ./tools/check-exercises |
   grep secure-code` (no line about your lesson may start with " - "), `go run
   ./tools/check-figures`, `node tools/check-highlight/check-highlight.mjs content`, `node
   tools/figure-fit/figure-fit.mjs`, `go run ./tools/check-design | grep secure-code`.
7. Natural-writing pass over your prose and scripts (`.claude/skills/natural-writing/SKILL.md`).
8. Commit ONLY your paths: `git add C/lessons/<id> C/lab/figures/lNN.py C/course.json` then
   `git commit -m "secure-code: aula N, <assunto em português>" -m "<attribution lines>"` (retry
   if `index.lock` exists), then `git push origin claude/secure-code` (retry on rejection with
   `git pull --rebase origin claude/secure-code` only if needed). One commit per finished lesson.

## Hard rules

- Never run lesson 1's captures.sh, never delete `/var/tmp/secure-code-home/ana/sc` or its
  `.venv`; other writers run captures at the same time. Touch only your lessons' folders in the
  lab and your files in the repo (plus course.json through add-lesson.py).
- Defender's side only, as the brief says: a flaw is shown in the student's own app by a failing
  test, then fixed at once, with the test that now passes.
- Every command and output in a fence was run by captures.sh and pasted by fill.py. A command not
  run is said so in prose. Never invent output, versions, flags or timings. No `text` fence label
  (use plain ``` or a known language: python, html, sh, json, sql, javascript, ini, yaml…).
- Never name `lab.sh`, `captures.sh` or a path under the course's `lab/` in anything a student
  reads.
- `.pt.md` fences byte-identical to the `.md` (syncfences/blocks handle it).
- Do not edit shared files other than course.json via add-lesson.py. If you think a shared tool in
  `C/lab/` needs a change, make the smallest change and say so in your report.
