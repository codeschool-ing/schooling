---
title: Two fields with one name
version: 1
---

Section 02 described promotion as a search: `e.Name` is looked for in `Employee` itself, and then
inside the structs embedded in it. The search goes level by level, and that gives two rules. **The
shallowest field of a name wins, and two fields of the same name at the same depth cancel each
other out**, so using that name is a compile error. Both show up as soon as an `Employee` embeds
a second struct with fields of the same names as the first:

```go
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Company struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company
	Email string
}

func main() {
	e := Employee{
		Person:  Person{Name: "Ana", Email: "ana@example.com"},
		Company: Company{Name: "Acme", Email: "contact@acme.example"},
		Email:   "ana@acme.example",
	}
	fmt.Println(e.Email)
	fmt.Println(e.Person.Email, e.Company.Email)
	fmt.Println(e.Name)
}
```

```
ana@vm:~/embed-clash$ go run .
# example.com/embed-clash
./main.go:29:16: ambiguous selector e.Name
```

Line 29 is the last `Println`. `Name` exists in `Person` and in `Company`, both one level down,
and **the compiler will not pick one for you**: neither is closer, and the order the fields were
declared in is not allowed to decide. Notice what was not refused. The type `Employee` compiled,
with its two `Name`s inside it, and so did the two lines above, which use `Email`. The error is on
the use of the ambiguous name and nowhere else.

`Email` is in three places, and it caused no trouble. `Employee` declares one of its own, at depth
zero, which is shallower than the two inside `Person` and `Company`, so `e.Email` means the
employee's work address. The other two are hidden from the short spelling, and still there for
the long one. Write the long spelling for `Name` as well and the program runs:

```go
	fmt.Println(e.Person.Name, e.Company.Name)
```

```
ana@vm:~/embed-depth$ go run .
ana@acme.example
ana@example.com contact@acme.example
Ana Acme
```

The two rules protect you unevenly, and it is worth knowing which way. If somebody later adds a
`Name` field to `Company`, every `e.Name` in the program stops compiling, which is loud and safe.
If somebody adds a `Name` field to `Employee` itself, every `e.Name` quietly starts reading the new
one, because it is shallower. **A field added to the outer struct can change what an existing
line of code reads, without an error.**

## Where nobody refuses: JSON

`json.Marshal`, from lesson 15, treats an embedded struct the way the selector does: its fields
are written as though they belonged to the outer struct, so a `Person` inside an `Employee`
produces `"Name"` and `"Email"` keys of the employee's own. That is usually what you want. With the
same `Employee` as above, and a `main` that marshals it instead of printing fields:

```go
	b, err := json.Marshal(e)
	fmt.Println(string(b), err)
```

```
ana@vm:~/embed-json$ go run .
{"Email":"ana@acme.example"} <nil>
ana@vm:~/embed-json$ go vet; echo $?
0
```

**The name is gone, and so is the company's, and nothing reported an error.** `err` is `nil` and
`go vet` exited 0. `Email` came out right, by the same depth rule the compiler uses. The two
`Name`s were the ambiguous pair, and where the compiler refused, `encoding/json` dropped them
both. That is documented behaviour rather than a bug, and the documentation says it plainly:

```
ana@vm:~/embed-json$ go doc encoding/json.Marshal | grep -A1 'Otherwise there are'
    3) Otherwise there are multiple fields, and all are ignored; no error
    occurs.
```

The way out is a struct tag, lesson 15's tool. An embedded field with a name in its tag is no
longer flattened; it is written as an object under that name, which takes its fields out of the
contest:

```go
type Employee struct {
	Person
	Company `json:"company"`
	Email   string
}
```

```
ana@vm:~/embed-json-tag$ go run .
{"Name":"Ana","company":{"Name":"Acme","Email":"contact@acme.example"},"Email":"ana@acme.example"} <nil>
```

`Name` is back, because `Person` is now the only embedded struct that is flattened, and the
company keeps its own name and address inside `"company"`. **When an embedded struct is written to
JSON, check the output once by eye**: an ambiguous field fails the build when Go code names it, and
fails nothing at all when the encoder meets it.
