package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

@Service
public class BookService {

    private final BookRepository books;

    public BookService(BookRepository books) {
        this.books = books;
    }

    public List<Book> list() {
        return books.findAll();
    }

    public Optional<Book> find(long id) {
        return books.findById(id);
    }

    public Book add(String isbn, String title, String author, int priceCents) {
        return books.save(new Book(0, isbn, title, author, priceCents));
    }
}
