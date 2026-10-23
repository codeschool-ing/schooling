---
title: What gofmt changes
version: 1
---

`gofmt` is often taken for a style checker, a tool that reads your code and complains. **It is a
printer.** It parses a file into Go's syntax tree and prints the tree back out, and the layout of
what comes out is decided by the printer rather than by whoever typed the file. Two people who
write the same program with different habits get the same bytes back. It came with your Go
installation, in `/usr/local/go/bin` beside `go`, and lesson 1 section 02 already found it there.

To see what it does, it needs something to work on. This lesson works in `~/fmt`, a copy of
`hits` with the `tally` package, `main.go`, `main_test.go` and `genlog` placed exactly as lesson 1
printed them, in a module made with `go mod init example.com/hits`. To that, add a small function
that folds the status codes into their families, written the way somebody in a hurry writes, with
two spaces here, four there and no spaces at all elsewhere. `internal/tally/classes.go`:

```go
package tally
import "fmt"
// Class is one family of status codes: 2xx, 3xx, 4xx or 5xx.
type Class struct {
    Name string // "2xx"
    Requests int // lines whose status is in the family
    Share float64 // Requests as a fraction of all lines
}



// Classes folds s.ByStatus into one row per family, 2xx first.
func Classes(s Summary) []Class{
  rows:=[]Class{}
  for _,c := range []int{2,3,4,5} {
      n:=0
      for status,count:=range s.ByStatus{
        if status/100==c {n+=count}
      }
      rows=append(rows,Class{Name:fmt.Sprintf("%dxx",c),Requests:n,Share:float64(n)/float64(s.Lines)})
  }
  return rows
}
```

It compiles as it is. The compiler cares about tokens, not about the spaces between them. Given a
file name and no flags, `gofmt` prints the formatted version to standard output and leaves the file
alone:

```
ana@vm:~/fmt$ gofmt internal/tally/classes.go
package tally

import "fmt"

// Class is one family of status codes: 2xx, 3xx, 4xx or 5xx.
type Class struct {
	Name     string  // "2xx"
	Requests int     // lines whose status is in the family
	Share    float64 // Requests as a fraction of all lines
}

// Classes folds s.ByStatus into one row per family, 2xx first.
func Classes(s Summary) []Class {
	rows := []Class{}
	for _, c := range []int{2, 3, 4, 5} {
		n := 0
		for status, count := range s.ByStatus {
			if status/100 == c {
				n += count
			}
		}
		rows = append(rows, Class{Name: fmt.Sprintf("%dxx", c), Requests: n, Share: float64(n) / float64(s.Lines)})
	}
	return rows
}
```

## What changed

Every difference between the two versions falls into one of a few kinds:

| what | before | after |
|---|---|---|
| indentation | two or four spaces, as typed | **one tab per level** |
| a struct's fields | `Name string`, `Requests int` | names, types and comments each in a column, padded with spaces |
| spacing around tokens | `rows:=[]Class{}`, `_,c` | `rows := []Class{}`, `_, c` |
| blocks | `{n+=count}` on the `if` line | the body on a line of its own |
| blank lines | none after `package`, three after the struct | one between declarations, never more than one in a row |

**Tabs indent and spaces align.** That is the rule `go doc cmd/gofmt` states in its first lines,
and the struct shows both: each field line starts with one tab, and the spaces after `Name` and
after `string` are there to line the columns up. A tab's width is whatever your editor says, so the
indentation follows the reader's preference, while the alignment is counted in spaces and survives
any tab width.

**The spacing around an operator depends on the expression it sits in.** `status/100 == c` has
spaces around `==` and none around `/`: the tighter-binding operator is written tight, so the
spacing shows how the expression groups. In `float64(n) / float64(s.Lines)` the `/` is the only
operator in the element, and it gets spaces. Nobody wrote that rule into `classes.go`; it comes from
the syntax tree, which is why `gofmt` can apply it to code it has never seen.

## Three flags that decide where the result goes

Printing to standard output is the mode you use least. The other three answer the questions people
actually ask: which files are wrong, how, and fix them:

```
ana@vm:~/fmt$ gofmt -l .
internal/tally/classes.go
ana@vm:~/fmt$ gofmt -d internal/tally/classes.go | head -20
diff internal/tally/classes.go.orig internal/tally/classes.go
--- internal/tally/classes.go.orig
+++ internal/tally/classes.go
@@ -1,23 +1,25 @@
 package tally
+
 import "fmt"
+
 // Class is one family of status codes: 2xx, 3xx, 4xx or 5xx.
 type Class struct {
-    Name string // "2xx"
-    Requests int // lines whose status is in the family
-    Share float64 // Requests as a fraction of all lines
-}
-
-
+	Name     string  // "2xx"
+	Requests int     // lines whose status is in the family
+	Share    float64 // Requests as a fraction of all lines
+}
```

**`-l` lists the files whose formatting differs**, one per line, and prints nothing about the rest.
Given a directory, `gofmt` walks it and every directory under it, reading each `.go` file, so `.`
means the whole module: four files of lesson 1 were read and found correct, and only `classes.go`
was named. **`-d` prints a unified diff** instead of the whole file, which is what you want in a
review or a CI log. The third flag, **`-w`, writes the result back into the file**, and prints
nothing.

## `go fmt` is `gofmt -l -w` over packages

`go help fmt` says it in one line: `go fmt` "runs the command 'gofmt -l -w' on the packages named by
the import paths". The `-n` flag prints the command instead of running it, as it
does for `go build` and several other subcommands, so you can see exactly what that means:

```
ana@vm:~/fmt$ go fmt -n ./...
/usr/local/go/bin/gofmt -l -w main.go main_test.go internal/tally/classes.go internal/tally/tally.go tools/genlog/main.go
ana@vm:~/fmt$ go fmt ./...
internal/tally/classes.go
ana@vm:~/fmt$ go fmt ./...
ana@vm:~/fmt$ gofmt -l .
```

The go command found the module's three packages, collected their five files and handed them to
the `gofmt` that came with the toolchain. **The first run rewrote `classes.go` and named it; the
second found nothing to do and printed nothing.** After that `gofmt -l .` has nothing to list.

The difference between the two commands is what they are given. **`go fmt` takes packages**,
`./...` or an import path, and formats the files those packages are made of. **`gofmt` takes
files and directories**, and reads every `.go` file it finds under them, whether or not a package
would include it. Section 05 shows where that difference bites. For everyday use, `go fmt ./...`
before a commit is the whole habit, and an editor that formats on save makes even that
unnecessary.
