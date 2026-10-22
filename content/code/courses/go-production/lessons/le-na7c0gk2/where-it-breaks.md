---
title: Where it breaks
version: 1
---

The `registered [csv mean]` line in section 02 is the key to every failure in this section. **Once
`plugin.Open` returns, the host and the plugin are one program, and every package they both import
exists in it once: the host's copy.** The plugin's code calls the host's `report`, the host's
`tally` and the host's runtime. So the runtime will load a plugin only if each of those shared
packages was compiled exactly as the host's was, and it checks that at `Open`, package by package.

## One copy of every package

How much the two share is a question `go list` answers. `-deps` prints a package and everything it
imports:

```
ana@vm:~/plugins$ go list -deps -buildmode=plugin ./plugins/csv | sort > plugin.deps
ana@vm:~/plugins$ go list -deps ./cmd/hits-plugin | sort > host.deps
ana@vm:~/plugins$ comm -12 plugin.deps host.deps | wc -l
66
ana@vm:~/plugins$ comm -23 plugin.deps host.deps
encoding/csv
example.com/hits/plugins/csv
example.com/hits/reporters/csv
ana@vm:~/plugins$ wc -l < plugin.deps; wc -l < host.deps
69
68
ana@vm:~/plugins$ nm -D --defined-only hits-plugin | wc -l
10406
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 362\" role=\"img\" aria-label=\"Two panels. The host, hits-plugin, holds 68 packages: 64 from the standard library including the runtime, internal/tally, report, plugin and cmd/hits-plugin. The plugin file, csv.so, holds 69: its own copies of the same 64 standard-library packages, of internal/tally and of report, which arrows bind to the host's copies, and three packages the host does not have, encoding/csv, reporters/csv and plugins/csv, which are loaded from the file.\"><defs><marker id=\"pl-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"300\" height=\"310\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the host, a program</text><text x=\"170\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">hits-plugin</text><rect x=\"420\" y=\"40\" width=\"280\" height=\"310\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the plugin, a file</text><text x=\"560\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">csv.so</text><rect x=\"40\" y=\"76\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">64 standard-library packages,</text><text x=\"170\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the runtime among them</text><rect x=\"40\" y=\"132\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">internal/tally</text><rect x=\"40\" y=\"172\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">report</text><rect x=\"40\" y=\"222\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">plugin</text><rect x=\"40\" y=\"262\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cmd/hits-plugin</text><text x=\"170\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">68 packages</text><rect x=\"440\" y=\"76\" width=\"240\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"560\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own copy of the same 64</text><path d=\"M438 99.0 H304\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pl-arrow)\"></path><rect x=\"440\" y=\"132\" width=\"240\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"560\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own copy of internal/tally</text><path d=\"M438 147.0 H304\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pl-arrow)\"></path><rect x=\"440\" y=\"172\" width=\"240\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"560\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own copy of report</text><path d=\"M438 187.0 H304\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pl-arrow)\"></path><rect x=\"440\" y=\"232\" width=\"240\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">encoding/csv</text><rect x=\"440\" y=\"262\" width=\"240\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reporters/csv</text><rect x=\"440\" y=\"292\" width=\"240\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plugins/csv</text><text x=\"560\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">69 packages: 66 shared, 3 new</text><text x=\"370\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">bound to the</text><text x=\"370\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">host's copy</text><text x=\"560\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">loaded from the file</text></svg>", "caption": "After plugin.Open there is one copy of each package in the process. The 66 that csv.so shares with the host are bound to the host's copies, and their hashes must match, so only three packages come from the file."}
```

**Sixty-six of the sixty-nine packages in `csv.so` are already in the host**, the runtime among
them. At load time the dynamic linker binds every reference to them to the host's definitions,
which is why the host exports 10,406 symbols for a plugin to bind to. The plugin's own copies of
those 66 are dead weight in the file: its calls go to the host's. Each package carries a hash of
what it was compiled to, and the runtime compares the plugin's hash with the host's for every
shared package before it runs a single `init`. Everything below is that comparison failing.

## A shared package changed

The ordinary way to break a plugin is to improve the host. A new method on `Summary`, in a file of
its own, `internal/tally/errors.go`:

```go
package tally

// Errors is the number of requests that ended with a status of 500 or more.
func (s Summary) Errors() int {
	n := 0
	for status, count := range s.ByStatus {
		if status >= 500 {
			n += count
		}
	}
	return n
}
```

The host is rebuilt and the plugins are not, which is what happens when the plugins were built by
somebody else, last month:

```
ana@vm:~/plugins$ go build -o hits-plugin ./cmd/hits-plugin
ana@vm:~/plugins$ ./hits-plugin access.log csv.so; echo $?
hits-plugin: plugin.Open("csv"): plugin was built with a different version of package example.com/hits/internal/tally
1
ana@vm:~/plugins$ go build -buildmode=plugin -o csv.so ./plugins/csv && go build -buildmode=plugin -o mean.so ./plugins/mean
ana@vm:~/plugins$ ./hits-plugin access.log csv.so mean.so | tail -1
hits-plugin: registered [csv mean]
20000 requests, mean 200ms
```

