---
title: Publishing a module: a tag is a version
version: 1
---

Most package ecosystems publish by uploading: an account on a registry, a command that sends an
archive to it, and the registry's copy is the release. **Go has no registry and nothing to
upload.** A module's path names the repository it lives in, a version is a tag in that repository,
and publishing is pushing the tag. The proxy that served every download in this course reads the
repository when somebody asks for a version, and its answer says where the version came from:

```
ana@vm:~/thirdparty-width$ curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.16.info; echo
{"Version":"v0.0.16","Time":"2024-07-22T12:40:34Z","Origin":{"VCS":"git","URL":"https://github.com/mattn/go-runewidth","Hash":"6ceadc68530e7bfea8cba17d6523bed32912d4fa","Ref":"refs/tags/v0.0.16"}}
```

The version section 02 installed is the git tag `refs/tags/v0.0.16` of a repository on GitHub, at
one commit, whose hash the proxy wrote down. That is all a Go release is.

## What the numbers promise

A version is three numbers, `vMAJOR.MINOR.PATCH`, and Go modules follow the convention called
Semantic Versioning about what each one means:

| you change | so you raise | for example | what a user may assume |
|---|---|---|---|
| a bug, without touching the API | PATCH | v1.1.0 to v1.1.1 | upgrade without reading anything |
| something added: a function, a field | MINOR | v1.0.0 to v1.1.0 | their code still compiles |
| something removed or changed | MAJOR | v1.1.1 to v2.0.0 | nothing; it is a new module (section 05) |

**v0 promises nothing.** Below v1.0.0 any release may break anything, and that is the honest
state for a module whose API is still being found: `go-runewidth` is at v0.0.30 after years of use.
From v1.0.0 on the promise is the one lesson 35 described for a sentinel error, made for the whole
API: what a caller can name, it can keep naming until v2.

## A module of your own, published in the lab

The lab has no code host, so it plays one. `~/thirdparty-greet` is an ordinary git repository
holding a module whose `go.mod` says `module example.com/ana/greet`, with this one file:

```go
// Package greet says hello.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
```

The work was committed, and releasing it is one command:

```
ana@vm:~/thirdparty-greet$ git tag v0.1.0
ana@vm:~/thirdparty-greet$ git log --oneline --decorate
c110eac (HEAD -> main, tag: v0.1.0) greet: Hello
```

On a real host, `git push origin v0.1.0` would be the publication. Here, a small program the lab
wrote does what the proxy does the first time somebody asks for a version: it reads the tag and
writes the answers to a directory, `~/thirdparty-proxy`, laid out the way the `GOPROXY` protocol
asks for them. `go help goproxy` says that such a directory, given as a `file://` URL, is a proxy
like any other:

```
ana@vm:~/thirdparty-greet$ find ~/thirdparty-proxy -type f | sort
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/list
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.info
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.mod
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.zip
ana@vm:~/thirdparty-greet$ cat ~/thirdparty-proxy/example.com/ana/greet/@v/v0.1.0.info; echo
{"Time":"2026-10-01T10:00:00-03:00","Version":"v0.1.0"}
```

Under the module's path, `@v/list` names the versions, `.info` says when each was made, `.mod` is
its `go.mod` and `.zip` is its files. Those four, plus `@latest`, are every request the go command
makes of a proxy; its source, `cmd/go/internal/modfetch/proxy.go`, has one function for each.

## Depending on it, and the checksum database

Another module, `~/thirdparty-app`, imports `example.com/ana/greet` and calls `Hello("Ana")`. Every
command that reads the published module names the lab's proxy with `GOPROXY`. The first attempt
names nothing else:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy go get example.com/ana/greet@v0.1.0
go: downloading example.com/ana/greet v0.1.0
go: example.com/ana/greet@v0.1.0: verifying module: example.com/ana/greet@v0.1.0: reading https://sum.golang.org/lookup/example.com/ana/greet@v0.1.0: 404 Not Found
	server response: not found: example.com/ana/greet@v0.1.0: unrecognized import path "example.com/ana/greet": reading https://example.com/ana/greet?go-get=1: 404 Not Found
