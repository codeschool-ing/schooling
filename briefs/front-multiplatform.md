You are writing ONE course of the `code` school in codeschool-ing/schooling, end to end, and opening its pull request. Several sessions are doing this at the same time, one course each, on separate branches. The person who owns the repository speaks Portuguese: talk to them in Portuguese, write commit subjects and the PR body in Portuguese, and keep everything inside `content/` in English (source) plus `.pt` translations. They have NO local copy of the repository: never tell them to `cd` into a checkout, pull or run anything locally. Everything they do happens on GitHub.

THE COURSE: front-multiplatform (`co-stctzkdq`), `content/code/courses/front-multiplatform/`, designed by `docs/design/front-multiplatform.md`. Your branch is `claude/front-multiplatform`; push only there.

## Read before writing anything

1. `CLAUDE.md` (loaded for you): the rules. Pay special attention to Content, the vocabulary, translations, figures, `::: track` blocks (C-39), and the "Before pushing" list.
2. `docs/CONTENT.md` (the format), `docs/TEACHING.md` (the craft: prose, figures, spoken scripts, "Code that is demonstrated"), and `docs/EXERCISES.md` (what makes a question worth asking).
3. The design sheet `docs/design/front-multiplatform.md`. It is a claim that `tools/check-design` holds against what you write, so the ids, the lesson count against the topics, the section total and the exercise count must agree with it. A budget can be overrun; a fact cannot disagree.
4. At least one finished course of the same kind, read as the model, for structure, voice and honesty. Read the ones corrected this week for how the STUDENT gets their environment: `networks`, `sql-databases`, `testing-cicd`, `docker`, `warehouse-modeling` and `virtualization`. Their `lab.sh` and `captures.sh` beside the course prove the captures; their lessons show the student, inside the lesson, everything they need to build the same environment on their own machine.

## The frontend courses: one environment, and the fork kept honest

The owner chose the eight remaining courses of the `frontend` track as batch 14 on 2026-10-23. Four are the track's fork (`react-ts`, `angular`, `vue`, `svelte`; a student takes ONE), and four come after it (`front-quality`, `front-performance`, `front-delivery`, `front-multiplatform`; every student takes them).

1. **One environment for the whole track.** **Node v22.22.0** from the official tarball and the npm it ships, exactly as `javascript` installs it, with the same versions. Read `javascript`'s setup lesson first and reuse it. The student never installs Node twice, nor two versions of it. A tool the course adds (the framework's CLI, Vite, Vitest, Playwright, Lighthouse, Electron, Tauri and its Rust toolchain, Capacitor) is installed in that course, in a lesson before the first one that uses it, under the C-38 rules below, and **pinned to an exact version** in `package.json` (no `^`, no `~`, no `latest`). Use the current stable release reachable through the proxy. Say the version in the prose once, and keep a lockfile in the student's project.
2. **The browser is Chromium.** Playwright and anything that drives a browser use the Chromium at `/opt/pw-browsers` here, and the lesson tells the student how to get the same browser on their machine. Never run `playwright install` in the sandbox. A screenshot of a page the student builds is a capture like a terminal: rendered by the script, never drawn by hand.
3. **The four framework courses run at the same time and are equals.** Each builds its own small app across the course, and **the four apps are the same app**: same screens, same data, same behaviour. That way the last lesson of each, which looks at the other three, compares like with like. The app is a **study planner**. A student lists courses, opens one, adds sessions with a date and a duration, marks them done, and sees the week's total. The data is a small JSON file served by the framework's dev server, or by a tiny Node server that a lesson shows whole. No external API and no account anywhere. Each course decides its own internals, but not the app's screens or its data, so that a student switching course recognises everything but the code.
4. **The four `front-*` courses name no framework** (each sheet's flag says so). Their example is a **plain TypeScript app built with Vite**, no framework: the same study planner, written once, small, and grown across the four courses. `front-quality` lesson 1 builds it, or a short section in each `front-*` course gives it whole so that each course stands alone. Where a lesson must show one framework's way of doing something (the four meta-frameworks of `front-performance` lesson 2, for instance), it shows all four side by side, briefly and evenly, and never assumes the student took one in particular. These four sessions also run at the same time. **The plain app is fixed here** so they cannot drift:
   - Vite with the `vanilla-ts` template;
   - `src/main.ts`, `src/planner.ts` (pure functions: add a session, mark it done, total a week) and `src/view.ts` (the DOM);
   - `public/courses.json` with three courses and six sessions in October 2026;
   - `npm run dev` serves it on port 5173.

   Extend it as each course needs, and never rename what is already there.
5. **What cannot run here is said plainly, never faked.**
   - **No real hosting** (`front-delivery`). Build the site, serve the built files locally exactly as a static host would, and show each provider's own documented steps, marked as not run. Defer to `portfolio-project` lesson 15 for the free-tier walk-through (the sheet's flag 3), naming it by course and lesson.
   - **No Xcode and no Apple signing** (`front-multiplatform` lessons 3 and 14). Teach those from Apple's and Capacitor's documentation, marked as not run, and declare the boundary in lesson 1, as the sheet's flag 1 asks.
   - **The Android SDK, an emulator, Electron and Tauri builds:** try them. Electron and Tauri under `xvfb-run` may work. If one does not, mark it not run, and say in the PR exactly what failed.
   - **No store publication anywhere.** Teach the checklist and the review rules from the stores' documentation.
