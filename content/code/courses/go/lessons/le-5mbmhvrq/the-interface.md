---
title: The `error` interface
version: 1
---

In Java, Python and JavaScript a failure is **thrown**: it leaves the function by an exit of its
own, skips every line after it and climbs the calls until something catches it. People arriving
from those languages look for the same machinery in Go, and it is not there. **In Go an error is
an ordinary value, returned beside the result**, and the caller decides on the next line what to
do with it. Lesson 20 showed the shape, `(T, error)`; this section is about the second half.

`error` is not a keyword and not a special kind of object. It is a type the language declares for
you, and `go doc` shows its whole declaration:

```
ana@vm:~/errors$ go doc builtin.error
package builtin // import "builtin"

type error interface {
	Error() string
}
    The error built-in interface type is the conventional interface for
    representing an error condition, with the nil value representing no error.

```

**An interface with one method, `Error() string`.** Any type that has that method is an `error`,
without saying so anywhere; lesson 27 is about interfaces satisfied that way. And the last words of
the comment are the rule the rest of this lesson rests on: **a nil `error` means nothing went
wrong.**

## Two errors from the standard library

Two calls that can fail, `os.Open` on a file that is not there and `strconv.Atoi` on text that is
not a number, in `~/errors`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command errors looks at two errors from the standard library.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"strconv\"\n)\n\nfunc main() {\n\tf, err := os.Open(\"notes.txt\")\n\tfmt.Println(f, err)\n",
      "note": "**`os.Open` returns two results, the file and an `error`.** There is no `notes.txt` in `~/errors`, so the file is `nil` and the error is not: printed, it is a sentence naming the operation, the path and the reason."
    },
    {
      "code": "\tfmt.Printf(\"%T\\n\", err)\n",
      "note": "`%T` prints the type of the value inside the interface, `*fs.PathError`. The variable was declared as `error`; what it holds is a pointer to a struct of the `io/fs` package."
    },
    {
      "code": "\n\tn, err := strconv.Atoi(\"12\")\n\tfmt.Println(n, err, err == nil)\n",
      "note": "**Success is an `err` equal to `nil`.** `\"12\"` is a number, so `n` is 12 and the comparison is `true`. `:=` is allowed here because `n` is new, and `err` is simply assigned (lesson 5)."
    },
    {
      "code": "\n\tn, err = strconv.Atoi(\"12a\")\n\tfmt.Println(n, err, err == nil)\n\tfmt.Printf(\"%T\\n\", err)\n\tfmt.Println(err.Error())\n}\n",
      "note": "A failed conversion: `n` is 0 and `err` holds a `*strconv.NumError`, another type entirely. **Calling its `Error` method gives the same text `fmt.Println` printed**, because printing an error is calling that method."
    }
  ],
  "output": "<nil> open notes.txt: no such file or directory\n*fs.PathError\n12 <nil> true\n0 strconv.Atoi: parsing \"12a\": invalid syntax false\n*strconv.NumError\nstrconv.Atoi: parsing \"12a\": invalid syntax\n"
}
```

The first and the last lines of the output are the two halves of one fact. `fmt.Println` printed
`open notes.txt: no such file or directory` because `fmt` checks whether a value is an `error`
and, if it is, calls `Error` and prints the string. **The message is whatever the error's own type
decided to say**, and the two types here say it differently: `*fs.PathError` writes the operation,
the path and the reason, and `*strconv.NumError` writes the function, the input and what was
wrong with it.

## One interface, many types behind it

Lesson 22 measured an interface value: 16 bytes, a type and a pointer. An `error` is exactly that.
The variable `err` was declared once, as `error`, and held a `*fs.PathError` on one line and a
`*strconv.NumError` four lines later. `%T` reads the type half, which is why it printed two
different names for one variable.

The documentation says which type to expect. `os.Open` promises it in its last sentence:

```
ana@vm:~/errors$ go doc os.Open
package os // import "os"

func Open(name string) (*File, error)
    Open opens the named file for reading. If successful, methods on the
    returned file can be used for reading; the associated file descriptor has
    mode O_RDONLY. If there is an error, it will be of type *PathError.

ana@vm:~/errors$ go doc os.PathError
package os // import "os"

type PathError = fs.PathError
    PathError records an error and the operation and file path that caused it.

```

`os.PathError` is an alias, the `=` form of lesson 10, for `fs.PathError`, which is why `%T`
named the `fs` package. **The signature still says `error` and not `*PathError`.** A caller that
only has to know whether the call failed, and what to tell a person, needs nothing but the
interface. A caller that wants the path out of the struct can get it, and lesson 34 shows how.

## Checking is a comparison with nil

Success is `err == nil`, and nothing shorter. Somebody used to Python or JavaScript tries the
short form first, in `~/errors-truthy`:

```go
	_, err := strconv.Atoi("12a")
	if err {
		fmt.Println(err)
	}
```

```
ana@vm:~/errors-truthy$ go run .
# example.com/truthy
./main.go:10:5: non-boolean condition in if statement
```

It is lesson 8's refusal: Go has no truthiness, and an interface is not a boolean. So the test is
always written out as a comparison, `err != nil` when you want the failure, and section 03 is
about the line that comparison sits in.

One more thing the output of `~/errors` shows: when `Atoi` failed, `n` was 0. The function still
returned a number, because a function with two results always returns two. **The value beside a
non-nil error is not an answer**, and 0 there means nothing more than "nothing to give you". The
few functions where it does mean something say so in their documentation: `go doc io.Reader`
tells a caller to use the bytes a `Read` returned before looking at its error.
