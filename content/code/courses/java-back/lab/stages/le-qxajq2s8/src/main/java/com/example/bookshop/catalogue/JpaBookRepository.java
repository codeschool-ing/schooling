package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import jakarta.persistence.EntityManager;

import org.springframework.stereotype.Repository;

@Repository
public class JpaBookRepository implements BookRepository {

    private final EntityManager em;

    public JpaBookRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public List<Book> findAll() {
        return em.createQuery("select b from Book b join fetch b.author order by b.id", Book.class)
                .getResultList();
    }

    @Override
    public Optional<Book> findById(long id) {
        return Optional.ofNullable(em.find(Book.class, id));
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return em.createQuery("select b from Book b where b.isbn = :isbn", Book.class)
                .setParameter("isbn", isbn)
                .getResultStream()
                .findFirst();
    }

    @Override
    public Book save(Book book) {
        em.persist(book);
        return book;
    }
}
