---
title: The documentation is already on your machine
version: 1
---

The habit most people bring to a new language is to search the web for a function's name. In Go
that is the slow way. **Every package documents itself in comments, and the toolchain you
installed carries the whole standard library's source**, so the answer is one command away and
works with no network at all:

```
ana@vm:~/hello$ go doc fmt.Println
package fmt // import "fmt"

func Println(a ...any) (n int, err error)
    Println formats using the default formats for its operands and writes to
    standard output. Spaces are always added between operands and a newline
    is appended. It returns the number of bytes written and any write error
    encountered.

```

Read it in the order it is printed, because each part answers a different question:

- **`package fmt // import "fmt"`** says where the function lives and the path you import to use
  it. For `fmt` the two are the same; for `json` the import path is `encoding/json`.
- **The signature** is the most precise sentence in the answer. `a ...any` means any number of
  arguments of any type, which lesson 21 explains, and `(n int, err error)` means `Println`
  returns two values: how many bytes it wrote and whether writing failed. The program in section
  01 ignored both, which is normal for printing to a terminal and wrong for writing to a file.
- **The comment** is what the author wrote above the function, unedited. Notice that it says what
  `Println` does with spaces between operands. That is the kind of detail the web summary leaves
  out.

## A package, and a function you did not know existed

Given a package name, `go doc` prints its documentation and a one-line summary of everything it
exports. Piped through `head`, the start of `strings`:

```
ana@vm:~/hello$ go doc strings | head -12
package strings // import "strings"

Package strings implements simple functions to manipulate UTF-8 encoded strings.

For information about UTF-8 strings in Go, see https://blog.golang.org/strings.

func Clone(s string) string
func Compare(a, b string) int
func Contains(s, substr string) bool
func ContainsAny(s, chars string) bool
func ContainsFunc(s string, f func(rune) bool) bool
func ContainsRune(s string, r rune) bool
```

This is how you find a function rather than look one up. Somebody who wants to split a sentence
into words and scrolls the rest of that list finds `Fields`:

```
ana@vm:~/hello$ go doc strings.Fields
package strings // import "strings"

func Fields(s string) []string
    Fields splits the string s around each instance of one or more consecutive
    white space characters, as defined by unicode.IsSpace, returning a slice
    of substrings of s or an empty slice if s contains only white space.
    Every element of the returned slice is non-empty. Unlike Split, leading and
    trailing runs of white space characters are discarded.

```

The last sentence is the reason to read documentation instead of guessing. `Fields` and `Split`
both break a string apart, and only one of them drops the empty pieces at the ends. A program that
used the wrong one would compile, run and be wrong only on input with a leading space.

**Lower-case letters in the argument match either case**, so `go doc json.decoder.decode` finds
`json.Decoder.Decode`. And the arguments work for your own code too. In `~/hello`, with no
argument, `go doc` prints the comment that sits above `package main`:

```
ana@vm:~/hello$ go doc
Command hello prints a greeting.
```

That is why the first line of `hello.go` was a sentence beginning with the program's name. A
comment directly above a declaration is its documentation, and the tools read it.

## The same text in a browser

The documentation of every public module is also published at **pkg.go.dev**, generated from the
same comments, with the source one click away. It is the place to look before you add a
third-party package, in lesson 40, because it also shows the module's licence, its versions and
which other modules import it. `go doc -http` serves the same pages from your own machine; it was
not run in the lab, because its first use downloads and builds a documentation server,
`golang.org/x/pkgsite`, before it can show anything.

The terminal is still the faster habit for the standard library, and it has one advantage the
website cannot have: it shows the documentation **of the Go you are running**, not of the latest
release.
