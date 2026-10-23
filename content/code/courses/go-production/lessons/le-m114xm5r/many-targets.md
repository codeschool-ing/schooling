---
title: Every target in one command
version: 1
---

Four builds typed by hand were enough to see how cross-compiling works. **A release is the same
builds every time, named the same way every time**, and that is a job for a script. A person typing six commands will one day type five, or call one binary `hits-mac` and the next `hits-darwin`.
Somebody downloading from a release page reads the name to pick a file, so the name has to say the
system and the processor in the words Go uses: `hits-<os>-<arch>`, with `.exe` on Windows.

## The script

`release.sh`, at the top of `~/cross` beside `go.mod`:

```schooling-example
{
  "language": "sh",
  "file": "release.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# release.sh builds hits for each target below, into release/.\nset -eu\n",
      "note": "A plain POSIX shell script, so it runs under `sh` on Linux and macOS alike. **`set -eu` stops it at the first command that fails** and at the first variable used without a value, so a build that breaks for one target stops the release instead of leaving a directory with a hole in it."
    },
    {
      "code": "targets=\"linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/arm64\"\n",
      "note": "The pairs to build, spelled the way `go tool dist list` prints them. **Adding a target is adding a word.**"
    },
    {
      "code": "rm -rf release\nmkdir release",
      "note": "Each run starts from an empty directory, so a target taken off the list does not leave last month's binary behind to be shipped by mistake."
    },
    {
      "code": "for t in $targets; do\n\tos=${t%/*}\n\tarch=${t#*/}\n\text=\n\tif [ \"$os\" = windows ]; then\n\t\text=.exe\n\tfi",
      "note": "`${t%/*}` is the word with everything from the slash on removed, `linux`; `${t#*/}` is the word with everything up to the slash removed, `amd64`. Windows gets `.exe`, which `go build -o` does not add by itself."
    },
    {
      "code": "\tout=release/hits-$os-$arch$ext\n\tCGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -o \"$out\" .\n\techo \"$out\"\ndone",
      "note": "**`CGO_ENABLED=0` makes the native build like the other five.** Left out, the `linux/amd64` binary would be built with cgo on, because that is this machine, and the other five with it off. The script prints each name as it goes, which is the progress a person watching wants."
    }
  ]
}
```

Nothing in it is specific to Go except the one `go build` line, and that line is section 02's
command with the variables filled in from a list. A `Makefile` with a rule per target is the other
common shape and does the same job; the loop is shorter, and a shell is on every machine that has
Go.

## A release directory

Run, and asked what it made:

```
ana@vm:~/cross$ sh release.sh
release/hits-linux-amd64
release/hits-linux-arm64
release/hits-darwin-amd64
release/hits-darwin-arm64
release/hits-windows-amd64.exe
release/hits-windows-arm64.exe
ana@vm:~/cross$ stat -c "%s bytes  %n" release/*
4120704 bytes  release/hits-darwin-amd64
3909762 bytes  release/hits-darwin-arm64
4031863 bytes  release/hits-linux-amd64
3831466 bytes  release/hits-linux-arm64
4217344 bytes  release/hits-windows-amd64.exe
3902464 bytes  release/hits-windows-arm64.exe
ana@vm:~/cross$ file release/* | cut -d, -f1,2
release/hits-darwin-amd64:      Mach-O 64-bit x86_64 executable, flags:<|DYLDLINK|PIE>
release/hits-darwin-arm64:      Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
release/hits-linux-amd64:       ELF 64-bit LSB executable, x86-64
release/hits-linux-arm64:       ELF 64-bit LSB executable, ARM aarch64
release/hits-windows-amd64.exe: PE32+ executable (console) x86-64, for MS Windows
release/hits-windows-arm64.exe: PE32+ executable (console) Aarch64, for MS Windows
```

**Six binaries for three systems and two processors**, each named for what it runs on, and `file`
agrees with every name. Sizes run from **3,831,466 bytes** for `linux/arm64` to **4,217,344** for
`windows/amd64`. The `linux/arm64` and `darwin/arm64` files are byte for byte the sizes section 02
printed, because they are the same builds. The first run of the script on a machine compiles the
standard library once for each new target, which takes noticeably longer than the runs after it. The
build cache keeps every one of them, so a second release is mostly linking.

Two more checks, on what the script promised:

```
ana@vm:~/cross$ go version -m hits | grep CGO_ENABLED; go version -m release/hits-linux-amd64 | grep CGO_ENABLED
	build	CGO_ENABLED=1
	build	CGO_ENABLED=0
ana@vm:~/cross$ du -sb release
24013603	release
ana@vm:~/cross$ qemu-aarch64-static release/hits-linux-arm64 top -n 1 access.log
path    requests
/login  2576
```

**The binary from a plain `go build` records `CGO_ENABLED=1`, and the release's `linux/amd64`
records `0`.** For `hits` the difference is only in that record, because nothing in it uses cgo and
both are statically linked. For a program like section 04's `who` it is the difference between a
dynamically linked native binary and five static ones. A release where one file behaves unlike the
others is the kind of thing nobody notices until a user on that system reports it. The ARM binary
from the release directory still answers like every other build in this lesson.

## What the directory costs

`du -sb` puts the directory at **24,013,603 bytes**, about 24 MB for a tool that counts lines. Each
binary carries the Go runtime, the parts of the standard library it uses, the symbol table and the
debugging information that `file` reports as `with debug_info, not stripped` when its output is not
cut short. Lesson 17 takes those apart with the compiler and linker flags that remove what a release
does not need, and lesson 18 puts a binary in a minimal container image and signs it. This
directory, built by one script from one source tree, is what both of them start from.
