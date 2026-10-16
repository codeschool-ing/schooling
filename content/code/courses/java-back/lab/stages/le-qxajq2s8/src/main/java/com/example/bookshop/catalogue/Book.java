package com.example.bookshop.catalogue;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;

@Entity
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String isbn;

    private String title;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Author author;

    @Column(name = "price_cents")
    private int priceCents;

    protected Book() {
    }

    public Book(String isbn, String title, Author author, int priceCents) {
        this.isbn = isbn;
        this.title = title;
        this.author = author;
        this.priceCents = priceCents;
    }

    public Long getId() {
        return id;
    }

    public String getIsbn() {
        return isbn;
    }

    public String getTitle() {
        return title;
    }

    public Author getAuthor() {
        return author;
    }

    public int getPriceCents() {
        return priceCents;
    }
}
