---
title: What reflect sees in a value
version: 1
---

Everything the `go` course taught about types is settled before the program runs. The compiler
knows that `x` is an `int`, refuses `x.Path`, and leaves nothing to check later. **Reflection is the
one way back from that: a program asking, while it runs, what type a value has, and then reading or
changing the value through the answer.** `encoding/json` is the example everybody has already used.
It was compiled long before your struct existed, and it still prints your fields by their names.

A common belief is that reflection is how Go writes code for many types at once. That was half true
before generics. Since Go 1.18, a function that works for many types is written with type parameters
and checked by the compiler, as `go` lessons 30 and 31 showed. **Reflection is for the other case:
code that cannot know the type even when it is compiled**, because the type belongs to somebody who
writes it later. Lessons 21 to 24 are the course's escape hatches, and this one takes reflection the
same way as the other three: what it can do, what it costs, and when to leave it alone.

## Two questions: the type, and the value

The package has two entry points. `reflect.TypeOf` answers "what type is this" with a `reflect.Type`,
and `reflect.ValueOf` hands back a `reflect.Value`, which holds the value itself and can be asked
about it. A program that puts eight different values through both, in `~/reflect`,
`typeof/main.go`:

```go
// Command typeof prints what reflect.TypeOf and reflect.ValueOf find in a
// few values of different types.
package main

import (
	"errors"
	"fmt"
	"reflect"
)

// Celsius is a float64 with a name of its own.
type Celsius float64

// PathCount has the shape of one row of tally.Top.
type PathCount struct {
	Path string
	Hits int
}

func main() {
	var err error
	values := []any{
		42,
		"hits",
		Celsius(21.5),
		PathCount{"/login", 2576},
		&PathCount{"/login", 2576},
		[]int{7, 8},
		errors.New("disk full"),
		err,
	}
	for _, x := range values {
		t := reflect.TypeOf(x)
		v := reflect.ValueOf(x)
		fmt.Printf("type %-20v kind %-8v value %v\n", t, v.Kind(), v)
	}

	p := reflect.ValueOf(&PathCount{"/login", 2576})
	s := p.Elem()
	fmt.Println(p.Kind(), "->", s.Kind(), s.Type(), "with", s.NumField(), "fields")
	for f, fv := range s.Fields() {
		fmt.Printf("  %s %v = %v\n", f.Name, f.Type, fv)
	}
}
```

`PathCount` here has the shape of the row `tally.Top` returns in lesson 1, without the tags; section
03 comes back to those. Run once:

```
ana@vm:~/reflect$ go run ./typeof
type int                  kind int      value 42
type string               kind string   value hits
type main.Celsius         kind float64  value 21.5
type main.PathCount       kind struct   value {/login 2576}
type *main.PathCount      kind ptr      value &{/login 2576}
type []int                kind slice    value [7 8]
type *errors.errorString  kind ptr      value disk full
type <nil>                kind invalid  value <invalid reflect.Value>
ptr -> struct main.PathCount with 2 fields
  Path string = /login
  Hits int = 2576
```

**`Type` is the exact type and `Kind` is the family it belongs to.** `Celsius` is a type of its own,
`main.Celsius`, and its kind is `float64`, because underneath it is one. There are 26 kinds and an
`Invalid`, from `Bool` to `UnsafePointer`, and that short list is what reflective code switches on: a
JSON encoder has one way to write any `float64` kind, whatever the type is called. A pointer's kind
prints as `ptr`, and a slice is a slice whatever it holds.

Two lines need a closer look. `errors.New` returned an `error`, yet the type printed is
`*errors.errorString`. **`TypeOf` never sees the static type, only the dynamic one**, because by the
time it runs, the value has already been put into an `any` and the interface type is gone. The last
line is a nil `error`, and there is nothing in it to see: `TypeOf` returns `nil`, and `ValueOf`
returns the zero `Value`, whose kind is `Invalid`. Any method that needs a real value panics on it.

## Following a pointer

