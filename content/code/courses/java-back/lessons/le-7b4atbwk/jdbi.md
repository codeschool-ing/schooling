---
title: JDBI against the bookshop, and choosing
version: 1
---

**JDBI** is the thinnest library in this lesson: JDBC with the ceremony taken out. It opens and closes
connections for you, binds named parameters and maps rows to objects, and that is all. There are no
entities, no generated code and nothing remembered between one call and the next. It sits close to
the `JdbcClient` of lesson 9, and the difference that matters is that JDBI needs no Spring to run.

This section runs it against the `bookshop` database as lesson 11 left it, with the authors and books
that `data.sql` puts there. The bookshop itself does not have to be running; PostgreSQL does.

## A project of its own

JDBI gets a small project beside the bookshop, so that nothing in `~/bookshop` changes. Create its
directories:

TRANSCRIPT-MKDIR

`~/jdbi-look/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>jdbi-look</artifactId>
  <version>0.1.0</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jdbi</groupId>
      <artifactId>jdbi3-core</artifactId>
      <version>3.55.0</version>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <version>42.7.13</version>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-nop</artifactId>
      <version>2.0.17</version>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-resources-plugin</artifactId>
        <version>3.5.0</version>
      </plugin>
      <plugin>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.15.0</version>
      </plugin>
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.10.0</version>
      </plugin>
    </plugins>
  </build>
</project>
```

Three dependencies, and the last two are there to be run, not compiled against, which is what
`runtime` scope says. `jdbi3-core` is the library. The driver is PostgreSQL's JDBC driver, at the
version the bookshop's parent picks. And `slf4j-nop` is a decision about logging: JDBI logs through
SLF4J, the facade lesson 16 is about, and with no logging library behind it SLF4J prints three lines
of warning on every run. `slf4j-nop` tells it to discard the log on purpose. The three plugins are
pinned for the reason lesson 1 gave.

`~/jdbi-look/src/main/java/com/example/look/Titles.java`, the titles and prices of one author's books:

```schooling-example
{
 "language": "java",
 "file": "Titles.java",
 "parts": [
  {
   "code": "package com.example.look;\n\nimport java.util.List;\n\nimport org.jdbi.v3.core.Jdbi;\nimport org.jdbi.v3.core.mapper.reflect.ConstructorMapper;\n\npublic class Titles {\n",
   "note": "Two classes from JDBI's core: `Jdbi`, where everything starts, and a mapper that builds an object through its constructor."
  },
  {
   "code": "    public record TitleAndPrice(String title, int priceCents) {\n    }\n",
   "note": "One row's shape. Lesson 11 declared `TitleAndPrice` as an interface projection; here it is a plain record."
  },
  {
   "code": "    public static void main(String[] args) {\n        Jdbi jdbi = Jdbi.create(\"jdbc:postgresql://localhost:5432/bookshop\", \"bookshop\", \"bookshop\");\n",
   "note": "The URL, user and password of the bookshop's `application.properties`. Creating a `Jdbi` opens no connection yet."
  },
  {
   "code": "        List<TitleAndPrice> books = jdbi.withHandle(handle -> handle\n                .createQuery(\"\"\"\n                        SELECT b.title, b.price_cents\n                        FROM book b JOIN author a ON a.id = b.author_id\n                        WHERE a.name = :name\n                        ORDER BY b.title\"\"\")",
   "note": "`withHandle` opens a connection, wraps it in a **handle**, runs the lambda and closes it whatever happens. The SQL is a text block, exactly what PostgreSQL will receive, with one named parameter, `:name`."
  },
  {
   "code": "                .bind(\"name\", args[0])",
   "note": "The first argument on the command line fills `:name`. It travels as a bound parameter, apart from the SQL, like the `?` of lesson 9's `PreparedStatement`."
  },
  {
   "code": "                .map(ConstructorMapper.of(TitleAndPrice.class))\n                .list());\n",
   "note": "Columns are matched to the record's components by name, and `price_cents` is read as `priceCents`. `list()` runs the query and collects every row."
  },
  {
   "code": "        books.forEach(System.out::println);\n    }\n}",
   "note": "A record prints its own components, which is all this look needs."
  }
 ]
}
```

## Running it

A program with dependencies needs them on its classpath, and lesson 1 showed how to ask Maven for one.
`compile` builds the class, and `dependency:build-classpath` writes the path of every jar it needs
into `cp.txt`. The first run downloads JDBI; `-q` keeps that quiet.

TRANSCRIPT-RUN

The classpath is the measure of how thin JDBI is. Apart from the driver and the logging pair, it is
`jdbi3-core` and two small jars it depends on. **The program is JDBC with the plumbing done for you**:
one connection, one prepared statement with one bound parameter, rows turned into records, everything
closed.

## A mistake, and when it surfaces

The SQL is a string, and it is worth seeing what that costs. As a detour, change `b.price_cents` to
`b.price` in the `SELECT` line of `Titles.java`, and compile and run again:

TRANSCRIPT-TYPO

The compile printed nothing, because to javac a SQL string is a string like any other. The mistake
surfaced when PostgreSQL read the statement, at run time, which for a real application means in front
of whoever made the request. `head -n 3` cut the stack trace below it. Put `b.price_cents` back before
moving on.

That is the same for every library whose SQL is text: `JdbcClient`, JDBI and MyBatis. The other
columns of this lesson's figure catch it earlier. **jOOQ and EBean's query beans catch it at compile
time**, because the column or property is a field of a generated class. Spring Data JPA sits between
the two: it checks the JPQL of every `@Query` and the property names of every derived query when the
application starts, so a typo there stops the start-up rather than a request. A native query is plain
SQL, and Spring Data passes it through unchecked.

## Choosing

| what the team wants | where to look |
|---|---|
| objects, tracked changes, and the largest ecosystem | JPA with Hibernate, through Spring Data JPA (lessons 10 and 11) |
| an ORM, without a persistence context to outlive | EBean |
| the database's full SQL, checked by the compiler | jOOQ |
| SQL kept as text, apart from the Java, built dynamically | MyBatis |
| a thin layer over JDBC, inside Spring | `JdbcClient` (lesson 9), or Spring Data JDBC |
| a thin layer over JDBC, without Spring | JDBI |

**The choice is not exclusive.** All of these end in the same JDBC calls, so one Spring Boot
application can keep Spring Data JPA for its entities and write the one heavy report with `JdbcClient`
or jOOQ beside it. Both use the same `DataSource` and join the same transactions, which lesson 14
looks at closely. Replacing JPA because one query is awkward in it trades a cost the team knows for
one it does not; adding a second tool for that query does not.
