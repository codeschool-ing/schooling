---
title: unsafe.Pointer, uintptr and the six valid patterns
version: 1
---

Two types carry an address, and they are easy to confuse because both print as a number.
**`unsafe.Pointer` is a pointer the type system has stopped checking**: it can be converted to and
from a pointer of any type, and the garbage collector still sees it as a pointer. **`uintptr` is an
integer**, wide enough to hold an address and with no more meaning to the runtime than an `int`
holding a temperature. The documentation of `unsafe.Pointer` lists the four conversions that make
the first type special:

- a pointer value of any type can be converted to a `Pointer`;
- a `Pointer` can be converted to a pointer value of any type;
- a `uintptr` can be converted to a `Pointer`;
- a `Pointer` can be converted to a `uintptr`.

The first two are how one type is read as another. The last two are how an address becomes
arithmetic and comes back, and they are where nearly every misuse lives.

## The patterns the documentation allows

`go doc unsafe.Pointer` lists six patterns and says of everything else that it is "likely to be
invalid today or to become invalid in the future". That sentence is the contract. **There is no rule
in the language that makes other code wrong; there is a list, and code off the list may compile, run
and pass its tests until a release changes something underneath it.**

| | pattern | the documentation's example |
|---|---|---|
| 1 | `*T1` to `Pointer` to `*T2`, when `T2` is no larger and has an equivalent layout | `math.Float64bits` reading a `float64` as a `uint64` |
| 2 | `Pointer` to `uintptr`, and never back | printing an address |
| 3 | `Pointer` to `uintptr` and back, with arithmetic, in one expression | the address of a field or of an array element |
| 4 | `Pointer` to `uintptr` in the argument list of a call like `syscall.Syscall` | passing a buffer to the kernel |
| 5 | the result of `reflect.Value.Pointer` or `UnsafeAddr`, converted at once | lesson 21's `reflect`, reaching memory |
| 6 | the `Data` field of `reflect.SliceHeader` or `StringHeader` | building a slice by hand, now deprecated |

Pattern 3 comes with three conditions that the documentation spells out. **The result must still
point into the original allocated object**, so even a pointer one byte past the end of a slice is
invalid, which C allows. The pointer may not be `nil`. And both conversions must appear in the same
expression, with nothing but arithmetic between them. Pattern 6 is history: `go doc
reflect.SliceHeader` says "Deprecated: Use unsafe.Slice or unsafe.SliceData instead", the functions
section 04 uses.

## An integer keeps nothing alive

The reason for "in the same expression" is what the garbage collector can see. It finds the objects
still in use by following pointers, and a `uintptr` is not one. **An object whose only remaining
trace is its address in a `uintptr` is garbage, and the collector frees it.** This program keeps the
address of a `tally.Entry`, drops the pointer, and asks the runtime to say when the entry is
collected. Save it as `alive/main.go`:

```go
// Command alive shows that an address held as a uintptr keeps nothing alive.
package main

import (
	"fmt"
	"runtime"
	"time"
	"unsafe"

	"example.com/hits/internal/tally"
)

func main() {
	e := &tally.Entry{Method: "GET", Path: "/login", Status: 200}
	runtime.AddCleanup(e, func(path string) {
		fmt.Println("collector: freed the entry for", path)
	}, e.Path)

	addr := uintptr(unsafe.Pointer(e)) // an integer, not a reference
	e = nil                            // the last real reference is gone

	runtime.GC()
	time.Sleep(10 * time.Millisecond) // cleanups run on their own goroutine
	fmt.Printf("main still holds %#x, which now points at nothing of ours\n", addr)
}
```

`runtime.AddCleanup` runs a function on a goroutine of its own some time after its first argument
stops being reachable. The function is given `e.Path`, a copy, because a cleanup that could reach
the entry would keep it reachable forever. Run twice:

```
ana@vm:~/unsafe$ go run ./alive
collector: freed the entry for /login
main still holds 0x316c3ee96000, which now points at nothing of ours
ana@vm:~/unsafe$ go run ./alive
collector: freed the entry for /login
main still holds 0x7d5063e2000, which now points at nothing of ours
```

**The entry was freed while `main` still held its address.** Nothing went wrong here, because the
program never turns `addr` back into a pointer, which is pattern 2. Had it done so, it would have
read memory the allocator was free to hand to anything. The address is different on every run
because Go 1.27 places the heap at a random base on 64-bit machines (`runtime/malloc.go` calls it
`randomizeHeapBase`), so even a number saved from one run means nothing in the next.

**The current collector moves no object in the heap, and that is no defence.** Goroutine stacks do
move: a stack that runs out of room is copied to a bigger one, and every pointer into it is
adjusted. A `uintptr` holding the address of a local variable is not, because the runtime does not
know it is an address. The help text of `go vet`'s `unsafeptr` check gives exactly that reason: such
a word "will be invisible to stack copying and to the garbage collector".

## What `go vet` catches

The next program reads `Status` out of a `tally.Entry` by address arithmetic, three ways. Save it as
`field/main.go`:

```go
// Command field reads one field of a tally.Entry through unsafe.Pointer,
// once by a valid pattern and once by an invalid one.
package main

import (
	"fmt"
	"unsafe"

	"example.com/hits/internal/tally"
)

func main() {
	e := tally.Entry{Method: "POST", Path: "/api/users", Status: 404}

	// Pattern 3: Pointer to uintptr and back, in one expression.
	p := unsafe.Pointer(uintptr(unsafe.Pointer(&e)) + unsafe.Offsetof(e.Status))
	fmt.Println("pattern 3:  ", *(*int)(p))

	// unsafe.Add says the same thing without the round trip.
	q := unsafe.Add(unsafe.Pointer(&e), unsafe.Offsetof(e.Status))
	fmt.Println("unsafe.Add: ", *(*int)(q))

	// INVALID: the address spends a moment as a plain integer.
	u := uintptr(unsafe.Pointer(&e))
	r := unsafe.Pointer(u + unsafe.Offsetof(e.Status))
	fmt.Println("stored:     ", *(*int)(r))
}
```

