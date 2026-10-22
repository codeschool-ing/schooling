---
title: "`go install` and the tools you did not write"
version: 1
---

`go install` is `go build` with a fixed destination. **It builds the same executable and puts it in
one directory, the one `GOBIN` names**, and nothing in the current directory changes. That directory
is on your `PATH` since `go` lesson 3, so whatever lands there is a command you can type from
anywhere. The same command fetches and builds programs other people wrote, and the way it does that
deliberately ignores the module you are standing in.

## Your own program, on the `PATH`

```
ana@vm:~/daily$ go env GOBIN GOPATH
/home/ana/go/bin
/home/ana/go
ana@vm:~/daily$ go install . && command -v hits
/home/ana/go/bin/hits
ana@vm:~/daily$ cd /tmp && hits top -n 2 ~/daily/access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/daily$ go version -m ~/go/bin/hits | head -3
/home/ana/go/bin/hits: go1.27.1
	path	example.com/hits
	mod	example.com/hits	(devel)	
```

`GOBIN` was never set on this machine, and `go env` printed what it falls back to: the `bin`
directory inside `GOPATH`, `/home/ana/go/bin`. **Set `GOBIN` and every `go install` writes there
instead**, which is how a team keeps its tools in a project directory of their own. The executable
is named after the import path, exactly as section 02's bare `go build` named it, and from `/tmp` it
answered like any other command.

`go version -m` reads what the go command wrote into a binary while building it: the Go release,
the package path and the module. **`(devel)` is the version of a module built from a directory
rather than downloaded at a version**; a module fetched at a version carries that version instead, as
`stringer` does below. The
rest of that listing, cut by `head` here, is the build settings: `CGO_ENABLED`, `GOOS`, `GOARCH`.
It answers "what is this binary, and how was it built" months later, on a machine where nobody
remembers.

## A tool from somewhere else, at a version

`stringer` is a code generator from the `golang.org/x/tools` module, the kind of program lesson 10's
`go generate` runs. Installing it from inside `~/daily` shows the rule:

```
ana@vm:~/daily$ go install golang.org/x/tools/cmd/stringer
no required module provides package golang.org/x/tools/cmd/stringer; to add it:
	go get golang.org/x/tools/cmd/stringer
ana@vm:~/daily$ go install golang.org/x/tools/cmd/stringer@v0.52.0
go: downloading golang.org/x/tools v0.52.0
go: downloading golang.org/x/sync v0.24.0
go: downloading golang.org/x/mod v0.42.0
ana@vm:~/daily$ cat go.mod
module example.com/hits

go 1.27.1
ana@vm:~/daily$ command -v stringer && go version -m $(command -v stringer) | head -5
/home/ana/go/bin/stringer
/home/ana/go/bin/stringer: go1.27.1
	path	golang.org/x/tools/cmd/stringer
	mod	golang.org/x/tools	v0.52.0	h1:ryxg4U63oaUYk7uOLTF37n43f4qgtGvqV4Ioit1BaEs=
	dep	golang.org/x/mod	v0.42.0	h1:ICeL3t2L30ljSPHHxDnR4fqVcBt/zR2zJAb9juavmQg=
	dep	golang.org/x/sync	v0.24.0	h1:iqiDrGoDgyuvAKrhLQthUEzU/R378N78gXbBjxed7oA=
```

Without a version, `go install` builds **in the context of the current module**: it looks for
`golang.org/x/tools` among the requirements in `go.mod`, finds none, and refuses, with the `go get`
that would add it. **With `@v0.52.0` it ignores `go.mod` altogether.** It downloads that version of
the module and the versions that module itself requires, builds `stringer`, and puts it in `GOBIN`.
`go.mod` is untouched, as `cat` shows, and `go version -m` names the three modules that went into
the binary with the checksum of each.

