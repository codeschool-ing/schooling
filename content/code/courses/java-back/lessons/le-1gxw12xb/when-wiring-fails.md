---
title: When the wiring fails
version: 1
---

Spring resolves every constructor parameter at start-up, before the application does any work, so a
wiring mistake stops it at once with a report instead of turning up later as a `null`. There are
three such mistakes and each has its own report, headed `APPLICATION FAILED TO START`. Every case
below is a detour: make the change, read the report, undo it. The `tail` keeps the report and drops
the start-up lines above it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 320\" role=\"img\" aria-label=\"Three rows. Two candidates: BookService points to both emptyBookRepository and inMemoryBookRepository, and the report says it required a single bean, but 2 were found; the repair is @Primary or @Qualifier. None: CatalogueReport points to an empty dashed box, nothing to inject, and the report says could not be found; the repair is a stereotype, in a package below the application’s. A cycle: bookService and catalogueReport point at each other, and the report says form a cycle; the repair is a change of design.\"><defs><marker id=\"f5-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f5-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">Two candidates</text><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">required a single bean, but 2 were found</text><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">@Primary or @Qualifier</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">None</text><text x=\"20\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">could not be found</text><text x=\"20\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a stereotype, in a package</text><text x=\"20\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">below the application’s</text><text x=\"20\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">A cycle</text><text x=\"20\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">form a cycle</text><text x=\"20\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a change of design</text><rect x=\"300\" y=\"30\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">BookService</text><rect x=\"510\" y=\"12\" width=\"230\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">emptyBookRepository</text><rect x=\"510\" y=\"56\" width=\"230\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">inMemoryBookRepository</text><line x1=\"450\" y1=\"46\" x2=\"508\" y2=\"30\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><line x1=\"450\" y1=\"54\" x2=\"508\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><rect x=\"300\" y=\"135\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">CatalogueReport</text><rect x=\"510\" y=\"135\" width=\"230\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"625\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing to inject</text><line x1=\"450\" y1=\"155\" x2=\"508\" y2=\"155\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><rect x=\"300\" y=\"240\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">bookService</text><rect x=\"510\" y=\"240\" width=\"230\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">catalogueReport</text><line x1=\"450\" y1=\"252\" x2=\"508\" y2=\"252\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><line x1=\"510\" y1=\"268\" x2=\"452\" y2=\"268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line></svg>", "caption": "The three reports, as shapes. Each names the constructor parameter it could not fill, and each has a different repair."}
```

## Two candidates

Add a second implementation of `BookRepository`, an empty one, of the kind somebody writes for a
demonstration, as `src/main/java/com/example/bookshop/catalogue/EmptyBookRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

@Repository
public class EmptyBookRepository implements BookRepository {

    @Override
    public List<Book> findAll() {
        return List.of();
    }

    @Override
    public Optional<Book> findById(long id) {
        return Optional.empty();
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return Optional.empty();
    }

    @Override
    public Book save(Book book) {
        return book;
    }
}
```

```
!!! MISSING BLOCK two
```

Read the description from its first line. **Parameter 0** of `BookService`'s constructor wants one
`BookRepository` and found two, listed by bean name and by the class file each came from. Matching by
type is no longer enough to decide, and Spring will not guess.

The `Action` lists the repairs, and two of them are annotations. `@Primary` on one candidate makes it
the one chosen whenever a single bean of its type is wanted. Add it to `InMemoryBookRepository`,
above the class, with its import:

```
!!! MISSING BLOCK primary
```

`@Qualifier` goes at the injection point and names the bean that consumer wants, and it wins over
`@Primary`. Take `@Primary` off again and qualify the parameter instead:

```
!!! MISSING BLOCK qualifier
```

The two differ in **who decides**. `@Primary` is decided by the candidate and applies to every
consumer; `@Qualifier` is decided by one consumer and applies there alone. A second store used by two
classes out of thirty is a `@Qualifier` in those two; a replacement meant to stand in everywhere is a
`@Primary`. The third repair in the list, accepting several beans, means a parameter of type
`List<BookRepository>`, into which Spring puts every candidate. It suits a class meant to use all of
them, and this one is not.

The last three lines of the report point at something quieter. Spring's final tie-breaker is the
**parameter's name**: when it matches one candidate's bean name, that candidate wins. The compiler
keeps parameter names in the class files only when it is given `-parameters`, and Spring Boot's
parent POM turns that on. Remove the qualifier and rename the parameter after one of the beans:

```
!!! MISSING BLOCK paramname
```

It starts, with no annotation anywhere, and that is the reason not to rely on it. Renaming a
parameter is an edit that looks harmless in any review, and here it would change which bean the class
receives. An annotation says the same thing on purpose.

Undo the detour: delete `EmptyBookRepository.java` and give the constructor back its parameter
`books`.

## None

The opposite failure is a type that nothing provides. Delete the `@Repository` line from
`InMemoryBookRepository`:

```
!!! MISSING BLOCK missing
```

Without its stereotype the class is invisible to component scanning, so no bean of type
`BookRepository` exists. The class still compiles and still implements the interface, and it is never
created. Put the line back.

The same report appears when the annotation is there and the class sits outside the scanned
packages. Move `ClockConfig` from `com.example.bookshop.config` to a package beside the bookshop's
instead of inside it:

```
!!! MISSING BLOCK outside
```

**Parameter 1** this time, `CatalogueReport`'s clock. `ClockConfig` still carries `@Configuration`
and its class is in the jar, but `com.example.clock` is not below `com.example.bookshop`, so scanning
never looked there. Move it back by reversing the three commands. When this report names a bean you
are sure you wrote, check its package before anything else.

## A cycle

The third failure needs two beans that each want the other. Give `BookService`'s constructor a
`CatalogueReport` as well, as if adding a book should update the report:

```
!!! MISSING BLOCK cycle
```

The drawing is the cycle: `bookService` needs `catalogueReport`, which needs `bookService`. With
constructors there is no order that works, because neither object can be created until the other
exists. The `Action` mentions a property that allows circular references. It helps with field and
setter injection, where Spring can hand one object over half-built and finish it later; with
constructors it cannot, and the report says so:

```
!!! MISSING BLOCK cycle-flag
```

The repair is in the design. Here it is easy, because the dependency was invented and the service does
not need the report. In real code a cycle usually means one class is doing two jobs, and the way out
is to move the part both of them need into a third class that both depend on. Put the constructor
back as it was.
