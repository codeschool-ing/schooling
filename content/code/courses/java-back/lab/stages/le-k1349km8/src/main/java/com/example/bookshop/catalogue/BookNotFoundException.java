package com.example.bookshop.catalogue;

public class BookNotFoundException extends RuntimeException {

    public BookNotFoundException(long id) {
        super("No book has id " + id);
    }
}
