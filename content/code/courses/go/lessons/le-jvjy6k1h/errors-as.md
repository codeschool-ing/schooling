---
title: "errors.As: take the link out, with its fields"
version: 1
---

`errors.Is` answers yes or no. Sometimes the code above needs more than that: the name of the file
that was missing, to put in a message for a person, or to create it. The tempting move is to read
it out of the message, with `strings.Contains(err.Error(), ...)` or worse, and **a message is
written for people and changes when anybody adds a layer of context**. The data is still in the
chain, in a value with fields. This is the link `os.ReadFile` put there, the type lesson 32 met
under its alias `os.PathError`:

```
ana@vm:~/is-as-as$ go doc fs.PathError
package fs // import "io/fs"

type PathError struct {
	Op   string
	Path string
	Err  error
}
    PathError records an error and the operation and file path that caused it.

func (e *PathError) Error() string
func (e *PathError) Timeout() bool
func (e *PathError) Unwrap() error
```

Three fields, and the methods are on the pointer, `*PathError`, so the error in the chain is a
`*fs.PathError`, as section 02's loop printed. `errors.As` finds a link by its type and hands it
over, and `errors.AsType` does the same with a different signature. Here are both, after the one
check that does not work, in a new `main` for the same program:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "func main() {\n\terr := start()\n\n",
      "note": "The same `start` as in section 02 runs first; `err` is the four-link chain."
    },
    {
      "code": "\t_, ok := err.(*fs.PathError)\n\tfmt.Println(\"assertion:\", ok)\n\n",
      "note": "**A type assertion asks about the outside value only**, the way `==` did in section 03. The outside is a `*fmt.wrapError`, so `ok` is false. Lesson 29 is about assertions."
    },
    {
      "code": "\tvar pe *fs.PathError\n\tif errors.As(err, &pe) {\n\t\tfmt.Println(\"Op:  \", pe.Op)\n\t\tfmt.Println(\"Path:\", pe.Path)\n\t\tfmt.Println(\"Err: \", pe.Err)\n\t}\n\n",
      "note": "**`errors.As` walks the chain looking for a link whose type is the type of `pe`**, and copies it into `pe` when it finds one. That is why it takes `&pe`: it needs the address of the variable it fills in."
    },
    {
      "code": "\tif pe, ok := errors.AsType[*fs.PathError](err); ok {\n\t\tfmt.Println(\"AsType found\", pe.Path)\n\t}\n}\n",
      "note": "**`errors.AsType` does the same and returns the link instead of filling a variable.** The type goes in the square brackets, as a type argument (lesson 31), and the result comes back with a comma-ok boolean."
    }
  ],
  "output": "assertion: false\nOp:   open\nPath: settings.json\nErr:  no such file or directory\nAsType found settings.json\n"
}
```

**`errors.Is` looks for a value; `errors.As` and `errors.AsType` look for a type**, and both walk
the whole chain the way section 02's figure draws it. Once the link is out, it is an ordinary
`*fs.PathError`: `pe.Path` is the string `settings.json`, with no parsing, and `pe.Err` is the
`syscall.Errno` one link further down.

The same works for any error type, including the ones you write. Lesson 32's `LineError` kept a line
number in a field; once a caller has wrapped one, `errors.As` with a `*LineError` variable, or
`errors.AsType[*LineError]`, is how the code above gets the number back.

## The target must be a pointer to a variable

`errors.As` takes its target as `any`, so the compiler accepts anything there. Forget the `&` and
pass the variable itself:

```go
	var pe *fs.PathError
	if errors.As(err, pe) {
		fmt.Println(pe.Path)
	}
```

`pe` is a `*fs.PathError` that points nowhere. `errors.As` has no variable to write into, and it
cannot tell you so at compile time, so it panics when it runs. `go vet` reads the call first and
says what is wrong:

```
ana@vm:~/is-as-panic$ go vet; echo $?
main.go:13:5: second argument to errors.As must be a non-nil pointer to either a type that implements error, or to any interface type
1
ana@vm:~/is-as-panic$ go build && ./panic 2>&1 | head -3
panic: errors: target must be a non-nil pointer

goroutine 1 [running]:
ana@vm:~/is-as-panic$ ./panic 2>/dev/null; echo $?
2
```

The program stops at the call with exit status 2, which lesson 36 explains, and prints a stack
trace that `head` cut short here and lesson 37 reads in full. **This is a mistake `go vet`
catches every time**, which is one more reason to run it before anybody else reads the code, as
lesson 4 said.

## `AsType` checks the type when it compiles

`errors.AsType` takes the type in square brackets instead of a variable, so there is nothing to
forget an `&` on. It also refuses a type that cannot be in a chain at all. `fs.PathError` without
the star is such a type, because its `Error` method is on the pointer:

```go
	if pe, ok := errors.AsType[fs.PathError](err); ok {
		fmt.Println(pe.Path)
	}
```

```
ana@vm:~/is-as-value$ go run .; echo $?
# example.com/value
./main.go:12:29: fs.PathError does not satisfy error (method Error has pointer receiver)
1
```

That is lesson 26's method sets, met from the other side: only `*fs.PathError` is an `error`, so
only it can be asked for. The same mistake written with `errors.As`, a `var pe fs.PathError` and
`&pe`, compiles, and is caught by the two things that caught the missing `&`:

```
ana@vm:~/is-as-value2$ go vet; echo $?
main.go:13:5: second argument to errors.As must be a non-nil pointer to either a type that implements error, or to any interface type
1
ana@vm:~/is-as-value2$ go build && ./value 2>&1 | head -1
panic: errors: *target must be interface or implement error
```

The documentation now points at the newer function:

```
ana@vm:~/is-as-old$ go doc errors.As | head -10
package errors // import "errors"

func As(err error, target any) bool
    As finds the first error in err's tree that matches target, and if one
    is found, sets target to that error value and returns true. Otherwise,
    it returns false.

    For most uses, prefer AsType. As is equivalent to AsType but sets its target
    argument rather than returning the matching error and doesn't require its
    target argument to implement error.
```

`AsType` is the younger of the two. The release before 1.26 does not have it at all:

```
ana@vm:~/is-as-old$ GOTOOLCHAIN=go1.25.0 go doc errors.AsType
doc: no symbol AsType in package errors
ana@vm:~/is-as-old$ GOTOOLCHAIN=go1.26.0 go doc errors.AsType | head -3
package errors // import "errors"

func AsType[E error](err error) (E, bool)
```

So write `AsType` in new code, and read `As` fluently, because it is the form in every module that
had to build with an older Go. The rule for choosing between them and `errors.Is` is shorter than
either signature: **ask `Is` when the answer is yes or no, and `As` or `AsType` when you need the
value**. Which errors deserve a variable of their own for `Is` to look for is lesson 35's subject.
