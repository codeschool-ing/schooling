---
title: Directories, walking a tree, and staying inside one
version: 1
---

Directories are where a program's files stop being one file. Three jobs come up every time: make
a path of directories, list one, and visit everything under one. A fourth used to be easy to get
wrong and since Go 1.24 has a type of its own: **opening files by a name that came from somebody
else without letting `..` take you outside the directory you meant.** One program does all four,
saved as `tree.go`:

```go
// Command tree makes directories, lists one, walks another and refuses to leave a root.
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

func main() {
	for _, day := range []string{"14", "15", "16"} {
		dir := filepath.Join("logs", "2026", "10", day)
		if err := os.MkdirAll(dir, 0o755); err != nil {
			fmt.Println(err)
			return
		}
		os.WriteFile(filepath.Join(dir, "app.log"), []byte("day "+day+"\n"), 0o644)
	}

	entries, err := os.ReadDir("logs/2026/10")
	if err != nil {
		fmt.Println(err)
		return
	}
	for _, e := range entries {
		fmt.Println("entry:", e.Name(), "dir:", e.IsDir())
	}

	files, bytes := 0, int64(0)
	err = filepath.WalkDir("/usr/local/go/src/io", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && filepath.Ext(path) == ".go" {
			info, err := d.Info()
			if err != nil {
				return err
			}
			files++
			bytes += info.Size()
		}
		return nil
	})
	fmt.Println("walked io:", files, "Go files,", bytes, "bytes, err", err)

	root, err := os.OpenRoot("logs")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer root.Close()
	if _, err := root.Open("2026/10/16/app.log"); err == nil {
		fmt.Println("inside the root: opened")
	}
	_, err = root.Open("../notes.txt")
	fmt.Println("outside the root:", err)
}
```

```
ana@vm:~/files$ go run tree.go
entry: 14 dir: true
entry: 15 dir: true
entry: 16 dir: true
walked io: 32 Go files, 144889 bytes, err <nil>
inside the root: opened
outside the root: openat ../notes.txt: path escapes from parent
```

## Making and listing

`os.MkdirAll` makes every missing directory on the path and is content when they already exist,
which is why the loop can call it three times on paths that share `logs/2026/10`. Its sibling
`os.Mkdir` makes one directory and fails if it is there. `os.ReadDir` returns the entries of one
directory **sorted by name**, so `14`, `15` and `16` came out in order whatever order the disk keeps
them in. Each entry knows its name and whether it is a directory without another trip to the
disk; `e.Info()` is that trip, for the size and the times.

The paths were built with `filepath.Join`, never with `+ "/" +`. It puts the separator the
operating system uses and cleans up doubled ones, so the same code is right on Windows.

## Walking

`filepath.WalkDir` visits a directory and everything under it, in lexical order, and calls your
function once per entry with the path, the entry and any error reaching it. Here it walked the
standard library's own `io` package in `/usr/local/go/src/io` and found 32 Go files holding
144,889 bytes, tests included. Two rules make a walk correct. **Return the `err` you were handed
unless you mean to skip it**, because a directory you could not read arrives as that error and not
as a crash. And return `filepath.SkipDir` from a directory's call to leave that subtree out, which
is how a walk avoids `.git` or `node_modules`.

## Staying inside a root

A program that serves files, unpacks an archive or writes uploads takes names from outside. A name
like `../notes.txt` joined onto `logs` points outside `logs`, and checking for `..` by hand misses
the cases a symbolic link creates. **`os.OpenRoot` returns an `os.Root`, and every name opened
through it is resolved inside that directory or refused.** `root.Open("2026/10/16/app.log")`
worked; `root.Open("../notes.txt")` failed with `path escapes from parent` before anything outside
`logs` was touched. `os.Root` has the file operations you need inside it, `Open`, `Create`,
`OpenFile`, `Mkdir` and `Remove` among them.
