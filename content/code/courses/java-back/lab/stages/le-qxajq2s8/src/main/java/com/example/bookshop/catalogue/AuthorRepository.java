package com.example.bookshop.catalogue;

import java.util.Optional;

public interface AuthorRepository {

    Optional<Author> findByName(String name);

    Author save(Author author);
}
