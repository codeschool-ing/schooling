package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface BookRepository extends JpaRepository<Book, Long> {

    Optional<Book> findByIsbn(String isbn);

    @EntityGraph(attributePaths = "author")
    Page<Book> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = "author")
    List<Book> findByTitleContainingIgnoreCaseOrderByTitle(String text);

    @Query("select b.title as title, b.priceCents as priceCents from Book b where b.author.name = :name order by b.title")
    List<TitleAndPrice> findTitlesByAuthor(String name);
}
