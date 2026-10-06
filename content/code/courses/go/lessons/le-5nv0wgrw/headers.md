---
title: Values that carry a pointer
version: 1
---

Section 02 had no exceptions, and some Go seems to contradict it at once. Lesson 11's `setFirst`
changed the caller's slice. A function that adds a key to a map changes the caller's map. From
those two, a lot of people conclude that **Go passes slices and maps by reference**, and you will
read that sentence in blog posts and answers. It is the wrong picture, and it fails in one specific
place that this section shows. What happens instead is that the value of a slice or a map is small
and holds a pointer, and copying the value copies the pointer.

## How big each value is

`unsafe.Sizeof` measured an array and a slice in lesson 11. Here it measures one value of each
type whose value holds a pointer:

```go
package main

import (
	"fmt"
	"unsafe"
)

type Player struct {
	Name  string
	Score int
}

func main() {
	var (
		s   []int
		m   map[string]int
		str string
		f   func()
		v   any
		c   chan int
	)
	fmt.Println("slice    ", unsafe.Sizeof(s))
	fmt.Println("map      ", unsafe.Sizeof(m))
	fmt.Println("string   ", unsafe.Sizeof(str))
	fmt.Println("func     ", unsafe.Sizeof(f))
	fmt.Println("interface", unsafe.Sizeof(v))
	fmt.Println("chan     ", unsafe.Sizeof(c))

	ana := Player{Name: "Ana", Score: 10}
	v = ana
	ana.Score = 99
	fmt.Println(v, ana)
}
```

```
ana@vm:~/byvalue-sizes$ go run .
slice     24
map       8
string    16
func      8
interface 16
chan      8
{Ana 10} {Ana 99}
```

**None of these sizes depends on what the value holds.** A map with a million keys is 8 bytes as a
value, because those 8 bytes are a pointer to the table where the keys live. The runtime's own
source says so: `makemap` in `/usr/local/go/src/runtime/map.go` returns a `*maps.Map`, and that
pointer is what a variable of a map type holds. A slice is the three words of lesson 11 and a
string the pointer and length of lesson 9. A function value is a pointer too, and `any`, the type
of `v` above, is two words: one says what type is stored and the other points at the stored value.

The last line of output is about that second word. `v = ana` stored a `Player` in `v`, and
`ana.Score = 99` afterwards did not reach it: **putting a struct into an interface copies the
struct**, just as passing it does. Interfaces are lessons 27 and 28; this is the one fact about
them that belongs here.

## The test that separates the two pictures

Under pass by reference, a parameter would be another name for the caller's variable, and
assigning to it would change the caller's variable. A map passed by value behaves differently in
exactly that case, and nowhere else:

```go
package main

import "fmt"

func addKey(m map[string]int) {
	m["bia"] = 2
}

func replace(m map[string]int) {
	m = map[string]int{"carla": 3}
	fmt.Println("inside: ", m)
}

func main() {
	ages := map[string]int{"ana": 1}

	addKey(ages)
	fmt.Println("addKey: ", ages)

	replace(ages)
	fmt.Println("replace:", ages)
}
```

```
ana@vm:~/byvalue-map$ go run .
addKey:  map[ana:1 bia:2]
inside:  map[carla:3]
replace: map[ana:1 bia:2]
```

