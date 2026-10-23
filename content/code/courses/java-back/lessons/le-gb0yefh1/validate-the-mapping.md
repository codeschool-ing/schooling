---
title: Hibernate checks instead of guessing
version: 1
---

The migrations own the schema now, and Hibernate still has an opinion about it. `ddl-auto` decides what
Hibernate does with that opinion at start-up. `create` and `create-drop` build the schema from the
entities, and `update` alters the schema towards them. `validate` compares the two and refuses to start
if they disagree. `none`, which lessons 10 and 11 used, does nothing at all.

The tempting one is `update`, and the reason it is wrong here is worth knowing. It adds what is missing
and never drops, renames or changes the type of anything, so a renamed field leaves the old column
behind and a widened one is not widened. Worse, the schema becomes whatever the last entity to start
asked for, which is a second author of the schema beside the migrations, and one that records nothing.
**With a migration tool, the migrations write the schema and Hibernate only checks it.** That is
`validate`. Change the second-to-last line of `application.properties`, so that the file reads:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
```

Build and start, with `grep` keeping the one line that says why:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by: org.hibernate'
Caused by: org.hibernate.tool.schema.spi.SchemaManagementException: Schema validation: wrong column type encountered in column [isbn] in table [book]; found [bpchar (Types#CHAR)], but expecting [varchar(255) (Types#VARCHAR)]
```

Read it from the end. Hibernate expected `varchar(255)`, which is what it maps a `String` field to when
nothing says otherwise, and found `bpchar`, PostgreSQL's internal name for `char(n)`, the blank-padded
fixed-length type that `isbn char(13)` declares. **This mismatch has been there since lesson 10.** Under
`none` nobody compared the two, and `validate` is the first setting that looked.

