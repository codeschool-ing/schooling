package com.example.bookshop.catalogue;

public record Book(long id, String isbn, String title, String author, int priceCents) {

    public Book withId(long newId) {
        return new Book(newId, isbn, title, author, priceCents);
    }
}
