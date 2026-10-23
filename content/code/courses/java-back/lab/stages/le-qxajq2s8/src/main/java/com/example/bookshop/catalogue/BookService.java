package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BookService {

    private final BookRepository books;
    private final AuthorRepository authors;

    public BookService(BookRepository books, AuthorRepository authors) {
        this.books = books;
        this.authors = authors;
    }

    @Transactional(readOnly = true)
    public List<BookResponse> list() {
        return books.findAll().stream().map(BookResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public BookResponse get(long id) {
        return books.findById(id).map(BookResponse::from).orElseThrow(() -> new BookNotFoundException(id));
    }

    @Transactional
    public BookResponse add(BookRequest request) {
        if (books.findByIsbn(request.isbn()).isPresent()) {
            throw new DuplicateIsbnException(request.isbn());
        }
        Author author = authors.findByName(request.author())
                .orElseGet(() -> authors.save(new Author(request.author())));
        Book book = books.save(new Book(request.isbn(), request.title(), author, request.priceCents()));
        return BookResponse.from(book);
    }
}
