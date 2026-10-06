---
title: Adding, upgrading and asking why
version: 1
---

`go get` reads like "download and install this package", which is what it did in Go before
modules. **It no longer builds or installs anything.** `go help get` says it in one line: it
resolves its arguments to modules at specific versions, "updates go.mod to require those versions,
and downloads source code into the module cache". Installing a program is `go install`, from
lesson 4.

Lesson 38 already showed that `go mod tidy` fetches whatever your imports need. What `tidy` does
not let you do is choose: it takes the latest version of anything missing and leaves alone what is
already there. **`go get` is the command for deciding which version you depend on**, and for
changing your mind afterwards.

## A dependency, at a version you chose

The program for this section measures strings the way a terminal draws them. A terminal gives
most characters one column and some of them two, and the standard library has no function that
knows which: `len` counts bytes and `utf8.RuneCountInString` counts runes, as lessons 8 and 9 showed. The
module `github.com/mattn/go-runewidth` does know.

```go
// Command width measures strings the way a terminal draws them.
package main

import (
	"fmt"
	"unicode/utf8"

	"github.com/mattn/go-runewidth"
)

func main() {
	words := []string{
		"Ana",
		"cafe\u0301",           // e and a combining accent
		"\u65e5\u672c",         // Japan, in Japanese
		"\U0001F1E7\U0001F1F7", // the flag of Brazil
		"\U0001FAE9",           // a recent emoji
	}
	for _, w := range words {
		fmt.Printf("%-+24q bytes %d  runes %d  columns %d\n",
			w, len(w), utf8.RuneCountInString(w), runewidth.StringWidth(w))
	}
}
```

The strings are written with escapes, and `%+q` prints them escaped, so every line below is plain
ASCII whatever your terminal does with emoji. The version is chosen on purpose: v0.0.16, an old
one, so that there is something to upgrade.

```
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@v0.0.16
go: added github.com/mattn/go-runewidth v0.0.16
go: added github.com/rivo/uniseg v0.2.0
ana@vm:~/thirdparty-width$ go mod tidy && cat go.mod
module example.com/width

go 1.27.1

require github.com/mattn/go-runewidth v0.0.16

require github.com/rivo/uniseg v0.2.0 // indirect
ana@vm:~/thirdparty-width$ go run .
"Ana"                    bytes 3  runes 3  columns 3
"cafe\u0301"             bytes 6  runes 5  columns 4
"\u65e5\u672c"           bytes 6  runes 2  columns 4
"\U0001f1e7\U0001f1f7"   bytes 8  runes 2  columns 1
"\U0001fae9"             bytes 4  runes 1  columns 1
```

**One `go get` added two modules.** `go-runewidth` v0.0.16 requires `github.com/rivo/uniseg` in its
own `go.mod`, so that module came too, and `tidy` filed it under `// indirect`: something your
module needs only because a dependency needs it. `go get` is followed by `go mod tidy` here so that
`go.mod` says exactly what the imports need, which is `tidy`'s job from lesson 38.

The output is the point of the module. The accented `cafe` is six bytes, five runes and four
columns; the two Japanese characters are two runes and four columns. The last two lines say one
column each, and that is where this old version is out of date.

## What is out of date, and upgrading

`go list -m -u all` lists every module in the build and, in square brackets, the newest version
each one has published:

```
ana@vm:~/thirdparty-width$ go list -m -u all
example.com/width
github.com/mattn/go-runewidth v0.0.16 [v0.0.30]
github.com/rivo/uniseg v0.2.0 [v0.4.7]
```

A module with no brackets is current, and the first line, with no version at all, is your own
module. Asking for `@latest` moves the dependency to the newest release:

