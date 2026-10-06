---
title: Type parameters, and the library built on them
version: 1
---

The usual first guess about a generic function is that it is a function taking `any` under a new
name: it accepts every type and sorts things out inside. **It is the reverse.** A generic function is
written once with a **type parameter**, a name standing for a type the caller chooses, and the
compiler checks every call against the types that parameter allows. Nothing is sorted out at run
time, because nothing is left to sort out. Here is `Sum` from section 02, written once, in
`~/generics-sum`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc Sum[T int | float64](xs []T) T {\n",
      "note": "**The square brackets after the name declare a type parameter.** `T` is its name and `int | float64` is the list of types it may stand for. The ordinary parameters then use `T` like any type: a slice of `T` comes in and a `T` goes out."
    },
    {
      "code": "\tvar total T\n",
      "note": "A variable of type `T`. It starts at the zero value of whatever `T` turns out to be, `0` or `0.0`, as lesson 6 promised every variable does."
    },
    {
      "code": "\tfor _, x := range xs {\n\t\ttotal += x\n\t}\n\treturn total\n}\n",
      "note": "**`+=` is allowed because every type in the list has a `+`.** The compiler checked this body once, against the whole list, and the body is the loop of section 02, unchanged."
    },
    {
      "code": "\nfunc main() {\n\tints := Sum([]int{3, 4, 5})\n\tfloats := Sum([]float64{1.5, 2.25})\n\tfmt.Printf(\"%v %T\\n\", ints, ints)\n\tfmt.Printf(\"%v %T\\n\", floats, floats)\n}\n",
      "note": "The calls name no type. The compiler reads `T` off the argument, `int` from a `[]int`, and the result comes back as that same type, which `%T` prints."
    }
  ],
  "output": "12 int\n3.75 float64"
}
```

Compare the output with section 02's. `SumAny` returned a `float64` whatever went in; `Sum` returned
an `int` for the `int`s, because its result is declared as `T`. **The type the caller had is the type
the caller gets back**, with no conversion at either end.

The wrong call that `SumAny` turned into a panic is now refused before the program exists. The same
`Sum`, in `~/generics-sumbad`, called with a slice of `int64` and a slice of `string`:

```go
func main() {
	var stock int64 = 7
	fmt.Println(Sum([]int64{3, stock}))
	fmt.Println(Sum([]string{"a", "b"}))
}
```

```
ana@vm:~/generics-sumbad$ go run .; echo $?
# example.com/generics-sumbad
./main.go:15:17: int64 does not satisfy int | float64 (int64 missing in int | float64)
./main.go:16:17: string does not satisfy int | float64 (string missing in int | float64)
1
```

The message names the type that was offered, the list it was checked against and what is missing
from that list. Adding `int64` to the list would make the first call legal. Adding `string` would make
the second legal too, and `Sum` would then join text, because that is what `+` does to strings.
Whether that counts as a sum is the author's decision, and the list is where it is written down.
The list after the type parameter is called its **constraint**, and lesson 31 is about writing them, including the one this list lacks, which is why `int | float64` refuses a type
like lesson 10's `Celsius`.

So the fourth row of the table in section 02 reads: written once, a wrong type caught by the compiler,
and the caller pays nothing. That is the whole case for type parameters, and it is a narrow one. They
are for code whose **logic is the same for every type and only the type differs**.

## The standard library is written this way

The clearest sign of how ordinary generics are in Go is the standard library, where whole packages
are made of them. `slices` holds the operations every program does on slices, each written once for
every element type:

```
ana@vm:~/generics-std$ go doc slices.Sort
package slices // import "slices"

func Sort[S ~[]E, E cmp.Ordered](x S)
    Sort sorts a slice of any ordered type in ascending order. When sorting
    floating-point numbers, NaNs are ordered before other values.

```

That signature is the function `sort.Ints` now calls. Its brackets declare two type parameters, `S`
for the slice and `E` for its elements, and `cmp.Ordered` is a constraint the `cmp` package defines
for every type that `<` works on. Lesson 31 reads that line piece by piece. What matters here is the
consequence: **one `Sort` sorts `int`s, `string`s and every other ordered type**, where `sort` needed a
copy for each.

The same goes for searching, comparing and taking the largest element, and `maps` does the same job
for maps. In `~/generics-std`:

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	ages := []int{41, 7, 23}
	names := []string{"caio", "ana", "bia"}

	slices.Sort(ages)
	slices.Sort(names)
	fmt.Println(ages, names)

	fmt.Println(slices.Index(names, "bia"), slices.Contains(ages, 23))
	fmt.Println(slices.Max(ages), slices.Max(names))

	stock := map[string]int{"pear": 4, "fig": 0, "plum": 9}
	fmt.Println(slices.Sorted(maps.Keys(stock)))
}
```

```
ana@vm:~/generics-std$ go run .
[7 23 41] [ana bia caio]
1 true
41 caio
[fig pear plum]
```

Every call above is to a generic function, and not one of them mentions a type. `slices.Index`
returned `1` for `"bia"` in the sorted names; `slices.Max` found the largest `int` and the last
`string` in alphabetical order; `slices.Sorted(maps.Keys(stock))` is the line lesson 14 used to print
a map's keys in order. **You have been calling generic functions since `slices.Clone` in
lesson 12, and nothing about the calls said so.** That is the point of inference: the caller writes
ordinary Go, and the brackets are the library author's business.

The whole `slices` package fits on one screen of `go doc`:

```
ana@vm:~/generics-std$ go doc slices | wc -l
44
```

Forty-four lines, and below the four at the top every one is a function written once for every element
type. The `sort` list in section 02 needed nine lines for three operations on three types.
