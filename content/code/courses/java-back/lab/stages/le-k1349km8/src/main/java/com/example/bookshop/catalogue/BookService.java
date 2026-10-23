package com.example.bookshop.catalogue;

import java.util.List;

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

    public Book get(long id) {
        return books.findById(id).orElseThrow(() -> new BookNotFoundException(id));
    }

    public Book add(String isbn, String title, String author, int priceCents) {
        if (books.findByIsbn(isbn).isPresent()) {
            throw new DuplicateIsbnException(isbn);
        }
        return books.save(new Book(0, isbn, title, author, priceCents));
    }
}
