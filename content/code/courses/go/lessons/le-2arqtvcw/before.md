---
title: One job, several types, and three ways around it
version: 1
---

Sooner or later a program needs the same function for two types. Adding up a slice is the smallest
case there is: one loop, one variable, one `+`. Written for `int` and then for `float64`, in
`~/generics`, it looks like this:

```go
package main

import "fmt"

func SumInts(xs []int) int {
	var total int
	for _, x := range xs {
		total += x
	}
	return total
}

func SumFloats(xs []float64) float64 {
	var total float64
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	fmt.Println(SumInts([]int{3, 4, 5}))
	fmt.Println(SumFloats([]float64{1.5, 2.25}))
}
```

```
ana@vm:~/generics$ go run .
12
3.75
ana@vm:~/generics$ diff <(sed -n 5,11p main.go) <(sed -n 13,19p main.go)
1,2c1,2
< func SumInts(xs []int) int {
< 	var total int
---
> func SumFloats(xs []float64) float64 {
> 	var total float64
```

`diff` compared the seven lines of one function with the seven lines of the other. **They differ in
two lines, and in those two lines only the types differ.** The loop, the `+=` and the `return` are
the same text. A third numeric type means a third copy, and a bug found in one copy is a bug you
have to remember to fix in all of them.

Go 1.0 shipped in 2012 with no way to write that function once and still have the compiler check
every call. Type parameters, the feature this lesson and lesson 31 teach, arrived in Go 1.18 in March
2022; lesson 2 put them on the timeline. For the decade in between, Go programmers worked around the gap in three ways, and the standard library's
`sort` package still carries all three. Each one is worth knowing, because you will read code
written each way, and because the third is still the right answer to a different question.

## Copy it for each type

The first way is the one above: write it again. `sort` did exactly that for the three element types
people sort most:

```
ana@vm:~/generics$ go doc sort | grep -E "Ints|Float64s|Strings"
func Float64s(x []float64)
func Float64sAreSorted(x []float64) bool
func Ints(x []int)
func IntsAreSorted(x []int) bool
func SearchFloat64s(a []float64, x float64) int
func SearchInts(a []int, x int) int
func SearchStrings(a []string, x string) int
func Strings(x []string)
func StringsAreSorted(x []string) bool
```

**Nine functions, which are really three functions written out for three types.** Somebody sorting a
`[]int64` or a `[]uint8` found nothing in that list. The documentation of the first one shows what
happened to the copies once the language could do better:

```
ana@vm:~/generics$ go doc sort.Ints
package sort // import "sort"

func Ints(x []int)
    Ints sorts a slice of ints in increasing order.

    Note: as of Go 1.22, this function simply calls slices.Sort.

```

`slices.Sort` is one generic function, and section 03 uses it. The copies stay because of the
compatibility promise of lesson 2: code that calls `sort.Ints` must keep compiling.

## Take `any` and look inside

The second way is to accept `any`, which lesson 28 showed holds a value of every type, and to find
out at run time what arrived. A type switch, lesson 29's subject, does the finding out:

```go
package main

import "fmt"

func SumAny(xs []any) float64 {
	var total float64
	for _, x := range xs {
		switch v := x.(type) {
		case int:
			total += float64(v)
		case float64:
			total += v
		default:
			panic(fmt.Sprintf("SumAny: cannot add %T", v))
		}
	}
	return total
}

func main() {
	fmt.Println(SumAny([]any{3, 4, 5}))
	fmt.Println(SumAny([]any{1.5, 2.25}))

	var stock int64 = 7
	fmt.Println(SumAny([]any{3, stock}))
}
```

```
ana@vm:~/generics-any$ go vet && go run . 2>&1 | head -3
12
3.75
panic: SumAny: cannot add int64
```

One function now handles both slices, and the third call is wrong: an `int64` is neither of the two
cases. `go vet` printed nothing and the compiler built the program, because `[]any{3, stock}` is a
perfectly good `[]any`. **The mistake was found by running the program, on the line that happened to
call it with the wrong type.** In a test, that is a failure you read. In a service, it is a panic on
somebody's request; lesson 36 is about what a panic does to a program.

That is the main cost, and there are two smaller ones. A caller holding a `[]int` cannot pass it, for
the reason lesson 21 gave about `fmt.Println`: a `[]int` is not a `[]any`, and Go does not convert
one into the other. The caller has to copy every element into a new slice first, which is what
`~/generics-anyslice` does:

```go
func main() {
	ages := []int{41, 7, 23}
	fmt.Println(SumAny(ages))

	boxed := make([]any, len(ages))
	for i, a := range ages {
		boxed[i] = a
	}
	total := SumAny(boxed)
	fmt.Printf("%v %T\n", total, total)
}
```

```
ana@vm:~/generics-anyslice$ go run .
# example.com/generics-anyslice
./main.go:22:21: cannot use ages (variable of type []int) as []any value in argument to SumAny
ana@vm:~/generics-anyslice$ go run .
71 float64
```

The second run is the same file with the refused line deleted. The sum is right and its type is
not: three `int`s went in and a `float64` came out, because `SumAny` has to declare one result type
for every input. The caller who wanted an `int` converts it back.

`sort` has this way too. `sort.Slice` takes the slice as an `any`:

```
ana@vm:~/generics-sort$ go doc sort.Slice | head -4
package sort // import "sort"

func Slice(x any, less func(i, j int) bool)
    Slice sorts the slice x given the provided less function. It panics if x is
```

The documentation says it panics if `x` is not a slice, and it means at run time. A program that
hands it the number 42 passes `go vet`, compiles, and stops:

```go
package main

import "sort"

func main() {
	sort.Slice(42, func(i, j int) bool { return false })
}
```

```
ana@vm:~/generics-sort$ go vet && go run .
panic: reflect: call of Swapper on int Value

goroutine 1 [running]:
internal/reflectlite.Swapper({0x51d4c0?, 0x487f30?})
	/usr/local/go/src/internal/reflectlite/swapper.go:20 +0x5d6
sort.Slice({0x51d4c0?, 0x487f30?}, 0x526a68)
	/usr/local/go/src/sort/slice.go:26 +0x85
main.main()
	/home/ana/generics-sort/main.go:6 +0x28
exit status 2
```

Nobody passes 42 on purpose. They pass a pointer to a slice, or a struct that holds one, and the
compiler cannot tell them, because `any` accepts both.

## Say what the type can do, with an interface

The third way asks the caller's type for methods. `sort.Sort(data Interface)` sorts anything whose
type has three: `Len`, `Less` and `Swap`. It is checked at compile time, and it works for types
`sort` has never heard of, which is what interfaces are for (lesson 27). The price is writing those
three methods for every slice type you want sorted. The `type IntSlice []int` in the package's own
list exists to carry them for `[]int`.

An interface is the right tool when what varies is **behaviour**: anything that can `Write`, anything
that can describe itself with `String`. It does not help `Sum`. **An interface lists methods, and `+`
is an operator, not a method**, so no ordinary interface can say "a type you can add".

| | written | a wrong type is caught | what the caller pays |
|---|---|---|---|
| a copy per type | once per type | by the compiler | nothing, if a copy exists for their type |
| `any` and a type switch | once | at run time, by a panic | a copy into `[]any`, and a result in one fixed type |
| an interface | once, plus methods per type | by the compiler | three methods on their type |

Each row gives something up. Section 03 is the fourth row, which gives up none of the three.
