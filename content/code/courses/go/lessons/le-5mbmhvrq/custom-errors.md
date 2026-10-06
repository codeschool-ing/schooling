---
title: An error type of your own, and the nil that is not nil
version: 1
---

A message is written for a person. A program that called you sometimes needs more than a sentence
it would have to take apart: which line of the file was wrong, which path could not be opened,
which input did not convert. **When the caller needs data, the error is a type of your own,
carrying that data in fields**, and the message is built from them. That is what the standard
library did in section 02: `*fs.PathError` has the operation and the path in fields, and
`*strconv.NumError` has the function and the input.

A configuration checker in `~/errors-custom` reports the first line that has no `=` in it:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command config checks the lines of a small configuration text.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n)\n\n// A LineError says which line of the input was wrong, and why.\ntype LineError struct {\n\tLine int\n\tMsg  string\n}\n",
      "note": "**An error type is an ordinary struct holding what the caller may want to know.** Here, the number of the line and what was wrong with it. The name ends in `Error`, like `PathError` and `NumError` in section 02."
    },
    {
      "code": "\nfunc (e *LineError) Error() string {\n\treturn fmt.Sprintf(\"line %d: %s\", e.Line, e.Msg)\n}\n",
      "note": "**The one method that makes it an `error`.** Nothing declares that `LineError` implements anything; having `Error() string` is enough. The receiver is a pointer, `*LineError`, so it is the pointer that satisfies `error`. Methods are lesson 25 and that choice is lesson 26."
    },
    {
      "code": "\nfunc check(text string) error {\n\tfor i, line := range strings.Split(text, \"\\n\") {\n\t\tif line != \"\" && !strings.Contains(line, \"=\") {\n\t\t\treturn &LineError{Line: i + 1, Msg: \"no = in \" + line}\n\t\t}\n\t}\n\treturn nil\n}\n",
      "note": "**The result type is `error`, not `*LineError`.** A failure returns a pointer to a new `LineError`; success returns the literal `nil`. Lines are counted from 1 because a person reads them, and `range` counts from 0."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(check(\"port=8080\\nhost=localhost\"))\n\terr := check(\"port=8080\\nhost localhost\")\n\tfmt.Println(err)\n\tfmt.Printf(\"%T\\n\", err)\n}\n",
      "note": "Two texts, one correct and one with a space where the `=` should be. The caller sees an `error` and prints it, and `fmt` calls the `Error` method the type wrote."
    }
  ],
  "output": "<nil>\nline 2: no = in host localhost\n*main.LineError\n"
}
```

`check` does what section 03 asked of a function: it returns `nil` when nothing failed and an
`error` when something did, and the caller needs nothing more than `if err != nil` to tell the two
apart. The `Line` field is there for the caller that wants it. Reaching a field through a variable
of type `error` takes a step this lesson does not show, `errors.As`, and lesson 34 is about it.

## The nil that is not nil

Now one small change, the kind somebody makes to be precise. `check` only ever fails with a
`LineError`, so why not say so in its signature? In `~/errors-nil` it returns `*LineError`, and a
second function, `load`, passes its result on as an `error`:

```go
func check(text string) *LineError {
	for i, line := range strings.Split(text, "\n") {
		if line != "" && !strings.Contains(line, "=") {
			return &LineError{Line: i + 1, Msg: "no = in " + line}
		}
	}
	return nil
}

func load(text string) error {
	return check(text)
}

func main() {
	err := load("port=8080\nhost=localhost")
	fmt.Printf("%T %v\n", err, err == nil)
	if err != nil {
		fmt.Println("load failed:", err)
		fmt.Println(err.Error())
	}
}
```

The text is correct, so `check` returns `nil`. Here is what `main` saw:

```
ana@vm:~/errors-nil$ go vet && go run .
*main.LineError false
load failed: <nil>
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x49caf0]

goroutine 1 [running]:
main.(*LineError).Error(...)
	/home/ana/errors-nil/main.go:16
main.main()
	/home/ana/errors-nil/main.go:37 +0xf0
exit status 2
```

`go vet` found nothing, and the program compiled. Then `err == nil` was `false` for a load that
succeeded, the program announced a failure and gave `<nil>` as its reason, and the direct call to
`Error` crashed it with exit status 2. The crash is a `panic`, lesson 36's subject, and lesson 37
reads that trace line by line; for now, its frames say the crash happened inside
`(*LineError).Error`, called from `main`.

This is lesson 28's interface holding a nil pointer, met where it costs the most. `return nil` in
`check` produced a nil pointer of type `*LineError`. When `load` returned it as an `error`, Go
stored it in an interface, type and all, so the interface's type word said `*main.LineError` and
only its pointer was nil. **An interface value is `nil` only when both of its words are empty**,
the type and the pointer of lesson 22, and with `error` that matters more than anywhere: every
`if err != nil` in the program reads this value as a failure.

The `<nil>` in the second line is `fmt` covering for it: printing called `Error` on a nil pointer, `Error` read `e.Line` through that pointer and panicked, and `fmt` caught the panic
and printed `<nil>` instead. The next line called `Error` without `fmt` in between, and nothing
caught it.

The repair is the signature somebody changed. In `~/errors-nilfix` the only difference is that
`check` returns `error` again:

```
ana@vm:~/errors-nilfix$ go vet && go run .
<nil> true
```

With `error` as its result type, `check`'s `return nil` is a nil interface from the start, and
`load` passes on exactly that. **A function that can fail declares its result as `error`, never as
its own error type, and returns a literal `nil` when it succeeds.** The concrete type is still
there when something does fail: `%T` printed `*main.LineError` in `~/errors-custom` for a function
whose signature said `error`.
