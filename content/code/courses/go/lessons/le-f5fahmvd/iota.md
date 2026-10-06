---
title: Constants in a block, and iota
version: 1
---

Programmers arriving from Java, C# or TypeScript look for an `enum` keyword. **Go has none, and
does not need one: a set of named values is a `const` block, a type for them, and `iota`.** This
section takes the three apart, starting with what a constant may hold at all.

## What can be a constant

Lesson 5 declared constants one at a time and showed that an untyped one is a number with no
size. The other half of that rule is that a constant can only be a value the compiler works out
before the program runs: a number, a string or a boolean. A slice is built at run time, so it
cannot be one, and neither can `iota` be used anywhere except inside a constant declaration:

```go
package main

import "fmt"

const primes = []int{2, 3, 5}

func main() {
	n := iota
	fmt.Println(primes, n)
}
```

```
ana@vm:~/zero-const$ go build
# example.com/const
./main.go:5:16: []int{…} (value of type []int) is not constant
./main.go:8:7: cannot use iota outside constant declaration
```

**A value that only exists once the program is running belongs in a `var`.** A table of primes
that nothing should change is a package-level `var` in Go, and keeping it unchanged is a matter of
not writing to it.

## A Weekday, a size and a status

The program below declares three sets of constants and prints what they turned into. Read the
notes beside each block, then the output under it.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command days numbers a set of constants with iota.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n",
      "note": "The package `time` is here only for its own `Weekday`, printed at the end to compare with this one."
    },
    {
      "code": "\ntype Weekday int\n",
      "note": "**A new type whose values are `int`s.** Declaring types is lesson 10's subject; here it gives the set of constants a type of its own, which the `%T` in `main` prints."
    },
    {
      "code": "\nconst (\n\tSunday Weekday = iota\n\tMonday\n\tTuesday\n\tWednesday\n\tThursday\n\tFriday\n\tSaturday\n)\n",
      "note": "**`iota` is the line's position in its `const` block, counting from 0.** Only the first line is written out. Each line after it that has a name and nothing else repeats the line above, type and expression both, so `Monday` is `Weekday = iota` on line 1, which is 1, and `Saturday` is 6."
    },
    {
      "code": "\nconst (\n\t_   = iota\n\tKiB = 1 << (10 * iota)\n\tMiB\n\tGiB\n\tTiB\n)\n",
      "note": "**A new block starts `iota` at 0 again, and `_` spends a line without naming it.** Line 0 is thrown away, so `KiB` is on line 1 and is `1 << 10`: 1 shifted left ten bits, which is 2 to the 10th, 1024. The repeated expression does the rest, so `MiB` is `1 << 20` and `TiB` is `1 << 40`."
    },
    {
      "code": "\ntype Status int\n\nconst (\n\tUnknown Status = iota\n\tActive\n\tSuspended\n)\n\ntype account struct {\n\tname   string\n\tstatus Status\n}\n",
      "note": "**Line 0 is what a forgotten field holds, so give it a name that says so.** An `account` built without a `status` gets the zero `Status`, which is `Unknown` rather than `Active`."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(Sunday, Monday, Saturday)\n\tfmt.Printf(\"%T\\n\", Monday)\n\n\tvar day Weekday\n\tfmt.Println(day == Sunday)\n\n\tfmt.Println(KiB, MiB, GiB, TiB)\n\n\ta := account{name: \"ana\"}\n\tfmt.Println(a.status == Unknown)\n\n\tfmt.Printf(\"%v %d\\n\", time.Saturday, time.Saturday)\n}\n",
      "note": "Six lines of output, one per `Println` or `Printf`. The last prints the standard library's `Saturday` twice: with `%v`, its default form, and with `%d`, as a whole number."
    }
  ],
  "output": "0 1 6\nmain.Weekday\ntrue\n1024 1048576 1073741824 1099511627776\ntrue\nSaturday 6\n"
}
```

Three things in that output are worth stopping on.

**`Println(Sunday, Monday, Saturday)` printed `0 1 6`, not the names.** A constant's name is for
the reader of the source; the program holds only the number. The standard library's
`time.Saturday` printed `Saturday` because its type has a method that turns the number into a
word, and methods are lesson 25.

**`day == Sunday` was `true` for a `Weekday` nobody set.** That is section 02's rule meeting this
one: the zero value of a `Weekday` is 0, and 0 is Sunday. A record with a forgotten day would
quietly say Sunday. `Status` avoids that by spending line 0 on `Unknown`, so the forgotten field
says what happened, and `a.status == Unknown` came out `true`.

**`KiB` to `TiB` are four lines of arithmetic written once.** The pattern is common for sizes and
for bit flags. It works because a repeated line repeats the expression with `iota` still in it,
and each line evaluates it at its own position.

The standard library does exactly this for its own days of the week, and `go doc` shows the block
unedited:

```
ana@vm:~/zero-iota$ go doc time.Sunday
package time // import "time"

const (
	Sunday Weekday = iota
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
)
```

**Constants numbered by `iota` are numbered by their position**, so inserting a line in the middle
of a block renumbers every constant after it. That is harmless while the numbers stay inside your
program, and a bug as soon as one is written to a file or a database and read back by a newer
build. A set whose numbers leave the program is safer written out by hand: `Active Status = 1`,
`Suspended Status = 2`.
