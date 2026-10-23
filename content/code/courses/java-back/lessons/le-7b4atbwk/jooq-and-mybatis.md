---
title: "jOOQ and MyBatis: the SQL stays yours"
version: 1
---

An ORM starts from the objects and works out the SQL. jOOQ and MyBatis start from the other end:
**the database and its SQL come first**, and Java objects are what a query's rows are turned into.
Neither keeps your objects in a persistence context, and the SQL that runs is SQL somebody on the
team wrote, so most of the bill in the first section's table never arrives. Where the two disagree
is where that SQL lives.

## jOOQ: SQL written in Java

**jOOQ** generates Java from the schema. Its code generator connects to the database, or reads the
scripts that create it, and writes a class for every table, `BOOK` and `AUTHOR` for the bookshop,
with a typed field for every column: `BOOK.TITLE` is a `TableField<BookRecord, String>`. A query is
then Java that reads like the SQL it renders. Lesson 11's titles of one author, as a sketch that
**was not run for this course**:

```java
List<TitleAndPrice> books = ctx
        .select(BOOK.TITLE, BOOK.PRICE_CENTS)
        .from(BOOK)
        .join(AUTHOR).on(AUTHOR.ID.eq(BOOK.AUTHOR_ID))
        .where(AUTHOR.NAME.eq("Machado de Assis"))
        .orderBy(BOOK.TITLE)
        .fetch(Records.mapping(TitleAndPrice::new));
```

**The compiler checks the query against the schema**, as the generator last saw it: drop the
`price_cents` column, generate again, and every query naming `BOOK.PRICE_CENTS` stops compiling,
before a test runs and before anybody deploys. Comparing `BOOK.PRICE_CENTS` with a string fails the
same way, because the field knows it holds an `Integer`. And nothing about the SQL is hidden: what
runs is the `SELECT ... JOIN ... WHERE` you can read in the Java, with no fetch plan to infer and no
association waiting to fire a second statement.

It also reaches what JPQL keeps behind native queries. Window functions, common table expressions,
PostgreSQL's `ON CONFLICT` and `RETURNING` are all methods of the same builder.

The costs are in the build and in the licence. The generator needs the schema, so the build needs a
database to read, or the migration scripts lesson 13 introduces, and the generated classes have to
be regenerated whenever the schema changes. And jOOQ's open-source edition, under the Apache 2.0
licence, covers open-source databases such as PostgreSQL and MySQL; Oracle, SQL Server and the other
commercial databases need a paid edition. Spring Boot has a starter for it,
`spring-boot-starter-jooq`, which gives the application a ready `DSLContext`, the `ctx` above.

## MyBatis: SQL in a mapper

**MyBatis** keeps the SQL as text and gives it a home. A **mapper** is a Java interface whose
methods each carry one statement, written in an annotation or in an XML file that sits beside it.
MyBatis implements the interface for you: it binds the method's arguments to the `#{...}`
placeholders and maps each row to the return type. The same query, again a sketch that was not run:

```java
@Mapper
public interface BookMapper {

    @Select("""
            SELECT b.title, b.price_cents
            FROM book b JOIN author a ON a.id = b.author_id
            WHERE a.name = #{name}
            ORDER BY b.title""")
    List<TitleAndPrice> titlesBy(String name);
}
```

Where MyBatis earns its XML is **dynamic SQL**, a statement whose clauses depend on which arguments
arrived. A search with two optional filters is one `<select>` in the mapper's XML file:

```xml
<select id="search" resultType="com.example.look.TitleAndPrice">
  SELECT title, price_cents FROM book
  <where>
    <if test="title != null">title ILIKE '%' || #{title} || '%'</if>
    <if test="maxPrice != null">AND price_cents &lt;= #{maxPrice}</if>
  </where>
  ORDER BY title
</select>
```

`<where>` writes `WHERE` only if a condition survived, and drops the `AND` in front of the second
one when the first did not. Building that statement by joining strings in Java is exactly where the
SQL injection of lesson 9 gets in; here every value still travels through `#{...}`, a bound
parameter.

The cost is that the SQL is a string again. A misspelt column is found when the statement first
runs, and an XML file and an interface have to agree on names that no compiler compares. The mapping
is also yours to configure: MyBatis's `mapUnderscoreToCamelCase` setting is what turns `price_cents`
into `priceCents`. You meet MyBatis in long-lived enterprise systems, in Spring Boot through
`mybatis-spring-boot-starter` (published by the MyBatis project, not by Spring), and all over
China's Java ecosystem, where **MyBatis-Plus** builds on it.
