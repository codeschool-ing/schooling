---
title: A version the binary can state
version: 1
---

When somebody reports a bug in a tool, the first question is which build they are running, and the
binary should be able to answer it. **A version written in a source file is a second copy of the
release's name**, and somebody has to remember to edit it before every release. The day nobody does,
the program states last month's version with confidence, which is worse than stating none. The
version belongs where the release is actually named, the git tag. Two mechanisms carry it from
there into the binary: what the go command records by itself, and `-X`, a linker flag that sets a
string variable while the program is linked.

## What the go command records

`go version -m` printed a `mod` line ending in `(devel)` in section 03, because `~/small` was not a
repository. It becomes one now, with git from Ubuntu's archive (`sudo apt install git`, if
`git --version` finds nothing). First a file that keeps the builds and the log out of the repository,
`.gitignore`:

```
/hits*
access.log
```

Then the directory is put under git, with one commit and a tag:

```
ana@vm:~/small$ git init -q && git add . && git commit -q -m "hits as lesson 1 left it" && git tag v1.0.0
ana@vm:~/small$ git log --oneline --decorate
c8e4f11 (HEAD -> master, tag: v1.0.0) hits as lesson 1 left it
```

The revision, `c8e4f11`, depends on who committed and when, so yours will be different. Built
again, the binary carries the tag and the commit:

```
ana@vm:~/small$ go build -o hits . && go version -m hits
hits: go1.27.1
	path	example.com/hits
	mod	example.com/hits	v1.0.0	
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
	build	vcs.revision=c8e4f11b0e80eec15e63704cd47c43985015d274
	build	vcs.time=2026-10-01T12:00:00Z
	build	vcs.modified=false
```

**The `mod` line now says `v1.0.0`, the tag on the commit that was built**, and four `vcs` settings
record that the source came from git, which revision, when it was committed and whether the working
tree had changes. Nothing in the build command asked for this. `go help build` describes the flag that
controls it, `-buildvcs`: in its default mode, `auto`, the go command stamps the information whenever
the main package, its module and the current directory are in the same repository, and
`-buildvcs=false` leaves it out.

## A `version` subcommand

`go version -m` reads all of this from outside. The program can read it too, through
`runtime/debug`, and print it alongside a name of its own. That takes one new file, `version.go`,
beside `main.go`:

```schooling-example
{
  "language": "go",
  "file": "version.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"runtime/debug\"\n\t\"strings\"\n)\n",
      "note": "A second file in package `main`, beside lesson 1's `main.go`. **`runtime/debug` is where a program reads what the go command recorded about its own build.**"
    },
    {
      "code": "// version names the release. The source says \"dev\", and a release build\n// replaces it at link time: go build -ldflags=\"-X main.version=v1.1.0\".\nvar version = \"dev\"\n",
      "note": "**The variable `-X` sets.** The linker can replace it because it is a package-level `string` initialised to a constant, which is exactly the condition `go doc cmd/link` states; a `const`, or a value computed by a function call, is out of its reach."
    },
    {
      "code": "// printVersion answers `hits version`: the name stamped at link time, then\n// what the go command recorded about the build.\nfunc printVersion(stdout io.Writer) int {\n\tfmt.Fprintf(stdout, \"hits %s\\n\", version)",
      "note": "The first line is whatever the link left in `version`: `dev` from the source, or the name a release build passed."
    },
    {
      "code": "\tinfo, ok := debug.ReadBuildInfo()\n\tif !ok {\n\t\treturn 0\n\t}\n\tfmt.Fprintf(stdout, \"module %s %s, %s\\n\", info.Main.Path, info.Main.Version, info.GoVersion)\n\tfor _, s := range info.Settings {\n\t\tif strings.HasPrefix(s.Key, \"vcs.\") {\n\t\t\tfmt.Fprintf(stdout, \"%s %s\\n\", s.Key, s.Value)\n\t\t}\n\t}\n\treturn 0\n}",
      "note": "`ReadBuildInfo` returns the same record `go version -m` prints from outside: the main module's path and version, the Go release, and the build settings. **Every setting whose key starts with `vcs.` came from git** at build time. `ok` is false only for a binary built without module support."
    }
  ]
}
```

And `run` needs to know the word. Two lines go into its `switch`, just before the `help` case, with an
editor or with `sed`. `git diff` shows exactly what changed:

