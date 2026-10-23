---
title: Two linker flags and `-trimpath`
version: 1
---

`go build` compiles each package and then calls the linker, `go tool link`, to join them into one
file. **`-ldflags` passes flags through to that linker**, and two of them remove what section 02 found
the program never reads: `-w` drops the DWARF, and `-s` drops the symbol table. A third flag,
`-trimpath`, belongs to the build itself and changes the paths recorded in the binary. Each one is
measured here on its own, and then together.

## One flag at a time

Five builds of the same source, each with one change:

```
ana@vm:~/small$ go build -ldflags="-w" -o hits-w . && go build -ldflags="-s" -o hits-s . && go build -ldflags="-s -w" -o hits-sw .
ana@vm:~/small$ go build -trimpath -o hits-trim . && go build -trimpath -ldflags="-s -w" -o hits-small .
ana@vm:~/small$ stat -c "%s bytes  %n" hits hits-w hits-s hits-sw hits-trim hits-small
4031935 bytes  hits
2869509 bytes  hits-w
2654368 bytes  hits-s
2654368 bytes  hits-sw
4026893 bytes  hits-trim
2650272 bytes  hits-small
```

| build | bytes | smaller than the default by |
|---|---|---|
| `go build` | 4,031,935 | |
| `-ldflags="-w"` | 2,869,509 | 1,162,426 |
| `-ldflags="-s"` | 2,654,368 | 1,377,567 |
| `-ldflags="-s -w"` | 2,654,368 | 1,377,567 |
| `-trimpath` | 4,026,893 | 5,042 |
| `-trimpath -ldflags="-s -w"` | 2,650,272 | 1,381,663 |

**`-w` saves 1,162,426 bytes**, within 119 bytes of the DWARF total that `size` printed. `-s`
saves another 215,141, the symbol table and its names. Together they take **34% off the file**, and
nothing the program does at run time changes, because it never read either part.

**`-s` on its own gave exactly the size of `-s -w`.** The linker's short help says only that `-s`
disables the symbol table, but its documentation says more, and a build that asks for the opposite
shows it:

```
ana@vm:~/small$ go doc cmd/link | grep -A2 "^    -s$"
    -s
    	Omit the symbol table and debug information.
    	Implies the -w flag, which can be negated with -w=0.
ana@vm:~/small$ go build -ldflags="-s -w=0" -o hits-dwarf . && stat -c "%s bytes  %n" hits-dwarf
3816730 bytes  hits-dwarf
ana@vm:~/small$ file hits-small | cut -d, -f1,2,7
hits-small: ELF 64-bit LSB executable, x86-64, stripped
```

`-s` implies `-w`, and `-w=0` turns the DWARF back on, which puts 1,162,362 bytes back. You will see
`-ldflags="-s -w"` in nearly every build script you read, and it is harmless: with this toolchain the
`-w` is already implied. `file` now reports the binary as `stripped`, the word for an executable
with its symbol table removed.

`-trimpath` saved only 5,042 bytes, and size is not why anybody uses it. What it does is in the next
part.

## What a stripped binary still does, and what it no longer does

Start with the tools that read the parts that went. `go tool nm` has nothing to list, and `gdb`, the
GNU debugger, cannot find a function it found in the default build:

```
ana@vm:~/small$ go tool nm hits-small
reading hits-small: no symbol section
reading hits-small: no symbols
ana@vm:~/small$ gdb -batch -ex "info line example.com/hits/internal/tally.Parse" ./hits 2>&1 | tail -1
Line 26 of "/home/ana/small/internal/tally/tally.go" starts at address 0x528ac0 <example.com/hits/internal/tally.Parse> and ends at 0x528ad3 <example.com/hits/internal/tally.Parse+19>.
ana@vm:~/small$ gdb -batch -ex "info line example.com/hits/internal/tally.Parse" ./hits-small 2>&1 | tail -1
No symbol table is loaded.  Use the "file" command.
```