The separation is deliberate. A tool you run on a project is not a dependency of the project's
code, and adding it to `go.mod` would make `example.com/hits` require `golang.org/x/tools` for no
reason its own packages have. `go help install` lists the conditions: every argument carries the
same version, the packages must be `main` packages of one module, and that module's own `replace`
directives are not allowed. That is what makes the build the same on every machine that asks for that version.
`@latest` works too, and it is what a quick experiment uses; **a version written out is what a
`Makefile` or a CI step should use**, because `@latest` means a different program next month.
`go run golang.org/x/tools/cmd/stringer@v0.52.0` does the same without keeping the executable.

The other way to pin a tool is to make it part of the module on purpose. `go get -tool` records it
in `go.mod` with a `tool` line, and `go tool stringer` then runs it at exactly the version the
module requires. That suits a tool the whole team must run identically, at the price of the tool's
dependencies appearing in `go.mod`.

## Taking it away again

`go clean -i` removes what `go install` put in `GOBIN`. `-n` prints the commands without running
them, which is the safe way to read what a `clean` will do:

```
ana@vm:~/daily$ go clean -i -n .
rm -f /home/ana/daily/hits
rm -f /home/ana/go/bin/hits
ana@vm:~/daily$ go clean -i . ; command -v hits; echo $?
1
```

It removes two files: the `hits` a bare `go build` leaves in the package directory, and the one in
`GOBIN`. `command -v` then finds nothing and returns 1. **`go clean -i` works only on packages of the
current module**: asked for `golang.org/x/tools/cmd/stringer`, it answers with the same "no required
module" refusal as `go install` above, so a tool installed at a version is removed with `rm`.

Here is the whole traffic of the four commands this lesson covers, with the counts this section and
section 02 measured. The test results at the bottom are section 04's subject:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"What the go command reads, keeps and writes. It reads your module, the standard library under /usr/local/go/src and downloaded modules under ~/go/pkg/mod. It keeps compiled packages, go run executables and test results in the build cache, ~/.cache/go-build: 79 compiled packages for hits, 43 MB from an empty cache. go build -o hits writes ./hits, go install writes into GOBIN, ~/go/bin, go run runs the executable it cached, and go test prints ok or (cached).\"><defs><marker id=\"b5-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"115\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it reads</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it keeps</text><text x=\"605\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it writes</text><rect x=\"20\" y=\"50\" width=\"190\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">your module</text><text x=\"115\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/daily</text><text x=\"115\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.go files and go.mod</text><path d=\"M210 83 H262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><rect x=\"20\" y=\"136\" width=\"190\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the standard library</text><text x=\"115\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/local/go/src</text><path d=\"M210 169 H262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><rect x=\"20\" y=\"222\" width=\"190\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the module cache</text><text x=\"115\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/go/pkg/mod</text><text x=\"115\" y=\"273\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">downloaded modules</text><path d=\"M210 255 H262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><rect x=\"265\" y=\"50\" width=\"190\" height=\"238\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOCACHE</text><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/.cache/go-build</text><rect x=\"280\" y=\"100\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">compiled packages</text><text x=\"360\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">79 for hits: 43 MB cold</text><rect x=\"280\" y=\"164\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">go run executables</text><text x=\"360\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linked once, run again</text><rect x=\"280\" y=\"228\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">test results</text><text x=\"360\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">printed as (cached)</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go build -o hits</text><text x=\"605\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">./hits, where -o says</text><rect x=\"510\" y=\"112\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go install</text><text x=\"605\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the directory GOBIN names</text><rect x=\"510\" y=\"174\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go run</text><text x=\"605\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs the cached copy</text><rect x=\"510\" y=\"236\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go test</text><text x=\"605\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ok, or (cached)</text><path d=\"M440 118 H475 V76 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><path d=\"M440 130 H475 V138 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><path d=\"M440 188 H475 V200 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><path d=\"M440 252 H475 V262 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path></svg>", "caption": "Every build goes through the cache. A file appears outside it only where go build -o or go install puts one."}
```