`unsafe.Add`, from Go 1.17, is pattern 3 without the round trip through `uintptr`, and the
documentation adds that "the rules for valid uses of Pointer still apply". Run, and then vet:

```
ana@vm:~/unsafe$ go run ./field
pattern 3:   404
unsafe.Add:  404
stored:      404
ana@vm:~/unsafe$ go vet ./field; echo $?
field/main.go:25:7: possible misuse of unsafe.Pointer
1
```

**All three printed 404, including the invalid one.** The address spent one statement as an integer,
nothing moved and nothing was collected in that moment, and the program worked. That is the usual
shape of an `unsafe` bug. The line that is wrong does not crash; something crashes some other day,
under load, on the run where the collector or the stack happened to act between those two lines. `go
vet` found it by looking at the code instead of the run: `unsafeptr` reports a `uintptr` turned back
into a `Pointer` anywhere outside the patterns.

**`go test` does not run that check.** Its help lists the subset of `vet` it runs before a test
binary (`atomic`, `bools`, `buildtag`, `directive`, `errorsas`, `ifaceassert`, `nilfunc`, `printf`,
`stdversion`, `stringintconv` and `tests`), and `unsafeptr` is not in it. A project with `unsafe` in
it needs `go vet ./...` as a step of its own, which is lesson 7's subject.

## What `go vet` cannot catch, and checkptr can

`vet` reads code, and some invalid conversions look perfectly regular. This program reads a status
code out of a binary record, once through a pointer cast and once through `encoding/binary`. A
record is a version byte, a 16-byte request id and the status as eight bytes, 25 in all; the second
record is cut off one byte into the status, as a truncated file would leave it. Save it as
`cast/main.go`:

```go
// Command cast reads the status code out of binary records. A record is a
// version byte, a request id of 16 bytes, and the status as eight
// little-endian bytes.
package main

import (
	"encoding/binary"
	"fmt"
	"unsafe"
)

const statusAt = 17

// quick reads the eight bytes of the status through a pointer cast.
func quick(rec []byte) uint64 {
	return *(*uint64)(unsafe.Pointer(&rec[statusAt]))
}

// checked reads the same eight bytes through encoding/binary.
func checked(rec []byte) uint64 {
	return binary.LittleEndian.Uint64(rec[statusAt:])
}

// record builds a whole record with the given status.
func record(status uint64) []byte {
	rec := make([]byte, statusAt+8)
	rec[0] = 1
	binary.LittleEndian.PutUint64(rec[statusAt:], status)
	return rec
}

// cut copies the first n bytes of a record, the way a truncated file would
// hand them over.
func cut(rec []byte, n int) []byte {
	return append([]byte(nil), rec[:n]...)
}

func main() {
	whole := record(404)
	for _, rec := range [][]byte{whole, cut(whole, statusAt+1)} {
		fmt.Printf("%d bytes: quick   %d\n", len(rec), quick(rec))
		fmt.Printf("%d bytes: checked %d\n", len(rec), checked(rec))
	}
}
```

```
ana@vm:~/unsafe$ go build -o bin/cast ./cast && bin/cast 2>&1 | head -4; echo ${PIPESTATUS[0]}
25 bytes: quick   404
25 bytes: checked 404
18 bytes: quick   3602879701896396948
panic: runtime error: index out of range [7] with length 1
2
ana@vm:~/unsafe$ go vet ./cast; echo $?
0
```

**The cast read eight bytes where the record had one, and returned a number.** The other seven came
from past the end of the record: spare bytes of its allocation, and the first byte of whatever the
allocator put next to it. `encoding/binary` checked the length and panicked, naming the index and
the length, which is what a bounds check is for. And `go vet` is silent. It has no rule about
pattern 1 at all, and whether eight bytes really follow `&rec[statusAt]` depends on the length of
`rec` at run time, which no reading of the code can know.

The compiler can instrument every conversion involving `unsafe.Pointer` with a check at run time,
called checkptr. **`-gcflags=all=-d=checkptr` turns it on for every package in the build**, and so
does `-race`: the compiler's flag handling says "-race, -msan and -asan imply -d=checkptr", which is
one more reason the race detector of lesson 15 belongs in CI.

```
ana@vm:~/unsafe$ go build -gcflags=all=-d=checkptr -o bin/cast ./cast && bin/cast 2>&1 | head -3; echo ${PIPESTATUS[0]}
25 bytes: quick   404
25 bytes: checked 404
fatal error: checkptr: converted pointer straddles multiple allocations
2
ana@vm:~/unsafe$ go build -race -o bin/cast ./cast && bin/cast 2>&1 | head -3; echo ${PIPESTATUS[0]}
25 bytes: quick   404
25 bytes: checked 404
fatal error: checkptr: converted pointer straddles multiple allocations
2
```

**The whole record passed and the cut one stopped the program**, before `quick` could return its
invented number. checkptr compares the allocation where the eight bytes start with the one where
they end, and here they differ. The allocator hands out small objects in fixed sizes (16, 24 and 32
bytes are three of them, listed in `internal/runtime/gc/sizeclasses.go`), so the 18-byte record sits
in a 24-byte slot, and bytes 17 to 24 run one byte past it. The same comparison explains its limit.
A read that stays inside its own slot's spare bytes passes, and so does anything on the stack, which
checkptr treats as one region. **A green run under checkptr says no conversion it checked was
invalid, and says nothing about the ones it could not see.**