**One added method in a package the CSV reporter never calls, and the plugin refuses to load.**
The message names the package, `example.com/hits/internal/tally`, and it is right: `csv.so` was
compiled against a `tally` without `Errors`. Rebuilding both plugins from the same source is the
only fix, and after it both load again. That is the rule `go doc plugin` states without
softening: in practice the application and its plugins must all be built together, by one
person or one part of a system.

## The same source, other flags

The hash covers how a package was compiled, so the same source built two ways counts as two
versions. The release build of a host often carries `-trimpath`, which lessons 17 and 18 use. A
CI job might test it with `-race`, from lesson 15. And a plugin author may simply be one patch
release of Go ahead:

```
ana@vm:~/plugins$ go build -trimpath -o hits-trim ./cmd/hits-plugin && ./hits-trim access.log csv.so
hits-plugin: plugin.Open("csv"): plugin was built with a different version of package internal/goarch
ana@vm:~/plugins$ go build -race -o hits-race ./cmd/hits-plugin && ./hits-race access.log csv.so
hits-plugin: plugin.Open("csv"): plugin was built with a different version of package internal/runtime/sys
ana@vm:~/plugins$ GOTOOLCHAIN=go1.27.2 go version
go version go1.27.2 linux/amd64
ana@vm:~/plugins$ GOTOOLCHAIN=go1.27.2 go build -buildmode=plugin -o csv-next.so ./plugins/csv
ana@vm:~/plugins$ ./hits-plugin access.log csv-next.so
hits-plugin: plugin.Open("csv-next"): plugin was built with a different version of package internal/goarch
```

**None of the three messages names the actual cause.** The first package whose hash differs is
deep in the runtime, `internal/goarch` or `internal/runtime/sys`. A person reading
`different version of package internal/goarch` after upgrading from Go 1.27.1 to 1.27.2 has to know
this section to understand it. The race detector is a problem even when both sides agree:
`go doc plugin` warns that it supports plugins poorly and may miss even simple races.

## Nothing comes out

`plugin.Plugin` has `Lookup` and nothing else:

```
ana@vm:~/plugins$ go doc plugin.Plugin
package plugin // import "plugin"

type Plugin struct {
	// Has unexported fields.
}
    Plugin is a loaded Go plugin.

func Open(path string) (*Plugin, error)
func (p *Plugin) Lookup(symName string) (Symbol, error)
ana@vm:~/plugins$ cp csv.so csv-copy.so && cmp csv.so csv-copy.so && echo identical
identical
ana@vm:~/plugins$ ./hits-plugin access.log csv.so csv-copy.so | wc -l
hits-plugin: plugin.Open("csv-copy"): plugin already loaded
11
```

**There is no `Close`, and there will be no unloading**: the documentation says a plugin cannot be
closed. And a second file holding the same plugin does not load beside the first. `csv-copy.so` is
a byte-for-byte copy of `csv.so`, and the runtime refuses it because a plugin is identified by its
package path, `example.com/hits/plugins/csv`, and that path is already in the process. A rebuilt
`csv.so` with a bug fixed is refused the same way. **The only way to run a new version of a plugin
is a new process**, which is the one thing a plugin system is usually built to avoid.

## Fourteen platforms, and only with cgo

Loading goes through the C library, so building a plugin needs cgo, and so does loading one:

```
ana@vm:~/plugins$ CGO_ENABLED=0 go build -buildmode=plugin -o x.so ./plugins/csv
-buildmode=plugin requires external (cgo) linking, but cgo is not enabled
ana@vm:~/plugins$ GOOS=windows go build -buildmode=plugin -o x.dll ./plugins/csv
-buildmode=plugin not supported on windows/amd64
ana@vm:~/plugins$ GOOS=darwin GOARCH=arm64 go build -buildmode=plugin -o x.so ./plugins/csv
-buildmode=plugin requires external (cgo) linking, but cgo is not enabled
ana@vm:~/plugins$ CGO_ENABLED=0 go build -o hits-nocgo ./cmd/hits-plugin && ./hits-nocgo access.log csv.so
hits-plugin: plugin: not implemented
ana@vm:~/plugins$ go tool dist list | wc -l
47
```

Four refusals of different kinds. A plugin cannot be built with cgo off, or for Windows at all.
Cross-compiling one for a Mac fails with the cgo message, because the go command turns cgo off by
default when it cross-compiles, and turning it back on needs a C compiler for the target. The last
refusal is the treacherous one: **a host built with `CGO_ENABLED=0` compiles without complaint, and
`plugin.Open` fails when it runs**, with `plugin: not implemented`. The toolchain's own table of
supported build modes, in `src/internal/platform/supported.go`, allows plugins on 14 of the 47
platforms in that list: nine Linux architectures, two Android, two macOS and FreeBSD on amd64.
