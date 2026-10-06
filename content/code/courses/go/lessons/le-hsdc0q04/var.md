---
title: var, in all its forms
version: 1
---

Go is statically typed, and people coming from Python or JavaScript often take that to mean
you have to write the type of every variable. You do not. **Static typing means that every
variable has exactly one type, fixed when the program is compiled and never changed afterwards.**
Whether you write that type or let the compiler work it out from the value is up to you, and
`var` lets you do either.

Here is every form `var` takes, in one program in `~/vars`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n"
    },
    {
      "code": "\nvar greeting = \"Hello\"\n",
      "note": "**A variable declared outside every function belongs to the package**, and every function in the package can use it. `var`, a name and a value: the type is left out, so the compiler takes it from `\"Hello\"`, which is a string."
    },
    {
      "code": "\nvar (\n\thost    string = \"localhost\"\n\tport    int    = 8080\n\tverbose bool\n)\n",
      "note": "Several declarations can share one `var` and a pair of parentheses. It changes nothing about them; it says they belong together, the way a program's settings do. The columns are `gofmt`'s work."
    },
    {
      "code": "\nfunc main() {\n\tvar count int\n",
      "note": "A type and no value. **The variable still has a value: it starts at its type's zero**, `0` for an `int`, which the output's second line shows. What each type's zero is belongs to lesson 6."
    },
    {
      "code": "\tvar name string = \"Ana\"\n",
      "note": "Type and value together. Here the type says nothing the value did not already say, so most Go code would leave it out."
    },
    {
      "code": "\tvar ratio = 0.5\n",
      "note": "Value and no type. A number with a decimal point gives `float64`, which `%T` confirms below."
    },
    {
      "code": "\tvar x, y int = 1, 2\n\tvar a, b = 3, \"four\"\n",
      "note": "Several names in one line, given values in the same order. With a type, they all share it; without one, each name takes the type of its own value, so `a` and `b` end up different."
    },
    {
      "code": "\n\tfmt.Println(greeting, host, port, verbose)\n\tfmt.Println(count, name, ratio, x, y, a, b)\n\tfmt.Printf(\"%T %T %T %T\\n\", count, ratio, a, b)\n}\n",
      "note": "`%T` in a `Printf` format prints the **type** of its argument instead of its value, which is the quickest way to ask the compiler what it decided."
    }
  ],
  "output": "Hello localhost 8080 false\n0 Ana 0.5 1 2 3 four\nint float64 int string\n"
}
```

The run shows what each form produced:

```
ana@vm:~/vars$ go run .
Hello localhost 8080 false
0 Ana 0.5 1 2 3 four
int float64 int string
```

So a declaration has three slots, the name, the type and the value, and **only the name is
compulsory, as long as one of the other two is there**. Leave out the type and the value decides
it: `0.5` made `ratio` a `float64`, and `3` made `a` an `int`. Leave out the value and the
variable starts at the zero of its type: `count` printed `0` and `verbose` printed `false`,
although nobody gave them anything.

Whichever form you choose, the type is now permanent. `ratio` is a `float64` for the rest of the
program, and putting a value of another type into it is a compile error that lesson 10 shows
in full.

## Where var is the right form

Section 02 introduces a shorter form, and most variables inside a function use it. `var` keeps
three jobs that the short form cannot do:

1. **At package level it is the only form.** `greeting`, `host`, `port` and `verbose` live
   outside `main`, and section 02 shows the compiler refusing the short form there.
2. **When the zero value is the starting value you want**, `var count int` says so plainly. A
   running total that starts at nothing reads better as that than as `count := 0`.
3. **When the type you need is not the one the value would give.** `var ratio float64 = 1` is a
   `float64` holding 1; without the type, `1` would make it an `int`, as section 02's run shows.

The parenthesised group is a matter of reading rather than of meaning. A block of related
package-level settings, like the three above, reads as one thing; three separate `var` lines
read as three.
