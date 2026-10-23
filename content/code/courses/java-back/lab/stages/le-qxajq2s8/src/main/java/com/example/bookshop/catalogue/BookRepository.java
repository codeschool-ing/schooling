package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

public interface BookRepository {

    List<Book> findAll();

    Optional<Book> findById(long id);

    Optional<Book> findByIsbn(String isbn);

    Book save(Book book);
}
