You are writing the FINAL EXAM of ONE track of the `code` school in codeschool-ing/schooling and opening its pull request. Four sessions are doing this at the same time, one track each, and six more are writing courses, on separate branches. The person who owns the repository speaks Portuguese: talk to them in Portuguese, and write commit subjects and the PR body in Portuguese. Everything inside `content/` is English (source) plus `.pt` translations. They have NO local copy of the repository: never tell them to run anything locally. Everything they do happens on GitHub.

Your track and branch are in the message that started your session. Push only to that branch.

## What a track exam is

- **The file:** `content/code/tracks/<track>-exam.json` and its translation `content/code/tracks/<track>-exam.pt.json`. Nothing else in the repository needs to change. If you think something else must, say so in the PR and keep it in its own commit.
- **The pool is 150 questions; a paper draws 30** (`docs/PLAN.md`, A-14 and A-11). A paper is a sample, so the pool is what makes a retake something other than a memory test.
- **A track final is every door in the track** (`CLAUDE.md`, "Sitting an exam"). It is the moment the system asserts that a student knows the whole track, and a certificate rests on it.
- **YOUR TRACK HAS A FORK, AND THE FORK IS OUT OF THE EXAM.** `content/code/tracks/<track>.json` lists, under `courses`, plain slugs (every student takes them) and one or two `choice` objects whose `options` each hold a list of courses (a student takes ONE option). A paper draws 30 questions at random from the whole pool. So a question about a course inside an option would reach a student who took a different option: a Go student asked about Java, an Azure student asked about AWS. **Write questions only about the courses outside every `choice`.** No question may need a course that sits inside an option, not even as the second course of a question that crosses two. Where a shared course mentions a language or a provider in passing, ask about the idea and not the vendor's spelling of it.
- **The shared courses, as the track file lists them on 2026-10-23:**
  - `backend`: web-fundamentals, html-css, git, linux-terminal, sql-databases, apis, servers-cache, ai-dev, testing-cicd, docker, architecture, scale, portfolio-project, first-job (the language fork is out)
  - `cloud-engineering`: web-fundamentals, linux-terminal, networks, cloud, docker, kubernetes, git, iac, portfolio-project, first-job (the provider fork is out)
  - `data`: web-fundamentals, linux-terminal, networks, git, python, data-fundamentals, statistics, sql-databases, warehouse-modeling, cloud, pipelines-etl, docker, ai-dev, portfolio-project, first-job (the cloud fork is out; `python` is shared here)
  - `devops`: web-fundamentals, linux-terminal, git, networks, servers-cache, docker, kubernetes, cloud, iac, testing-cicd, gitops, observability, ai-dev, portfolio-project, first-job (both forks are out: the automation language and the cloud)

  Read the track file yourself and trust it over this list if they differ. Say in the PR which courses were excluded and why.