**Debuggers read DWARF and the symbol table, so a stripped binary cannot be debugged at the source
level.** gdb came from Ubuntu's archive (`sudo apt install gdb`) and was already on this machine;
Delve, the debugger written for Go, reads the same DWARF. That is the one real cost, and the usual
answer is to keep the unstripped build of every release you ship, so that a crash on a customer's
machine can be investigated with the binary that matches it.

Now the runtime's own table. **`SIGQUIT` makes a Go program print every goroutine's stack and exit**,
which is a way to see a stack trace without a bug. `timeout -s QUIT 1` sends it after one second,
while `hits count` waits for input from a `sleep` that writes nothing, and `grep` keeps the frames
that belong to `hits`:

```
ana@vm:~/small$ sleep 3 | timeout -s QUIT 1 ./hits-small count 2>&1 | grep -A1 -E "^(main|example)"
example.com/hits/internal/tally.Count({0x674698, 0x1fb62db46028})
	example.com/hits/internal/tally/tally.go:59 +0x12f fp=0x1fb62dbacc40 sp=0x1fb62dbaca58 pc=0x528fef
main.summarise({0x1fb62db58070?, 0x1fb62db58070?, 0x4?}, {0x674698?, 0x1fb62db46028?}, {0x6746d8, 0x1fb62db46038})
	example.com/hits/main.go:111 +0x16b fp=0x1fb62dbacd00 sp=0x1fb62dbacc40 pc=0x52c2cb
main.count({0x1fb62db58070, 0x0, 0x0}, {0x674698, 0x1fb62db46028}, {0x6746d8, 0x1fb62db46030}, {0x6746d8, 0x1fb62db46038})
	example.com/hits/main.go:56 +0x1a5 fp=0x1fb62dbacdd8 sp=0x1fb62dbacd00 pc=0x52ba85
main.run({0x1fb62db58070?, 0x0?, 0x0?}, {0x674698?, 0x1fb62db46028?}, {0x6746d8?, 0x1fb62db46030?}, {0x6746d8, 0x1fb62db46038})
	example.com/hits/main.go:38 +0x12f fp=0x1fb62dbace60 sp=0x1fb62dbacdd8 pc=0x52b76f
main.main()
	example.com/hits/main.go:28 +0x6c fp=0x1fb62dbaceb8 sp=0x1fb62dbace60 pc=0x52b60c
ana@vm:~/small$ sleep 3 | timeout -s QUIT 1 ./hits count 2>&1 | grep -A1 "^main.main"
main.main()
	/home/ana/small/main.go:28 +0x6c fp=0x37eb90ec4eb8 sp=0x37eb90ec4e60 pc=0x52b60c
```

**The stripped binary named every function, its file and its line**, from `tally.Count` down to
`main.main`: that information is in `.gopclntab`, which no flag removes. The same table is why a
CPU profile, which records function names when it is written, reads as well from a stripped binary
as from any other; lesson 12 is about profiles.

The two traces differ in their paths. **`-trimpath` writes `example.com/hits/main.go` where the default
build writes `/home/ana/small/main.go`**, a module path in place of a directory on the build machine,
and the standard library's files lose their `/usr/local/go/src` prefix the same way. `strings` lists
the printable runs of bytes in a file, and the default build contains Ana's home directory:

```
ana@vm:~/small$ strings hits | grep -c /home/ana; strings hits-trim | grep -c /home/ana
2
0
ana@vm:~/small$ go version -m hits-small | head -3
hits-small: go1.27.1
	path	example.com/hits
	mod	example.com/hits	(devel)	
```

**A binary you ship should not carry your home directory**, which can contain a user name and says
how your machine is laid out. And with the paths gone, two people who build the same commit in
different directories get the same paths in the binary, which is one condition for builds that come
out byte for byte the same. Last, the stripped binary still answers `go version -m`, because the
build information has a section of its own and `-s` leaves it alone. Its main module says `(devel)`
because this directory is not yet under version control. Section 04 changes that.
