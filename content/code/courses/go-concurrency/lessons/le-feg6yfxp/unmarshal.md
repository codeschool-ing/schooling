---
title: Unmarshal, from a document to a Go value
version: 1
---

Reading JSON is where the surprises are, because the document comes from somebody else and was not
written against your types. **`encoding/json` is forgiving by default, and each kind of
forgiveness is a decision you should know it made for you.** The program reads one body four ways,
saved as `decode.go`:

```go
// Command decode reads JSON into a struct: what it forgives, and what it refuses.
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type Order struct {
	ID       int    `json:"id"`
	Customer string `json:"customer"`
	Items    []struct {
		SKU string `json:"sku"`
		Qty int    `json:"qty"`
	} `json:"items"`
}

func main() {
	body := `{"id": 1042, "Customer": "ana@example.com",
		"items": [{"sku": "KB-01", "qty": 1}], "coupon": "WELCOME"}`

	var o Order
	err := json.Unmarshal([]byte(body), &o)
	fmt.Printf("%+v %v\n", o, err)

	dec := json.NewDecoder(strings.NewReader(body))
	dec.DisallowUnknownFields()
	var strict Order
	fmt.Println("strict:", dec.Decode(&strict))

	var wrongType Order
	fmt.Println("type:", json.Unmarshal([]byte(`{"id": "1042"}`), &wrongType))

	var broken Order
	fmt.Println("syntax:", json.Unmarshal([]byte(`{"id": 1042,}`), &broken))
}
```

```
ana@vm:~/jsondemo$ go run decode.go
{ID:1042 Customer:ana@example.com Items:[{SKU:KB-01 Qty:1}]} <nil>
strict: json: unknown field "coupon"
type: json: cannot unmarshal string into Go struct field Order.id of type int
syntax: invalid character '}' looking for beginning of object key string
```

## What it forgave

**The key `Customer` filled the field tagged `customer`.** `encoding/json` matches keys to fields
without regard to case, so a sender who capitalises differently still gets through. **The key
`coupon` matched nothing and was dropped without a word.** The `Order` came out complete, and `err`
was `nil`. Both are convenient when the other side adds a field you do not care about yet, which is
how APIs grow without breaking their clients.

They are dangerous when a missing field means a mistake. A client that sends `"cupon"` for
`"coupon"` gets no discount and no error. **`Decoder.DisallowUnknownFields` turns the silence into
an error**, `json: unknown field "coupon"`, and a server that would rather refuse a request than
half-understand it sets it. The choice belongs to whoever owns the API, and it should be made on
purpose.

## What it refused

**A string where the type says `int` is an error**, and the message names the field by its Go
path and its JSON key, `Order.id`, and both types. Nothing is converted for you, which is the same
rule lesson 10 of `go` gave for the language itself. **A document that is not JSON at all**, here
with a trailing comma, fails before any field is looked at, with the character and what was expected
instead.

So check the error from every `Unmarshal` and every `Decode`. The struct after a failed call may be
partly filled, with no sign of where it stopped.

## Unmarshal or Decoder

`json.Unmarshal` takes a `[]byte` already in memory. `json.NewDecoder` takes an `io.Reader` and
reads as much as it needs, which suits a file, a network connection or an HTTP request body, the
case lesson 28 tests. A Decoder also reads one value after another from the same stream, which is
how JSON Lines is read back. And it is the only one of the two that has the
`DisallowUnknownFields` switch.
