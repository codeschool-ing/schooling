---
title: An Employee is not a Person
version: 1
---

Anybody who has met classes in Java, Python or C++ reads `Employee` as a subclass: it extends
`Person`, so an employee *is* a person and can go wherever a person is wanted. **Embedding is not
inheritance, and the compiler says so the first time you lean on it.** Here is a function that
greets a `Person`, handed an `Employee`:

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

func greet(p Person) {
	fmt.Println("Hello,", p.Name)
}

func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	greet(e)
}
```

```
ana@vm:~/embed-notis$ go run .
# example.com/embed-notis
./main.go:21:8: cannot use e (variable of struct type Employee) as Person value in argument to greet
```

`Employee` and `Person` are two different struct types, and a value of one cannot be used where
the other is wanted, any more than an `int` can be passed where a `string` is. In a language with
inheritance this call is the whole point of the hierarchy. In Go, **an `Employee` has a `Person`
inside it, and that is the only relationship between the two types.**

So you hand over the part rather than the whole. The embedded field has a name, `Person`, and
`e.Person` is a complete `Person` value:

```go
func main() {
	e := Employee{Name: "Ana", Email: "ana@example.com", Company: "Acme"}
	greet(e.Person)

	c := e
	c.Name = "Bia"
	fmt.Println(e.Name, c.Name)
}
```

```
ana@vm:~/embed-part$ go run .
Hello, Ana
Ana Bia
```

The second half of that `main` shows where the `Person` lives. `c := e` copied the employee, and
changing the name through `c` left `e` alone. **The `Person` is stored inside the `Employee`,
field by field, and copying the outer struct copies the inner one with it.** It is not
a reference to a person kept somewhere else. And `greet` received a copy of the part, as every Go
function receives a copy of what it is passed, which is lesson 22's subject.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The value e, of type Employee, is one box holding two fields: an embedded Person, which is itself a box holding Name &quot;Ana&quot; and Email &quot;ana@example.com&quot;, and Company &quot;Acme&quot;. e.Name and e.Person.Name both point at the Name inside the Person: one field, two spellings. greet(e.Person) points at the whole Person box and receives a copy of that part. greet(e) points at the outer box and is refused, because an Employee is not a Person.\"><defs><marker id=\"em-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"em-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"330\" height=\"236\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">e  Employee</text><rect x=\"48\" y=\"68\" width=\"294\" height=\"124\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"64\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Person</text><path d=\"M64 104 L326 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Name</text><text x=\"326\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Ana&quot;</text><path d=\"M64 146 L326 146\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"70\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Email</text><text x=\"326\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;ana@example.com&quot;</text><path d=\"M48 212 L342 212\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"64\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Company</text><text x=\"326\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;Acme&quot;</text><text x=\"420\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">greet(e.Person)</text><text x=\"420\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">receives a copy of this part</text><path d=\"M412 70 L346 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#em-phosphor)\"></path><text x=\"420\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">e.Name</text><text x=\"476\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">e.Person.Name</text><text x=\"420\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one field, two spellings</text><path d=\"M412 126 L332 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#em-phosphor)\"></path><text x=\"420\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">greet(e)</text><text x=\"420\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">refused: an Employee is not a Person</text><path d=\"M412 234 L364 234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#em-amber)\"></path></svg>", "caption": "An Employee holds a whole Person inside it. e.Name reaches into that part, greet(e.Person) hands over a copy of the part, and greet(e) is refused, because the whole is a different type."}
```

## The part never learns about the whole

`greet` was given a `Person`, and that is all it has. It cannot ask for the company, because a
`Person` has no company, and nothing inside the `Person` knows that it was cut out of an
`Employee`. That is the deepest difference from inheritance. A class that inherits can change
what its parent's code does when the parent's code runs. **An embedded struct is only ever
itself.** The outer struct can add fields around it, and cannot reach back into what it does.

This is what "composition" means in the title of this lesson: a type built by putting other types
inside it. Lesson 1 said Go has no classes and no inheritance, and this is the tool it offers
instead. It covers the half of inheritance that is about reuse, getting the fields and methods of
a type you already have without writing them again. The other half, letting several different
types stand in for one another, belongs to interfaces, and lesson 27 is where a function learns to
accept anything that can do what it needs.
