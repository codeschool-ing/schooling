---
title: A repository is an interface
version: 1
---

Lesson 10 ended with two classes, `JpaBookRepository` and `JpaAuthorRepository`, and most of their
lines handed a JPQL string to an `EntityManager` and returned what came back. Every application with a
database writes that code, and it barely changes from one entity to the next. Spring Data JPA takes it
over, and the arrangement it offers is one sentence: **you declare the repository as an interface, and
Spring Data supplies the object that implements it when the application starts.**

The picture most people bring is code generation: a plugin writes a `BookRepositoryImpl.java`
somewhere under `target/`, and the build compiles it. Nothing of the kind is written. When the
application starts, Spring Data looks under the application's package for interfaces that extend one of
its repository interfaces, and makes a **proxy** for each: an object created at run time that implements
the interface and decides what every call does. Methods that every repository has go to one shared
class, `SimpleJpaRepository`, which calls the same `EntityManager` lesson 10 called. Methods you
declare yourself get a query built for them once, during startup, from the method's name or from an
`@Query` annotation on it.

```schooling-figure
@@fig:proxy@@
```

Nobody switched this on. `spring-boot-starter-data-jpa` has been in the pom since lesson 10, and its
autoconfiguration, the same mechanism lesson 4 read in the conditions report, enables repository
scanning as soon as there is something to scan.

The author repository is the smallest example, and this is all of it:

```java
package com.example.bookshop.catalogue;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthorRepository extends JpaRepository<Author, Long> {

    Optional<Author> findByName(String name);
}
```

`JpaRepository<Author, Long>` names the entity and the type of its id. That is enough for Spring Data to
know the table, the id column and the types of every method the interface inherits. `findByName` is
the one method the shop needs that no repository has already; `BookService.add` calls it before it
creates an author. `save`, which lesson 10's class wrote by hand, is not declared at all.

## What comes with it

`javap`, which ships with the JDK, prints the methods a compiled interface declares, and Maven has
already put Spring Data's jars in `~/.m2`. The root of the family is `CrudRepository`:

```
@@javap@@
```

Twelve methods, all generic: `T` is the entity and `ID` the type of its id, which
`JpaRepository<Author, Long>` fills in. `JpaRepository` extends three interfaces, and the first of them
extends `CrudRepository`:

```
@@javap-jpa@@
```

`ListCrudRepository` returns a `List` wherever `CrudRepository` returns an `Iterable`.
`ListPagingAndSortingRepository` adds `findAll(Sort)` and `findAll(Pageable)`, the subject of this
lesson's last section. `QueryByExampleExecutor` builds queries from an example object, which this
course does not use. And `JpaRepository` itself adds what only JPA has: `flush`, `saveAndFlush`,
`getReferenceById` and deletes in one batch.

**`save` chooses between two operations.** If Spring Data considers the entity new, which by default
means its id is still `null`, it calls `persist`, and the object you passed is the one the persistence
context now manages. Otherwise it calls `merge`, which copies your object's state onto a managed copy
and returns the copy, leaving yours untouched. Using what `save` returns, as `BookService` does, is
right in both cases.

The inherited methods also bring their own transactions: `SimpleJpaRepository` runs each read in a
read-only transaction and each write in a read-write one, so a repository called on its own is never
outside a transaction. `BookService` still declares `@Transactional` on every method, because one call
to the service may make several calls to repositories that must succeed or fail together; lesson 14 is
about that.