`addKey` wrote through its copy of the pointer, into the one table both variables point at, so
`main` sees `bia`. `replace` assigned a new map to `m`, which changed `m` and only `m`: inside it
holds `carla`, and back in `main`, `ages` is the map it was before the call.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 345\" role=\"img\" aria-label=\"Two calls, each passing the map ages from main. In addKey(ages), main&#x27;s variable ages and addKey&#x27;s parameter m are two copies of one pointer, and both arrows reach the same table, which now holds ana: 1 and bia: 2. In replace(ages), the assignment m = map[string]int{...} points m at a new table holding carla: 3, while ages still points at the table it had.\"><defs><marker id=\"pv-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pv-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">addKey(ages)</text><rect x=\"40\" y=\"44\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ages</text><text x=\"144\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main&#x27;s variable</text><rect x=\"40\" y=\"104\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">m</text><text x=\"144\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the parameter</text><rect x=\"330\" y=\"66\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana: 1</text><text x=\"405\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bia: 2</text><text x=\"405\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the map&#x27;s table</text><path d=\"M152 60 L250 60 L250 82 L326 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-phosphor)\"></path><path d=\"M152 120 L250 120 L250 104 L326 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-phosphor)\"></path><text x=\"520\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two copies of one pointer,</text><text x=\"520\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and both reach the same</text><text x=\"520\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">table: the new key shows</text><path d=\"M20 168 L700 168\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">replace(ages)</text><rect x=\"40\" y=\"212\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ages</text><text x=\"144\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main&#x27;s variable</text><rect x=\"40\" y=\"272\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">m</text><text x=\"144\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the parameter</text><rect x=\"330\" y=\"222\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana: 1</text><text x=\"405\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bia: 2</text><text x=\"405\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the map&#x27;s table</text><rect x=\"330\" y=\"304\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">carla: 3</text><text x=\"405\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a new table</text><path d=\"M152 228 L326 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-phosphor)\"></path><path d=\"M152 288 L250 288 L250 319 L326 319\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-amber)\"></path><text x=\"520\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the assignment changed m,</text><text x=\"520\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the copy; ages still points</text><text x=\"520\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">at the table it had</text></svg>", "caption": "Passing a map copies one pointer. What the callee does through it reaches the caller's table; what it assigns to its parameter does not."}
```

## Where the wrong picture costs something

Nobody writes `replace` on purpose. What people do write is a function that makes a map when it
was given none, believing the caller will get it:

```go
package main

import "fmt"

func load(m map[string]int) {
	if m == nil {
		m = make(map[string]int)
	}
	m["ana"] = 1
}

func main() {
	var ages map[string]int
	load(ages)
	fmt.Println(ages, len(ages), ages == nil)
	ages["bia"] = 2
}
```

```
ana@vm:~/byvalue-nil$ go run .
map[] 0 true
panic: assignment to entry in nil map

goroutine 1 [running]:
main.main()
	/home/ana/byvalue-nil/main.go:16 +0x136
exit status 2
```

`load` made a map, put `ana` in it and returned, and the map went with its variable. `ages` in
`main` is still nil, and line 16 writes to it, which is the panic lesson 14 showed for a nil map.
**A function can change what a pointer leads to, and cannot change which pointer the caller
holds.** The fix is section 02's: return the map and let the caller store it.

```go
package main

import "fmt"

func load(m map[string]int) map[string]int {
	if m == nil {
		m = make(map[string]int)
	}
	m["ana"] = 1
	return m
}

func main() {
	var ages map[string]int
	ages = load(ages)
	ages["bia"] = 2
	fmt.Println(ages, len(ages), ages == nil)
}
```

```
ana@vm:~/byvalue-fix$ go run .
map[ana:1 bia:2] 2 false
```

## What a copy shares, type by type

Each of these values is copied whole on every call and assignment, like a struct. What differs is
what the copy can still reach:

| type | the value that is copied | what the copy shares with the original |
|---|---|---|
| slice | 24 bytes: pointer, length, capacity | the array: elements yes, length no (lesson 11) |
| map | 8 bytes: a pointer | the whole table: keys added or deleted through either copy |
| string | 16 bytes: pointer and length | the bytes, which nobody can change (lesson 9) |
| func | 8 bytes: a pointer | the variables a closure captured (lesson 21) |
| interface | 16 bytes: a type and a pointer | the value stored in it, which was copied in when it was stored |
| chan | 8 bytes: a pointer | the channel itself, which is the `go-concurrency` course's subject |

So "by value or by reference" is the wrong question to ask of a Go type. **Everything is passed by
value, and the useful question is what the value points at.** For a struct or an array the answer
is nothing, unless it contains a value from this table or a pointer, which is lesson 23's subject.
