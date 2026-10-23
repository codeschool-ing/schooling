package com.example.bookshop.ordering;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;

import com.example.bookshop.catalogue.Book;

@Entity
public class OrderLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Book book;

    private int quantity;

    @Column(name = "price_cents")
    private int priceCents;

    protected OrderLine() {
    }

    OrderLine(Order order, Book book, int quantity, int priceCents) {
        this.order = order;
        this.book = book;
        this.quantity = quantity;
        this.priceCents = priceCents;
    }

    public int totalCents() {
        return quantity * priceCents;
    }

    public Book getBook() {
        return book;
    }

    public int getQuantity() {
        return quantity;
    }

    public int getPriceCents() {
        return priceCents;
    }
}
