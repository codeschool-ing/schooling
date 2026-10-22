---
title: What unsafe costs, and a rule for using it
version: 1
---

Sections 03 and 04 kept meeting programs that worked when they should not have: a pointer stored as
an integer that still read 404, a cast that returned a number for bytes that were not there, a map
that counted every request under the wrong keys. **The price of `unsafe` is not speed or size; it is
that the compiler, the type system and most of the tools stop being able to tell you that you are
wrong.** It comes in four parts.

## Outside the compatibility promise

The second sentence of `go doc unsafe` is the first cost: "Packages that import unsafe may be
non-portable and are not protected by the Go 1 compatibility guidelines." Go's promise is that a
program which builds with one Go 1 release keeps building, and behaving the same way, with the next.
**Code that depends on how the runtime lays memory out has stepped out of that promise**, and the
runtime is free to change the layout in any release.

The standard library keeps the evidence. When a widely used package reaches into an unexported
function of the runtime (which takes a `//go:linkname` directive, and the compiler refuses that
directive in a file that does not import `unsafe`), the Go team cannot change that function without
breaking the package. So the function gets a comment naming who depends on it:

```
ana@vm:~/unsafe$ grep -r "hall of shame" "$(go env GOROOT)/src" --include=*.go | wc -l
182
ana@vm:~/unsafe$ grep -B7 "^func checkptrBase" "$(go env GOROOT)/src/runtime/checkptr.go"
// Notable members of the hall of shame include:
//   - github.com/bytedance/sonic
//
// Do not remove or change the type signature.
// See go.dev/issue/67401.
//
//go:linkname checkptrBase
func checkptrBase(p unsafe.Pointer) uintptr {
```

**182 such comments in the Go source tree, each one a function that can no longer change**, because
a package outside the standard library linked to something that was never offered. One of them is
the function checkptr itself uses to find where an allocation starts, from section 03.

## Portability: the numbers belong to one machine

Section 02's offsets were measured on `linux/amd64`. The compiler builds for other architectures,
and lesson 16 showed how; `GOARCH=386` builds a 32-bit program that this machine can run directly:

```
ana@vm:~/unsafe$ GOARCH=386 go run ./layout
tally.Entry  size 48  align 4
  Time      offset  0  size 20
  Method    offset 20  size  8
  Path      offset 28  size  8
  Status    offset 36  size  4
  Duration  offset 40  size  8
Loose        size 24  align 4
  Cached    offset  0  size  1
  Bytes     offset  4  size  8
  TLS       offset 12  size  1
  Status    offset 16  size  4
  Retry     offset 20  size  1
Tight        size 16  align 4
  Bytes     offset  0  size  8
  Status    offset  8  size  4
  Cached    offset 12  size  1
  TLS       offset 13  size  1
  Retry     offset 14  size  1
1000000 Loose  24006048 bytes
1000000 Tight  16007168 bytes
```

**Every number changed except `Tight`'s size and offsets**, which hold because its fields were
already in order of size. On 386 a pointer is four bytes, so a string is 8 and `tally.Entry` is 48;
an `int64` aligns to 4, so `Loose` wastes less and is 24. `Status` in `tally.Entry` is at offset 36
here and at 56 on amd64. **Code that wrote 56 into a pointer calculation reads the wrong bytes on
386**, and compiles without a word on both. Code that wrote `unsafe.Offsetof(e.Status)` is right on
both, because the compiler answers per platform: the rule inside the rule is that an offset or a
size is always asked for, never typed in.

## The review burden

A reader of ordinary Go can check a function by reading it. A reader of `unsafe` code has to check
it against a list of six patterns and their conditions, against the doc comments of whatever memory
it borrows, and against every caller. `zc.String`'s safety depends on what the caller does with its
bytes for as long as the string lives. **The `paths` bug in section 04 has no wrong line in it**:
`zc.String` is correct, `sc.Bytes()` is correct, and the defect is that one was handed to the other.
That makes every call site of an unsafe function a thing a reviewer has to reason about, forever.

## Bugs that do not show

| bug in this lesson | what it did when run | what found it |
|---|---|---|
| a `uintptr` stored, then turned back into a pointer | printed the right answer | `go vet` |
| eight bytes read where a record had one | printed a wrong number, no error | checkptr, `-race` |
| a zero-copy string used as a map key over a reused buffer | printed plausible totals | nothing |

**None of them crashed in an ordinary build.** A program with a type error does not compile; a
program with an index error panics and names the index. These print, and the first symptom is a
report that is wrong in a way nobody can trace back to its cause.

## Where unsafe is the right tool

None of that makes the package a mistake. The standard library uses it where the alternative is
worse, behind an interface that is safe to call:

```
ana@vm:~/unsafe$ go doc -src strings.Builder.String
package strings // import "strings"

// String returns the accumulated string.
func (b *Builder) String() string {
	return unsafe.String(unsafe.SliceData(b.buf), len(b.buf))
}
ana@vm:~/unsafe$ go list -f '{{join .Imports " "}}' std | grep -cw unsafe; go list std | wc -l
101
383
```

**`strings.Builder` is the zero-copy conversion of section 04, made safe by its design.** The
builder owns its buffer, never lets anybody else write to it, and only appends, so the bytes a
returned string uses are never changed afterwards. The promise `zc.String` asks every caller to keep
is kept here by the type itself. The same goes for the runtime, which manages memory and cannot be
written without it, for `reflect`, lesson 21's subject, and for `sync/atomic` and `syscall`, which
talk to hardware and to the kernel in addresses.

## A rule for your own code

1. **Measure first.** A profile from lesson 12, or a benchmark like section 04's, has to show the
   allocation or the copy costing something that matters. Then look for the safe version, which
   is often already there: `m[string(b)]` for a lookup, `strings.Builder` for building,
   `encoding/binary` for reading fixed-size fields, and a reordered struct for padding.
2. **Isolate it in one small package**, like `zc`, with the promise written in the doc comment of
   every exported function. The rest of the program then imports a name, and `grep -rl '"unsafe"'`
   finds every place that needs the stricter review.
3. **Test it with checkptr on.** Run `go test -race` in CI, which turns checkptr on as well, and
   `go vet ./...` as a step of its own, since `go test` skips `unsafeptr`. Neither proves the code
   right, as the `paths` program showed; between them they catch the two kinds of mistake that
   tools can see.
4. **Pin the Go version you build with, and re-run all of it on each upgrade**, because the one
   guarantee that covers the rest of the program does not cover this package.
