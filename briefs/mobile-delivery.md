You are writing ONE course of the `code` school in codeschool-ing/schooling, end to end, and opening its pull request. Several sessions are doing this at the same time, one course each, on separate branches. The person who owns the repository speaks Portuguese: talk to them in Portuguese, write commit subjects and the PR body in Portuguese, and keep everything inside `content/` in English (source) plus `.pt` translations. They have NO local copy of the repository: never tell them to `cd` into a checkout, pull or run anything locally. Everything they do happens on GitHub.

THE COURSE: mobile-delivery (`co-28fbcyhm`), `content/code/courses/mobile-delivery/`, designed by `docs/design/mobile-delivery.md`. Your branch is `claude/mobile-delivery`; push only there.

## Read before writing anything

1. `CLAUDE.md` (loaded for you): the rules. Pay special attention to Content, the vocabulary, translations, figures, `::: track` blocks (C-39), and the "Before pushing" list.
2. `docs/CONTENT.md` (the format), `docs/TEACHING.md` (the craft: prose, figures, spoken scripts, "Code that is demonstrated"), and `docs/EXERCISES.md` (what makes a question worth asking).
3. The design sheet `docs/design/mobile-delivery.md`. It is a claim that `tools/check-design` holds against what you write, so the ids, the lesson count against the topics, the section total and the exercise count must agree with it. A budget can be overrun; a fact cannot disagree.
4. At least one finished course of the same kind, read as the model, for structure, voice and honesty. Read the ones corrected this week for how the STUDENT gets their environment: `networks`, `sql-databases`, `testing-cicd`, `docker`, `warehouse-modeling` and `virtualization`. Their `lab.sh` and `captures.sh` beside the course prove the captures; their lessons show the student, inside the lesson, everything they need to build the same environment on their own machine.

## The mobile courses: what can be built here, and saying plainly what cannot

The owner chose the eight courses of the `mobile` track as batch 15 on 2026-10-30. `mobile-fundamentals` comes before the track's fork. The fork has three options, and a student takes ONE: `kotlin` then `android-apps`, `swift` then `ios-apps`, or `javascript` then `react-native`. `mobile-offline` and `mobile-delivery` come after it, and every student takes them. Read `docs/design/mobile.md` if it exists, and every sheet's flags.

1. **Nothing after the fork may assume an option** (`mobile-offline`, `mobile-delivery`). Where a lesson must show platform code, it shows Kotlin, Swift and React Native side by side, briefly and evenly. Its own runnable example is platform-free:
   - logic in plain TypeScript run with Node v22.22.0, as `javascript` installs it;
   - SQLite through `better-sqlite3` where a lesson needs a database;
   - a tiny Node server, shown whole, where it needs a backend.

   The example app is a **study planner**, the same one the `frontend` track builds. A student lists courses, opens one, adds sessions with a date and a duration, marks them done, and sees the week's total. It runs offline and syncs when it can.
2. **One environment per option, pinned and reused.**
   - **Kotlin:** Temurin or OpenJDK 21 from Ubuntu 24.04 and Gradle through its wrapper. `android-apps` reuses what `kotlin` builds.
   - **Swift:** the Swift 6 toolchain for Linux. `ios-apps` reuses what `swift` builds.
   - **React Native:** Node v22.22.0, as `javascript` installs it, and Expo. `react-native` installs Expo itself.

   Pin every version exactly. Each course stands alone (C-38): it opens with the setup in brief, names the course and lesson that build it in full, and checks each tool answers.
3. **Read `front-multiplatform`'s PR (#587) before planning.** It recorded exactly what failed in this sandbox. **`dl.google.com` was refused**, and that host serves the Android SDK, the platform jars and the emulator. **There is no Mac and no Xcode.** Check again at the start of your session, because the owner may have widened the network. Then follow these rules:
   - **What runs is captured:** Kotlin and Swift on Linux, Gradle builds of pure-Kotlin modules, unit tests, Expo's web target, Jest, SQLite, and anything that needs only Node or the JVM.
   - **What does not run is taught from the platform's own documentation and marked as not run** in the prose, with no transcript, no screenshot and no invented output. That covers an Android build without the SDK, the emulator, Xcode and the iOS simulator, store consoles and signing with a real identity.
   - **Declare the boundary early.** Say in lesson 1 of your course which lessons the student can practise only on a Mac or with the Android SDK, as `front-multiplatform` did. Never let a student find the wall in the middle of a lesson.
   - **Compose and SwiftUI previews:** if a JVM screenshot tool such as Paparazzi or Roborazzi renders Compose without an emulator here, use it and say how. Never draw a phone screen by hand and present it as a capture.