6. **Security in `front-quality` is the defender's side**, as `secure-code` (merged 2026-10-23) does it. A flaw is shown only in the student's own app, with a benign witness: an ordinary input that breaks the app and does nothing else. It is a failing test, followed at once by the fix and the passing test. No payload collection, no attack recipe. Read `secure-code` lessons 4, 7, 8 and 9 (escaping, XSS, CSP and CSRF) first. `frontend` does not reach `secure-code`, so explain each flaw in your own lesson and do not send the student there.
7. **Accessibility is this repository's own practice** (flag 2 of `front-quality`): WCAG 2.2 AA, axe, a keyboard path for every control, and the screen reader. Take the example from the student's app, and run axe with Playwright the way `tools/a11y-test` does.

## The student's machine is the lab (C-38, C-40)

Read the C-38 and C-40 rows of `docs/PLAN.md` and the paragraphs on them in `docs/CONTENT.md` before planning a single lesson.

- **The platform provides no machine, container or lab, and never will.** A course whose practice needs an environment teaches the student to build one, in a lesson early in the course, before the first one that asks them to type anything. That lesson gives three paths, installed, in a virtual machine and online. It recommends one and names the others, says what each costs the student's computer, and has a section on what to do when the setup fails. Never depend on one company's free tier.
- **What a lesson uses, the student is given inside the lesson.** A program the student runs is shown whole, or generated by a short program a lesson shows. A data set is small enough to paste, or generated the same way. An example project is built in the lessons. If an example does not fit, make the example smaller.
- **Your `lab.sh`, the `captures.sh` files and the course's `lab/` are yours, not the student's.** They prove each capture was run, and the student never receives them. The prose, the scripts, the questions and the exam never name them. `validate-content` refuses `lab.sh`, `captures.sh` and a path under the course's `lab/` in anything a student reads, fences included, and `tools/validate-content/lab-pending/` takes no new entries.
- **The script a lesson shows is the very file the capture runs.** Make `captures.sh` extract it from the lesson's `.md`, or compare the two byte for byte, so they cannot drift.
- **A course with nothing to install** (a course about people, process or strategy) says so in its first lesson, and names the tools the student will use (a spreadsheet, a text editor, a diagram tool) with free options.
- **If a lesson needs a language model**, the recommended path is a local `llama3.2:3b` run with Ollama (`briefs/retrofit-ai.md` on `origin/claude/wonderful-cray-nrgjb2` explains how), and every answer shown is a real capture.

## What "done" means, per course

