---
title: Fixing a finding, and running the check for ever
version: 1
---

A finding has one of three fixes, and the report says which. **A module you require gets a newer
version with `go get`. The standard library gets a newer Go. And a module that arrives through
another module gets either.** None of them is an edit to your own code, which is why a vulnerability
scan is cheap to act on: most findings close with a version number and a rerun of the tests.

## Who brought the module in

In a real module the bad dependency can be one you never asked for. `go mod why -m` prints the
shortest chain of imports from your packages to the module, and `go list -m -u` says what newer
versions exist:

```
ana@vm:~/langs$ go mod why -m golang.org/x/text
# golang.org/x/text
example.com/langs/accept
golang.org/x/text/language
```

```
ana@vm:~/langs$ go list -m -u golang.org/x/text
golang.org/x/text v0.3.7 [v0.43.0]
```

Here the chain is two lines long: `accept` imports `language` directly. **When the chain runs
through another module, that module is the one that chose the version**, and you have two moves.
Upgrade it, if its newer releases ask for a fixed version. Or require the fixed version yourself
with `go get`, which works on a module you only use indirectly: Go's minimal version selection picks
the highest version anybody in the build asks for. The bracket in the second line is the newest
release on the module proxy, v0.43.0, forty minor versions on.

## The smallest fix, and the sensible one

`Fixed in` named v0.3.8. That is the smallest change that clears the gate:

```
ana@vm:~/langs$ go get golang.org/x/text@v0.3.8
go: upgraded golang.org/x/text v0.3.7 => v0.3.8
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb ./...; echo $?
=== Symbol Results ===

No vulnerabilities found.

Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

Both programs pass now, since `./...` covers both, and the exit status is 0. The 14 at the module
level are still there, and two of them are in `golang.org/x/text` itself, fixed only in v0.39.0 and
v0.41.0. **The smallest fix is right for a hotfix that has to ship tonight with the least change to
review.** For the ordinary case, take the newest release and let the tests say whether anything
broke:

```
ana@vm:~/langs$ go get golang.org/x/text@latest && go mod tidy && cat go.mod
go: upgraded golang.org/x/text v0.3.8 => v0.43.0
module example.com/langs

go 1.27.1

require golang.org/x/text v0.43.0
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb ./...; echo $?
=== Symbol Results ===

No vulnerabilities found.

Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 12
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

Fourteen became 12, and **every one of the 12 is in the standard library**. The two
`golang.org/x/text` fixes landed in v0.39.0 and v0.41.0, not on the old v0.3 line, and every month
of waiting makes the eventual jump bigger. These two programs have no tests to run; yours would run
`go test ./...`, as `go-concurrency` lessons 25 and 26 wrote them, before the change goes anywhere.

**A fix in `go.mod` fixes nothing that is already running.** The binary built in section 04 still
carries the old module, and the binary scan says so until it is rebuilt:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-bin | grep -E 'Found in|Your code'; echo ${PIPESTATUS[0]}
    Found in: golang.org/x/text@v0.3.7
Your code is affected by 1 vulnerability from 1 module.
3
ana@vm:~/langs$ go build -o accept-bin ./accept
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-bin | grep 'Your code'; echo ${PIPESTATUS[0]}
Your code is affected by 0 vulnerabilities.
0
```

The finding closes when the new binary replaces the old one wherever it runs. Lessons 16 to 18 are
about building and shipping that binary.

## The standard library is fixed by a newer Go

`hits` from lesson 1 has no dependencies, and it still had 13 entries at the module and package
levels in section 04. All of them name the same fix:

```
ana@vm:~/vuln-hits$ govulncheck -db file:///home/ana/vulndb -show verbose ./... | grep 'Fixed in' | sort | uniq -c
      1     Fixed in: os@go1.27.2
     12     Fixed in: stdlib@go1.27.2
```

**The standard library is versioned with the toolchain**, so there is no `go get` for it: the fix is
Go 1.27.2, the next patch release. Patch releases of Go carry security fixes and serious bug fixes,
with no change to the language, which makes them cheap to take. The go command can fetch a release
from the module proxy and run it for one command, with `GOTOOLCHAIN`, which is enough to see the
result without replacing the lab's Go:

```
ana@vm:~/vuln-hits$ GOTOOLCHAIN=go1.27.2 go version
go version go1.27.2 linux/amd64
ana@vm:~/vuln-hits$ GOTOOLCHAIN=go1.27.2 govulncheck -db file:///home/ana/vulndb ./...; echo $?
No vulnerabilities found.
0
ana@vm:~/langs$ GOTOOLCHAIN=go1.27.2 govulncheck -db file:///home/ana/vulndb ./...; echo $?
No vulnerabilities found.
0
```

Not even a line of context this time: every entry was about Go 1.27.1, and under 1.27.2 there is
nothing at any level. This works because `govulncheck` asks the go command on the `PATH` which
version it is, the first line of `-version` in section 02, and the variable changes the answer. **To
actually take the fix, install the new release the way `go` lesson 3 installed this one and rebuild
every binary**; in a CI job, raise the version the job installs. This course stays on 1.27.1 so that
every transcript in it comes from the same compiler.

## In the pipeline, and on a schedule

The check belongs in CI next to the formatting check of lesson 6 and the linters of lesson 8. A
GitHub Actions job, `.github/workflows/vuln.yml`:

```yaml
name: vuln
on:
  push:
  pull_request:
  schedule:
    - cron: "17 6 * * *"
jobs:
  govulncheck:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - run: go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./...
```

**This file was not run**: the lab has no GitHub. Its last line was, against the lab's database, in
`~/langs` after the upgrade:

```
ana@vm:~/langs$ go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 -db file:///home/ana/vulndb ./... | tail -n 5; echo ${PIPESTATUS[0]}
Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 12
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

`go run` with a version builds the pinned release and runs it, with no `go install` step and no
`PATH` to arrange, and the job fails exactly when the text report exits 3. `go-version-file` takes
the Go release from `go.mod`, so the job judges the standard library you build with. The two actions
are the ones lesson 6's format job uses, at the same versions.

The `push` and `pull_request` triggers catch the change that adds a vulnerable call. **The
`schedule` trigger catches the other half: the database changes while your code does not.** A commit
that passed on Monday can fail on Thursday without anybody touching it, because on Wednesday
somebody published an entry for a function it has called all along. Without the schedule, that
finding waits for the next unrelated pull request, which then fails for a reason its author did not
cause. The cron line runs the job once a day, at 06:17 UTC; GitHub reads schedules in UTC, and
documents the start of each hour as the time scheduled runs are most often delayed.

One thing `govulncheck` does not have is a way to mark a finding as accepted. Its documentation
lists the absence among its limitations. **A symbol-level finding stays red until the version
moves**, which is the right pressure for something a stranger can trigger. If you decide a finding
cannot be reached in your deployment, that decision lives outside the tool: in a `-format json` run
read by a script of your own, with the reason written next to the id.
