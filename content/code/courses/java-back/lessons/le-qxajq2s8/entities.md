---
title: Entities
version: 1
---

An **entity** is a class whose objects are rows. You mark it, say which field is the key and how it
relates to other entities, and Hibernate works out the rest from the fields themselves. The bookshop
has two: `Author`, and `Book`, which points at it.

Lesson 5 made `Book` a record, and it cannot stay one. A record is final, has no constructor without
arguments and never changes, and the mapper needs the opposite of each: it generates subclasses of
entities for its proxies, creates an empty object, fills its fields from a row, and later notices when
one of them has changed. So both entities are ordinary classes. Create
`src/main/java/com/example/bookshop/catalogue/Author.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    protected Author() {
    }

    public Author(String name) {
        this.name = name;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }
}
```

Then replace `Book.java` in the same directory. Each piece is explained beside it:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport jakarta.persistence.Column;\nimport jakarta.persistence.Entity;\nimport jakarta.persistence.FetchType;\nimport jakarta.persistence.GeneratedValue;\nimport jakarta.persistence.GenerationType;\nimport jakarta.persistence.Id;\nimport jakarta.persistence.ManyToOne;\n",
      "note": "Every annotation comes from `jakarta.persistence`, the specification. Nothing here names Hibernate."
    },
    {
      "code": "@Entity\npublic class Book {\n",
      "note": "`@Entity` tells the mapper this class is stored in a table. With no `@Table`, the table is named after the class: `book`. It is a class, not a record, because the mapper creates the object empty and fills its fields afterwards."
    },
    {
      "code": "    @Id\n    @GeneratedValue(strategy = GenerationType.IDENTITY)\n    private Long id;\n",
      "note": "`@Id` marks the primary key, and the field's position decides that Hibernate reads and writes FIELDS directly, so no setters are needed. `IDENTITY` says the database invents the number, which is what `bigserial` does. A `Long` rather than a `long`, because a book not yet saved has no id at all, and `null` says so."
    },
    {
      "code": "    private String isbn;\n\n    private String title;\n",
      "note": "Plain fields need no annotation: every field of an entity is a column unless it is marked otherwise. `isbn` maps to `isbn`, `title` to `title`."
    },
    {
      "code": "    @ManyToOne(fetch = FetchType.LAZY, optional = false)\n    private Author author;\n",
      "note": "The relationship. Many books, one author: the column is `author_id`, the field name plus the key it points at. `LAZY` means loading a book does not load its author; `optional = false` matches the `NOT NULL` in the table."
    },
    {
      "code": "    @Column(name = \"price_cents\")\n    private int priceCents;\n",
      "note": "Spring Boot's naming strategy would turn `priceCents` into `price_cents` on its own. The annotation writes it where a reader of this file can see it."
    },
    {
      "code": "    protected Book() {\n    }\n",
      "note": "Hibernate needs a constructor with no arguments to create the empty object it then fills. `protected` lets it in and keeps everybody else out, so application code cannot build a book with no title."
    },
    {
      "code": "    public Book(String isbn, String title, Author author, int priceCents) {\n        this.isbn = isbn;\n        this.title = title;\n        this.author = author;\n        this.priceCents = priceCents;\n    }\n",
      "note": "The constructor application code uses. It takes no id: the database assigns one when the book is inserted."
    },
    {
      "code": "    public Long getId() {\n        return id;\n    }\n\n    public String getIsbn() {\n        return isbn;\n    }\n\n    public String getTitle() {\n        return title;\n    }\n\n    public Author getAuthor() {\n        return author;\n    }\n\n    public int getPriceCents() {\n        return priceCents;\n    }\n}",
      "note": "Getters only. Nothing outside the class changes a book, which keeps every change in this file."
    }
  ]
}
```

## Lazy, and why that is not the default

The relationship deserves a second look, because it decides how many queries every screen of the
application will cost. `@ManyToOne` on its own means `EAGER`: JPA's default for a single reference
is to load it together with the object that holds it. That sounds helpful and is a trap. Every book
loaded anywhere would bring its author along, in every query, whether the code reading it ever asks
for the name or not.

**`LAZY` turns the default round.** A book is loaded alone, and its `author` field holds a
**proxy**: an object of a subclass Hibernate generated, which knows the author's id and nothing
else. The first time code calls a method on it that needs data, such as `getName()`, the proxy asks
the database for the row.

That one decision is behind the two problems in the rest of this lesson. A proxy that loads itself
is a query nobody wrote, which is where the N+1 problem comes from. And a proxy that tries to load
itself after its connection to the database is gone throws instead, which is the last section.

## What is not here

There is no `@Table`, no `@Column` on `isbn` or `title`, and no list of books on `Author`. Both were
left out on purpose.

- The table and column names follow from the class and field names, so writing them out would only
  give two places to change on a rename. `price_cents` is the one exception, and its note says why.
- An author could hold `@OneToMany(mappedBy = "author") List<Book> books`, the other side of the
  same relationship. Nothing in the application needs to go from an author to its books yet, and a
  collection that nobody reads is one more thing that can be loaded by accident. Lesson 11 comes
  back to relationships.
