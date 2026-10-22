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
{"svg": "<svg viewBox=\"0 0 750 256\" role=\"img\" aria-label=\"BookService calls BookRepository, which is a proxy Spring Data made at startup. The proxy sends inherited methods such as save, findById and count to SimpleJpaRepository, and each declared method such as findByIsbn to a query built at startup. Both reach the EntityManager.\"><defs><marker id=\"l11-px\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"130\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BookService</text><text x=\"85\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">your code</text><rect x=\"190\" y=\"100\" width=\"175\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"277\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BookRepository</text><text x=\"277\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a proxy, made at startup</text><rect x=\"410\" y=\"20\" width=\"190\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SimpleJpaRepository</text><text x=\"505\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">inherited methods</text><text x=\"505\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">save, findById, count</text><rect x=\"410\" y=\"164\" width=\"190\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a query per declared method</text><text x=\"505\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">findByIsbn</text><text x=\"505\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">@Query</text><rect x=\"625\" y=\"100\" width=\"105\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"677\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EntityManager</text><text x=\"677\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">SQL to PostgreSQL</text><line x1=\"150\" y1=\"128\" x2=\"188\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></line><path d=\"M 365 120 C 385 120, 385 56, 408 56\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path><path d=\"M 365 136 C 385 136, 385 200, 408 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path><path d=\"M 600 56 C 615 56, 610 116, 623 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path><path d=\"M 600 200 C 615 200, 610 140, 623 138\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path></svg>", "caption": "The interface you write is implemented by a proxy that Spring Data makes when the application starts. Inherited methods go to one shared class; every method you declare gets its query once, before the first request."}
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
ana@vm:~/bookshop$ javap -cp ~/.m2/repository/org/springframework/data/spring-data-commons/4.1.1/spring-data-commons-4.1.1.jar org.springframework.data.repository.CrudRepository
Compiled from "CrudRepository.java"
public interface org.springframework.data.repository.CrudRepository<T, ID> extends org.springframework.data.repository.Repository<T, ID> {
  public abstract <S extends T> S save(S);
  public abstract <S extends T> java.lang.Iterable<S> saveAll(java.lang.Iterable<S>);
  public abstract java.util.Optional<T> findById(ID);
  public abstract boolean existsById(ID);
  public abstract java.lang.Iterable<T> findAll();
  public abstract java.lang.Iterable<T> findAllById(java.lang.Iterable<ID>);
  public abstract long count();
  public abstract void deleteById(ID);
  public abstract void delete(T);
  public abstract void deleteAllById(java.lang.Iterable<? extends ID>);
  public abstract void deleteAll(java.lang.Iterable<? extends T>);
  public abstract void deleteAll();
}
```

Twelve methods, all generic: `T` is the entity and `ID` the type of its id, which
`JpaRepository<Author, Long>` fills in. `JpaRepository` extends three interfaces, and the first of them
extends `CrudRepository`:

```
ana@vm:~/bookshop$ javap -cp ~/.m2/repository/org/springframework/data/spring-data-jpa/4.1.1/spring-data-jpa-4.1.1.jar org.springframework.data.jpa.repository.JpaRepository | head -n 2
Compiled from "JpaRepository.java"
public interface org.springframework.data.jpa.repository.JpaRepository<T, ID> extends org.springframework.data.repository.ListCrudRepository<T, ID>, org.springframework.data.repository.ListPagingAndSortingRepository<T, ID>, org.springframework.data.repository.query.QueryByExampleExecutor<T> {
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
