---
title: Which build is this? Traces from production
version: 1
---

A trace from production arrives with a question attached: line 20 of `main.go`, but **which**
`main.go`? The code on your machine has moved on since the binary was built. And people who learnt
on C or C++ bring a second worry, that a binary shipped stripped and optimised prints addresses
instead of lines. **In Go both answers are inside the binary.** It records the commit and the Go it
was built from, and stripping it does not take out its file and line table.

## The binary knows its commit

`~/stacks-release` is the order program of section 02 in a git repository with one commit, plus one
function, `version`, that `main` calls first to print where the binary came from:

```go
// version says which commit and which Go this binary was built from.
func version() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "unknown"
	}
	rev := "unknown"
	for _, s := range info.Settings {
		if s.Key == "vcs.revision" {
			rev = s.Value[:12]
		}
	}
	return info.Main.Version + " " + rev + " " + info.GoVersion
}

func main() {
	fmt.Println("stacks", version())
	order := []line{{"coffee", 2}, {"cake", 4}}
	fmt.Println(orderTotal(order))
}
```

```
ana@vm:~/stacks-release$ git log --oneline
d569db7 Total an order
ana@vm:~/stacks-release$ go build && ./stacks 2>/dev/null; echo $?
stacks v0.0.0-20261006130000-d569db795b44 d569db795b44 go1.27.1
2
```

The trace went to `/dev/null` here, so only the first line shows, and that line is the point: the
module's version, the commit and the Go release, printed by the program about itself before it did
anything else. `debug.ReadBuildInfo` reads what the go command wrote into the binary when it built
it:

```
ana@vm:~/stacks-release$ go doc runtime/debug.ReadBuildInfo
package debug // import "runtime/debug"

func ReadBuildInfo() (info *BuildInfo, ok bool)
    ReadBuildInfo returns the build information embedded in the running binary.
    The information is available only in binaries built with module support.

```

`go version -m` reads the same record from outside, from any Go binary, without running it:

```
ana@vm:~/stacks-release$ go version -m stacks
stacks: go1.27.1
	path	example.com/stacks
	mod	example.com/stacks	v0.0.0-20261006130000-d569db795b44	
	build	-buildmode=exe
	build	-compiler=gc
	build	CGO_ENABLED=1
	build	CGO_CFLAGS=
	build	CGO_CPPFLAGS=
	build	CGO_CXXFLAGS=
	build	CGO_LDFLAGS=
	build	GOARCH=amd64
	build	GOOS=linux
	build	GOAMD64=v1
	build	vcs=git
	build	vcs.revision=d569db795b44a1fd42d691bd80c40be2d01226db
	build	vcs.time=2026-10-06T13:00:00Z
	build	vcs.modified=false
```

`path` is the main package and `mod` is its module. With no version tag on the commit, the go command
made a version up from it: `v0.0.0`, the commit's time in UTC, and the first twelve characters of
its hash, the commit `git log` showed as `d569db7`. The `build` lines are the settings
the build used, and the last four are the ones an incident needs:

```
ana@vm:~/stacks-release$ go doc runtime/debug.BuildSetting | sed -n 27,32p
      - vcs: the version control system for the source tree where the build ran
      - vcs.revision: the revision identifier for the current commit or checkout
      - vcs.time: the modification time associated with vcs.revision, in RFC3339
        format
      - vcs.modified: true or false indicating whether the source tree had local
        modifications
```

**`vcs.revision` is the exact commit, and `vcs.modified=false` says the binary was built from it
and nothing else.** A build from a tree with uncommitted changes says `true`, and then the commit
alone does not describe the code. That is why `.gitignore` in this directory names the three
binaries built here: a binary lying in the tree counts as a change too. The go command stamps all of
this by itself when it builds inside a repository; nothing in the program or the build command asked
for it.

## `-trimpath`: no home directory in the binary

The file names in a trace are the ones the compiler saw, and on a laptop that means the builder's
home directory:

```
ana@vm:~/stacks-release$ ./stacks 2>&1 | tail -2
main.main()
	/home/ana/stacks-release/main.go:53 +0x1c8
ana@vm:~/stacks-release$ go build -trimpath -o trim . && ./trim 2>&1 | tail -2
main.main()
	example.com/stacks/main.go:53 +0x1c8
ana@vm:~/stacks-release$ go version -m trim | grep trimpath
	build	-trimpath=true
```

`-trimpath` replaced `/home/ana/stacks-release` with the module path, and `go version -m` records
that it was used. Its help says what it does:

```
ana@vm:~/stacks-release$ go help build | sed -n 167,171p
	-trimpath
		remove all file system paths from the resulting executable.
		Instead of absolute file system paths, the recorded file names
		will begin either a module path@version (when using modules),
		or a plain import path (when using the standard library, or GOPATH).
```

For the main module the run shows the module path alone, with no `@version`. Either way **the binary
no longer carries a path from the machine that built it**, which leaves user names and directory
layouts out of what you ship, and lets two machines building the same commit produce the same file
names in their traces. Builds meant for other people's machines usually set it.

## Stripped, and still readable

`-ldflags` passes flags to the linker, and `-s` is the one that strips:

```
ana@vm:~/stacks-release$ go doc cmd/link | sed -n 118,120p
    -s
    	Omit the symbol table and debug information.
    	Implies the -w flag, which can be negated with -w=0.
ana@vm:~/stacks-release$ go build -ldflags=-s -o small . && ./small 2>&1 | head -6
stacks v0.0.0-20261006130000-d569db795b44 d569db795b44 go1.27.1
panic: runtime error: index out of range [4] with length 4

goroutine 1 [running]:
main.unitPrice(...)
	/home/ana/stacks-release/main.go:20
```

The stripped binary still printed `main.unitPrice` and `main.go:20`. Its size and its build record:

```
ana@vm:~/stacks-release$ wc -c stacks small
2430545 stacks
1568928 small
3999473 total
ana@vm:~/stacks-release$ go version -m small | head -3
small: go1.27.1
	path	example.com/stacks
	mod	example.com/stacks	v0.0.0-20261006130000-d569db795b44	
```

A third smaller, and the module and its version are still in its record.
**Stripping takes out the symbol table and the DWARF information that debuggers read; the table the
runtime reads to print a trace is part of the program and stays.** A Go binary in production, built
however a release script likes, still turns a crash into function names, files and lines.

## From a trace to a line of code

So the binary gave a commit, and the trace gave a file and a line. Together they are an address in
the repository, and git can open it without anybody checking anything out:

```
ana@vm:~/stacks-release$ git show d569db795b44:main.go | sed -n 20p
	return prices[item] * (100 - discount[qty]) / 100
```

That is line 20 of `main.go` as it was in the commit the binary was built from, `discount[qty]` and
all, which is the bug section 02 found. **Log the version at start-up, keep the default
`GOTRACEBACK`, and a trace from a machine you cannot log into points at one line of one commit.**
