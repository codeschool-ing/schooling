package com.example.bookshop.catalogue;

public class OutOfStockException extends RuntimeException {

    public OutOfStockException(Book book, int wanted) {
        super("Only " + book.getStock() + " of '" + book.getTitle() + "' left, " + wanted + " wanted");
    }
}
