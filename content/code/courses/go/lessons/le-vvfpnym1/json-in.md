---
title: JSON comes back in
version: 1
---

`json.Unmarshal` goes the other way: it takes JSON and fills a Go value from it. The wrong
expectation here is the mirror of section 03's. Coming from a typed language, people expect the
JSON to be checked against the struct, so that an extra key or a missing one is an error. **By
default `encoding/json` checks almost nothing: unknown keys are skipped, missing keys leave their
fields at zero, and key names match in either case.** All three in one run:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string   `json:"name"`
	Email string   `json:"email"`
	Tags  []string `json:"tags"`
}

func main() {
	data := []byte(`{"NAME": "Bia", "tags": ["go", "sql"], "nickname": "b"}`)
	var u User
	err := json.Unmarshal(data, &u)
	fmt.Printf("%+v %v\n", u, err)
}
```

```
ana@vm:~/structs-in$ go run .
{Name:Bia Email: Tags:[go sql]} <nil>
```

`"NAME"` filled `Name`, though the tag says `name`: when no key matches exactly, `encoding/json`
accepts one that differs only in upper and lower case. `"nickname"` matched no field and was thrown
away. There was no `"email"`, so `Email` kept the zero value it had from `var`. And `err` is nil:
from the program's point of view, nothing happened that it needs to know about.

The `&` in `&u` hands `Unmarshal` the variable itself rather than a copy of it, so it can write
into the fields; lesson 23 is about `&` and pointers. Forgetting it compiles, and fails when it
runs.

## What does count as an error

The JSON has to be JSON, a value has to fit the field's type, and the destination has to be
something `Unmarshal` can write into:

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name string `json:"name"`
}

func main() {
	var u User
	fmt.Println(json.Unmarshal([]byte(`{"name": 42}`), &u))
	fmt.Println(json.Unmarshal([]byte(`{"name": "Bia",}`), &u))
	fmt.Println(json.Unmarshal([]byte(`{"name": "Bia"}`), u))
	fmt.Printf("%+v\n", u)
}
```

```
ana@vm:~/structs-in-bad$ go run .
json: cannot unmarshal number into Go struct field User.name of type string
invalid character '}' looking for beginning of object key string
json: Unmarshal(non-pointer main.User)
{Name:}
ana@vm:~/structs-in-bad$ go vet; echo $?
main.go:16:28: call of Unmarshal passes non-pointer as second argument
1
```

A number where a string belongs is refused, and the message names the field by its Go type and its
JSON key. A comma before the closing brace is not JSON, whatever JavaScript allows. The third call
passed `u` without `&`, and `Unmarshal` could only refuse; `go vet` saw that one before anything
ran, which is another reason to run it. After three failures `u` is still empty: **check the error
before you trust the value**, which is lesson 32's whole subject.

## Refusing unknown keys

Skipping unknown keys is what lets an old program read JSON from a newer one that added a field.
It is also what lets a typo through. A client that sends `"emial"` gets no complaint and no email
stored. When the input should match the struct exactly, a `json.Decoder` can be told to refuse:

```go
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type User struct {
	Name  string   `json:"name"`
	Email string   `json:"email"`
	Tags  []string `json:"tags"`
}

func main() {
	data := `{"name": "Bia", "emial": "bia@example.com"}`

	var loose User
	fmt.Println(json.Unmarshal([]byte(data), &loose))
	fmt.Printf("%+v\n", loose)

	var strict User
	dec := json.NewDecoder(strings.NewReader(data))
	dec.DisallowUnknownFields()
	fmt.Println(dec.Decode(&strict))
}
```

```
ana@vm:~/structs-strict$ go run .
<nil>
{Name:Bia Email: Tags:[]}
json: unknown field "emial"
```

`json.NewDecoder` reads JSON from a stream rather than from a `[]byte` in memory: a file, a network
connection, or here a string wrapped by `strings.NewReader`. Lesson 27 explains what a reader is.
`DisallowUnknownFields` switches the one check on, and `Decode` then names the key it did not
recognise. **Choose per input**: refuse unknown keys from a configuration file a person typed, and
skip them in a message from another service that may be newer than yours.

## `encoding/json/v2`

The behaviours above belong to `encoding/json`, and in go1.27.1 the standard library carries a
second package next to it. Its first lines of documentation say why:

```
ana@vm:~/structs-v2$ go doc encoding/json | sed -n 13,15p
For historical reasons, the default behavior of v1 encoding/json unfortunately
operates with less secure defaults. New usages of JSON in Go are encouraged to
use encoding/json/v2 instead.
```

The same input through both, and the same struct back out through both:

```go
package main

import (
	"encoding/json"
	jsonv2 "encoding/json/v2"
	"fmt"
)

type User struct {
	Name string   `json:"name"`
	Tags []string `json:"tags"`
}

func main() {
	data := []byte(`{"NAME": "Bia"}`)
	var a, b User
	fmt.Println(json.Unmarshal(data, &a), jsonv2.Unmarshal(data, &b))
	fmt.Printf("%+v\n%+v\n", a, b)

	out1, _ := json.Marshal(a)
	out2, _ := jsonv2.Marshal(a)
	fmt.Println(string(out1))
	fmt.Println(string(out2))
}
```

```
ana@vm:~/structs-v2$ go run .
<nil> <nil>
{Name:Bia Tags:[]}
{Name: Tags:[]}
{"name":"Bia","tags":null}
{"name":"Bia","tags":[]}
```

Both packages are called `json`, so the import gives the second one the name `jsonv2`. **Version 2
matches key names exactly**, so `"NAME"` filled nothing, and it writes a nil slice as `[]` rather
than `null`. The tags are the same tags. It is still lenient about unknown keys by default.

It is new enough that you will mostly read code using the first one. The lab's toolchain from lesson
2 shows how new. The program in `~/structs-v2old` marshals a nil `[]string` with `jsonv2`, in a
module whose `go.mod` says `go 1.26.0`.
Under go1.26.0 the package is only there behind an experiment switch:

```
ana@vm:~/structs-v2old$ go run .
[]
ana@vm:~/structs-v2old$ GOTOOLCHAIN=go1.26.0 go run .
package example.com/v2old
	imports encoding/json/v2: build constraints exclude all Go files in /home/ana/go/pkg/mod/golang.org/toolchain@v0.0.1-go1.26.0.linux-amd64/src/encoding/json/v2
ana@vm:~/structs-v2old$ GOTOOLCHAIN=go1.26.0 GOEXPERIMENT=jsonv2 go run .
[]
```

So a module that imports `encoding/json/v2` needs go1.27 to build without setting anything, and
that is a decision about who can compile your code. **Whichever package you use, the struct is the
contract**: the exported fields and their tags are what goes out, and what comes in is checked only
as far as you asked.
