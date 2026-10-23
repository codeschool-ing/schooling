package com.example.bookshop.catalogue;

public class DuplicateIsbnException extends RuntimeException {

    public DuplicateIsbnException(String isbn) {
        super("A book with ISBN " + isbn + " is already in the catalogue");
    }
}
