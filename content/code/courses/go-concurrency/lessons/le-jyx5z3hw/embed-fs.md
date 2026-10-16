---
title: A directory inside the binary
version: 1
---

A string holds one file. A website, a set of templates or a folder of database migrations is
several, and **an `embed.FS` holds a whole tree**: a read-only file system inside the program,
behind the `fs.FS` interface of the `io/fs` package. The program below embeds a directory twice, in
two ways, and lists what each one got, saved as `site/main.go`:

```go
// Command site lists the files it carries inside itself.
package main

import (
	"embed"
	"fmt"
	"io/fs"
)

//go:embed static
var static embed.FS

//go:embed all:static
var everything embed.FS

func list(name string, fsys fs.FS) {
	fmt.Println(name + ":")
	fs.WalkDir(fsys, ".", func(path string, d fs.DirEntry, err error) error {
		if !d.IsDir() {
			fmt.Println("  " + path)
		}
		return nil
	})
}

func main() {
	list("static", static)
	list("all:static", everything)

	page, err := static.ReadFile("static/index.html")
	fmt.Printf("%d bytes, %v\n", len(page), err)
	_, err = static.ReadFile("index.html")
	fmt.Println(err)
}
```

Four small files go into `site/static`, two of them with names that start with `.` and `_`:

```
ana@vm:~/embedding$ mkdir site/static
ana@vm:~/embedding$ printf "<h1>Orders</h1>\n" > site/static/index.html
ana@vm:~/embedding$ printf "h1 { color: teal }\n" > site/static/style.css
ana@vm:~/embedding$ printf "draft\n" > site/static/.draft.html
ana@vm:~/embedding$ printf "notes\n" > site/static/_notes.txt
ana@vm:~/embedding$ go run ./site
static:
  static/index.html
  static/style.css
all:static:
  static/.draft.html
  static/_notes.txt
  static/index.html
  static/style.css
16 bytes, <nil>
open index.html: file does not exist
```

**The plain pattern left out `.draft.html` and `_notes.txt`.** A directory named in `//go:embed`
brings in its files except those whose names begin with a dot or an underscore, which is what
editors' backups and drafts tend to be called. The prefix `all:` takes everything. Leaving them out
by default is a safety measure: a `.env` with a password in it, sitting in a directory somebody
embeds, would otherwise ship inside the binary to everyone who downloads it.

Paths inside an `embed.FS` keep the directory's name, so the page is `static/index.html` and
`index.html` alone does not exist. **The error is the ordinary `fs.ErrNotExist`** that a missing
file on disk gives, `open index.html: file does not exist`, which is what lets code written against
`fs.FS` work on either without knowing which. The next section uses that to strip the `static/`
off.
