---
title: Pointers, maps and slices
version: 1
---

Lesson 22 showed that a map value and a slice value already carry a pointer, which is why a
function can change a map's keys or a slice's elements without being handed an address. The
pointers of this lesson meet those two types in three places, and each one has a rule that looks
arbitrary until you see what is underneath.

## A function that appends for its caller

Lesson 11's `addFour` appended to its copy of a slice, and the caller's length stayed at 3. A
pointer to the slice fixes that from the other side: the function receives the address of the
caller's slice variable and stores the result of `append` there.

```go
package main

import "fmt"

func addTo(s *[]int, v int) {
	*s = append(*s, v)
}

func main() {
	nums := []int{1, 2, 3}
	addTo(&nums, 4)
	fmt.Println(nums, len(nums))
}
```

```
ana@vm:~/pointers-append$ go run .
[1 2 3 4] 4
```

`*s` is the caller's `nums` itself, so assigning to it changes the caller's length and, when
`append` had to move, the caller's pointer as well. It works, and **the standard library's habit is
the other shape, a function that returns the new slice**: `append` does, and so does
`slices.Insert`, whose signature `go doc slices.Insert` prints as
`func Insert[S ~[]E, E any](s S, i int, v ...E) S`. A returned slice shows the change at the call, as `nums = withFour(nums)` did in
lesson 11, which is the same argument lesson 22 made for structs.

Where `*[]T` does turn up is as the argument of a function that fills in whatever you hand it.
`json.Unmarshal(data, &list)` takes the address of `list` because it has to set the slice, length
and all; its documentation says it returns an error when the value is not a pointer. JSON is
lesson 15.

## A map element has no address

A slice element is a variable you can point at. A map element is not:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	nums := []int{1, 2, 3}
	n := &nums[0]

	ages := map[string]int{"ana": 30}
	a := &ages["ana"]

	players := map[string]Player{"ana": {Name: "Ana", Score: 10}}
	players["ana"].Score = 11

	fmt.Println(*n, *a)
}
```

```
ana@vm:~/pointers-map$ go run .
# example.com/mapaddr
./main.go:15:8: invalid operation: cannot take address of ages["ana"] (map index expression of type int)
./main.go:18:2: cannot assign to struct field players["ana"].Score in map
```

Line 12, `&nums[0]`, compiled; only the two map lines were refused. The reason is in the runtime,
not the grammar. **A map moves its entries when it grows**: `grow`, in
`/usr/local/go/src/internal/runtime/maps/table.go`, allocates a new table, puts every element of the
old one into it, and discards the old one. A pointer to an element would then lead to a table the
map no longer uses, so the compiler does not let you make one. Line 18 is the same rule in a form
that surprises more people: changing one field of a struct stored in a map would need that struct
as a variable, and `players["ana"]` is a value read out of the map, not a variable.

Two ways round it, and both appear in real code:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	players := map[string]Player{"ana": {Name: "Ana", Score: 10}}
	p := players["ana"]
	p.Score++
	players["ana"] = p
	fmt.Println(players["ana"])

	byName := map[string]*Player{"ana": {Name: "Ana", Score: 10}}
	byName["ana"].Score++
	fmt.Println(*byName["ana"])
}
```

```
ana@vm:~/pointers-mapfix$ go run .
{Ana 11}
{Ana 11}
```

The first reads the struct out as a copy, changes the copy and stores it back. The second stores
pointers in the map, so the map moves pointers when it grows and the players stay where they are;
`byName["ana"].Score++` follows the pointer to a struct that is a variable. Inside the literal,
`{Name: "Ana", Score: 10}` is short for `&Player{...}`, because the map's element type already says
it is a pointer.

## A pointer into a slice can be left behind

A slice element does have an address, and that address belongs to one particular array. Lesson 12
showed `append` moving a full slice to a new array. A pointer taken before the move does not move
with it:

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	first := &nums[0]
	*first = 10
	fmt.Println(nums, len(nums), cap(nums))

	nums = append(nums, 4)
	*first = 100
	fmt.Println(nums, *first, first == &nums[0])
}
```

```
ana@vm:~/pointers-stale$ go run .
[10 2 3] 3 3
[10 2 3 4] 100 false
```

Before the append, `first` and `nums[0]` are one `int`, and writing 10 through the pointer shows up
in the slice. The slice is full, length 3 and capacity 3, so `append` copies the three elements to
a new array and adds the 4 there. After that, `*first = 100` writes into the old array, `nums[0]`
still reads 10, and `first == &nums[0]` is `false`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Before the append, nums views an array of three ints, 10, 2 and 3, and first points at its element 0. The array is full, so append copies 10, 2 and 3 into a new array and adds 4 there, and nums now points at the new array. first still points at element 0 of the old array, so *first = 100 writes into the old array, and nums[0] stays 10.\"><defs><marker id=\"ps-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ps-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ps-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">nums = append(nums, 4)</text><text x=\"20\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*first = 100</text><text x=\"260\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the old array</text><rect x=\"260\" y=\"70\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></rect><text x=\"284.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">100</text><rect x=\"308\" y=\"70\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"332.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"356\" y=\"70\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"40\" y=\"120\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">first</text><text x=\"116\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><path d=\"M118 135 L225 135 L225 85 L256 85\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#ps-amber)\"></path><path d=\"M284 102 L284 196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ps-phosphor-dim)\"></path><path d=\"M332 102 L332 196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ps-phosphor-dim)\"></path><path d=\"M380 102 L380 196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ps-phosphor-dim)\"></path><text x=\"418\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copied by append</text><text x=\"246\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a new array</text><rect x=\"260\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"284.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10</text><rect x=\"308\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"332.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"356\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"404\" y=\"200\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"40\" y=\"240\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nums</text><text x=\"116\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><path d=\"M118 255 L284 255 L284 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#ps-phosphor)\"></path><text x=\"480\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nums moved to the new array;</text><text x=\"480\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">first still points at the old one,</text><text x=\"480\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">so 100 lands where nums no longer looks</text></svg>", "caption": "A pointer to a slice element points into one particular array. When append has to move the slice, the pointer stays behind."}
```

Nothing crashed, and nothing will: the old array stays alive for as long as `first` points into it,
so the program goes on writing into memory that no slice shows. **A pointer to a slice element is
only good until the next `append` that might move the slice**, and the safe habit is to keep the
index, `0`, and read `nums[0]` again when you need it.
