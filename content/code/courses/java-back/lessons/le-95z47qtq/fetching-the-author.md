---
title: The relationship, and when its other end is loaded
version: 1
---

The catalogue has one relationship, and lesson 10 mapped it: every `Book` has an `Author`, declared on
`Book.author` as `@ManyToOne(fetch = FetchType.LAZY, optional = false)` and stored in the `author_id`
column. **`LAZY` means that loading a book does not load its author.** The field holds a placeholder
that knows only the author's id, and the first time something asks it for more, the name for instance,
it sends a `select` of its own. **`optional = false`** says every book has an author, which is also what
`author_id bigint NOT NULL` says in the schema.

`Author` has no list of its books. The relationship is mapped from one side, which is all the shop
reads: from a book to its author, never the other way. A collection on the other side,
`@OneToMany(mappedBy = "author")`, would make it **bidirectional**, and lesson 14's order with its lines
is where a collection earns its place.

## The N+1 problem, again

Lesson 10 found that a list of books with lazy authors costs one `select` for the books and one more
for every author, and fixed it with `join fetch` in the JPQL. A derived query has no JPQL to write
`join fetch` in. **`@EntityGraph(attributePaths = "author")` is the same instruction attached to a
method**: whatever query this method runs, load the `author` with the books.

The common wrong fix is to change the mapping to `FetchType.EAGER`. That loads the author in every
query that will ever touch a book, including the ones that never read it, and it is a decision about
the entity made to solve a problem of one query. An entity graph is a decision about one query.

To see what the graph is doing, take it away. As a detour, delete the `@EntityGraph` line above
`findAllBy` in `BookRepository`, then build, restart the second terminal, and ask for the first page:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -s localhost:8080/books > /dev/null
```

```
2026-10-22T19:19:00.472-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 order by b1_0.id fetch first ? rows only
2026-10-22T19:19:00.908-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.933-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.938-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.944-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:19:00.946-03:00 DEBUG 22594 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

One `select` for the page of books, then one per author. Put the line back, build, restart, and ask
again:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -s localhost:8080/books > /dev/null
```

```
2026-10-22T19:19:23.866-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by b1_0.id fetch first ? rows only
```

One statement, with the author's columns in it. It is a **`join`**, an inner join, and not a
`left join`, because `optional = false` told Hibernate that no book is without an author, so no row
can be lost by requiring one.

## One book is two statements, and that is fine

`findById` is inherited from `CrudRepository` and carries no entity graph:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/2; echo
{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950}
```

```
2026-10-22T19:19:24.492-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:19:24.497-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

The book, and then its author, when `BookResponse.from` reads the name. That is the same lazy loading,
and for one book it costs one extra round trip to the database. The N+1 problem is a problem of
lists, where N grows with the data; a single read with one lazy reference is not a reason to annotate
anything.

Both loads happen inside `BookService.get`, which is `@Transactional(readOnly = true)`. Lesson 10 set
`spring.jpa.open-in-view=false`, so a lazy author touched after the service returned, in the
controller or while Jackson writes the JSON, would throw `LazyInitializationException` rather than
quietly run another query. That is why the service hands out DTOs and never entities.
