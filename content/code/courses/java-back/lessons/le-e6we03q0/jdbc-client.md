---
title: JdbcClient
version: 1
---

DRAFT

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcBookRepository implements BookRepository {

    private static final String COLUMNS = "SELECT id, isbn, title, author, price_cents FROM book";

    private final JdbcClient jdbc;

    public JdbcBookRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<Book> findAll() {
        return jdbc.sql(COLUMNS + " ORDER BY id").query(Book.class).list();
    }

    @Override
    public Optional<Book> findById(long id) {
        return jdbc.sql(COLUMNS + " WHERE id = ?").param(id).query(Book.class).optional();
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return jdbc.sql(COLUMNS + " WHERE isbn = ?").param(isbn).query(Book.class).optional();
    }

    @Override
    public Book save(Book book) {
        long id = jdbc.sql("""
                INSERT INTO book (isbn, title, author, price_cents)
                VALUES (:isbn, :title, :author, :priceCents)
                RETURNING id""")
                .paramSource(book)
                .query(Long.class)
                .single();
        return book.withId(id);
    }
}
```