- **The models to read first:** `content/code/tracks/ai-exam.json` and `ai-exam.pt.json` (150 questions), and `it-support-exam.json` and `networks-infra-exam.json`. Match their shape, their hint convention (the course's name and the lesson number, e.g. `"Web and Internet Fundamentals, lesson 6."`) and their mix of types.

## Read before writing

`CLAUDE.md` (loaded for you), `docs/CONTENT.md` (the exercise shapes, `exam.json`, translations of questions), `docs/EXERCISES.md` (what makes a question worth asking, and the tells `check-exercises` refuses), and the A-11 and A-14 rows of `docs/PLAN.md`. Then read the track file and **every course in it**: `course.json` for the topics, and the lessons themselves. Read the lessons, not only the titles. A question is only fair if the answer is in a lesson the student read. Each course's own `exam.json` shows what that course already asks; do not copy from it.

## How to write the 150

1. **Coverage, before writing anything.** Write a table: each SHARED course in the track, its declared hours, and the number of questions it gets. Make the number roughly proportional to the hours, with at least 5 per course. Put the table in the PR body.
2. **The track, not the course.** A third or more of the questions should need two courses at once: the situation a person in the track's `outcome` meets at work, where the answer comes from one course and the reason from another. That is what a track final measures and a course exam cannot. Such a question's hint names both lessons.
3. **Every question is answerable from the lessons.** Its hint names the course and the lesson where the answer is. Every number, command, flag and output in a question must exist in that lesson, byte for byte where it is a capture. Never invent one.
4. **The types:** use the machine-graded types the models use: `quiz`, `multiple-choice`, `numeric`, `cloze`, `ordering`, `matching`; `expected-output` and `expression-answer` where a lesson supports them. Grading is binary. No question is `drillable`: an exam pool is sealed, and `validate-content` refuses `"drillable": true` in it.
5. **Ids:** every question gets a fresh opaque id, `ex-` plus 8 characters of Crockford's base32 (no `i`, `l`, `o` or `u`), unique across the whole repository. Generate them with `crypto`-quality randomness and check against `grep -r` before you use one. `version` is 1. Never derive an id from the text.
6. **Distractors that need the material.** `docs/EXERCISES.md` says what makes an option worth offering. A wrong choice is a mistake a student who skipped the lesson would actually make, and its `why` says what is wrong with it. `check-exercises` refuses the tells a machine can see: the longest option being the right one, "all of the above", a key always in the same position, and so on. Read its output and fix what it finds.
7. **The translation.** `<track>-exam.pt.json` is keyed by question id and carries only what a student reads: prompt, hint, trap, option texts and their `why`, the items of an ordering, the two halves of a pair, and a cloze's `accept`. It never names `correct`, `value`, `tolerance` or a label's coordinates. A fence or inline code inside a prompt stays byte-identical to the English. A cloze is translated whole, and its `accept` carries the Portuguese answers a student would type. A hint's course name is the course's Portuguese name from its `course.pt.json`, and "lesson 6" becomes "aula 6".
8. **A natural-writing pass** (`.claude/skills/natural-writing`) over the English and the Portuguese of the prompts and the `why`s. Apply what it finds, without touching a capture, a number or a key.

## Checks, then a render walk

```sh
export GOTOOLCHAIN=local
gofmt -l .
go build ./...
go run ./tools/validate-content     # it runs every key through the grader
go run ./tools/check-exercises
go run ./tools/check-design
go run ./tools/check-figures
node tools/check-highlight/check-highlight.mjs content
go test ./tools/validate-content/
```

The render walk is the same as for a course: migrate, load and start the API against a local Postgres, sign up a student through the form (`tools/lib/sign-up.mjs`), give them a subscription (`tools/a11y-test/bought.sql`, then set it active), and open the track's final exam in both languages with Playwright (Chromium is at `/opt/pw-browsers`). Start a paper, answer a few questions of each type, and hand it in. Fail on raw markers, an empty body, a paywall or a page error. Delete the walk script before committing.

## The PR

- **Title:** `<track>: prova final da trilha, 150 questões`.
- **Body, in Portuguese:**
  - **Por quê**;
  - **O que entra**: the coverage table, how many questions cross two courses, and the count per type;
  - **Como foi verificado**, with real numbers: the output lines of each check and what the render walk did.
- **After opening it:** subscribe to its activity and drive it to green. Never skip, disable or loosen a check.

## Standing rules

- **Commit and push as you go:** at least after every 50 questions, and after the translation. The container is ephemeral, and a session can stop on a usage limit for hours. If you stop, the owner's main session will poke you; continue from the last push.
- **Do not create other sessions.** The account's weekly limit is close.
- **Commit subjects in Portuguese.** End commit messages and the PR body with the attribution lines your own session gives you, and never put a model identifier anywhere else.
- **Keep changes outside the two exam files at zero** unless a check forces one. If one does, put it in its own commit and explain it in the PR, because other sessions are working at the same time.
