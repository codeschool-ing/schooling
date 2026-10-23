---
title: What `go run` and `go build` leave behind
version: 1
---

`go run` feels like an interpreter: you name a directory and the program runs, with no binary left
on the disk. **It is a compiler with the output hidden.** `go run` and `go build` go through the
same steps, read the same sources and keep their work in the same cache. What differs is where the
finished executable ends up and who starts it. Knowing that is what lets you predict how long a
command will take, and why a script should never depend on the exit status of `go run`.

Everything in this lesson runs on lesson 1's `hits`, copied into a directory of its own, `~/daily`:
the four files lesson 1 prints, a `go.mod` made with `go mod init example.com/hits`, and the 20,000
lines `go run ./tools/genlog -n 20000 > access.log` writes.

```
ana@vm:~/daily$ find . -type f | sort
./access.log
./go.mod
./internal/tally/tally.go
./main.go
./main_test.go
./tools/genlog/main.go
```

## A run is a build and then an exec

The go command keeps everything it compiles in **the build cache**, a directory it names in
`GOCACHE`. To watch it work from nothing, Ana points `GOCACHE` at an empty directory for a few
commands. It is an ordinary environment variable, so this leaves the real cache alone:

```
ana@vm:~/daily$ go env GOCACHE
/home/ana/.cache/go-build
ana@vm:~/daily$ GOCACHE=/tmp/cold go build -o hits . && echo built
built
ana@vm:~/daily$ GOCACHE=/tmp/cold go run -x . top -n 1 access.log 2>&1 | grep -E "link -o|exe/hits|-d/hits" | cut -c1-96
GOROOT='/usr/local/go' /usr/local/go/pkg/tool/linux_amd64/link -o $WORK/b001/exe/hits -importcfg
go tool buildid -w $WORK/b001/exe/hits # internal
cp $WORK/b001/exe/hits /tmp/cold/ab/ab03424fdf182dd09ed40909f09aeec5e7408029cba36d37c18d058213c0
$WORK/b001/exe/hits top -n 1 access.log
ana@vm:~/daily$ GOCACHE=/tmp/cold go run -x . top -n 1 access.log 2>&1 | grep -E "link -o|exe/hits|-d/hits" | cut -c1-96
/tmp/cold/ab/ab03424fdf182dd09ed40909f09aeec5e7408029cba36d37c18d058213c08567-d/hits top -n 1 ac
```

`-x` prints every command the go command runs, about a hundred lines here, so the `grep` keeps the
four that matter and `cut` trims them to the width of the page. **The first `go run` linked an
executable in a temporary directory, `$WORK`, copied it into the cache, and ran it.** The packages
it needed were already compiled, by the `go build` just before. It still had to link, because
`go run` builds without the information a debugger uses (`go help run` says so), which makes its
executable a different file from the one `go build` wrote. The second `go run` found that
executable in the cache under the same hash, the one beginning `ab03424f`, and started it directly: nothing was
compiled or linked at all.

The other half of the difference is who starts the program. `go run` is the parent process, and it
does not pass on the child's exit status:

```
ana@vm:~/daily$ go run .; echo $?
usage: hits <command> [flags] [file]

commands:
  count   requests per status code
  top     the paths with the most requests

With no file, or with -, hits reads standard input.
exit status 2
1
```

`hits` returned 2, for a command line with no subcommand, as lesson 1 section 05 designed it.
`go run` printed `exit status 2` as a message and exited with **1**, the same as it does for any
failure of its own. `go help run` states it in one line: the exit status of `go run` is not the
exit status of the compiled binary. **A script, a `Makefile` or a CI step that tests an exit code
builds the binary and runs it**, because through `go run` a usage error and a failed run look the
same.

## The build cache, measured

Here is the same `go build` twice, timed with the shell's `time`, on the empty cache:

```
ana@vm:~/daily$ time GOCACHE=/tmp/cold go build -o hits .

real	0m5.832s
user	0m10.743s
sys	0m4.385s
ana@vm:~/daily$ time GOCACHE=/tmp/cold go build -o hits .

real	0m0.078s
user	0m0.063s
sys	0m0.100s
ana@vm:~/daily$ du -sh /tmp/cold
43M	/tmp/cold
```

The first build took **5.8 seconds** and the second **0.078**, about seventy-five times less. Your
machine's seconds will differ from these and from one run to the next; the ratio is what carries over. Nearly all of the first build was the standard library:
`hits` is two small packages, and it depends on 79 packages in all, each compiled once and kept, 43 MB
of them. Your ordinary `GOCACHE` already holds most of the standard library from every build you
have run since `go` lesson 3, which is why a build there feels instant the first time too.

The cache is keyed by **what goes into a compile**: the content of the source files, the compiler
version, the flags, and the compiled form of every package imported. Timestamps are not part of it:

```
ana@vm:~/daily$ touch main.go internal/tally/tally.go; GOCACHE=/tmp/cold go build -v -o hits .
ana@vm:~/daily$ sed -i 's/want 5 fields/want five fields/' internal/tally/tally.go && GOCACHE=/tmp/cold go build -v -o hits .
example.com/hits/internal/tally
example.com/hits
ana@vm:~/daily$ sed -i 's/want five fields/want 5 fields/' internal/tally/tally.go
ana@vm:~/daily$ GOCACHE=/tmp/cold go build -a -v -o hits . 2>&1 | wc -l
79
```

`-v` names each package as it is compiled, and after `touch` it named none, because the bytes had
not changed. That is the difference from `make`, which compares modification times and would have
rebuilt both. The `sed` changed one message in `tally.go`, and `-v` named two packages: `tally`,
and the `main` package that imports it. Nothing from the standard library was compiled again, and
the second `sed` puts the message back. **`-a` ignores the cache and
rebuilds everything**, here 79 packages; it is the flag to reach for when you suspect the cache,
and almost never the fix. `go clean -cache` empties the cache for good. It was not run in this lab,
because what it costs is those 5.8 seconds again, for every package of every project on the machine.

## What lands where

`go build` writes an executable only when it builds **exactly one `main` package**. Given a
package that is not `main`, or several packages, it compiles them, keeps the results in the cache
and throws the final product away, so the command is a check that everything builds:

```
ana@vm:~/daily$ go build ./... && ls
access.log
go.mod
internal
main.go
main_test.go
tools
ana@vm:~/daily$ go build ./internal/tally && go build && ls
access.log
go.mod
hits
internal
main.go
main_test.go
tools
ana@vm:~/daily$ go build -o bin/ ./... && stat -c "%s bytes  %n" bin/*
2586446 bytes  bin/genlog
4031935 bytes  bin/hits
```

`./...` is the pattern for this directory and every one below it: three packages here, two of them
`main`, and nothing was written. `go build ./internal/tally` wrote nothing either. A bare `go build`
built the package in the current directory and named the file after the last element of its import
path, `example.com/hits`, so it is called `hits`. **`-o` with a directory, written with a trailing
slash, changes the rule**: every `main` package in the list gets an executable there, named the same
way, which is how one command builds both programs into `bin/`. Section 03 takes the next step,
where the executable goes into a directory on your `PATH`.
