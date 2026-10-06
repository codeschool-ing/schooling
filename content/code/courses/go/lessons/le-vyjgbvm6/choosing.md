---
title: Choosing a receiver
version: 1
---

Two pieces of advice circulate, and both are half right. One says to use pointer receivers
everywhere because they avoid a copy. The other says to use value receivers because a copy is
safe. **The receiver is not chosen per method for speed or for safety. It is chosen once per type,
from what the type is**, and four questions settle it, asked in this order.

## 1. Does any method change the receiver?

**Then that method needs a pointer**, as section 02 showed: a value receiver changes a copy and the
caller never sees it. This is the question that decides most types, and once one method needs a
pointer, the rule at the end of question 4 gives the pointer to all of them.

## 2. Does the type hold something that must not be copied?

Some values stop working when copied. The clearest is a `sync.Mutex`, a lock that lets only one
part of a program at a time touch some data. Locks belong to the `go-concurrency` course; what
matters here is that **a copy of a lock is a different lock**, so a method that copies one is
locking something nobody else holds. Here a value receiver copies it on every call:

```go
package main

import (
	"fmt"
	"sync"
)

type Stats struct {
	mu   sync.Mutex
	hits int
}

func (s *Stats) Hit() {
	s.mu.Lock()
	s.hits++
	s.mu.Unlock()
}

func (s Stats) Hits() int {
	s.mu.Lock()
	n := s.hits
	s.mu.Unlock()
	return n
}

func main() {
	var s Stats
	s.Hit()
	s.Hit()
	fmt.Println(s.Hits())
}
```

```
ana@vm:~/receivers-lock$ go run .
2
ana@vm:~/receivers-lock$ go vet; echo $?
main.go:19:9: Hits passes lock by value: example.com/stats.Stats contains sync.Mutex
1
```

The program prints the right answer, because nothing else is running at the same time, and `go
vet` refuses it anyway. Line 19 is the receiver of `Hits`. `Hits` only reads, so by question 1
alone it could have been a value method. Question 2 overrules that: a type holding a lock takes a
pointer on every method. `strings.Builder` says the same about itself in its documentation, below.

## 3. Is the value large?

A value receiver copies the whole value on every call, like any parameter. Lesson 22 timed what
that costs on the lab's machine: 1.954 ns to pass a 16-byte struct, 15.51 ns for a 1,024-byte one
and 350,746 ns for an 8,000,000-byte array. A struct of a few fields is nowhere near the size that
matters. **A type that carries a large array inside it is, and its methods take a pointer.**

## 4. Otherwise a value, and either way one kind per type

A small type that is used like a number — a date, an amount, a coordinate — reads best with value
receivers. Its methods return new values instead of changing the old one, and a value of it can be
passed, stored and printed without anybody asking who else holds it. `time.Time` is the standard
library's example, and its documentation says so directly:

```
ana@vm:~/receivers$ go doc time.Time | head -10
package time // import "time"

type Time struct {
	// Has unexported fields.
}
    A Time represents an instant in time with nanosecond precision.

    Programs using times should typically store and pass them as values,
    not pointers. That is, time variables and struct fields should be of type
    time.Time, not *time.Time.
ana@vm:~/receivers$ go doc -all time | grep -c "^func (t Time)"
43
ana@vm:~/receivers$ go doc -all time | grep "^func (t \*Time)"
func (t *Time) GobDecode(data []byte) error
func (t *Time) UnmarshalBinary(data []byte) error
func (t *Time) UnmarshalJSON(data []byte) error
func (t *Time) UnmarshalText(data []byte) error
```

Forty-three methods with a value receiver and four with a pointer, and the four are not a lapse.
Each one decodes a `Time` from bytes, which means overwriting the receiver, which is question 1.
`t.Add(d)` returns a new `Time`; `t.UnmarshalJSON(data)` has to replace `t`.

**Apart from methods like those four, pick one kind of receiver for a type and use it on every
method.** Section 03 is the reason. A type whose methods are mixed has a value method set that is
missing some of them, so whether a value of it satisfies an interface depends on which method the
interface happens to name. `strings.Builder` shows the other half of the rule:

```
ana@vm:~/receivers$ go doc strings.Builder
package strings // import "strings"

type Builder struct {
	// Has unexported fields.
}
    A Builder is used to efficiently build a string using Builder.Write methods.
    It minimizes memory copying. The zero value is ready to use. Do not copy a
    non-zero Builder.

func (b *Builder) Cap() int
func (b *Builder) Grow(n int)
func (b *Builder) Len() int
func (b *Builder) Reset()
func (b *Builder) String() string
func (b *Builder) Write(p []byte) (int, error)
func (b *Builder) WriteByte(c byte) error
func (b *Builder) WriteRune(r rune) (int, error)
func (b *Builder) WriteString(s string) (int, error)
```

`Len`, `Cap` and `String` only read, and they take a pointer like the rest, because the type is
one that must not be copied — "Do not copy a non-zero Builder" is question 2, in the type's own
words. A `Builder` is meant to be held as a `*strings.Builder`, and lesson 27 passes one to a
function that writes into it.

So the four questions come down to one decision per type:

| the type | receiver | example |
|---|---|---|
| has a method that changes it | pointer, on every method | `strings.Builder` |
| holds a lock or anything else that must not be copied | pointer, on every method | `Stats` above |
| is large | pointer, on every method | a struct carrying a big array |
| is small and used like a number | value, on every method | `time.Time`, `Money` |