The last block of the output goes one step further. `reflect.ValueOf(&PathCount{...})` is a
pointer, and **`Elem` follows it to the struct it points at**, the way `*p` does in ordinary code.
Only then do struct questions make sense: `NumField` says 2, and `Fields` returns an iterator over
each field's description and value, so a plain `for range` walks them by name and type. Skipping
`Elem` is a mistake the compiler cannot see: `go doc reflect.Value.NumField` says it panics if the
kind is not `Struct`, and a pointer's kind is `Pointer`.

## What is underneath: an `any`

`TypeOf` and `ValueOf` take a parameter of type `any`, and that is the whole trick. The go command
shows the signature, and the toolchain's own source shows what the functions do with it:

```
ana@vm:~/reflect$ go doc reflect.TypeOf
package reflect // import "reflect"

func TypeOf(i any) Type
    TypeOf returns the reflection Type that represents the dynamic type of i.
    If i is a nil interface value, TypeOf returns nil.

ana@vm:~/reflect$ sed -n 1367,1369p /usr/local/go/src/reflect/type.go
func TypeOf(i any) Type {
	return toType(abi.TypeOf(i))
}
ana@vm:~/reflect$ sed -n 158,169p /usr/local/go/src/reflect/value.go
func unpackEface(i any) Value {
	e := (*abi.EmptyInterface)(unsafe.Pointer(&i))
	t := e.Type
	if t == nil {
		return Value{}
	}
	f := flag(t.Kind())
	if !t.IsDirectIface() {
		f |= flagIndir
	}
	return Value{t, e.Data, f}
}
```

`go` lesson 28 described an `any` as a value that has forgotten its static type and kept its dynamic
one. In memory **an `any` is two words**: one points at a type descriptor the compiler wrote for
the value's type, and one points at the data. `unpackEface` reads those two words straight
out of the interface, `e.Type` and `e.Data`, and returns `Value{t, e.Data, f}`: the same two words,
plus a `flag` that records the kind and whether the value may be changed. `TypeOf` keeps only the
first word.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"An any holds two words. The type word points at a type descriptor the compiler wrote, naming main.PathCount, kind struct, and the fields Path string and Hits int. The data word points at a copy of x. reflect.TypeOf returns the type word as a reflect.Type. reflect.ValueOf returns a reflect.Value with three fields: typ_, the type word; ptr, the data word; and flag, the kind and access bits.\"><defs><marker id=\"rf-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"rf-phos\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"rf-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">reflect.Type</text><path d=\"M130 118 L130 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-phos)\"></path><text x=\"142\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">TypeOf keeps the type word</text><text x=\"40\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the argument, converted to any</text><rect x=\"40\" y=\"120\" width=\"180\" height=\"76\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40 158 H220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"52\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">type word</text><text x=\"52\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data word</text><path d=\"M220 139 L466 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-wire)\"></path><path d=\"M220 177 L466 229\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-wire)\"></path><text x=\"470\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">type descriptor, written by the compiler</text><rect x=\"470\" y=\"40\" width=\"220\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"486\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">main.PathCount</text><text x=\"486\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kind  struct</text><text x=\"486\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Path  string</text><text x=\"486\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Hits  int</text><text x=\"470\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a copy of x</text><rect x=\"470\" y=\"204\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">{\"/login\" 2576}</text><path d=\"M130 198 L130 256\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-amber)\"></path><text x=\"142\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ValueOf copies both words and adds a flag</text><text x=\"40\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">reflect.Value</text><rect x=\"40\" y=\"282\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M160 282 V318 M280 282 V318\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"100\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">typ_</text><text x=\"220\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ptr</text><text x=\"350\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flag</text><text x=\"100\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the type word</text><text x=\"220\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the data word</text><text x=\"350\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kind and access bits</text></svg>", "caption": "reflect.ValueOf(x) for x := PathCount{\"/login\", 2576}: both functions start from the two words of an any, and reflect.Value adds one word of its own."}
```

**So reflection reads nothing new.** The descriptor was in the binary all along, because the runtime
needs it to make type switches and type assertions work; `reflect` is a public way to read it. That
is also why `ValueOf(x)` holds a copy of `x` and not `x` itself: converting to `any` copies the value,
exactly as passing it to any other function does. Section 04 turns that one fact into the rule for
what reflection may change.
