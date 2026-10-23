---
title: Linting in the pipeline without drowning in it
version: 1
---

A linter on one laptop is advice. **A linter in CI is a gate, and a gate has three jobs**: give the
same answer on every machine, hold back new problems without demanding that every old one be fixed
first, and do it quickly enough that nobody learns to wait for it. Each of the three is a setting
somebody has to choose, and the defaults choose wrongly for an old codebase.

## The same answer everywhere

Asking for whatever release is newest is the common wrong idea here: "the latest golangci-lint"
sounds like the safest choice, and it is the one that turns a green build red on a morning when
nobody changed a line. **Each release changes what gets reported.** Section 04 met two instances: 2.0.0 dropped every
default exclusion, which made `errcheck` report printing and closing again, and 2.14.0 moved revive
from 1.15.0 to 1.17.0, which brought a new rule, and switched one of `gosec`'s checks, `G407`, back
on. Pinning golangci-lint pins every linter inside it, since their versions are fixed in its own
`go.mod`. So the version is written in one place that CI reads, and upgrading it is a pull request
of its own, where the new findings are the whole diff and can be fixed or excluded on purpose.

## Only what this change added

An old codebase has an old pile of warnings, and the first run of a new linter over it reports all of
them. `~/lint` is that codebase in miniature: `report.go` carries the eleven findings section 04
ended with, and they are going to stay for a while. Make it a Git repository and commit it as it is,
the way lesson 6 did for `~/fmt`:

```
ana@vm:~/lint$ git init -q -b main && git config user.name Ana && git config user.email ana@example.com
ana@vm:~/lint$ git add -A && git commit -q -m "hits, with the warnings it has today" && git log --oneline | wc -l
1
```

Then a new feature arrives, written by somebody in a hurry. `internal/tally/share.go`:

```go
package tally

// Share returns the percentage of requests that ended with status.
func Share(s Summary, status int) float64 {
	n, ok := s.ByStatus[status]
	if ok == false || s.Lines == 0 {
		return 0
	}
	return 100 * float64(n) / float64(s.Lines)
}
```

```
ana@vm:~/lint$ golangci-lint run --output.text.print-issued-lines=false | tail -9
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not be capitalized (staticcheck)
internal/tally/share.go:6:5: S1002: should omit comparison to bool constant, can be simplified to !ok (staticcheck)
12 issues:
* errcheck: 1
* govet: 1
* revive: 4
* staticcheck: 6
ana@vm:~/lint$ golangci-lint run --new-from-rev=HEAD; echo $?
internal/tally/share.go:6:5: S1002: should omit comparison to bool constant, can be simplified to !ok (staticcheck)
	if ok == false || s.Lines == 0 {
	   ^
1 issues:
* staticcheck: 1
1
```

**The plain run reports twelve findings, and only the last is about the new file.** A gate that fails
on all twelve fails this change for eleven problems it did not cause, and the person who wrote
`share.go` learns that the lint step is red whatever they do. `--new-from-rev=HEAD` keeps only the
findings on lines that differ from the named commit, here the new file, and the gate now says one
thing: `ok == false` is `!ok`.

On a pull request the commit to compare against is where the branch left `main`, and
`--new-from-merge-base` works that out:

```
ana@vm:~/lint$ git switch -q -c share && git add -A && git commit -q -m "tally: Share"
ana@vm:~/lint$ golangci-lint run --new-from-merge-base=main; echo $?
internal/tally/share.go:6:5: S1002: should omit comparison to bool constant, can be simplified to !ok (staticcheck)
	if ok == false || s.Lines == 0 {
	   ^
1 issues:
* staticcheck: 1
1
ana@vm:~/lint$ golangci-lint run --new-from-merge-base=main --issues-exit-code=0 > /dev/null; echo $?
0
ana@vm:~/lint$ golangci-lint run ./cmd/...; echo $?
level=error msg="[linters_context] typechecking error: pattern ./cmd/...: lstat ./cmd/: no such file or directory"
0 issues.
7
```

**The same single finding, now measured against the branch point**, however many commits the branch
has. Both flags have a blind spot that comes from how they work: they keep findings on changed lines.
A change that deletes the only call to an old function would make `unused` report that function, on a
line the change never touched, so the new problem would be filtered out with the old ones.
That is the price of the approach, and it is why the old pile has to shrink as well, by separate pull requests, until the
flag can come off.