- **Every lesson** in `course.json` `lessons`, in the order of `topics`, with ids that are the topic ids. Each lesson has a `lesson.json` (sections in order, each with an opaque `se-` id and a slug), a `.md` and a `.pt.md` per section, `exercises.json` and `exercises.pt.json`, and a `captures.sh` wherever a terminal appears. Stay near the sheet's section budget. Video sections carry their spoken script in `lesson.json` under `sections[].videos[].script`.
- **Ids are written, never derived.** Use Crockford base32 (no i, l, o or u), 8 characters, with the right prefix, and unique across the whole repository. Generate them and check for collisions with a grep before using them.
- **Captures are real.** Every command and every line of output in a fence was run, in the lab, by the capture script, and is pasted byte for byte. Anything staged (built by the lab rather than typed) is written in the script's header comment. A command you could not run is marked in the prose as not run. Never invent output, a version, a flag or a timing. Never disable TLS verification and never unset the proxy; if something needs the network, read `/root/.ccr/README.md` first.
- **The Portuguese translates prose and never the program.** Every fence in a `.pt.md` is byte-identical to the English fence at the same place. The notes of a `schooling-example` are prose. The one exception is a block labelled `localised` in both files, and never for a capture.
- **Consider `schooling-example` wherever code is demonstrated** (the note beside the code). This is a standing request from the owner.
- **No attack material.** Explain how things are defended, detected and verified, and never give a working recipe for harming a system you do not own. This matters most in anything about security.
- **A course exam of about 100 questions**, in `exam.json` and `exam.pt.json` beside `course.json`, about five per lesson and spread over the types (`quiz` mostly, plus `numeric`, `ordering`, `cloze`, `multiple-choice` and `matching`). Look at `content/code/courses/portfolio-project/exam.json` for the shape.
- **A natural-writing pass** (`.claude/skills/natural-writing`) over ALL the reading prose (`.md` and `.pt.md`) and ALL the spoken scripts in `lesson.json`. Apply the findings, then rerun the checkers.
- **Every check green:**
  ```sh
  export GOTOOLCHAIN=local
  go run ./tools/validate-content
  go run ./tools/check-exercises        # grep for your course: none of its lines may start with " - "
  go run ./tools/check-design
  go run ./tools/check-figures
  node tools/check-highlight/check-highlight.mjs content
  node tools/figure-fit/figure-fit.mjs
  ```
- **A render walk.** Migrate, load and start the API against a local Postgres. Sign up a student through the form (see `tools/lib/sign-up.mjs`), give them a subscription (`tools/a11y-test/bought.sql`, then set the subscription active), and open EVERY section of the course in both languages with Playwright (Chromium is at `/opt/pw-browsers`). Fail on raw markers (`:::`, triple backticks, `@@`), an empty body, a paywall, a figure count lower than the file's, or a page error. Screenshot a few sections and LOOK at them. Delete the walk script before committing.

## What the checkers will catch you on, learned the hard way

- `check-exercises` measures whether a question can be answered without the material. **The correct option must not be the longest (or any one length rank) in more than 45% of the questions**, and that is checked per lesson and for the exam, in EN and in PT separately. Vary the key's length rank on purpose, and lengthen or shorten distractors to do it.
- **Hedges** (EN: usually, often, can, may, tends to, generally, sometimes, typically; PT: geralmente, normalmente, pode, podem, costuma, às vezes…) must not sit only in the correct option. It matches whole words anywhere, including the `why` text and a date: "20 May" is a hedge. **Absolutes** (never, always, only, all, must, none, every, cannot, nothing; PT: nunca, sempre, só, todo, nada, deve, não pode…) must not sit only in wrong options.
- **A cloze hole is exactly `___`**, and a translated cloze carries its own `accept` list.
- **Fence labels** are plain triple backticks or a language the highlighter knows. `text` is not one. `$ ` works as a prompt for a transcript.
- **Figures** use only palette tokens that exist: `--amber`, `--ink`, `--panel`, `--paper`, `--paper-dim`, `--phosphor`, `--phosphor-dim`, `--scan`, `--wire` (and `--term-*` for a captured terminal). `figure-fit` fails on a label outside its box.
- **Every label drawn in the prose face in a figure is translated in the `.pt` figure**, or carries a `same` entry.
- **Reading prose sentences** have a median of about 19 words; **script sentences** about 13. Keep bold in the reading prose, as house style, and almost none in scripts. British spelling in English.
- **The CI "Links" job** follows relative Markdown links outside fences. A link inside a fence is ignored.

## Lab notes, from building five of these in this environment

