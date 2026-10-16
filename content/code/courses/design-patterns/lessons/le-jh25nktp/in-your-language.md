---
title: The functional ideas in your language
version: 1
---

**None of this lesson needs a functional language, and none of the four languages of this course is
one.** Each has borrowed the ideas to a different degree, and each has a place where the borrowing
stops. Knowing where that place is matters more than knowing the syntax, because it is where a
functional design in that language either needs discipline or needs a library.

## Immutability

| language | an immutable record | where it stops |
|---|---|---|
| Python | `@dataclass(frozen=True)`, `NamedTuple`, `tuple`, `frozenset` | shallow: a frozen object holding a list can still have the list changed |
| Java | `record Loan(String title, LocalDate due)` (Java 16+), `final` fields, `List.of(...)` | `final` stops reassignment, not mutation of the object a field points to |
| Go | none; a struct passed by value is copied, so the callee cannot change the caller's copy | slices and maps inside the struct are shared by the copy |
| TypeScript | `readonly` properties, `Readonly<T>`, `as const` | checked at compile time only; at run time it is an ordinary object |

The same limit appears in all four: **immutability is shallow unless every field is immutable too.**
Java's `List.of` and Python's `tuple` are the deep options; Go has to copy a slice by hand; TypeScript
can freeze an object at run time with `Object.freeze`, which is shallow as well.

## Functions as values, and the pipeline

All four pass functions as values. What differs is how pleasant the pipeline is:

```java
long total = loans.stream()
        .filter(loan -> loan.daysLate(today) > 0)
        .mapToLong(loan -> loan.daysLate(today) * 50)
        .sum();
```

```ts
const total = loans
  .filter((loan) => daysLate(loan, today) > 0)
  .map((loan) => daysLate(loan, today) * 50)
  .reduce((a, b) => a + b, 0);
```

```go
total := 0
for _, loan := range loans {
	if d := daysLate(loan, today); d > 0 {
		total += d * 50
	}
}
```

Java's streams are lazy and consumed once, like Python's iterators. TypeScript's array methods build
a new array at every step, which is simple and allocates more. Go's idiom is still the loop: the
language has had closures from the start and generics only since 1.18, and the community never
adopted map and filter as a style. A Go reviewer will usually ask for the loop, and that is a
cultural fact about the language rather than a gap in your design.

## Errors as values

| language | the usual way | a result-like value |
|---|---|---|
| Python | exceptions | `Ok` and `Err` classes as in the previous section, or a library |
| Java | exceptions, checked and unchecked | `Optional<T>` for absence; an `Either` from a library such as Vavr, or a sealed interface |
| Go | `value, err` returned from the function | that *is* the convention: errors are values |
| TypeScript | exceptions | a discriminated union of `{ ok: true, value }` and `{ ok: false, error }` |

Go is the interesting one. It made errors values in 2009, by convention rather than through a type,
and the result is visible in every Go file: `if err != nil { return err }`. Java's checked
exceptions were an earlier attempt to put failure in the signature, and most modern Java code avoids
them because they leak through every layer. TypeScript's discriminated union is the closest of the
four to Rust's `Result`, because the compiler narrows on the `ok` field just as mypy narrows on
`isinstance`.

## Purity

No language here checks it. In all four, a pure function is one that takes everything as arguments
and returns everything as a value, and a reviewer can see that by reading the signature and the
body. **Functional core, imperative shell is a way of laying out a program, and it works in any
language** with functions and values, which is all four. The structure is what you take with you;
the syntax is whatever your language offers.
