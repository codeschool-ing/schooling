package com.example.bookshop.catalogue;

import java.util.Optional;

import jakarta.persistence.EntityManager;

import org.springframework.stereotype.Repository;

@Repository
public class JpaAuthorRepository implements AuthorRepository {

    private final EntityManager em;

    public JpaAuthorRepository(EntityManager em) {
        this.em = em;
    }

    @Override
    public Optional<Author> findByName(String name) {
        return em.createQuery("select a from Author a where a.name = :name", Author.class)
                .setParameter("name", name)
                .getResultStream()
                .findFirst();
    }

    @Override
    public Author save(Author author) {
        em.persist(author);
        return author;
    }
}
