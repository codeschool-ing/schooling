---
title: Breaking a promise on purpose: retract and /v2
version: 1
---

Section 04 ended with a bad release in the world. The tempting repair is to fix the code and move
the tag, and section 04 showed what every importer then gets: a checksum mismatch and the words
`SECURITY ERROR`. A version, once published, stays. **What an author can do is publish more
versions: a fix, a note that an old one should not be used, and, when the API itself has to
change, a new major version.** This section does all three.

## The fix, and a retraction

The fix is one string, `" and "` where `""` was, so it is a patch: v1.1.1. The release also carries
a line in its `go.mod`, which `go mod edit` writes, as lesson 38 said every kind of line has a
command that writes it:

```
ana@vm:~/thirdparty-greet$ go mod edit -retract=v1.1.0 && cat go.mod
module example.com/ana/greet

go 1.27

retract v1.1.0
```

The reason goes in a comment at the end of the line. `go mod edit` has no flag for it, so the
author types it, and then tags:

```
ana@vm:~/thirdparty-greet$ cat go.mod
module example.com/ana/greet

go 1.27

retract v1.1.0 // HelloAll runs the names together.
ana@vm:~/thirdparty-greet$ git tag v1.1.1
```

**A `retract` directive is a statement, published in a newer version, about an older one.** It
deletes nothing: v1.1.0 is still in the proxy, and whoever has it in `go.sum` can still download
it. The go command reads the directive from the `go.mod` of the module's latest version, and from
then on it treats v1.1.0 differently. The importer still on v1.1.0 is told at once:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -u all
example.com/app
example.com/ana/greet v1.1.0 (retracted) [v1.1.1]
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -versions example.com/ana/greet
example.com/ana/greet v0.1.0 v1.0.0 v1.1.1
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -retracted -versions example.com/ana/greet
example.com/ana/greet v0.1.0 v1.0.0 v1.1.0 v1.1.1
```

The retracted version is marked in `-u`, left out of the plain list of versions, and left out of
`@latest`. It is listed again when you ask for it with `-retracted`.
Upgrading picks the fix, and the program prints what it should:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@latest
go: downloading example.com/ana/greet v1.1.1
go: upgraded example.com/ana/greet v1.1.0 => v1.1.1
ana@vm:~/thirdparty-app$ go run .
Hello, Ana
Hello, Ana and Bia
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet@v1.1.0
go: warning: example.com/ana/greet@v1.1.0: retracted by module author: HelloAll runs the names together.
go: to switch to the latest unretracted version, run:
	go get example.com/ana/greet@latest
go: downgraded example.com/ana/greet v1.1.1 => v1.1.0
```

Asking for v1.1.0 by name still works, and the warning quotes the author's comment from the
directive. That comment is the only explanation an importer will see, so it should say what is
wrong, not just that something is. Section 03 met two real ones in the `go.mod` of `uax29/v2`, and
the two listings show them:

```
ana@vm:~/thirdparty-width$ go list -m -versions github.com/clipperhouse/uax29/v2
github.com/clipperhouse/uax29/v2 v2.0.0 v2.0.1 v2.2.0 v2.3.0 v2.3.1 v2.4.0 v2.5.0 v2.6.0 v2.7.0
ana@vm:~/thirdparty-width$ go list -m -retracted -versions github.com/clipperhouse/uax29/v2
github.com/clipperhouse/uax29/v2 v2.0.0 v2.0.1 v2.1.0 v2.1.1 v2.2.0 v2.3.0 v2.3.1 v2.4.0 v2.5.0 v2.6.0 v2.7.0
```

## A breaking change is a new module

Now the author wants `Hello` to report an empty name instead of greeting nobody. That changes its
signature, and every caller that wrote `s := greet.Hello(name)` stops compiling. Section 04's table
says what that costs: the major version.

```go
// Package greet says hello.
package greet

import (
	"errors"
	"strings"
)

// Hello returns a greeting for name, and an error if name is empty.
func Hello(name string) (string, error) {
	if name == "" {
		return "", errors.New("greet: empty name")
	}
	return "Hello, " + name, nil
}

// HelloAll greets several people at once.
func HelloAll(names ...string) string {
	return "Hello, " + strings.Join(names, " and ")
}
```

In Go a major version above 1 is not only a number. **From v2 on, the major version is part of the
module path**, so the author changes the path in `go.mod` before tagging:

```
ana@vm:~/thirdparty-greet$ go mod edit -module example.com/ana/greet/v2 -dropretract=v1.1.0 && cat go.mod
module example.com/ana/greet/v2

go 1.27
ana@vm:~/thirdparty-greet$ git tag v2.0.0
ana@vm:~/thirdparty-greet$ find ~/thirdparty-proxy -name list | sort
/home/ana/thirdparty-proxy/example.com/ana/greet/@v/list
/home/ana/thirdparty-proxy/example.com/ana/greet/v2/@v/list
```

The retraction was dropped because it is about v1.1.0, which is a version of the other path; the
v1 line keeps its own in v1.1.1. The proxy now holds two modules, each with its own list of
versions, built from the same repository.

The rule has a reason, and it is a promise to the people who import you: **an import path keeps
meaning the same API.** Code that imports `example.com/ana/greet` was written against `Hello`
returning one value, and nothing published later can change what that path means. A breaking API
gets a path of its own. Section 03's `uax29` is a real module that went through it, and its two
paths have separate histories:

