package com.example.bookshop.ordering;

import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = {"lines", "lines.book"})
    Optional<Order> findWithLinesById(long id);
}
