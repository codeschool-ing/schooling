---
title: A module path, and what go.mod says
version: 1
---

Lesson 4 ran `go mod init example.com/hello` and called the argument the module's **path**. It looks
like a web address, and the usual conclusion is that the go command visits it, so you need a
repository somewhere before you can start. **`go mod init` asks nothing of the network.** The path
is a name, checked for its shape and nothing else, and it becomes an address only on the day
somebody else asks to download your module.

This lesson's module is the program lesson 8 promised: it compares two spellings of `café`, and
section 03 gives it its first dependency. It starts as one file in `~/mods-accents`. Without an
argument, `init` refuses, and so it does with a name that has a space in it:

```
ana@vm:~/mods-accents$ go mod init
go: cannot determine module path for source directory /home/ana/mods-accents (outside GOPATH, module path must be specified)

Example usage:
	'go mod init example.com/m' to initialize a v0 or v1 module
	'go mod init example.com/m/v2' to initialize a v2 module

Run 'go help mod init' for more information.
ana@vm:~/mods-accents$ go mod init "my accents"
go: malformed module path "my accents": invalid char ' '
```

The first message mentions `GOPATH` because, under the arrangement lesson 3 described, the directory
a package sat in was its name. Outside `GOPATH` there is nothing to work it out from, so you say it.
The example usage also hints at a rule about `v2` that this section comes back to at the end.

```
ana@vm:~/mods-accents$ go mod init example.com/accents
go: creating new go.mod: module example.com/accents
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/mods-accents$ cat go.mod
module example.com/accents

go 1.27.1
```

## Choosing the path

What you write depends on who will ever import the code.

| the code is | write | why |
|---|---|---|
| yours, imported by nobody else | `example.com/accents`, or any name of the right shape | `example.com` is reserved for examples, so it can never clash with a real module |
| going to be published | where it will live: `github.com/ana/accents` | the go command finds a module by asking for its path, and lesson 40 publishes one |
| a word with no dot, like `hello` | allowed, and best avoided | the go command reads a first element with no dot as the standard library |

The last row is easy to check. Another module that imports a package from a module called `hello`
gets this:

```
ana@vm:~/mods-dotless$ go build
main.go:3:8: package hello/greet is not in std (/usr/local/go/src/hello/greet)
```

The go command looked for `hello/greet` inside `/usr/local/go/src`, where `fmt` and `strings` live,
and went no further. A path that starts with a domain never meets that problem, which is why almost
every module path you will read begins with one.

**Renaming a module later means editing every import of its packages**, because, as lesson 39 shows,
an import path starts with the module path. Choosing the published address on the first day costs
nothing, even if the repository does not exist yet.

## The lines go.mod can hold

The file `init` wrote has two lines. `module` names the module. `go` is the version of the language
the module is written in, which lesson 2 showed deciding how a loop variable behaves. Section 03
adds a third, `require`, and those three are what most `go.mod` files contain.

The format has room for more. `go help mod edit` lists a flag for each kind of line, and there are
ten: `module`, `go`, `toolchain`, `godebug`, `require`, `exclude`, `replace`, `retract`, `tool` and
`ignore`. Lesson 2 met `toolchain`, the release a module would rather be built with, and lesson 40
writes `retract` when it publishes a version. **Every kind of line has a command that writes it**,
`go mod edit` at the least, and the command is the one to reach for: it checks what it writes.

## Reading a path and a version

Lesson 1 asked the module proxy for the latest version of four programs and printed lines like
these:

```
k8s.io/kubernetes v1.37.1
github.com/prometheus/prometheus v0.315.0
github.com/docker/docker v28.5.2+incompatible
```

Each line is a module path and a version. The paths start with a domain, as the table above
recommends: Kubernetes uses a short domain of its own, `k8s.io`, and the other two name GitHub. The
versions are **semantic versions**, `vMAJOR.MINOR.PATCH`. A new PATCH fixes something, a new MINOR
adds something, and a new MAJOR is allowed to break the code that used the old one. Kubernetes is at
major 1. Prometheus is at major 0, minor 315, and major 0 promises no compatibility at all from one
release to the next; lesson 40 says what a module owes its users at each major.

Docker's line is the odd one. Its repository was tagged `v28.5.2`, and a Go module at major 2 or
above ends its path in that major, `/v2` for major 2 and `/v28` for Docker's. That is the rule the
`v2` example in `init`'s message hinted at. Docker's path does not, so the go command accepts the
tag and marks it. `go list -m -json` shows where the version came from, and the file the go command
uses as its `go.mod`:

```
ana@vm:~/mods-accents$ go list -m -json github.com/docker/docker@v28.5.2+incompatible
{
	"Path": "github.com/docker/docker",
	"Version": "v28.5.2+incompatible",
	"Time": "2025-11-05T14:19:32Z",
	"GoMod": "/home/ana/go/pkg/mod/cache/download/github.com/docker/docker/@v/v28.5.2+incompatible.mod",
	"Origin": {
		"VCS": "git",
		"URL": "https://github.com/docker/docker",
		"Hash": "89c5e8fd66634b6128fc4c0e6f1236e2540e46e0",
		"Ref": "refs/tags/v28.5.2"
	}
}
ana@vm:~/mods-accents$ cat ~/go/pkg/mod/cache/download/github.com/docker/docker/@v/v28.5.2+incompatible.mod
module github.com/docker/docker
```

The tag is `refs/tags/v28.5.2`, a commit in a git repository. The `go.mod` is one line with no `go`
line and no requirements, because that commit has no `go.mod` of its own, and a one-line stand-in
takes its place. The go command's source states the condition in a comment, in
`modfetch/coderepo.go`: a plain tag on a path with no major-version suffix is allowed with
`+incompatible` only **"if the underlying file tree has no go.mod"**. So `+incompatible` means a
repository past v1 that never adopted modules. The code still builds; the suffix tells you that its
versions carry none of the promises a module's versions make.
