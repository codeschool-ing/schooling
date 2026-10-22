---
title: One file, copied in when the program is built
version: 1
---

Lesson 1 of `go` showed what a Go program is at the end: one file to copy, with nothing to install
beside it. A program that reads a template, a page or a default configuration from disk breaks that
promise, because now the file has to travel too and be found at run time. **`//go:embed` copies a
file into the binary when it is built**, and the program reads it from a variable.

Every program of this lesson lives in a directory of its own under `~/embedding`, one module for
all of them. The first prints a version number and the size of a small banner, both from files
beside it, saved as `version/main.go`:

```schooling-example
{"language": "go", "file": "version/main.go", "parts": [{"code": "// Command version prints a file that was copied into it when it was built.\npackage main\n\nimport (\n\t_ \"embed\"\n\t\"fmt\"\n\t\"strings\"\n)\n\n", "note": "**The `embed` package has to be imported**, even when nothing in the file names it. The blank `_` says the import is there for its effect on the build."}, {"code": "//go:embed version.txt\nvar version string\n\n", "note": "**`//go:embed` is a directive to the go command, written as a comment with no space after `//`**, on the line right above a package-level variable. The file is named relative to the directory of the source file. A `string` receives its contents as text."}, {"code": "//go:embed logo.txt\nvar logo []byte\n\n", "note": "A `[]byte` receives them as bytes. The third choice, `embed.FS`, is the next section's."}, {"code": "func main() {\n\tfmt.Println(\"version\", strings.TrimSpace(version))\n\tfmt.Println(len(logo), \"bytes of logo\")\n}\n", "note": "From here on the variables are ordinary values, and nothing reads the disk."}]}
```

The data files are typed rather than shown, one line each. The first build has only one of the
two:

```
ana@vm:~/embedding$ printf "1.4.2\n" > version/version.txt
ana@vm:~/embedding$ go build -o bin/version ./version
version/main.go:13:12: pattern logo.txt: no matching files found
ana@vm:~/embedding$ printf "[ go ]\n" > version/logo.txt
ana@vm:~/embedding$ go build -o bin/version ./version
ana@vm:~/embedding$ bin/version
version 1.4.2
7 bytes of logo
ana@vm:~/embedding$ printf "1.5.0\n" > version/version.txt
ana@vm:~/embedding$ bin/version
version 1.4.2
7 bytes of logo
ana@vm:~/embedding$ go build -o bin/version ./version
ana@vm:~/embedding$ bin/version
version 1.5.0
7 bytes of logo
```

**A file that is not there is a build error**, naming the pattern that matched nothing, so a binary
can never ship missing a file it embeds. Once the banner existed the program built and ran. Then
the version file was changed and the same binary run again: it still said `1.4.2`, because the
contents were copied when it was built and the file on disk is no longer consulted. Only a new
build picked up `1.5.0`. That is the whole behaviour, and it is worth remembering on the day a
change to an embedded file seems to have no effect.

## The import is not optional

The same directive in a file that does not import `embed`, saved as `noimport/main.go`:

```go
package main

import "fmt"

//go:embed version.txt
var version string

func main() { fmt.Print(version) }
```

```
ana@vm:~/embedding$ go build -o bin/noimport ./noimport
# example.com/embedding/noimport
noimport/main.go:5:3: go:embed requires import "embed" (or import _ "embed", if package is not used)
```

The message gives both forms of the fix. It is a refusal rather than a silent nothing, which
matters: a directive is a comment, and without this check a misspelt or unimported one would leave
an empty string where the file should be.