```

The download worked and the verification did not. Lesson 38 showed that the go command checks every
module against the public checksum database, sum.golang.org, before using it. **The database does
not take your word for a module's contents: it fetches the module itself**, from the path, and here
the path leads to `example.com`, where nothing answers. A real public module passes this step the
first time anybody downloads it, and from then on its hash is fixed for everybody.

A module that is not public, like one inside a company, is listed in `GONOSUMDB`, or in `GOPRIVATE`,
which `go help private` describes and which also keeps it away from the public proxy. The lab sets
`GONOSUMDB=example.com` beside `GOPROXY` on every command from here on:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@v0.1.0
go: downloading example.com/ana/greet v0.1.0
go: added example.com/ana/greet v0.1.0
ana@vm:~/thirdparty-app$ go mod tidy && go run .
Hello, Ana
ana@vm:~/thirdparty-app$ cat go.sum
example.com/ana/greet v0.1.0 h1:FmIo6uqFcLn7girE5x/uPjTRwuOZFptQYGM6k1U18QI=
example.com/ana/greet v0.1.0/go.mod h1:QFMWQnEnM/cie1zlph17cNjMg9a7FN9R8vsm06XS5Fw=
```

`go.sum` recorded the hash of the zip and of the `go.mod`, as it does for any module. Suppose the
author now changes the code and moves the tag instead of making a new version. The lab let that
happen: it tagged a different commit `v0.1.0`, published it again over the old files, and removed
the copy in the module cache so that the go command had to download it once more:

```
ana@vm:~/thirdparty-greet$ git tag -f v0.1.0
Updated tag 'v0.1.0' (was c110eac)
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go mod download example.com/ana/greet@v0.1.0
verifying example.com/ana/greet@v0.1.0: checksum mismatch
	downloaded: h1:AG4vmWZeBI+aVcIbTfsxRx1h8ETLnamdXmXn+hZZ1zI=
	go.sum:     h1:FmIo6uqFcLn7girE5x/uPjTRwuOZFptQYGM6k1U18QI=

SECURITY ERROR
This download does NOT match an earlier download recorded in go.sum.
The bits may have been replaced on the origin server, or an attacker may
have intercepted the download attempt.

For more information, see 'go help module-auth'.
```

The go command cannot tell a careless author from an attacker, and it treats both the same. For a
public module the checksum database would refuse it for everybody, not only for those who had
downloaded it before. **A published version cannot be changed, only followed by another one.** The
lab put the tag back where it was before going on.

## New versions

The author then tagged v1.0.0 on a commit that changed only the package comment, promising the API,
and wrote a second function for v1.1.0. It is a new function and nothing old changed, so the minor
number goes up:

```go
// Package greet says hello. From v1.0.0 on, its API only grows.
package greet

import "strings"

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, "")
}
```

```
ana@vm:~/thirdparty-greet$ git tag v1.1.0
ana@vm:~/thirdparty-greet$ git tag
v0.1.0
v1.0.0
v1.1.0
```

Each tag went to the proxy as v0.1.0 did. The importer sees them with the commands of section 02:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -versions example.com/ana/greet
example.com/ana/greet v0.1.0 v1.0.0 v1.1.0
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -u all
example.com/app
example.com/ana/greet v0.1.0 [v1.1.0]
```

The importer was on v0.1.0, which promised nothing, and decides to move to the stable line:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@latest
go: downloading example.com/ana/greet v1.1.0
go: upgraded example.com/ana/greet v0.1.0 => v1.1.0
```

The importer's `main.go` now also calls `HelloAll("Ana", "Bia")`, and the new function has a bug
that the author's eyes passed over:

```
ana@vm:~/thirdparty-app$ go run .
Hello, Ana
Hello, AnaBia
```

The names are joined with nothing between them. v1.1.0 is published, somebody has already
upgraded to it, and its hash is in their `go.sum`. Section 05 is what the author does next.