4. **The stores charge, and the course says so before it asks for anything** (`mobile-delivery` flag 1). Teach the checklist, the review rules and the fees from the stores' documentation, dated, and mark it as not run.
5. **The fork's three options are equals.** `android-apps`, `ios-apps` and `react-native` each build the same study planner, with the same screens and the same data, so that their closing lessons compare like with like. `ios-apps` is mostly not runnable here (its sheet's flag 1). Write it anyway, from Apple's documentation. Run everything that is plain Swift (models, logic, tests, `async/await`, `Codable`) on Linux. Mark every SwiftUI, Xcode and simulator step as not run, and say so in the PR in numbers: how many sections are practised and how many are read.

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
- One PR for the course against `main`, title `mobile-delivery: …`, with the body in Portuguese. Use the structure of the recent course PRs (see #438 for the shape): Por quê, O que entra, O que o curso diz de si mesmo if relevant, and Como foi verificado, with real numbers.
- If the course needs a change outside `content/` (a checker, the loader, the interface), keep it minimal, put it in its own commit, and say so in the PR. Other sessions are writing courses at the same time, so do not reformat or reorganise shared files.
- After opening the PR, subscribe to its activity and drive it to green. A red check is yours to root-cause and fix. Never skip, disable or loosen a check to get green.

## Learned from the last batch

- **Commit and push to your branch after every finished lesson**, not at the end. The container is ephemeral and a session can stop on a usage limit for hours; what is pushed survives, what is only on disk may not.
- **If you stop on a usage limit**, the owner's main session will poke you to continue. Pick up from the last pushed lesson.
- **Models to read now include the recent ones**: the eight `frontend` courses merged on 2026-10-30 (`front-multiplatform` above all, for what failed in this sandbox and how it said so), `javascript`, `java` (for a JVM course's environment) and `secure-code`. Also read the five networks-infra courses: `networks-addressing`, `networks-availability`, `networks-security`, `networks-automation` and `cloud`. They solved labs, captures and exams in this same environment.
- **A course that sits in several tracks** may need a sentence that is true for one track and false for another. Use a `::: track <slugs>` group with a `::: track *` passage (C-39; see `first-job` lessons 1, 12 and 14 for the shape), and only where the difference is real.
- **Anything a language model said is a capture like any other.** If a lesson shows a model's answer, it must be an answer a model actually gave, recorded by a script, with the model name and date in the script header. If no model API is reachable from the sandbox, do not invent replies: teach the technique with examples marked plainly as illustrative, written by the course and not by a model, and say so in the prose.
- **The platform gives the student no machine, container or lab.** Every course teaches the student to build their own practice environment on their own computer, a virtual machine or containers they create themselves, and every exercise and command in the course is done there. Write the lessons that way: setting the environment up is part of the course, explained step by step in the first lesson that needs it, and nothing assumes a machine we host. Your captures stay real: run them here, in an environment built exactly the way the lesson tells the student to build theirs, and keep the script that builds it beside `course.json` as the other courses do.
- **Sixteen sessions are writing at the same time**: the eight `mobile` courses (`mobile-fundamentals`, `kotlin`, `swift`, `android-apps`, `ios-apps`, `react-native`, `mobile-offline`, `mobile-delivery`) and the eight GCP and Azure courses (`gcp-` and `azure-` `foundations`, `compute`, `operations`, `data`). Do not wait for another one and do not write its material. Where yours must mention another, take what its design sheet in `docs/design/` says it teaches, and point at it by course and lesson number as the sheet numbers them. A course after a fork never points at a fork option as something the student took.
- **Read the most recent courses as models too**: the ten from the last writing batch (`servers-cache`, `pipelines-etl`, `data-cleaning`, `visualization`, `data-storytelling`, `data-governance`, `process-management`, `architect-communication`, `threat-modeling`, `soc-response`) and the AI courses corrected this week (`prompt-engineering`, `rag`, `agents-mcp`, `llm-observability`).
- **Ask nothing you can decide from the brief and the docs.** A question to the owner stops the session for hours. If something is truly the owner's to decide, choose the conservative option, say so in the PR, and keep going.
- **Do not create other sessions.** Write the whole course in this one.
- **Security is taught from the defender's side**: how to recognise, detect, respond and prevent. No working exploit, no malware, no instructions for getting into a system.
