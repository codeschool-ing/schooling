---
title: Optional fields, absent fields and zero
version: 1
---

JSON has three ways to say nothing about a field: leave the key out, give it `null`, or give it a
zero, `0`, `""` or `false`. A Go field always holds a value, and its zero value is a perfectly good
one. **The work of this section is keeping "the sender said zero" apart from "the sender said
nothing", in both directions**, because a stock level of zero and a stock level nobody mentioned
lead to different decisions. Saved as `optional.go`:

```go
// Command optional tells "absent" from "zero" in both directions.
package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type Patch struct {
	Stock *int `json:"stock"`
}

type Product struct {
	SKU       string    `json:"sku"`
	Stock     int       `json:"stock,omitempty"`
	Restocked time.Time `json:"restocked,omitempty"`
	Retired   time.Time `json:"retired,omitzero"`
}

func main() {
	for _, body := range []string{`{"stock": 0}`, `{}`, `{"stock": null}`} {
		var p Patch
		json.Unmarshal([]byte(body), &p)
		if p.Stock == nil {
			fmt.Printf("%-16s stock not given\n", body)
		} else {
			fmt.Printf("%-16s stock set to %d\n", body, *p.Stock)
		}
	}

	b, _ := json.Marshal(Product{SKU: "KB-01"})
	fmt.Println(string(b))

	var loose map[string]any
	json.Unmarshal([]byte(`{"qty": 2, "sku": "KB-01"}`), &loose)
	fmt.Printf("qty is %v of type %T\n", loose["qty"], loose["qty"])
}
```

```
ana@vm:~/jsondemo$ go run optional.go
{"stock": 0}     stock set to 0
{}               stock not given
{"stock": null}  stock not given
{"sku":"KB-01","restocked":"0001-01-01T00:00:00Z"}
qty is 2 of type float64
```

## Reading: a pointer tells absent from zero

`Patch.Stock` is a `*int`. **A key that is absent leaves the pointer `nil`; a key with a value,
even `0`, makes it point at that value.** So `{"stock": 0}` set the stock to 0 and `{}` left it
alone, which is the difference an update request needs: "set it to zero" against "do not touch
it". `null` also left the pointer `nil`, so a pointer cannot tell an absent key from an explicit
`null`. When that third case matters, the field has to be read as `json.RawMessage` and inspected,
which few APIs need.

## Writing: `omitempty` against `omitzero`

`Product` was written with only its `SKU` set. `stock` vanished, because `omitempty` drops a zero
`int`, and that is a trap of its own: **a product that really has zero in stock would also be
written without a `stock` key**, and the reader cannot tell it from one whose stock is unknown. Use
`omitempty` only where zero and absent mean the same thing.

`restocked` was written as `"0001-01-01T00:00:00Z"` although it was never set. **`omitempty` judges
emptiness by kind**: zero numbers, empty strings, slices and maps, nil pointers. A struct such as
`time.Time` is never empty by that rule. `omitzero`, since Go 1.24, judges by the zero value of
whatever the type is, or by the type's own `IsZero` method when it has one, so `retired` was left
out as intended.

## Reading without a type

Decoding into `map[string]any` is the escape hatch for JSON whose shape you do not know. **Every
number comes back as `float64`**, here `qty is 2 of type float64`, because JSON does not say which
numbers are integers. That is harmless for a quantity of two and wrong for an identifier above
2^53, which a `float64` cannot hold exactly; `Decoder.UseNumber` keeps such numbers as text. A
struct is the better answer whenever the shape is known.

## And a second version beside it

Go 1.27 also ships `encoding/json/v2`, a newer design of the same package, and on this toolchain
`encoding/json` is built on top of it while keeping its old behaviour. The two differ in places
this lesson has just relied on, and one program shows two of them, saved as `versions.go`:

```go
// Command versions runs the same value through encoding/json and encoding/json/v2.
package main

import (
	jsonv1 "encoding/json"
	jsonv2 "encoding/json/v2"
	"fmt"
)

type order struct {
	ID    int      `json:"id"`
	Items []string `json:"items"`
}

func main() {
	a, _ := jsonv1.Marshal(order{ID: 1})
	b, _ := jsonv2.Marshal(order{ID: 1})
	fmt.Println("v1:", string(a))
	fmt.Println("v2:", string(b))

	var o1, o2 order
	e1 := jsonv1.Unmarshal([]byte(`{"ID": 7}`), &o1)
	e2 := jsonv2.Unmarshal([]byte(`{"ID": 7}`), &o2)
	fmt.Println("v1:", o1.ID, e1)
	fmt.Println("v2:", o2.ID, e2)
}
```

```
ana@vm:~/jsondemo$ go run versions.go
v1: {"id":1,"items":null}
v2: {"id":1,"items":[]}
v1: 7 <nil>
v2: 0 <nil>
```

**A nil slice is `null` in v1 and `[]` in v2, and v2 matches keys with their case**, so `"ID"` no
longer fills a field tagged `id`. Neither is wrong; they are different defaults. This course uses
`encoding/json`, the package every Go program you will read uses today, and `go doc
encoding/json/v2` describes the rest of the newer one for when you meet it.
