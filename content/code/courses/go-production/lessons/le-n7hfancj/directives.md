---
title: A comment that names a command
version: 1
---

`go generate` is the one go command with no work of its own. **It reads `.go` files for comments of
the form `//go:generate command arguments`, and runs each command, in order, in the directory of the
package that holds it.** The command can be any program on your machine. The intent, in the words of
`go help generate`, is "to create or update Go source files": a `String` method for a set of
constants, a lookup table, the code a protocol definition describes. The program that does the
writing is called a generator, and the comment that names it is a directive.

The common belief is that `go build` runs the directives first, the way `make` runs a rule before it
compiles. **It never does.** The help text says so in two sentences: "Go generate is never run
automatically by go build, go test, and so on. It must be run explicitly." Everything else about
generated code in Go follows from that one decision, and section 05 is about living with it.

## Four directives and a comment

To see what the go command does with a directive, without a generator in the way, make a module of
its own in `~/gen-try` with `go mod init example.com/try`, and give it a package that holds nothing
but directives. Save it as `internal/demo/demo.go`:

```go
// Package demo holds nothing but directives, to show what go generate does
// with each one.
package demo

//go:generate echo file=$GOFILE package=$GOPACKAGE line=$GOLINE arch=$GOARCH
//go:generate pwd
//go:generate printf [%s]\n "two words" two words
//go:generate touch made-by-generate
// go:generate echo this line has a space after the slashes
```

The syntax is short. **The line starts with `//go:generate` in the first column, with no space after
the slashes**, and the rest is a command and its arguments, split at spaces. A double-quoted string
is one argument, unquoted the way Go unquotes a string literal. `$GOFILE`, `$GOPACKAGE`, `$GOLINE`
and `$GOARCH` are set by go generate, any other `$NAME` comes from the environment, and nothing else
is expanded: there is no shell, so a `*` or a `|` is just a character. The last line has a space
after its slashes, which makes it an ordinary comment.

Built first, then generated:

```
ana@vm:~/gen-try$ go build ./... && ls internal/demo
demo.go
ana@vm:~/gen-try$ go generate ./...
file=demo.go package=demo line=5 arch=amd64
/home/ana/gen-try/internal/demo
[two words]
[two]
[words]
ana@vm:~/gen-try$ ls internal/demo
demo.go
made-by-generate
```

`go build` compiled the package and ran nothing: the directory held only `demo.go` afterwards.
`go generate ./...` then ran four commands, one per directive, top to bottom, and every line of
output says something about the rules:

- `file=demo.go package=demo line=5` describes the directive itself, its file, its package and its
  line. A generator reads `$GOFILE` to know which file asked for it and `$GOPACKAGE` to know what
  package clause to write.
- `/home/ana/gen-try/internal/demo` is where `pwd` ran. **A directive runs in its package's
  directory**, wherever you typed `go generate`, so a path in a directive is relative to the file
  that holds it.
- `[two words]` came out as one argument and `[two]` and `[words]` as two. The quotes chose the
  boundary and were gone before `printf` started.
- `made-by-generate` is in the listing because `touch` ran. What a generator writes is an ordinary
  file, and it stays.
- Nothing came from the last line. The space made it a comment, and go generate ignores it without
  a word.

## Reading the commands before they run

Running a directive you have not read means running a program you have not chosen, so go generate
has flags for looking first. **`-n` prints each command and runs none; `-x` prints each command as
it runs it.** `-run` takes a regular expression and keeps only the directives whose whole line
matches, `-skip` drops the ones that match, and `-v` names each file as it is read:

```
ana@vm:~/gen-try$ go generate -n ./...
echo file=demo.go package=demo line=5 arch=amd64
pwd
printf [%s]\n two words two words
touch made-by-generate
ana@vm:~/gen-try$ GOARCH=arm64 go generate -x -run echo ./...
echo file=demo.go package=demo line=5 arch=arm64
file=demo.go package=demo line=5 arch=arm64
ana@vm:~/gen-try$ go generate -v -skip "touch|printf" ./...
internal/demo/demo.go
file=demo.go package=demo line=5 arch=amd64
/home/ana/gen-try/internal/demo
```

`-n` shows the arguments after the variables and the quotes were dealt with, which is why
`two words` appears bare: it is still one argument, and the printout can no longer say so. **`$GOARCH`
is the architecture being built for, not the one the machine has.** Set to `arm64` on this amd64
machine, it said `arm64`, and a generator that writes code per platform reads it for exactly that;
lesson 16 sets `GOARCH` for real. `-run echo` kept one directive, because the expression is matched
against the directive's whole line, `//go:generate echo file=…`, and the comment at the bottom is not
a directive at all.

`go generate` takes the same package patterns as `go build`, so `./...` is every package of the
module. **Within a package the files go in name order, and within a file the directives go from top
to bottom.** If a command exits with anything but 0, go generate skips the rest of that package and
reports the failure; section 04 shows that with a generator refusing its input.

## The author's step, not the builder's

There is a reason for keeping generation out of the build. A directive runs any program, so a
`go build` that ran directives would run whatever a dependency's source asked for, on every machine
that compiled it, and would need every generator installed everywhere. **Instead, generating is a
step for whoever changes the source**: they run `go generate`, and the files it writes are committed
next to the code that asked for them. Somebody who adds your module to theirs downloads the generated
files with the rest and never runs, or needs, your generator.

The cost is that the source and the generated files can disagree. Nothing in `go build` notices a
file nobody regenerated, and sections 03 and 05 show two ways to find out.