```
ana@vm:~/thirdparty-width$ go list -m -versions github.com/clipperhouse/uax29
github.com/clipperhouse/uax29 v0.9.0 v0.9.1 v0.9.2 v0.9.3 v0.9.4 v0.9.6 v0.9.7 v0.9.8 v0.9.9 v0.9.10 v0.9.11 v1.0.0 v1.0.1 v1.0.2 v1.0.3 v1.0.4 v1.0.5 v1.0.6 v1.1.0 v1.2.0 v1.2.1 v1.5.0 v1.6.0 v1.6.1 v1.6.2 v1.6.3 v1.6.4 v1.6.5 v1.6.6 v1.6.7 v1.6.8 v1.6.9 v1.7.0 v1.7.1 v1.8.0 v1.9.0 v1.9.1 v1.10.0 v1.11.0 v1.12.0 v1.12.1 v1.12.2 v1.12.3 v1.12.4 v1.12.5 v1.13.0 v1.14.0 v1.14.2 v1.14.3 v1.15.0 v1.16.0
ana@vm:~/thirdparty-width$ go get github.com/clipperhouse/uax29@v2.7.0
go: github.com/clipperhouse/uax29@v2.7.0: invalid version: go.mod has post-v2 module path "github.com/clipperhouse/uax29/v2" at revision v2.7.0
```

The tag `v2.7.0` is in the same repository as `v1.16.0`, and asked for under the path without
`/v2` it is refused, because its own `go.mod` says it belongs to the other path. A repository whose
`v2.0.0` tag kept the old path in `go.mod` would be refused the same way; lesson 38's
`+incompatible` versions are what the go command makes of repositories that had no `go.mod` at all.

## Both at once

Because the two major versions are two modules, one program can use both. The importer's `main.go`
keeps the v1 package and imports v2 under a name of its own, since both packages are called `greet`:

```go
package main

import (
	"fmt"

	"example.com/ana/greet"
	greetv2 "example.com/ana/greet/v2"
)

func main() {
	fmt.Println(greet.HelloAll("Ana", "Bia"))
	if _, err := greetv2.Hello(""); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go get example.com/ana/greet/v2@v2.0.0
go: downloading example.com/ana/greet/v2 v2.0.0
go: added example.com/ana/greet/v2 v2.0.0
ana@vm:~/thirdparty-app$ go mod tidy && go run .
Hello, Ana and Bia
greet: empty name
ana@vm:~/thirdparty-app$ go list -m all
example.com/app
example.com/ana/greet v1.1.1
example.com/ana/greet/v2 v2.0.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"One git repository, ~/thirdparty-greet, with five tags along one branch: v0.1.0, v1.0.0, v1.1.0, v1.1.1 and v2.0.0. The first four are versions of the module example.com/ana/greet, and v1.1.0 among them is retracted. The tag v2.0.0 is a version of a different module, example.com/ana/greet/v2, because its go.mod names that path. example.com/app requires v1.1.1 of the first module and v2.0.0 of the second, and builds with both.\"><defs><marker id=\"mv-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one repository, one branch, five tags</text><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/thirdparty-greet</text><path d=\"M200 62 L680 62\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><rect x=\"224\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v0.1.0</text><rect x=\"314\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.0.0</text><rect x=\"404\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.0</text><rect x=\"494\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.1</text><rect x=\"624\" y=\"56\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2.0.0</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">module path</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">example.com/ana/greet</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">example.com/ana/greet/v2</text><path d=\"M230 94 L230 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"196\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v0.1.0</text><path d=\"M320 94 L320 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"286\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.0.0</text><path d=\"M410 94 L410 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"376\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"410\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">v1.1.0</text><text x=\"410\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">retracted</text><path d=\"M500 94 L500 134\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><rect x=\"466\" y=\"138\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"500\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.1</text><path d=\"M630 94 L630 194\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#mv-wire)\"></path><text x=\"630\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">go.mod names the /v2 path</text><rect x=\"596\" y=\"198\" width=\"68\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></rect><text x=\"630\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2.0.0</text><path d=\"M200 186 L680 186\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">example.com/app builds with the two marked versions: two modules, one build</text></svg>", "caption": "A new major version is a new module path. The repository is the same; what changed is the path in go.mod, and with it the import path, so an importer can hold both."}
```

That is what makes a major upgrade something you do one package at a time in a large program,
rather than all at once. And it is why the go command never does it for you:

```
ana@vm:~/thirdparty-app$ GOPROXY=file:///home/ana/thirdparty-proxy GONOSUMDB=example.com go list -m -u all
example.com/app
example.com/ana/greet v1.1.1
example.com/ana/greet/v2 v2.0.0
```

`example.com/ana/greet v1.1.1` has no brackets, although v2.0.0 exists. `-u`, `@latest` and
`go get -u` stay inside one module path, so they never cross a major version. **Moving to v2 is a
change to your code**, the import paths and whatever the new API asks of the calls, and you make it
when you have read why the author broke the promise.

Two details complete the rule. v0 and v1 share a path, because v0 never promised anything, so
the first stable release needs no new path. And there is no `/v1` suffix to add:

```
ana@vm:~/thirdparty-v1$ go mod init example.com/ana/greet/v1
go: invalid module path "example.com/ana/greet/v1": major version suffixes must be in the form of /vN and are only allowed for v2 or later:
	go mod init example.com/ana/greet/v2
```
