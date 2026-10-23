package com.example.bookshop.ordering;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;

import org.junit.jupiter.api.Test;

import com.example.bookshop.catalogue.Author;
import com.example.bookshop.catalogue.Book;

class OrderTest {

    private final Author machado = new Author("Machado de Assis");

    @Test
    void totalIsTheSumOfQuantityTimesPrice() {
        Order order = new Order("ana", Instant.parse("2026-10-16T12:00:00Z"));
        order.add(new Book("9786500000016", "Dom Casmurro", machado, 3990, 5), 2);
        order.add(new Book("9786500000054", "Quincas Borba", machado, 3690, 5), 1);

        assertThat(order.totalCents()).isEqualTo(11670);
        assertThat(order.getLines()).extracting(OrderLine::getQuantity).containsExactly(2, 1);
    }

    @Test
    void anEmptyOrderCostsNothing() {
        assertThat(new Order("ana", Instant.EPOCH).totalCents()).isZero();
    }
}
