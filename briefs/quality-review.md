You are reviewing finished courses of the `code` school in codeschool-ing/schooling. Each course gets its own pull request. Several sessions are doing this at the same time, each on a different group of courses. The person who owns the repository speaks Portuguese. Talk to them in Portuguese, and write commit subjects and PR bodies in Portuguese. They have NO local copy: never tell them to run anything locally.

Your courses are in the message that started your session, in the order to do them. For each course, use the branch `claude/review-<course>` and open one PR from it. Do one course at a time: finish it, open its PR, then start the next.

## Why

These courses were written between August and early October 2026. Since then, three rules arrived that they were never held to:

- **Spoken scripts are part of the natural-writing pass** (2026-09-21). Before that date the skill read only the `.md` files, so the scripts in `lesson.json` were never audited.
- **Every number in the prose traces to a capture**, checked by reading. On 2026-10-23 two drifts were found by chance in `portfolio-project` and `testing-cicd`: a commit hash and a pass count that the prose stated and the capture above it contradicted. Nothing in CI can see this.
- **The annotated example is considered wherever code is demonstrated** (`schooling-example`, `docs/TEACHING.md`, "Code that is demonstrated").

The owner asked for a review of the older courses against all three. Nothing in a course's structure changes: no lesson, section, id or slug is added, removed or renamed.

## Read first

- `CLAUDE.md` (loaded for you).
- `.claude/skills/natural-writing/SKILL.md`, whole: the floor, the measured voice in two registers, and what not to flag.
- `docs/TEACHING.md`, especially "Code that is demonstrated" and "Code in a translation is the English code".
- `docs/EXERCISES.md`.

## Per course, in this order

### 1. Facts against captures, which is the part that can be wrong

Read every reading section (`.md` and `.pt.md`), every spoken script (`lesson.json`, `sections[].videos[].script`) and every exercise's `prompt`, `hint` and `why` (`exercises.json` and `exercises.pt.json`, plus the course's `exam.json`). For each number, value, flag, path, version, filename, hash or quoted output, find the capture it comes from. Usually that is a fence in the same section, sometimes another section of the same lesson. Check it against the capture.

- **The capture is the truth.** Where the prose and the capture disagree, change the prose. Never edit a fence to match the prose.
- **A number derived from a capture** (a sum, a difference, a percentage, "three of the five") is recomputed from the capture's own figures.
- **A numeric, cloze or matching question whose key depends on a capture is checked the same way.** `validate-content` proves a key grades, not that it agrees with the lesson. If a key is wrong, fix the key and bump the exercise's `version`, because a student's answer records the version.
- **A capture that looks tidied or impossible**, such as output in a different order from the command or a total that does not add up, is NOT yours to fix by hand. List it in the PR under "Para o dono decidir", with the file and line. Rerunning the course's `captures.sh` is allowed only if the course's lab can be rebuilt here exactly as its `lab.sh` says. If you rerun, every number that moved is changed in the prose in the same commit.
- **The `.pt.md` carries the same numbers as the `.md`.** Check it separately: a translation is where a corrected English number most often stays wrong.

Keep a list as you go. Every drift goes into the PR as a row: file, what the prose said, what the capture says, and the fix.

### 2. The natural-writing pass, over reading prose AND scripts

Run the skill's audit on the course's reading prose and its spoken scripts, measured apart, and apply what it finds within the skill's floor. The owner's standing request is that every section goes through it, and these never did in full.

These are the measurements taken on 2026-10-31 with the skill's own method:
- reading sentences over 45 words;
- spoken sentences over 28 words;
- reading sections longer than 60 words with neither bold nor ALL-CAPS.

Your course's row is in the message that started your session. Use it to know where to look first, not as a target. Report what you declined and why, as the skill asks.

### 3. Code that is demonstrated

Wherever a section walks through a program, or where trailing comments have grown into clauses (three or more in one block, or past a few words), consider a `schooling-example`, as `docs/TEACHING.md` describes. Convert only where it clearly reads better. The program must stay byte-identical: the copy button hands it over without the notes, so the notes come out of the comments and nothing else moves. In the `.pt.md` the notes are prose and are translated, and the code is not. Count the conversions in the PR, and list in it the places you considered and left alone.

### 4. Checks and a look

```sh
export GOTOOLCHAIN=local
go run ./tools/validate-content
go run ./tools/check-exercises
go run ./tools/check-design
go run ./tools/check-figures
node tools/check-highlight/check-highlight.mjs content
node tools/check-cloze/check-cloze.mjs content
node tools/figure-fit/figure-fit.mjs
```

Then a render walk of every section you changed, in both languages. Migrate, load and start the API against a local Postgres. Sign up a student through `tools/lib/sign-up.mjs`, give them a subscription with `tools/a11y-test/bought.sql`, and open the sections with Playwright (Chromium is at `/opt/pw-browsers`). Fail on raw markers, an empty body, a figure count lower than the file's, or a page error. Delete the walk script before committing.

## The PR, one per course

- **Title:** `<course>: revisão — números contra as capturas, escrita natural e código demonstrado`.
- **Body in Portuguese, with these sections:**
  - **Por quê.**
  - **Números contra as capturas:** the table of drifts. If there are none, say so plainly, with how many statements were checked.
  - **Escrita natural:** what was applied and what was declined, with counts, and the course's measurements before and after.
  - **Código demonstrado:** the conversions, and what was considered and left.
  - **Para o dono decidir**, only if there is something.
  - **Como foi verificado**, with the real output lines.
- **After opening it:** subscribe to its activity and drive it to green. Never skip, disable or loosen a check.

## Standing rules

- **Commit and push as you go**, at least after every few lessons. The container is ephemeral, and a usage limit can stop you for hours. If you stop, the owner's main session will poke you; continue from the last push.
- **Touch only your courses.** Change nothing outside `content/code/courses/<course>/` and its design sheet. If a checker must change, put that in its own commit and explain it. Other sessions are working at the same time.
- **Ask nothing you can decide from this brief and the docs.** A question to the owner stops the session for hours. When something is truly the owner's to decide, take the conservative option, note it in the PR, and keep going.
- **Do not create other sessions.**
- **Commit subjects in Portuguese.** End commit messages and the PR body with the attribution lines your own session gives you, and never put a model identifier anywhere else.
