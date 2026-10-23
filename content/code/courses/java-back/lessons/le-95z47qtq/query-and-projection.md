---
title: Writing the JPQL yourself, and selecting less
version: 1
---

`GET /books/by-author?name=…` wants the titles and prices of one author's books, in title order. A
derived query could ask for it, `findByAuthorNameOrderByTitle`, and would load whole `Book` entities to
answer a question about two of their fields. `findTitlesByAuthor` writes the query instead:

```java
    @Query("select b.title as title, b.priceCents as priceCents from Book b where b.author.name = :name order by b.title")
    List<TitleAndPrice> findTitlesByAuthor(String name);
```

**`@Query` takes JPQL**, the language lesson 10 wrote by hand, so it names the entity `Book` and the
field `priceCents`, never the table or the column. **`b.author.name` walks the relationship**, and
Hibernate turns the path into a join. **`:name` is a named parameter**, bound from the method's
parameter of the same name. Java keeps parameter names in the compiled class only when asked to, and
Spring Boot's parent pom asks the compiler for them, so nothing else is needed to connect the two.

The return type is the other half. `TitleAndPrice` is an interface with two getters, `getTitle` and
`getPriceCents`, and nothing in the project implements it. It is an **interface projection**. Spring
Data matches each getter to a value of the same name in the query's result, which is what the aliases
`as title` and `as priceCents` are for. What comes back is one small proxy per row, answering the
getters from that row.

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books/by-author?name=H.%20G.%20Wells"; echo
[{"priceCents":2950,"title":"The Time Machine"},{"priceCents":3200,"title":"The War of the Worlds"}]
```

```
2026-10-22T19:19:25.049-03:00 DEBUG 23329 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.title,b1_0.price_cents from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where a1_0.name=? order by b1_0.title
```

**Two columns, and no entity anywhere.** The statement selects the title and the price and nothing
else, and since no `Book` was loaded, nothing entered the persistence context, no author placeholder
was created, and there is no N+1 problem to have. The join to `author` is the path in the `where`.

A projection does not have to be an interface. A record would work too, say a `TitlePrice` with a
constructor taking the two values, written in JPQL as `select new com.example.bookshop.catalogue.TitlePrice(b.title, b.priceCents) from …`.
The interface needs no constructor expression and the record needs no proxy; for two values read
straight into JSON, either is fine, and this course keeps the interface.

## A query is checked at startup too

Spring Data hands every `@Query` to Hibernate while the application starts, and Hibernate parses it
against the entities. As a detour, change `b.priceCents` to `b.price` in the query, stop the
application, build, and start it in the first terminal:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by' | tail -n 1
Caused by: org.hibernate.query.sqm.PathElementException: Could not resolve attribute 'price' of 'com.example.bookshop.catalogue.Book'
```

**No `Book` has a `price`**, and the application stopped before it served anybody, as it did for the
misspelt derived query. Put `b.priceCents` back.

That check reaches only what Hibernate can see. With `nativeQuery = true`, `@Query` sends its string
to PostgreSQL as SQL, and Hibernate checks nothing in it against the entities, so a native query's
mistakes wait for the first call. It is also tied to one database's dialect. The bookshop has no need for one.
