---
title: The bookshop gets a database
version: 1
---

Now the same work inside the bookshop. The project starts as lesson 7 left it, and the change is
smaller than it looks, because lesson 5 put the catalogue behind an interface: `BookService` asks a
`BookRepository` and does not know what is behind it. This lesson swaps what is behind it and
leaves everything above untouched.

## The dependencies

Replace `pom.xml` with this. Two dependencies are new, at the end of the list:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-jdbc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

**`spring-boot-starter-jdbc`** brings Spring's JDBC support and a connection pool. The
**`postgresql`** driver has `runtime` scope: the code compiles against `java.sql` only and never
names a PostgreSQL class, so the driver is needed when the application runs and not when it
compiles. Neither line has a version; the parent manages both. Build, and ask Maven what arrived:

```
ana@vm:~/bookshop$ mvn -q package
```

`grep` keeps the five lines that matter out of the whole tree, and the first command is the one
deletion in this lesson, explained in the next section. The driver is the same 42.7.13 that
`Jdbc.java` used. Under the starter are `spring-jdbc`, Spring Framework's JDBC support, and
**HikariCP**, the pool.

## Where the database is

Replace `src/main/resources/application.properties` with this:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.sql.init.mode=always
```

The three `spring.datasource` lines are the URL, user and password that `Jdbc.java` passed to
`DriverManager`, moved into configuration. Lesson 4 showed that a command-line argument overrides a
line in this file, and the last section of this lesson uses exactly that to break each one on
purpose.

## The schema and the first rows

Spring Boot looks for two scripts on the class path and runs them against the database at start-up:
`schema.sql` first, then `data.sql`. Create `src/main/resources/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author      text      NOT NULL,
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

and `src/main/resources/data.sql`:

```sql
INSERT INTO book (isbn, title, author, price_cents) VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000030', 'Frankenstein', 'Mary Shelley', 3500)
ON CONFLICT (isbn) DO NOTHING;
```

By default Boot runs them only for an **embedded** database, one that lives inside the JVM and
starts empty every time. PostgreSQL is a real server, so `spring.sql.init.mode=always` asks for them
on every start. Both are written to be run again and again: `CREATE TABLE IF NOT EXISTS` leaves an
existing table alone, and `ON CONFLICT (isbn) DO NOTHING` skips any row whose ISBN the `UNIQUE`
rule already holds. Running them on every start is a stopgap, and lesson 13 explains why it stops
working and replaces both files with migrations.

The table you made by hand in `psql` has the same columns, but it holds Wise Blood and The War of
the Worlds, which `data.sql` does not. Drop it, so that what you see next is what the application
builds from nothing:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'DROP TABLE book'
DROP TABLE
```

## Starting it

Start the application in a second terminal, with `java -jar target/bookshop-0.1.0.jar` in
`~/bookshop`:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-16T20:22:50.210-03:00  INFO 7072 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 7072 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-16T20:22:50.213-03:00  INFO 7072 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-16T20:22:51.560-03:00  INFO 7072 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-16T20:22:51.575-03:00  INFO 7072 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-16T20:22:51.575-03:00  INFO 7072 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-16T20:22:51.597-03:00  INFO 7072 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1262 ms
2026-10-16T20:22:51.706-03:00  INFO 7072 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2026-10-16T20:22:52.106-03:00  INFO 7072 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@de7e193
2026-10-16T20:22:52.107-03:00  INFO 7072 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2026-10-16T20:22:52.607-03:00  INFO 7072 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-16T20:22:52.627-03:00  INFO 7072 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 2.915 seconds (process running for 3.423)
2026-10-16T20:22:52.654-03:00  INFO 7072 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-16 with 3 books
```

Three new lines, between Tomcat and `Started`, are the pool. `HikariPool-1 - Starting...`, then
`Added connection` with the driver's `PgConnection`, then `Start completed`: Boot saw a JDBC driver
and three `spring.datasource` properties, built a **`DataSource`** from them, and the first
connection it opened ran `schema.sql` and `data.sql`. The last line is lesson 5's `CatalogueReport`,
and its 3 books now come from a `SELECT`.

A `DataSource` is JDBC's other way to get a connection, an interface in `javax.sql` with one job,
`getConnection()`. Boot's is a **connection pool**: it opens connections ahead of time and lends
them out, and when code calls `close()` on one, the connection goes back to the pool instead of
being closed. That answers the cost at the end of the plain-JDBC section. Ask the server who is
connected while the application runs:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c "SELECT application_name, state, count(*) FROM pg_stat_activity WHERE usename = 'bookshop' GROUP BY 1, 2"
    application_name    | state  | count 
------------------------+--------+-------
 PostgreSQL JDBC Driver | idle   |    10
 psql                   | active |     1
(2 rows)
```

**Ten connections, all `idle`**, opened by the driver for the pool, and the one `active` is `psql`
asking. Ten is HikariCP's default size. A request borrows one for a few milliseconds and gives it
back; lesson 14 measures what happens when they are all borrowed at once, and how to size the pool.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 372\" role=\"img\" aria-label=\"Two programs side by side. On the left, Jdbc.java calls DriverManager, which opens a new connection on every call. On the right, the bookshop's JdbcBookRepository calls Spring's JdbcClient, which borrows connections from a HikariCP pool. Both then go through the same java.sql interfaces and the same PostgreSQL driver jar, over TCP to localhost port 5432, to one PostgreSQL 16 server.\"><defs><marker id=\"jl9-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">this lesson's first program</text><text x=\"525\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bookshop</text><rect x=\"30\" y=\"26\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Jdbc.java</text><text x=\"175\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code</text><rect x=\"30\" y=\"82\" width=\"290\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">DriverManager.getConnection(…)</text><text x=\"175\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new connection on every call</text><rect x=\"380\" y=\"26\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">JdbcBookRepository</text><text x=\"525\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code</text><rect x=\"380\" y=\"82\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">JdbcClient</text><text x=\"525\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Spring: SQL in, records out</text><rect x=\"380\" y=\"134\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HikariDataSource</text><text x=\"525\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Boot's pool of open connections</text><line x1=\"175\" y1=\"70\" x2=\"175\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"70\" x2=\"525\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"126\" x2=\"525\" y2=\"132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"175\" y1=\"178\" x2=\"175\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"178\" x2=\"525\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><rect x=\"30\" y=\"198\" width=\"640\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">java.sql: Connection, PreparedStatement, ResultSet</text><text x=\"350\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">JDBC, the interfaces both programs are written against</text><line x1=\"350\" y1=\"242\" x2=\"350\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><rect x=\"30\" y=\"254\" width=\"640\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">postgresql-42.7.13.jar</text><text x=\"350\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the driver: JDBC calls turned into PostgreSQL's protocol</text><line x1=\"350\" y1=\"298\" x2=\"350\" y2=\"324\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><text x=\"360\" y=\"311\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">TCP, localhost:5432</text><rect x=\"30\" y=\"326\" width=\"640\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL 16 server</text></svg>", "caption": "Both programs reach PostgreSQL through the same JDBC interfaces and the same driver. JdbcClient and the pool are what Spring adds on top, and they do not replace what is underneath."}
```

The figure is the whole stack at once. Everything under `JdbcClient` is the same JDBC that
`Jdbc.java` called by hand; what Boot added is the pool, and the class that writes the repetitive
part for you, which the next section reads.
