package com.example.bookshop.catalogue;

public record BookResponse(long id, String isbn, String title, String author, int priceCents) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.getId(), book.getIsbn(), book.getTitle(),
                book.getAuthor().getName(), book.getPriceCents());
    }
}