- The sandbox allows `systemd-nspawn` machines and network namespaces. For Podman inside nspawn it took a unified cgroup hierarchy, a syscall filter and `pids_limit = 0`. Start background servers with `setsid … </dev/null &`, and kill them by pid, never with a `pkill` pattern that also matches your own shell.
- Keep the lab deterministic: fixed dates, fixed names and addresses from the documentation ranges, and TZ=America/Sao_Paulo. The lesson text quotes numbers the capture printed, so rerun the capture after any change to the lab and re-read every number in the prose.
- Your writable disk is a fixed allowance. Delete root filesystems and images you no longer need.

## Commits, PR and after

- Commit subjects in Portuguese. End commit messages and the PR body with the attribution lines your own session gives you. Never put a model identifier anywhere else in the repository or the PR.
- One PR for the course against `main`, title `front-multiplatform: …`, with the body in Portuguese. Use the structure of the recent course PRs (see #438 for the shape): Por quê, O que entra, O que o curso diz de si mesmo if relevant, and Como foi verificado, with real numbers.
- If the course needs a change outside `content/` (a checker, the loader, the interface), keep it minimal, put it in its own commit, and say so in the PR. Other sessions are writing courses at the same time, so do not reformat or reorganise shared files.
- After opening the PR, subscribe to its activity and drive it to green. A red check is yours to root-cause and fix. Never skip, disable or loosen a check to get green.

## Learned from the last batch

- **Commit and push to your branch after every finished lesson**, not at the end. The container is ephemeral and a session can stop on a usage limit for hours; what is pushed survives, what is only on disk may not.
- **If you stop on a usage limit**, the owner's main session will poke you to continue. Pick up from the last pushed lesson.
- **Models to read now include the recent ones**: `javascript` (the environment and the language), `html-css` and `web-fundamentals` (where the track starts), `portfolio-project` and `first-job` (where it ends), `secure-code` (merged 2026-10-23, for the defender's-side pattern), and the backend courses merged on 2026-10-22 (`node` above all). Also read the five networks-infra courses: `networks-addressing`, `networks-availability`, `networks-security`, `networks-automation` and `cloud`. They solved labs, captures and exams in this same environment.
- **A course that sits in several tracks** may need a sentence that is true for one track and false for another. Use a `::: track <slugs>` group with a `::: track *` passage (C-39; see `first-job` lessons 1, 12 and 14 for the shape), and only where the difference is real.
- **Anything a language model said is a capture like any other.** If a lesson shows a model's answer, it must be an answer a model actually gave, recorded by a script, with the model name and date in the script header. If no model API is reachable from the sandbox, do not invent replies: teach the technique with examples marked plainly as illustrative, written by the course and not by a model, and say so in the prose.
- **The platform gives the student no machine, container or lab.** Every course teaches the student to build their own practice environment on their own computer, a virtual machine or containers they create themselves, and every exercise and command in the course is done there. Write the lessons that way: setting the environment up is part of the course, explained step by step in the first lesson that needs it, and nothing assumes a machine we host. Your captures stay real: run them here, in an environment built exactly the way the lesson tells the student to build theirs, and keep the script that builds it beside `course.json` as the other courses do.
- **Eight sessions are writing the eight frontend courses at the same time**: `react-ts`, `angular`, `vue`, `svelte`, `front-quality`, `front-performance`, `front-delivery` and `front-multiplatform`. Do not wait for another one and do not write its material. Where yours must mention another, take what its design sheet in `docs/design/` says it teaches, and point at it by course and lesson number as the sheet numbers them. No `front-*` course may point at one of the four framework courses as something the student took.
- **Read the most recent courses as models too**: the ten from the last writing batch (`servers-cache`, `pipelines-etl`, `data-cleaning`, `visualization`, `data-storytelling`, `data-governance`, `process-management`, `architect-communication`, `threat-modeling`, `soc-response`) and the AI courses corrected this week (`prompt-engineering`, `rag`, `agents-mcp`, `llm-observability`).
- **Ask nothing you can decide from the brief and the docs.** A question to the owner stops the session for hours. If something is truly the owner's to decide, choose the conservative option, say so in the PR, and keep going.
- **Do not create other sessions.** Write the whole course in this one.
- **Security is taught from the defender's side**: how to recognise, detect, respond and prevent. No working exploit, no malware, no instructions for getting into a system.
