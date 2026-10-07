You are writing ONE course of the `code` school in codeschool-ing/schooling, end to end, and opening its pull request. Several sessions are doing this at the same time, one course each, on separate branches. The person who owns the repository speaks Portuguese: talk to them in Portuguese, write commit subjects and the PR body in Portuguese, and keep everything inside `content/` in English (source) plus `.pt` translations. They have NO local copy of the repository: never tell them to `cd` into a checkout, pull or run anything locally. Everything they do happens on GitHub.

THE COURSE: soc-response (`co-1amdw8bz`), `content/code/courses/soc-response/`, designed by `docs/design/soc-response.md`. Your branch is `claude/soc-response`; push only there.

## Read before writing anything

1. `CLAUDE.md` (loaded for you): the rules. Pay special attention to Content, the vocabulary, translations, figures, `::: track` blocks (C-39), and the "Before pushing" list.
2. `docs/CONTENT.md` (the format), `docs/TEACHING.md` (the craft: prose, figures, spoken scripts, "Code that is demonstrated"), and `docs/EXERCISES.md` (what makes a question worth asking).
3. The design sheet `docs/design/soc-response.md`. It is a claim that `tools/check-design` holds against what you write, so the ids, the lesson count against the topics, the section total and the exercise count must agree with it. A budget can be overrun; a fact cannot disagree.
4. At least one finished course of the same kind, read as the model. `networks` is the closest for anything with a topology: its `lab.sh` beside `course.json` builds an office, an ISP and a small internet out of network namespaces, and every lesson's `captures.sh` reproduces its transcripts. Also look at `tech-support`, `virtualization` and `portfolio-project` (its `lab.sh` rebuilds a project's git history deterministically). Copy their structure, their voice and their honesty, and extend or fork their labs where yours needs more.

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
- One PR for the course against `main`, title `soc-response: …`, with the body in Portuguese. Use the structure of the recent course PRs (see #438 for the shape): Por quê, O que entra, O que o curso diz de si mesmo if relevant, and Como foi verificado, with real numbers.
- If the course needs a change outside `content/` (a checker, the loader, the interface), keep it minimal, put it in its own commit, and say so in the PR. Other sessions are writing courses at the same time, so do not reformat or reorganise shared files.
- After opening the PR, subscribe to its activity and drive it to green. A red check is yours to root-cause and fix. Never skip, disable or loosen a check to get green.

## Learned from the last batch

- **Commit and push to your branch after every finished lesson**, not at the end. The container is ephemeral and a session can stop on a usage limit for hours; what is pushed survives, what is only on disk may not.
- **If you stop on a usage limit**, the owner's main session will poke you to continue. Pick up from the last pushed lesson.
- **Models to read now include the five networks-infra courses merged last week**: `networks-addressing`, `networks-availability`, `networks-security`, `networks-automation` and `cloud`. They solved labs, captures and exams in this same environment.
- **A course that sits in several tracks** may need a sentence that is true for one track and false for another. Use a `::: track <slugs>` group with a `::: track *` passage (C-39; see `first-job` lessons 1, 12 and 14 for the shape), and only where the difference is real.
- **Anything a language model said is a capture like any other.** If a lesson shows a model's answer, it must be an answer a model actually gave, recorded by a script, with the model name and date in the script header. If no model API is reachable from the sandbox, do not invent replies: teach the technique with examples marked plainly as illustrative, written by the course and not by a model, and say so in the prose.
- **The platform gives the student no machine, container or lab.** Every course teaches the student to build their own practice environment on their own computer, a virtual machine or containers they create themselves, and every exercise and command in the course is done there. Write the lessons that way: setting the environment up is part of the course, explained step by step in the first lesson that needs it, and nothing assumes a machine we host. Your captures stay real: run them here, in an environment built exactly the way the lesson tells the student to build theirs, and keep the script that builds it beside `course.json` as the other courses do.
- **Ten sessions are writing ten courses at the same time**, one each: `servers-cache`, `pipelines-etl`, `data-cleaning`, `visualization`, `data-storytelling`, `data-governance`, `process-management`, `architect-communication`, `threat-modeling` and `soc-response`. If your course builds on one of them, do not wait for it and do not write its material. Take what its design sheet in `docs/design/` says it teaches, and point at it by course and lesson number as the sheet numbers them.
- **Read the most recent courses as models too**: `docker`, `kubernetes`, `statistics`, `warehouse-modeling`, `go`, `javascript`, `security-fundamentals`, `observability` and `iac`. They were written in this same environment in the last few days.
- **Do not create other sessions.** Write the whole course in this one.
- **Security is taught from the defender's side**: how to recognise, detect, respond and prevent. No working exploit, no malware, no instructions for getting into a system.
