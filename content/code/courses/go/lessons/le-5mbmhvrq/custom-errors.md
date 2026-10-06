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

**An interface value is `nil` only when both of its words are empty**, the type and the pointer
that lesson 22 measured. `return nil` in `check` produced a nil pointer of type `*LineError`. When
`load` returned it as an `error`, Go stored it in an interface, and storing it filled in the type
word:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Three error values, each drawn as the two words of an interface: a type and a pointer. First, var err error: both words are empty, and err == nil is true. Second, the nil *LineError that check returned, stored in an error: the type word says *main.LineError and the pointer is nil, and err == nil is false. Third, a real failure: the type word says *main.LineError and the pointer leads to a LineError with Line 2. err == nil is false. Only the first is nil, because an interface is nil only when both words are empty.\"><defs><marker id=\"tn-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"285.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">type</text><text x=\"435.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pointer</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">err == nil</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nothing stored</text><text x=\"20\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">var err error</text><rect x=\"210\" y=\"40\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">nil</text><rect x=\"360\" y=\"40\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">nil</text><text x=\"600\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">true</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a nil *LineError stored</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">return check(text)</text><rect x=\"210\" y=\"110\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">*main.LineError</text><rect x=\"360\" y=\"110\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">nil</text><text x=\"600\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">false</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a real failure</text><text x=\"20\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&amp;LineError{...}</text><rect x=\"210\" y=\"180\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">*main.LineError</text><rect x=\"360\" y=\"180\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">•</text><text x=\"600\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">false</text><path d=\"M435.0 205.0 L435.0 238\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-phosphor)\"></path><rect x=\"310.0\" y=\"240\" width=\"250\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">LineError{Line: 2, Msg: ...}</text><text x=\"600\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nil only when both words are empty</text></svg>", "caption": "An error is nil only when both of its words are empty. Storing a nil *LineError fills in the type word, and from then on err != nil is true although the pointer is nil."}
```

So `err` held a type and a nil pointer, which is not the nil interface. Lesson 28 met the same
thing with `any`; with `error` it costs more, because every `if err != nil` in the program reads it
as a failure. The `<nil>` in the second line is `fmt` covering for it: printing called `Error` on a
nil pointer, `Error` read `e.Line` through that pointer and panicked, and `fmt` caught the panic
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