```
ana@vm:~/small$ sed -i '/case "help"/i\\tcase "version":\n\t\treturn printVersion(stdout)' main.go
ana@vm:~/small$ git diff
diff --git a/main.go b/main.go
index a09baa8..0da35c1 100644
--- a/main.go
+++ b/main.go
@@ -38,6 +38,8 @@ func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {
 		return count(args[1:], stdin, stdout, stderr)
 	case "top":
 		return top(args[1:], stdin, stdout, stderr)
+	case "version":
+		return printVersion(stdout)
 	case "help", "-h", "-help", "--help":
 		fmt.Fprint(stdout, usage)
 		return 0
```

Built and asked, first as it is and then with `-X`:

```
ana@vm:~/small$ go build -o hits . && ./hits version
hits dev
module example.com/hits v1.0.0+dirty, go1.27.1
vcs.revision c8e4f11b0e80eec15e63704cd47c43985015d274
vcs.time 2026-10-01T12:00:00Z
vcs.modified true
ana@vm:~/small$ go build -ldflags="-X main.version=v1.1.0" -o hits . && ./hits version
hits v1.1.0
module example.com/hits v1.0.0+dirty, go1.27.1
vcs.revision c8e4f11b0e80eec15e63704cd47c43985015d274
vcs.time 2026-10-01T12:00:00Z
vcs.modified true
```

**`-X main.version=v1.1.0` replaced `dev` without a change to the source.** The name before the `=` is
the package path and the variable, and for the `main` package the path is simply `main`. The other
lines show the stamp at work: the tree has an uncommitted change, so the module version is
`v1.0.0+dirty` and `vcs.modified` is `true`. A binary built from a tree like this one is never quite
the tagged release, and the stamp says so.

**`-X` does not complain about a name it cannot find.** Spell the variable with a capital letter and
the build succeeds, and the binary is still `dev`:

```
ana@vm:~/small$ go build -ldflags="-X main.Version=v1.1.0" -o hits . && ./hits version | head -1
hits dev
```

Go names are case-sensitive, so `main.Version` is a different variable, and the linker found no such
string to set. A release script should therefore check the result: `./hits version | grep -q v1.1.0`
fails loudly where the build passed quietly.

## The tag, and where `-X` is still needed

Commit the change and tag it, and build once more without `-X`:

```
ana@vm:~/small$ git add . && git commit -q -m "hits version" && git tag v1.1.0
ana@vm:~/small$ go build -o hits . && ./hits version
hits dev
module example.com/hits v1.1.0, go1.27.1
vcs.revision ab54a88f87bb0a40de5be75684eb66198f83d4ab
vcs.time 2026-10-02T12:00:00Z
vcs.modified false
```

**The go command took `v1.1.0` from the tag by itself**, and the tree is clean again. On a machine that
builds from a git checkout, the module version answers the question this section began with, and
`version` stays at `dev`. Not every build runs in a checkout, though. A source archive has no `.git`
directory, and neither does a build that copies only the source files into a fresh place, which is
common inside a container. `git archive` writes such a copy of the tagged tree:

```
ana@vm:~/small$ mkdir /tmp/small-v1.1.0 && git archive v1.1.0 | tar -x -C /tmp/small-v1.1.0
ana@vm:~/small$ cd /tmp/small-v1.1.0 && go build -o hits . && ./hits version
hits dev
module example.com/hits (devel), go1.27.1
ana@vm:~/small$ cd /tmp/small-v1.1.0 && go build -ldflags="-X main.version=v1.1.0" -o hits . && ./hits version
hits v1.1.0
module example.com/hits (devel), go1.27.1
```

**Outside a repository the module version falls back to `(devel)` and the `vcs` lines disappear**,
because there is nothing to read them from. `-X` still works, because the value comes from the build
command and not from the directory. That is the case for stamping at link time. The build command
gets the name from the one place it is written, the tag, and `git describe --tags` prints it, so the
release build is one line:

```
ana@vm:~/small$ git describe --tags
v1.1.0
ana@vm:~/small$ go build -trimpath -ldflags="-s -w -X main.version=$(git describe --tags)" -o hits . && ./hits version
hits v1.1.0
module example.com/hits v1.1.0, go1.27.1
vcs.revision ab54a88f87bb0a40de5be75684eb66198f83d4ab
vcs.time 2026-10-02T12:00:00Z
vcs.modified false
ana@vm:~/small$ stat -c "%s bytes  %n" hits
2666656 bytes  hits
```

`git describe --tags` prints the tag itself on a tagged commit; on a later commit it adds the number
of commits since the tag and the short revision, so even a build between releases says where it came
from. **This is the build to ship**: no DWARF, no symbol table, no home directory, and a binary of
2,666,656 bytes that can say exactly which commit it is. It is 16,384 bytes larger than section 03's
smallest build, the price of `version.go`, the `runtime/debug` it imports and the recorded revision.
