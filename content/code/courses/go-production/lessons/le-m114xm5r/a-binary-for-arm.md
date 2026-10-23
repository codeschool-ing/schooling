---
title: Running the ARM binary on an Intel machine
version: 1
---

A binary built for another processor is a file of instructions this processor does not have.
**Building it proves only that it compiled**; whether it counts the log correctly is a claim
somebody has to check, and the obvious place to check it is a machine of that kind. When there is
none at hand, an emulator does the job: QEMU's user mode translates one program's ARM instructions
into the host's as they run and passes its system calls to the Linux kernel underneath.

## The kernel refuses it, the emulator runs it

Ubuntu packages the emulators as `qemu-user-static`, one program per processor. The lab machine
already had them, so this line was **not run here**:

```sh
sudo apt install qemu-user-static
```

Asked to run the `arm64` build directly, the kernel looks at the file's header, sees a processor it
does not drive, and refuses. Handed to `qemu-aarch64-static`, the same file runs:

```
ana@vm:~/cross$ ./hits-arm64 count access.log; echo $?
bash: line 1: ./hits-arm64: cannot execute binary file: Exec format error
126
ana@vm:~/cross$ qemu-aarch64-static ./hits-arm64 count access.log
status  requests
200     7554
201     1256
204     1248
301     1192
304     1229
400     1223
401     1226
404     2549
500     1269
503     1254
```

**Exit status 126 is the shell's code for "found it, could not execute it"**, the neighbour of the
127 of lesson 1, which means not found at all. `Exec format error` is the kernel's word for a file
in a format it cannot load. Some machines have the emulator registered with the kernel, through a
mechanism called `binfmt_misc`, and there the direct run works because the kernel hands the file to
QEMU itself. This one does not, so every ARM run in this lesson names the emulator.

The table is lesson 1's table, **7,554 requests with status `200`** and the rest to the digit. A
table read by eye is a weak comparison, so here is a strong one: `diff` between the native binary
and the emulated one, over a longer output.

```
ana@vm:~/cross$ diff <(./hits top -n 8 access.log) <(qemu-aarch64-static ./hits-arm64 top -n 8 access.log) && echo identical
identical
```

`<(command)` is the shell running a command and passing its output to `diff` as if it were a file.
`diff` printed no difference and exited 0, so `echo` ran. Two programs compiled for two processors
from one source read the same 20,000 lines and agreed on every row.

## The binary says what it was built for

A Go binary carries a record of how it was built. `go version -m` reads it without running the file,
which matters for a binary this machine cannot run:

```
ana@vm:~/cross$ go version -m hits-arm64
hits-arm64: go1.27.1
	path	example.com/hits
	mod	example.com/hits	(devel)	
	build	-buildmode=exe
	build	-compiler=gc
	build	CGO_ENABLED=0
	build	GOARCH=arm64
	build	GOOS=linux
	build	GOARM64=v8.0
```

**`GOOS`, `GOARCH` and the Go release are all there**, and so are two settings nobody typed.
`CGO_ENABLED=0` is the go command's own choice for a cross build, which section 04 takes apart.
`GOARM64=v8.0` is the oldest 64-bit ARM processor the code may assume, the default; section 04 shows
its counterpart on Intel. When somebody hands you a binary and asks which machine it is for, this is
the command that answers.

## Running the tests on the other processor

`go test` builds a test binary and runs it, so with `GOARCH=arm64` it builds an ARM test binary and
then fails to start it, for the reason above. Its `-exec` flag names a program to run the test
binary through, and QEMU is such a program:

```
ana@vm:~/cross$ GOARCH=arm64 go test -count=1 .
fork/exec /tmp/go-build4148814532/b001/hits.test: exec format error
FAIL	example.com/hits	0.000s
FAIL
ana@vm:~/cross$ GOARCH=arm64 go test -count=1 -exec qemu-aarch64-static .
ok  	example.com/hits	0.167s
```

**Lesson 1's table test passed on an emulated ARM processor**, every row of it. `-count=1` keeps the
go command from answering with a cached result, so both lines are runs. The 0.167 seconds against
the 0.003 of lesson 1's native run is the price of translating every instruction. On a real ARM
machine the tests run at full speed, and a CI system with an ARM runner is where a project that
ships ARM binaries runs them.

## What could not be run here

The macOS and Windows builds of section 02 were **built and not run**. QEMU's user mode emulates a
processor for a Linux program; it cannot stand in for macOS or Windows, whose system calls are
different. `file` and `go version -m` are what this lesson can say about them: the right format, the
right processor, the right settings. Trying them on a Mac and a Windows machine is the step left to
whoever has one, and for `hits`, which reads a file and writes text, there is little system-specific
left to go wrong.
