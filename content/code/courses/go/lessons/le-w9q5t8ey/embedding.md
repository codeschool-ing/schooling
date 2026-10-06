---
title: A field with a type and no name
version: 1
---

Every field of lesson 15's structs had a name and a type. **Leave the name out, write only the
type, and the field is embedded**: the outer struct now holds a whole value of that type, and the
inner value's fields can be reached as though they were the outer struct's own. That is all
embedding is, and the program below shows each piece of it:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Person struct {\n\tName  string\n\tEmail string\n}\n",
      "note": "An ordinary struct with two fields, the kind lesson 15 declared."
    },
    {
      "code": "\ntype Employee struct {\n\tPerson\n\tCompany string\n}\n",
      "note": "**`Person` on a line of its own is a field with a type and no name.** The field still has a name, though nobody wrote it: an embedded field is called after its type, so this one is `Person`."
    },
    {
      "code": "\nfunc main() {\n\te := Employee{\n\t\tPerson:  Person{Name: \"Ana\", Email: \"ana@example.com\"},\n\t\tCompany: \"Acme\",\n\t}\n",
      "note": "In a literal, the embedded field is set like any other, by that name and with a whole `Person` value."
    },
    {
      "code": "\tfmt.Println(e.Name, e.Person.Name)\n\tfmt.Println(e.Email)\n",
      "note": "**`e.Name` is short for `e.Person.Name`.** The fields of `Person` are **promoted** to `Employee`, so the short spelling finds them; both print `Ana`, and `e.Email` works the same way."
    },
    {
      "code": "\n\te.Name = \"Ana Lima\"\n\tfmt.Println(e.Person.Name)\n",
      "note": "The short spelling is not a copy. Assigning to `e.Name` changed `e.Person.Name`, because they are one field written two ways."
    },
    {
      "code": "\n\tfmt.Printf(\"%+v\\n\", e)\n}\n",
      "note": "`%+v` prints the field names, and it shows what the value really is: an `Employee` has two fields, `Person` and `Company`, and `Name` lives inside `Person`."
    }
  ],
  "output": "Ana Ana\nana@example.com\nAna Lima\n{Person:{Name:Ana Lima Email:ana@example.com} Company:Acme}"
}
```

The last line of the output is the one to keep in mind for the rest of the lesson. **Promotion is a shortcut in
the spelling and nothing else**: no field was copied into `Employee`, and no `Name` exists at the
outer level. The compiler sees `e.Name`, finds no field called `Name` in `Employee` itself, looks
inside the embedded `Person`, and finds it there.

## Writing the literal the short way

Naming `Person:` and building a whole `Person` inside the literal is long-winded when all you want
is to set three fields. Go 1.27 accepts the promoted names directly:

```go
package main

import "fmt"

type Person struct {
	Name  string
	Email string
}

type Employee struct {
	Person
	Company string
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	fmt.Printf("%+v\n", e)
}
```

```
ana@vm:~/embed-literal$ go run .
{Person:{Name:Ana Email:ana@example.com} Company:Acme}
ana@vm:~/embed-literal$ go mod edit -go=1.26
ana@vm:~/embed-literal$ go run .
# example.com/embed-literal
./main.go:16:16: use of promoted field Person.Name in struct literal of type Employee requires go1.27 or later (-lang was set to go1.26; check go.mod)
./main.go:16:29: use of promoted field Person.Email in struct literal of type Employee requires go1.27 or later (-lang was set to go1.26; check go.mod)
```

The value it built is the same as before, with `Name` and `Email` inside `Person`. The second run
is the same file after `go mod edit -go=1.26` rewrote the `go` line of `go.mod`, and the compiler
refused it. **The `go` line decides which version of the language a module is written in**, which
is lesson 2's subject, and the message says so in as many words: `check go.mod`. Go 1.27 was
released in August 2026, so code written before then, or for a module whose `go` line is older,
uses the long form, because it was the only one that compiled.

The two forms cannot be mixed for one embedded struct. Setting `Person` and then one of its fields
as well is refused, since the two would be writing the same field twice:

```go
	e := Employee{Person: Person{Name: "Ana"}, Email: "ana@example.com"}
```

```
ana@vm:~/embed-mix$ go run .
# example.com/embed-mix
./main.go:16:45: cannot specify promoted field Email and enclosing embedded field Person
```

## Methods are promoted too

A type can also have functions attached to it, called methods, and lesson 25 is where they start.
Embedding promotes them exactly as it promotes fields: a method declared on `Person` can be called
on an `Employee`, and lesson 25 comes back to this lesson to show it. For now it is enough to know
that **whatever `e.Something` finds in the embedded struct, a field or a method, it finds by the
same search**, and section 03 says exactly how far down that search goes.