There are two ways to make them agree: change the column with a new migration, or tell Hibernate the
truth about the column. The column is right, since an ISBN-13 is always thirteen characters, so the
mapping changes. In `src/main/java/com/example/bookshop/catalogue/Book.java`, the `isbn` field gains
two annotations, and two imports come with them:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport jakarta.persistence.Column;\nimport jakarta.persistence.Entity;\nimport jakarta.persistence.FetchType;\nimport jakarta.persistence.GeneratedValue;\nimport jakarta.persistence.GenerationType;\nimport jakarta.persistence.Id;\nimport jakarta.persistence.ManyToOne;\n"
    },
    {
      "code": "import org.hibernate.annotations.JdbcTypeCode;\nimport org.hibernate.type.SqlTypes;\n",
      "note": "**Two imports from Hibernate itself**, not from `jakarta.persistence`. The JPA standard has no way to say which JDBC type a column is, so this mapping is Hibernate's own."
    },
    {
      "code": "@Entity\npublic class Book {\n\n    @Id\n    @GeneratedValue(strategy = GenerationType.IDENTITY)\n    private Long id;\n"
    },
    {
      "code": "    @JdbcTypeCode(SqlTypes.CHAR)\n    @Column(length = 13)\n    private String isbn;\n",
      "note": "**The whole fix.** `@JdbcTypeCode(SqlTypes.CHAR)` says the column is a fixed-length `char`, and `@Column(length = 13)` gives it the length the migration gave it. The field is still a `String`; only Hibernate's idea of the column changed."
    },
    {
      "code": "    private String title;\n\n    @ManyToOne(fetch = FetchType.LAZY, optional = false)\n    private Author author;\n\n    @Column(name = \"price_cents\")\n    private int priceCents;\n\n    protected Book() {\n    }\n\n    public Book(String isbn, String title, Author author, int priceCents) {\n        this.isbn = isbn;\n        this.title = title;\n        this.author = author;\n        this.priceCents = priceCents;\n    }\n\n    public Long getId() {\n        return id;\n    }\n\n    public String getIsbn() {\n        return isbn;\n    }\n\n    public String getTitle() {\n        return title;\n    }\n\n    public Author getAuthor() {\n        return author;\n    }\n\n    public int getPriceCents() {\n        return priceCents;\n    }\n}",
      "note": "The rest of the entity is lesson 10's, unchanged."
    }
  ]
}
```

Build and start once more. This time it is the whole log, as the second terminal shows it:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v4.1.1)

2026-10-22T19:29:54.835-03:00  INFO 16475 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Starting BookshopApplication v0.1.0 using Java 25.0.4.1 with PID 16475 (/home/ana/bookshop/target/bookshop-0.1.0.jar started by ana in /home/ana/bookshop)
2026-10-22T19:29:54.838-03:00  INFO 16475 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : No active profile set, falling back to 1 default profile: "default"
2026-10-22T19:29:55.543-03:00  INFO 16475 --- [bookshop] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2026-10-22T19:29:55.583-03:00  INFO 16475 --- [bookshop] [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 32 ms. Found 2 JPA repository interfaces.
2026-10-22T19:29:55.972-03:00  INFO 16475 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat initialized with port 8080 (http)
2026-10-22T19:29:55.983-03:00  INFO 16475 --- [bookshop] [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2026-10-22T19:29:55.983-03:00  INFO 16475 --- [bookshop] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/11.0.24]
2026-10-22T19:29:56.002-03:00  INFO 16475 --- [bookshop] [           main] b.w.c.s.WebApplicationContextInitializer : Root WebApplicationContext: initialization completed in 1128 ms
2026-10-22T19:29:56.232-03:00  INFO 16475 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2026-10-22T19:29:56.512-03:00  INFO 16475 --- [bookshop] [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection@3b0d3a63
2026-10-22T19:29:56.513-03:00  INFO 16475 --- [bookshop] [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2026-10-22T19:29:56.530-03:00  INFO 16475 --- [bookshop] [           main] org.flywaydb.core.FlywayExecutor         : Database: jdbc:postgresql://localhost:5432/bookshop (PostgreSQL 16.15)
2026-10-22T19:29:56.583-03:00  INFO 16475 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.017s)
2026-10-22T19:29:56.624-03:00  INFO 16475 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:29:56.627-03:00  INFO 16475 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
2026-10-22T19:29:56.707-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.jpa                    : HHH008540: Processing PersistenceUnitInfo [name: default]
2026-10-22T19:29:56.749-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.core                   : HHH000001: Hibernate ORM core version 7.4.5.Final
2026-10-22T19:29:57.082-03:00  INFO 16475 --- [bookshop] [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2026-10-22T19:29:57.151-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Database info:
	Database JDBC URL [jdbc:postgresql://localhost:5432/bookshop]
	Database driver: PostgreSQL JDBC Driver
	Database dialect: PostgreSQLDialect
	Database version: 16.15
	Default catalog/schema: bookshop/public
	Autocommit mode: undefined/unknown
	Isolation level: READ_COMMITTED [default READ_COMMITTED]
	JDBC fetch size: none
	Pool: DataSourceConnectionProvider
	Minimum pool size: undefined/unknown
	Maximum pool size: undefined/unknown
2026-10-22T19:29:57.821-03:00  INFO 16475 --- [bookshop] [           main] org.hibernate.orm.core                   : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2026-10-22T19:29:57.854-03:00  INFO 16475 --- [bookshop] [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2026-10-22T19:29:57.931-03:00  INFO 16475 --- [bookshop] [           main] o.s.d.j.r.query.QueryEnhancerFactories   : Hibernate is in classpath; If applicable, HQL parser will be used.
2026-10-22T19:29:58.663-03:00  INFO 16475 --- [bookshop] [           main] o.s.boot.tomcat.TomcatWebServer          : Tomcat started on port 8080 (http) with context path '/'
2026-10-22T19:29:58.675-03:00  INFO 16475 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 4.145 seconds (process running for 4.49)
2026-10-22T19:29:58.776-03:00  INFO 16475 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

Flyway validated its two migrations, found the schema already at version 2 and applied nothing; then
Hibernate built its `EntityManagerFactory`, which is where `validate` ran, and said nothing, which is
what agreement looks like.

Know what that silence covers. `validate` checks that every table and column an entity maps exists,
with a compatible type. It does not check `NOT NULL`, `UNIQUE`, `CHECK` or foreign keys, and it ignores
columns the entities do not map at all. Those belong to the migrations, which is one more reason the
migrations, and not the entities, are the schema's single source.
