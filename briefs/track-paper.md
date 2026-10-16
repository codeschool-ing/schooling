You are making ONE change to codeschool-ing/schooling and opening its pull request: **a track's final exam draws 30 questions, as `docs/PLAN.md` A-14 decided, instead of the 20 a course exam draws.** The person who owns the repository speaks Portuguese: talk to them in Portuguese, and write commit subjects and the PR body in Portuguese. They have NO local copy: never tell them to run anything locally. Your branch is `claude/track-paper`; push only there.

## The defect

- **The decision:** A-14 (`docs/PLAN.md`) settles four sizes: "4–6, 10–14, 20 of 100, 30 of 150". A course exam is 20 drawn from about 100. A track exam is 30 drawn from 150, because a track is 12 to 15 courses and a 20-question paper is under two questions per course, which measures luck rather than a track.
- **The code:** `internal/exam/exam.go` has one declared parameter, `QuestionsPerAttempt` (`exam.questions`, fallback 20, fence 5 to 60), and `questionsPerPaper` answers it for every scope. So every track final draws 20.
- **How it was found:** the render walks of the six track exams merged on 2026-10-16 (#547 to #552). Three of those PRs said it under "Para o dono decidir". The pools are already 150, so the content is right and only the draw is wrong.

## What to do

1. **Read first:** `CLAUDE.md` (loaded for you), especially "Sitting an exam", K-13 and "And that cost is a declaration, not a table". Then `internal/setting`, `internal/exam/exam.go`, and every reader of `exam.QuestionsPerAttempt`: `cmd/api/main.go` (the registry, `tenant.NewHandler` and the exam store's `Numbers`), `cmd/seed`, `internal/exam/exam_test.go`, and the console and storefront code that shows a paper's length. Finally `tools/exam-offer-test` and `tools/console-test`, which press these numbers in a browser.
2. **Make the length per scope.** The natural shape is a second declaration beside the first, for example `QuestionsPerTrackAttempt` named `exam.questions.track`, fallback 30, with a fence and a `Why` argued in the same voice as its neighbour. `questionsPerPaper` then takes the scope. Keep the course exam exactly as it is: same name, same fallback, same fence, so nothing a deployment already set moves.
3. **Every place that shows or assumes a length follows the scope.** That includes the storefront or offer card that tells a student how long the paper is, the seed's arithmetic, and the tests. `TestEveryParameterCarriesItsArgument` must pass with the new declaration. A name declared twice panics at start-up, so register it once.
4. **Tests:**
   - the track paper draws the track number when the pool is larger, and the whole pool when it is smaller;
   - the course paper still draws its own number;
   - a track value outside the fence falls back to 30.

   Follow "A test does not own the database" in `CLAUDE.md`.
5. **Docs:** if `CLAUDE.md` or `docs/PLAN.md` describes the paper length, make it say what the code now does. `CLAUDE.md` wins where the two disagree.

## Checks

The "Before pushing" list in `CLAUDE.md`, in full:

- `gofmt`, `go build`, `golangci-lint` and `go test -race ./...` against a real Postgres;
- the content tools;
- the browser suites that touch exams and the console: `exam-offer-test`, `a11y-test` and `console-test` (run last).

Paste the real output lines into the PR.

## The PR

- **Title:** `exam: a prova de trilha sorteia 30 questões (A-14)`.
- **Body, in Portuguese:** Por quê, O que muda, and Como foi verificado.
- **After opening it:** subscribe to its activity and drive it to green. Never skip, disable or loosen a check. Do not create other sessions. End commit messages and the PR body with the attribution lines your own session gives you, and never put a model identifier anywhere else.
