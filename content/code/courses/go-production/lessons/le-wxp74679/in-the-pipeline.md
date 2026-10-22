---
title: The check in a hook and in CI
version: 1
---

An editor that formats on save covers the people who use it. **The check that covers everybody
runs where every change passes**: in a hook before a commit, and in CI before a merge. Both come
down to one question asked of the tools of sections 02 and 04, "would you change anything?", and
the first attempt at asking it is usually wrong.

## `gofmt -l` succeeds when it finds something

To have something to find, put `internal/tally/classes.go` back the way section 02 printed it,
untidy. Then ask `gofmt` and look at the exit status:

```
ana@vm:~/fmt$ gofmt -l .; echo $?
internal/tally/classes.go
0
ana@vm:~/fmt$ test -z "$(gofmt -l .)"; echo $?
1
ana@vm:~/fmt$ gofmt -d . > /dev/null; echo $?
1
ana@vm:~/fmt$ goimports -d . > /dev/null; echo $?
0
```

**`gofmt -l` named the file and exited 0.** Listing files is what it was asked to do, and it did it,
so by its own account it succeeded. A CI step that runs `gofmt -l .` on its own goes green with a
list of unformatted files sitting in its log. The fix is to treat the output as the answer:
`$(...)` captures what `gofmt` printed, and `test -z` succeeds only when that is empty, so the
second line fails as a check should.

`gofmt -d` behaves differently: it exits 1 when it prints a diff, which makes `gofmt -d .` a usable
check on its own, with the diff in the log as a bonus. **`goimports -d` does not**: it printed a
diff into `/dev/null` and exited 0. Two tools with the same flags and different exit codes is
reason enough to stop relying on exit codes here and capture the output every time.

## One script, run by the hook and by CI

The check belongs in one file, so the hook and the CI job cannot drift apart. It runs `goimports`,
which formats the way `gofmt` does and checks the import block as well, with the `-local` prefix of
section 04 written down once. `go run` with a version builds the pinned `goimports` on first use and
takes it from the build cache after that, so the script needs nothing installed beyond Go itself.
`scripts/check-fmt.sh`:

```sh
#!/bin/sh
# check-fmt.sh: fail when goimports would change any Go file in the module.
# goimports formats the way gofmt does and fixes the imports as well, so one
# command covers both. The pre-commit hook and the CI job both run this file.
out=$(go run golang.org/x/tools/cmd/goimports@v0.52.0 -l -local example.com/hits .) || exit 2
if [ -n "$out" ]; then
	echo "check-fmt: goimports -local example.com/hits -w would change:" >&2
	echo "$out" >&2
	exit 1
fi
```

Git runs `.git/hooks/pre-commit`, if it exists and is executable, before it records a commit, and
abandons the commit if the hook exits with anything but 0. The hook only has to call the script.
`.git/hooks/pre-commit`:

```sh
#!/bin/sh
# Refuse the commit when the check fails. Git runs hooks from the top of
# the working tree.
exec ./scripts/check-fmt.sh
```

Before the first commit of a repository, Git needs to know who is making it, so `git config` sets
a name and an address for this one. Then the first commit, with `classes.go` still untidy:

```
ana@vm:~/fmt$ git init -q -b main && git config user.name Ana && git config user.email ana@example.com
ana@vm:~/fmt$ chmod +x scripts/check-fmt.sh .git/hooks/pre-commit
ana@vm:~/fmt$ git add go.mod go.sum '*.go' scripts .github && git commit -q -m 'hits, formatted'; echo $?
check-fmt: goimports -local example.com/hits -w would change:
internal/tally/classes.go
1
ana@vm:~/fmt$ go fmt ./...
internal/tally/classes.go
ana@vm:~/fmt$ git add -u && git commit -q -m 'hits, formatted'; echo $?
0
ana@vm:~/fmt$ git log --oneline | wc -l
1
```

**The hook refused the commit and named the file**; after `go fmt` and `git add -u`, which stages
the new version of every file Git already tracks, the same commit went through. Two limits are
worth knowing. A hook lives in `.git`, which is not committed, so every clone has to install it
again, and anybody can skip it with `git commit --no-verify`. And this one checks the files as they
are on disk rather than as they were staged, so a file fixed after `git add` and not added again
passes the hook and goes into the commit untidy. **The hook is a convenience for the person
committing; CI is the check nobody can skip.**

## The same script in CI

On GitHub Actions the job is three steps: fetch the code, install the Go that `go.mod` names, run
the script. `.github/workflows/format.yml`:

```yaml
name: format
on: [push, pull_request]
jobs:
  format:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - run: sh scripts/check-fmt.sh
```

**This file was not run**: the lab has no GitHub. It was committed with the rest above, and on a
repository hosted there it runs on every push and every pull request. Any other CI system needs the
same three things, and the last line is the same everywhere. The versions of the two actions were
the newest when this lesson was written.

## A file that does not parse

Capturing the output has a trap of its own. A file `gofmt` cannot parse is not listed, because
there is nothing to compare it with; `gofmt` reports the syntax error on standard error and exits 2.
Here is one, typed in the middle of an edit, beside the tree just committed:

```
ana@vm:~/fmt$ echo 'package tally; func Broken(' > internal/tally/broken.go
ana@vm:~/fmt$ test -z "$(gofmt -l .)"; echo $?
internal/tally/broken.go:1:29: expected ')', found 'EOF'
0
ana@vm:~/fmt$ out=$(gofmt -l .) && test -z "$out"; echo $?
internal/tally/broken.go:1:29: expected ')', found 'EOF'
2
ana@vm:~/fmt$ sh scripts/check-fmt.sh; echo $?
internal/tally/broken.go:1:29: expected ')', found 'EOF'
exit status 2
2
ana@vm:~/fmt$ rm internal/tally/broken.go
```

**`test -z "$(gofmt -l .)"` passed.** Standard output was empty, the error went to the terminal,
and the exit status of `gofmt` was thrown away inside `$(...)`. The second form keeps it: an
assignment like `out=$(gofmt -l .)` has the exit status of the command it ran, so `&&` stops at 2
and the line fails. The build would have caught this file anyway, but a format check should not
need the build to cover for it. The third command is `check-fmt.sh`, which is written the second
way; its `exit status 2` is `go run` reporting how the program it ran ended.

## What not to check

`gofmt -l .` and `goimports -l .` read every `.go` file under the directory, and section 02 showed
that this is not what `go fmt` does. `go fmt ./...` formats the files of packages, and the package
pattern `./...` leaves two kinds of directory out. A check on `.` reads them anyway:

| directory | what is in it | why a check should skip it |
|---|---|---|
| `vendor/` | copies of your dependencies, made by `go mod vendor` | it is other people's code, and the next `go mod vendor` would undo any change to it |
| `testdata/` | inputs for tests, which the go command never builds | a test of a parser may keep a deliberately broken `.go` file there, and the script above would fail on it with status 2 |

`hits` has neither, so `.` is right for it. A module that has them should write, in place of the `.` at
the end of the script's `goimports` line, the directories that hold its own code, such as
`internal tools *.go` here.

**Generated files are a different case.** A file that starts with a comment like
`// Code generated by stringer; DO NOT EDIT.` is read like any other, and `gofmt` has no exemption
for it. A good generator formats its own output: `stringer`, from the same `golang.org/x/tools`
module as `goimports`, passes what it writes through the standard library's `go/format`, which
formats exactly as `gofmt` does. If a generator does not, the fix belongs in the step that runs
it, not in the file, since the next `go generate`, the subject of lesson 10, overwrites anything you
edit by hand.
