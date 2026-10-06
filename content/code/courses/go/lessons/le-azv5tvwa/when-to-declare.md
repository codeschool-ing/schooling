---
title: Sentinel, error type or neither
version: 1
---

Section 03 makes declaring a sentinel look cheap: one line, one `errors.New`. The habit that
follows is to declare one for every way a function can fail, "just in case a caller wants it".
**Each one is a promise you keep for as long as the package exists**, and most failures are not
worth promising anything about. There are three shapes an error can take, and two questions pick
between them:

| does a caller branch on this failure? | does it need data from it? | return | examples |
|---|---|---|---|
| yes | no | a sentinel, `var ErrX = errors.New(...)` | `io.EOF`, `fs.ErrNotExist`, `store.ErrNotFound` |
| yes | yes | an error type, found with `errors.As` | `*fs.PathError`, lesson 32's `*LineError` |
| no | no | an opaque error from `errors.New` or `fmt.Errorf` | the bad age of lesson 32's `price` |

The third row is the default, and it is the right answer far more often than the table's layout
suggests. An opaque error is still a perfectly good error: it has a message, it can wrap what
caused it, and the caller does what lesson 32's idiom does with any error, which is return it with
some context or report it. What it does not have is a name anybody can check for, and that is
exactly what keeps it free to change.

## A type can carry a sentinel

The two upper rows are not exclusive, and `strconv` shows both at once. A failed conversion
returns a `*strconv.NumError`, whose `Err` field holds one of two sentinels:

```
ana@vm:~/sentinel-strconv$ go doc strconv.NumError
package strconv // import "strconv"

type NumError struct {
	Func string // the failing function (ParseBool, ParseInt, ParseUint, ParseFloat, ParseComplex)
	Num  string // the input
	Err  error  // the reason the conversion failed (e.g. ErrRange, ErrSyntax, etc.)
}
    A NumError records a failed conversion.

func (e *NumError) Error() string
func (e *NumError) Unwrap() error
```

`Unwrap` returns that field, so a caller can ask either question of the same error:

```go
	for _, s := range []string{"42", "4x2", "99999999999999999999"} {
		n, err := strconv.Atoi(s)
		switch {
		case err == nil:
			fmt.Println(s, "->", n)
		case errors.Is(err, strconv.ErrSyntax):
			fmt.Println(s, "-> not a number")
		case errors.Is(err, strconv.ErrRange):
			fmt.Println(s, "-> too big for an int")
		}
		if ne, ok := errors.AsType[*strconv.NumError](err); ok {
			fmt.Printf("   Func=%s Num=%q Err=%v\n", ne.Func, ne.Num, ne.Err)
		}
	}
```

```
ana@vm:~/sentinel-strconv$ go run .
42 -> 42
4x2 -> not a number
   Func=Atoi Num="4x2" Err=invalid syntax
99999999999999999999 -> too big for an int
   Func=Atoi Num="99999999999999999999" Err=value out of range
```

**The sentinel answers which kind of failure it was; the type answers which input it was about.**
A program that only needs the first never has to name `NumError`, and one that needs the input
gets it from a field instead of from the message.

## Taking a promise back

`store.ErrNotFound` has a caller now, section 03's `main`. There are two ways to stop promising it,
and they fail very differently.

The quiet one: somebody tidies `Count` and writes the message out by hand, `fmt.Errorf("count %q: not found", item)`,
with no `%w`. The variable is still there and still exported, and `Count`'s
comment still says the error wraps it. `main` is not touched:

```
ana@vm:~/sentinel-v2$ go vet && go run .
apple: 12 in stock
pear: 0 in stock
plum: failed: count "plum": not found
```

`go vet` found nothing and the program compiled. The message for `plum` is the same text, letter
for letter. **The only change is that the caller's branch stopped firing**, and `plum` is now
reported as a failure of the store rather than an item it does not sell. No tool in this lesson
could have caught it; a test that asks for a missing item could, and tests are the `go-concurrency`
course's subject.

The loud one: delete the variable.

```
ana@vm:~/sentinel-v3$ go run .; echo $?
# example.com/shop
./main.go:14:29: undefined: store.ErrNotFound
1
```

That breaks every caller at once, and at least it says so: line 14 of `main.go`, the `case` that
named it. **Removing a sentinel breaks callers loudly; ceasing to return it breaks them
silently**, and the silent version is the one that ships.

That is the cost on the other side of the table. A sentinel cannot be taken back without breaking
somebody, which is why the first two rows are a decision and the third is the default. Lesson 33
said the same of `%w`: wrapping an error makes it part of your API. A sentinel is that promise made
on purpose, with a name, and lesson 40's versions are how a module tells its callers it has broken
one.
