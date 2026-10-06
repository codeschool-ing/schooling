---
title: A wrapped error is a chain
version: 1
---

Lesson 33 wrapped errors with `%w` and printed the result, and what it printed was a longer
message. That makes wrapping look like string concatenation with extra steps. **It is not: an error
wrapped with `%w` is a new value that holds the old one**, and the old one is still there, whole,
for any code that goes looking. This program goes looking. It tries to read a configuration file
that does not exist, wraps the failure twice on the way up, and then takes it apart:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n\t\"os\"\n)\n\n",
      "note": "The program imports `errors` for one function, `errors.Unwrap`, and `os` to read a file that is not there."
    },
    {
      "code": "func readConfig(path string) ([]byte, error) {\n\tdata, err := os.ReadFile(path)\n\tif err != nil {\n\t\treturn nil, fmt.Errorf(\"read config: %w\", err)\n\t}\n\treturn data, nil\n}\n\n",
      "note": "**`readConfig` wraps what `os.ReadFile` returned**, with `%w` and the words `read config`, exactly as lesson 33 did."
    },
    {
      "code": "func start() error {\n\tif _, err := readConfig(\"settings.json\"); err != nil {\n\t\treturn fmt.Errorf(\"start server: %w\", err)\n\t}\n\treturn nil\n}\n\n",
      "note": "**`start` wraps again**, so the error it returns has two layers of context on top of the one `os.ReadFile` made."
    },
    {
      "code": "func main() {\n\terr := start()\n\tfmt.Println(err)\n\tfor e := err; e != nil; e = errors.Unwrap(e) {\n\t\tfmt.Printf(\"%-20T %v\\n\", e, e)\n\t}\n}\n",
      "note": "**The loop takes one link off on every turn.** `errors.Unwrap(e)` returns the error `e` holds, or `nil` when it holds none, and `nil` ends the loop. `%-20T` prints each link's type, padded to 20 columns, then `%v` its message."
    }
  ],
  "output": "start server: read config: open settings.json: no such file or directory\n*fmt.wrapError       start server: read config: open settings.json: no such file or directory\n*fmt.wrapError       read config: open settings.json: no such file or directory\n*fs.PathError        open settings.json: no such file or directory\nsyscall.Errno        no such file or directory\n"
}
```

The first line is the message lesson 33 would print. The four lines under it are the same error
taken apart, one value per line, and each value is a different type:

- two `*fmt.wrapError`, which is what `fmt.Errorf` returns when its format has one `%w`. The
  type is unexported, so no program ever names it; what matters is that it has a method
  `Unwrap() error` that returns the error it was given;
- an `*fs.PathError`, which `os.ReadFile` made: the operation, the path, and the error behind
  them. It has an `Unwrap` method too, which is how the loop got past it;
- a `syscall.Errno`, the number the operating system answered the `open` call with, printed as
  words. It has no `Unwrap` method, so `errors.Unwrap` returned `nil` and the loop stopped.

**`errors.Unwrap` does one small thing: it calls the error's `Unwrap` method if it has one, and
returns `nil` if it has not.** Nothing else in the chain is magic. A wrapper is any error type with
that method, and lesson 33's `%w` is the quickest way to make one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"The error that start returned, drawn as a chain of four values. The outermost is a *fmt.wrapError whose message adds &#x27;start server: &#x27;; Unwrap leads to a second *fmt.wrapError that adds &#x27;read config: &#x27;; Unwrap leads to an *fs.PathError made by os.ReadFile, which adds &#x27;open settings.json: &#x27;; Unwrap leads to a syscall.Errno whose message is &#x27;no such file or directory&#x27;. It has no Unwrap method, so the chain ends there.\"><defs><marker id=\"ch-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*fmt.wrapError</text><text x=\"32\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">start server: </text><text x=\"116.0\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">read config: open settings.json: no such file or directory</text><text x=\"520\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">start&#x27;s wrap: the error</text><text x=\"520\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main received</text><path d=\"M60 66 L60 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><rect x=\"20\" y=\"94\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*fmt.wrapError</text><text x=\"32\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">read config: </text><text x=\"110.0\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">open settings.json: no such file or directory</text><text x=\"520\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">readConfig&#x27;s wrap</text><path d=\"M60 146 L60 174\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><rect x=\"20\" y=\"174\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*fs.PathError</text><text x=\"32\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">open settings.json: </text><text x=\"152.0\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">no such file or directory</text><text x=\"520\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">made by os.ReadFile: the</text><text x=\"520\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">operation, the path, the cause</text><path d=\"M60 226 L60 254\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><rect x=\"20\" y=\"254\" width=\"480\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">syscall.Errno</text><text x=\"32\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">no such file or directory</text><text x=\"520\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the system call&#x27;s own answer</text><path d=\"M60 306 L60 334\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-phosphor)\"></path><text x=\"72\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Unwrap()</text><text x=\"60\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">nil</text><text x=\"84\" y=\"344\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no Unwrap method: the chain ends here</text></svg>", "caption": "The error start returned is four values, each holding the next. The bold part of each message is what that link added; errors.Unwrap follows one arrow, and errors.Is and errors.As follow all of them."}
```

Each message contains the message of the link below it, because each link's message was built
from its own words followed by the message of the error it holds. That is why the top line reads left to right
as the story of the failure. **The message is a by-product of the chain, and the chain is what
code inspects.** Sections 03 and 04 are about inspecting it.

## More than one `%w` makes a tree

Lesson 33 also wrapped several errors at once, with several `%w` in one format or with
`errors.Join`. An error made that way holds a list, and its method is `Unwrap() []error`, a
different method from the one above. `errors.Unwrap` only calls the single-error form, so it gives
up on a joined error:

```go
	both := errors.Join(fs.ErrNotExist, fs.ErrPermission)
	fmt.Printf("%T\n", both)
	fmt.Println(errors.Unwrap(both))
	fmt.Println(errors.Is(both, fs.ErrPermission))
```

```
ana@vm:~/is-as-tree$ go run .
*errors.joinError
<nil>
true
```

`errors.Unwrap` says there is nothing inside, and the next line finds `fs.ErrPermission` inside
anyway. The package documentation calls the general shape a **tree**: a chain where any link may
branch. `errors.Is` and `errors.As` walk all of it, the error first and then each branch in turn,
depth first.

So `errors.Unwrap` is the tool for looking at a chain, as the loop above did, and rarely the tool
for deciding anything. Code that has to decide what to do about an error asks one of two questions
— is a particular error in there, or is an error of a particular type in there — and each question
has its own function.
