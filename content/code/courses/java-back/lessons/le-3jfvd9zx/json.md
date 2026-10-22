---
title: Records in, JSON out, with Jackson 3
version: 1
---

Steps 2 and 4 of the `DispatcherServlet` hand the body to a message converter, and for JSON that
converter is **Jackson**, the library that turns Java objects into JSON and back. You never added it.
The web starter depends on it, and Maven's dependency tree shows the path:

```
ana@vm:~/bookshop$ mvn dependency:tree -Dincludes=tools.jackson.core,com.fasterxml.jackson.core | grep jackson
[INFO]    \- org.springframework.boot:spring-boot-starter-jackson:jar:4.1.1:compile
[INFO]       \- org.springframework.boot:spring-boot-jackson:jar:4.1.1:compile
[INFO]          \- tools.jackson.core:jackson-databind:jar:3.1.5:compile
[INFO]             +- com.fasterxml.jackson.core:jackson-annotations:jar:2.21:compile
[INFO]             \- tools.jackson.core:jackson-core:jar:3.1.5:compile
```

`-Dincludes` keeps the tree to the groups named, and `grep jackson` drops Maven's other lines. What is
left says two things worth knowing before you read any other tutorial.

**Spring Boot 4 runs on Jackson 3**, here 3.1.5, and Jackson 3 moved from the group and the package
`com.fasterxml.jackson` to `tools.jackson`. A tutorial that imports
`com.fasterxml.jackson.databind.ObjectMapper` was written for Jackson 2 and for Spring Boot 3 or older;
in this project that class is `tools.jackson.databind.ObjectMapper`. The exception is the
annotations, `jackson-annotations` 2.21 above, which kept their old group and package so that one
annotated class works with both versions. `@JsonProperty` is still imported from
`com.fasterxml.jackson.annotation`.

## How a record is written

`python3 -m json.tool` reads JSON on its standard input and prints it with one property to a line,
which makes the list readable. Python 3 comes with Ubuntu.

```
ana@vm:~/bookshop$ curl -s localhost:8080/books | python3 -m json.tool
[
    {
        "id": 1,
        "isbn": "9786500000016",
        "title": "Dom Casmurro",
        "author": "Machado de Assis",
        "priceCents": 3990
    },
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 3,
        "isbn": "9786500000030",
        "title": "Frankenstein",
        "author": "Mary Shelley",
        "priceCents": 3500
    }
]
```

The rules Jackson applied, each visible above:

- every component of the record becomes a property, **named after the component**, in the order the
  record declares them;
- `long` and `int` become JSON numbers, `String` a JSON string, a `List` an array;
- nothing needed annotating, because a record declares its components and Jackson reads them.

A name on the wire that differs from the Java one, `price_cents` for instance, is
`@JsonProperty("price_cents")` on the component. The bookshop keeps the Java names.

The price is a whole number of **cents**, 3990 rather than 39.90. Money in a binary floating-point
number is a classic way to lose a cent, because 0.10 has no exact binary form, and an integer count
of the smallest unit has no such problem.

## Reading is stricter in some ways and looser in another

`@RequestBody` runs the same machinery backwards: Jackson builds a record from the JSON, calling its
constructor with the properties it found. Two defaults of Jackson 3 decide what happens to a body that
does not fit, and both appear in this lesson:

- a property the record has **no component for is ignored**, without an error; the section on POST
  sends an `id` that way and watches it disappear;
- a **missing value or a `null` for a primitive** such as `int` is refused, because there is no
  honest `int` to put there; the section on validation starts from exactly that refusal.
