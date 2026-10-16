package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Repository;

@Repository
public class InMemoryBookRepository implements BookRepository {

    private final Map<Long, Book> books = new ConcurrentSkipListMap<>();
    private final AtomicLong nextId = new AtomicLong(1);

    public InMemoryBookRepository() {
        save(new Book(0, "9786500000016", "Dom Casmurro", "Machado de Assis", 3990));
        save(new Book(0, "9786500000023", "The Time Machine", "H. G. Wells", 2950));
        save(new Book(0, "9786500000030", "Frankenstein", "Mary Shelley", 3500));
    }

    @Override
    public List<Book> findAll() {
        return List.copyOf(books.values());
    }

    @Override
    public Optional<Book> findById(long id) {
        return Optional.ofNullable(books.get(id));
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return books.values().stream().filter(b -> b.isbn().equals(isbn)).findFirst();
    }

    @Override
    public Book save(Book book) {
        Book stored = book.id() == 0 ? book.withId(nextId.getAndIncrement()) : book;
        books.put(stored.id(), stored);
        return stored;
    }
}