```
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@latest
go: added github.com/clipperhouse/uax29/v2 v2.2.0
go: upgraded github.com/mattn/go-runewidth v0.0.16 => v0.0.30
ana@vm:~/thirdparty-width$ go run .
"Ana"                    bytes 3  runes 3  columns 3
"cafe\u0301"             bytes 6  runes 5  columns 4
"\u65e5\u672c"           bytes 6  runes 2  columns 4
"\U0001f1e7\U0001f1f7"   bytes 8  runes 2  columns 2
"\U0001fae9"             bytes 4  runes 1  columns 2
```

The flag and the emoji are now two columns each. **Not one line of `main.go` changed, and the
program prints something different.** That is what an upgrade is: somebody else's code, replaced
under yours. Here it is an improvement, because the new version knows newer Unicode data. The
habit to take from it is to run the program, and its tests once you have them, after every
upgrade rather than trust a version number.

The upgrade also swapped a dependency: v0.0.30 no longer uses `uniseg` and requires
`github.com/clipperhouse/uax29/v2` instead. `go get` added the new one and did not remove the old
one, so `tidy` finishes the job:

```
ana@vm:~/thirdparty-width$ go mod tidy && cat go.mod
module example.com/width

go 1.27.1

require github.com/mattn/go-runewidth v0.0.30

require github.com/clipperhouse/uax29/v2 v2.2.0 // indirect
```

## Asking why a module is there

A long `go.mod` raises the question of what each line is for. `go mod why -m`
answers it with the chain of imports that leads from your code to the module:

```
ana@vm:~/thirdparty-width$ go mod why -m github.com/clipperhouse/uax29/v2
# github.com/clipperhouse/uax29/v2
example.com/width
github.com/mattn/go-runewidth
github.com/clipperhouse/uax29/v2/graphemes
ana@vm:~/thirdparty-width$ go mod why -m github.com/rivo/uniseg
# github.com/rivo/uniseg
(main module does not need module github.com/rivo/uniseg)
```

Read the first answer from the top: your package imports `go-runewidth`, which imports the
`graphemes` package of `uax29/v2`. The second says `uniseg` is no longer needed by anything, which
is why `tidy` dropped it. **`go mod why` is how you find out whose decision a dependency was**,
and so who to ask before you try to get rid of it.

One more line is worth a look after the upgrade:

```
ana@vm:~/thirdparty-width$ go list -m -u all
example.com/width
github.com/clipperhouse/uax29/v2 v2.2.0 [v2.7.0]
github.com/mattn/go-runewidth v0.0.30
```

`go-runewidth` asks for `uax29/v2` v2.2.0, so that is what the build uses, even though v2.7.0
exists: lesson 38's minimal version selection takes the version somebody asked for, not the newest.
`go help get` describes the flag that changes this: `go get -u` with a package also upgrades the
modules that package depends on to their newest minor or patch releases.

## Going back, and leaving

The same command moves the other way. Naming an older version downgrades, and the special version
`none` removes the requirement:

```
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@v0.0.16
go: downgraded github.com/mattn/go-runewidth v0.0.30 => v0.0.16
go: added github.com/rivo/uniseg v0.2.0
ana@vm:~/thirdparty-width$ go get github.com/mattn/go-runewidth@none
go: removed github.com/mattn/go-runewidth v0.0.16
```

Removing the requirement does not remove the import from `main.go`, so the program would no longer
build; `@none` is for after you have deleted the code that used the module. Every form after the
`@` is a **version query**, and the go command's source lists the ones it accepts:

| after the `@` | which version |
|---|---|
| `v0.0.16` | exactly that tagged version |
| `latest` | the newest tagged release, retracted ones left out (section 05) |
| `v1`, `v1.2` | the newest `v1.x.x`, the newest `v1.2.x` |
| `patch` | the newest with the same major and minor numbers as the one you have |
| `upgrade` | like `latest`, but never older than the one you have |
| `<v1.3.0`, `>=v1.2.0` | the closest version that satisfies the comparison |
| a commit hash | that commit, under a pseudo-version built from its date and hash, like `v0.0.0-20261005191246-02052bb39a2e` |
| `none` | no version: remove the requirement |
