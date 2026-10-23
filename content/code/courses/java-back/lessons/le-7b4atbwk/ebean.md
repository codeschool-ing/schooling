---
title: "EBean: an ORM without the session"
version: 1
---

**EBean** is an ORM of the same family as Hibernate. You write entities with the mapping annotations
lesson 10 put on `Book` (`@Entity`, `@Id`, `@ManyToOne`), EBean writes the SQL, and an association
loads when you touch it. Where it parts company is the persistence context. **EBean has no
`EntityManager` to attach an entity to**, so there is no attached or detached state, no `merge`, and
no session whose end turns a lazy association into an exception.

## The state lives in the object

Hibernate keeps what it knows about an entity in the persistence context: the values it loaded, so
it can compare them at commit and find what changed. EBean keeps that knowledge in the entity
itself. A build step called **enhancement** (a Maven plugin, or a Java agent at start-up) rewrites
the compiled entity classes, so that each object records which of its properties were loaded and
which were changed since.

Three behaviours follow from that, and each one answers a row of the table in the first section:

- Saving is a call you make, `DB.save(book)`, and the `UPDATE` it sends names only the columns that
  changed. Hibernate, by default, writes every column of the entity.
- A lazy association touched after the transaction has ended is loaded then, in a statement of its
  own, where lesson 10's bookshop threw `LazyInitializationException`.
- Nothing has to be closed, cleared or merged, because nothing holds the objects but your code.

Loading on touch is still a query per touch, though, and the N+1 problem of lesson 10 is still there
to be had. EBean blunts it by loading lazy associations in batches rather than one at a time, and
you plan the fetch, exactly as `join fetch` did, when the batches are not enough.

## Query beans

EBean's second idea is the **query bean**. An annotation processor reads each entity at compile time
and generates a class for querying it, `QBook` for `Book`, with one field per property. The query
lesson 11 wrote with `@Query`, one author's books in order of title, reads like this in EBean. It is
a sketch of the shape and **was not run for this course**:

```java
List<Book> books = new QBook()
        .author.name.eq("Machado de Assis")
        .orderBy().title.asc()
        .findList();
```

`author.name` is a chain of fields of a generated class, so a misspelt property is a compile error.
A JPQL string inside `@Query` is only checked by Spring Data when the application starts, and the
JDBI section of this lesson shows a plain SQL string being checked later still.

## What it charges

The price is the enhancement, and a team pays it in places it notices. The build needs the plugin,
and every other way of running the code needs enhanced classes too, a test started from the IDE
included. An entity that missed the step fails at run time rather than at build. The community is
far smaller than Hibernate's, which means fewer answers to search for and fewer colleagues who have
met your error before. And Spring Boot has no auto-configuration for it, so wiring EBean into the
bookshop would be yours to write.

You meet it mostly in two places. One is the **Play Framework** of lesson 8, whose Java side has
offered EBean through its `play-ebean` module for many years. The other is a codebase whose authors
wanted an ORM and did not want the session.
