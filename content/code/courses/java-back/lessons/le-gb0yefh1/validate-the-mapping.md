---
title: Hibernate checks instead of guessing
version: 1
---

The migrations own the schema now, and Hibernate still has an opinion about it. `ddl-auto` decides what
Hibernate does with that opinion at start-up, and it has five values: `create` and `create-drop` build the
schema from the entities, `update` alters the schema towards them, `validate` compares the two and
refuses to start if they disagree, and `none`, which lessons 10 and 11 used, does nothing at all.

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
@@validate@@
```

Read it from the end. Hibernate expected `varchar(255)`, which is what it maps a `String` field to when
nothing says otherwise, and found `bpchar`, PostgreSQL's internal name for `char(n)`, the blank-padded
fixed-length type that `isbn char(13)` declares. **This mismatch has been there since lesson 10.** Under
`none` nobody compared the two, and it did no harm only because PostgreSQL converts between the two
types when a query compares them. `validate` is the first setting that looked.

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
@@started@@
```

Flyway validated its two migrations, found the schema already at version 2 and applied nothing; then
Hibernate built its `EntityManagerFactory`, which is where `validate` ran, and said nothing, which is
what agreement looks like.

Know what that silence covers. `validate` checks that every table and column an entity maps exists,
with a compatible type. It does not check `NOT NULL`, `UNIQUE`, `CHECK` or foreign keys, and it ignores
columns the entities do not map at all. Those belong to the migrations, which is one more reason the
migrations, and not the entities, are the schema's single source.
