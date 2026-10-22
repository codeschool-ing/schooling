---
title: Files are Readers and Writers with a name
version: 1
---

Lesson 17 said a file is a Reader and a Writer. **That is the whole of what is special about a
file once it is open: the rest is opening it, closing it, and knowing what went wrong when either
fails.** The package is `os`, the work lives in `~/files`, made with
`go mod init example.com/files`, and the first program does the three things nearly every program
does to a file: write one, add to it, read it back. Saved as `notes.go`:

```go
// Command notes writes a file, adds to it, and reads it back.
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
)

func main() {
	if err := os.WriteFile("notes.txt", []byte("first line\n"), 0o644); err != nil {
		fmt.Println("write:", err)
		return
	}

	f, err := os.OpenFile("notes.txt", os.O_APPEND|os.O_WRONLY, 0)
	if err != nil {
		fmt.Println("open:", err)
		return
	}
	fmt.Fprintln(f, "second line, appended")
	if err := f.Close(); err != nil {
		fmt.Println("close:", err)
		return
	}

	data, err := os.ReadFile("notes.txt")
	if err != nil {
		fmt.Println("read:", err)
		return
	}
	fmt.Printf("%d bytes:\n%s", len(data), data)

	_, err = os.ReadFile("missing.txt")
	fmt.Println("missing:", err)
	fmt.Println("does not exist:", errors.Is(err, fs.ErrNotExist))
}
```

```
ana@vm:~/files$ go run notes.go
33 bytes:
first line
second line, appended
missing: open missing.txt: no such file or directory
does not exist: true
ana@vm:~/files$ ls -l notes.txt
-rw-r--r-- 1 ana ana 33 Oct 16 19:44 notes.txt
ana@vm:~/files$ umask
0022
```

## Three ways in

**`os.WriteFile` and `os.ReadFile` are the whole-file shortcuts**: one call writes a slice to a
file, creating or emptying it first, and one call reads a file into a slice. They suit anything
that fits comfortably in memory, which for a configuration file or a small report is everything.

**`os.OpenFile` is the general door**, and the flags say what kind. `os.O_APPEND|os.O_WRONLY` opens
for writing at the end, so the second line went after the first instead of over it. `os.Open` is
`OpenFile` for reading only, and `os.Create` is `OpenFile` for writing that creates the file or
empties an existing one. Whatever opened the file, `fmt.Fprintln(f, …)` wrote to it, because `f`
is an `io.Writer`, and an `io.Copy` or a `json.Encoder` would have done the same.

**The `Close` after writing has its error checked, and that is deliberate.** Some systems report a
failed write only when the file is closed, so a program that writes and then ignores `Close`'s
error can lose data without a word. For a file only read, a plain `defer f.Close()` is enough,
since nothing is waiting to be written.

## Permissions, and who trims them

`0o644` asked for read and write for the owner and read for everybody else, and `ls -l` shows
exactly that, `-rw-r--r--`. The number is a request, not an order: the process's **umask**, `0022`
here, removes bits from every file it creates. A program asking for `0o666` on this machine would
still get `-rw-r--r--`. Ask for what you mean, and do not be surprised when a stricter umask gives
you less.

## The error says what and where

The missing file produced `open missing.txt: no such file or directory`: the operation, the path,
and the reason from the operating system, which is the shape of every error from `os`. **To decide
what to do about an error, test it with `errors.Is` against a value from `io/fs`**, not by reading
its text: `fs.ErrNotExist` here, `fs.ErrPermission` for a file you may not open, `fs.ErrExist` for
one you asked to create only if it was new. The text is for people; `errors.Is` is for programs,
as lesson 34 of `go` showed for errors in general.
