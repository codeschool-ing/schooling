---
title: Constraints written in the file name
version: 1
---

`progress_darwin.go` in section 02 has no `//go:build` line, and it is compiled for macOS and for
nothing else. **A file whose name ends in an operating system or a processor carries a constraint
in its name**, as if the line were there. The rule is mechanical, and knowing it exactly matters,
because a name that almost follows it is an ordinary file that every build compiles.

## The three patterns

Take the name, drop the `.go`, and drop a `_test` at the end if there is one. If what is left ends
in one of these, the file has an implicit constraint:

| the name ends in | example | compiled when |
|---|---|---|
| `_GOOS` | `progress_darwin.go` | the target system is `darwin` |
| `_GOARCH` | `crc32_arm64.go` | the target processor is `arm64` |
| `_GOOS_GOARCH` | `zerrors_linux_amd64.go` | both hold |

**`GOOS` and `GOARCH` stand for any value the toolchain knows**: the 47 pairs `go tool dist list`
prints, and lesson 16 lists those for the three common systems. A `_test` suffix is removed
first, so `progress_darwin_test.go` holds tests that run only on macOS. **A name and a `//go:build`
line combine with "and"**: a file named `progress_darwin.go` that also says `//go:build !darwin` is
compiled by no build at all.

`go list` shows which files a package compiles for a target. `{{.GoFiles}}` is the list it builds
and `{{.IgnoredGoFiles}}` the list it leaves out because of a constraint:

```
ana@vm:~/tags$ go list -f '{{.GoFiles}}' .
[main.go progress.go progress_unix.go]
ana@vm:~/tags$ GOOS=darwin go list -f '{{.GoFiles}}' .
[main.go progress.go progress_darwin.go]
ana@vm:~/tags$ GOOS=windows go list -f '{{.GoFiles}} {{.IgnoredGoFiles}}' .
[main.go progress.go progress_other.go] [progress_darwin.go progress_unix.go]
```

Each target compiled `main.go`, `progress.go` and exactly one of the three per-system files. For
macOS that is `progress_darwin.go`, chosen by its name alone. For Windows the two left out are
named in the second list, one by its name and one by its `//go:build unix && !darwin` line. `go
list` reports both the same way, because to the go command they are the same kind of rule.

## A name that almost follows it

The suffix has to be a value the toolchain knows. **`mac` is not one**, and neither is `osx` or
`win`, so a file called `progress_mac.go` carries no constraint and is compiled for every target,
Linux included:

```
ana@vm:~/tags$ cp progress_darwin.go progress_mac.go; go vet .; rm progress_mac.go
# example.com/hits
# [example.com/hits]
vet: ./progress_unix.go:11:5: progressSignals redeclared in this block
```

The copy defined `progressSignals` a second time in the Linux build, and vet stopped there. It
would have gone on to complain that `syscall.SIGINFO` does not exist on Linux, which is the real
problem. **A suffix the go command does not recognise is no rule at all**, and the error you get is
about whatever the file happens to collide with.

Two more near misses are worth recognising. **The suffix has to come after an underscore and at
the end of the name.** A file called just `linux.go` is not constrained, and neither is
`linux_progress.go`. A file whose name starts with `_` or `.` is a different case: the go command
ignores it entirely, in every build, and it appears in neither list.

## The standard library is written this way

Names are how the standard library carries code for 47 targets. In `syscall` the constants and the
system call numbers are generated per system and per processor, one file each:

```
ana@vm:~/tags$ go list -f '{{join .GoFiles "\n"}}' syscall | grep _linux_
syscall_linux_amd64.go
zerrors_linux_amd64.go
zsyscall_linux_amd64.go
zsysnum_linux_amd64.go
ztypes_linux_amd64.go
ana@vm:~/tags$ GOARCH=arm64 go list -f '{{join .GoFiles "\n"}}' syscall | grep _linux_
syscall_linux_arm64.go
zerrors_linux_arm64.go
zsyscall_linux_arm64.go
zsysnum_linux_arm64.go
ztypes_linux_arm64.go
```

**Changing `GOARCH` swapped five files for five others**, each the same name with `arm64` in place of
`amd64`. `{{join .GoFiles "\n"}}` prints the list one name to a line, so that `grep` can pick the
Linux ones out of it. A count shows how much of a portable package is per system:

```
ana@vm:~/tags$ for os in linux darwin windows; do echo "$os: $(GOOS=$os go list -f '{{len .GoFiles}} files, {{len .IgnoredGoFiles}} left out' os)"; done
linux: 45 files, 87 left out
darwin: 44 files, 92 left out
windows: 34 files, 105 left out
```

`os` has 119 files that are not tests, and **a build compiles about a third of
them**: 45 for Linux, 44 for macOS, 34 for Windows. The rest are other systems' versions of the same
functions. The "left out" figure is larger than 119 minus the first because it also counts test
files written for one system, which `go list` reports in the same list.

## A name, a line or a `switch`

Three tools, each with a place:

- **A name**, when the file is for exactly one system, one processor or one pair. It is visible in
  `ls`, which is where people look first.
- **A `//go:build` line**, for anything a name cannot say: `unix && !darwin`, `!unix`, `cgo`, a
  release tag, or a tag of your own.
- **An `if` or a `switch` on `runtime.GOOS`**, when every branch compiles everywhere and only the
  behaviour differs. `os.UserConfigDir` in the standard library is a `switch runtime.GOOS` that
  picks `%AppData%` on Windows and `~/Library/Application Support` on macOS: plain strings, which
  compile on every system.

`progressSignals` needed files, because `syscall.SIGINFO` and `syscall.SIGUSR1` do not exist on
every system. A message such as "press Ctrl-T" could have been a `switch`, since a string compiles
anywhere.