## What the exit code says

The last two commands show the other two codes worth knowing. `--issues-exit-code=0` keeps the
report and passes the step, which is how a linter can run for a week in CI, printing, before
anybody makes it a gate. The second is a mistake in the command itself: a pattern that names no
package.

| code | what golangci-lint is saying |
|---|---|
| `0` | it ran, and found nothing it was asked to report |
| `1` | it found issues, or the number set by `--issues-exit-code` |
| `3` | it could not run: a configuration file it refused, as in section 04 |
| `5` | there were no Go files to look at |
| `7` | it ran and logged an error along the way, like the missing `./cmd/` above |

**A code that compiles badly is not a separate case**: a syntax error comes back as an issue from
the linter called `typecheck`, with status 1. The build step finds it too, which is one reason the
lint step should never be the only one.

## The cache

golangci-lint keeps what each linter found for each package in a cache, and a run where nothing
changed reads it back instead of analysing again:

```
ana@vm:~/lint$ golangci-lint cache clean && time golangci-lint run > /dev/null

real	0m2.891s
user	0m2.791s
sys	0m0.402s
ana@vm:~/lint$ time golangci-lint run > /dev/null

real	0m0.370s
user	0m0.255s
sys	0m0.091s
ana@vm:~/lint$ golangci-lint cache status
Dir: /home/ana/.cache/golangci-lint
Size: 179.7KiB
```

**2.891 seconds with the cache cleared, 0.370 seconds with it full**, on a module of six Go files; the
ratio grows with the size of the code. The numbers are timings from one run and move a little every
time, and the order of magnitude does not. A CI machine starts empty, so the cache is worth keeping
between runs, together with Go's own build and module caches, under `~/.cache` and `~/go/pkg/mod`.

## The same check in CI

On GitHub Actions the work is done by the project's own action, the one golangci-lint's repository
runs on its own pull requests. It installs the pinned version and runs it. `.github/workflows/lint.yml`:

```yaml
name: lint
on: pull_request
permissions:
  contents: read
jobs:
  golangci:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - uses: golangci/golangci-lint-action@v9
        with:
          version: v2.14.0
          args: --new-from-merge-base=origin/main
```

```
ana@vm:~/lint$ git add .github && git commit -q -m "ci: lint" && git log --oneline | head -1 | cut -c9-
ci: lint
```

**This file was not run**: the lab has no GitHub, as in lesson 6. It is committed above, and on a
repository hosted there it runs on every pull request. Four lines carry decisions. `on: pull_request`
and not `push`, because on `main` itself the merge base is the commit being checked and
`--new-from-merge-base` would always find nothing. `fetch-depth: 0` fetches the whole history, without
which `origin/main` is not there to compare against. `go-version-file` takes Go from `go.mod`, as in
lesson 6. And `version: v2.14.0` is the pin, the only place in the repository that names it. The
three actions are at the major versions golangci-lint's own workflow used when 2.14.0 was released:
`actions/checkout` v7, `actions/setup-go` v7 and `golangci/golangci-lint-action` v9.

## Rolling it out on an old codebase

**The cost of a noisy linter is not the minutes spent reading it.** It is that people stop reading:
a gate that is wrong one time in five teaches everybody to add `//nolint` without looking, and the
sixth time it was right. Every step below is about keeping the signal high enough that a red build
is believed.

1. Start from `default: standard` and the `std-error-handling` preset. Never `default: all`: it
   switches on all 115, including `arangolint` and `clickhouselint`, written for two database
   drivers `hits` has never heard of.
2. Run it with `--issues-exit-code=0` for a few days and read what it says, in CI, where everybody
   sees the same list.
3. Fix what is cheap, exclude what is wrong for this codebase in `exclusions.rules`, and turn on
   `--new-from-merge-base`. From that day new code is held to the standard.
4. Pay down the old findings one package at a time, in pull requests of their own, until the flag can
   come off.
5. Add one linter at a time, each in a pull request that also makes the code pass it, so that no
   linter ever arrives with a backlog.
