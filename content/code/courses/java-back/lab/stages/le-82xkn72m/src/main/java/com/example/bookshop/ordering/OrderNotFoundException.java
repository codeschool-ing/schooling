package com.example.bookshop.ordering;

public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(long id) {
        super("No order has id " + id);
    }
}
