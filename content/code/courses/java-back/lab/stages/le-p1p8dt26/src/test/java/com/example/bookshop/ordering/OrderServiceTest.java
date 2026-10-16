package com.example.bookshop.ordering;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import com.example.bookshop.catalogue.Author;
import com.example.bookshop.catalogue.Book;
import com.example.bookshop.catalogue.BookRepository;
import com.example.bookshop.catalogue.OutOfStockException;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    BookRepository books;

    @Mock
    OrderRepository orders;

    OrderService service;

    Book frankenstein = new Book("9786500000030", "Frankenstein", new Author("Mary Shelley"), 3500, 1);

    @BeforeEach
    void setUp() {
        Clock noon = Clock.fixed(Instant.parse("2026-10-16T15:00:00Z"), ZoneOffset.UTC);
        service = new OrderService(books, orders, noon, new SimpleMeterRegistry());
        ReflectionTestUtils.setField(frankenstein, "id", 3L);
    }

    @Test
    void placingAnOrderTakesTheStockAndSavesTheOrder() {
        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));
        when(orders.save(any(Order.class))).thenAnswer(call -> {
            Order order = call.getArgument(0);
            ReflectionTestUtils.setField(order, "id", 7L);
            return order;
        });

        OrderResponse placed = service.place("ana", new OrderRequest(List.of(new OrderRequest.Line(3L, 1))));

        assertThat(placed.id()).isEqualTo(7);
        assertThat(placed.totalCents()).isEqualTo(3500);
        assertThat(placed.placedAt()).isEqualTo(Instant.parse("2026-10-16T15:00:00Z"));
        assertThat(frankenstein.getStock()).isZero();
    }

    @Test
    void anOrderForMoreThanTheStockIsNeverSaved() {
        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));

        assertThatThrownBy(() -> service.place("ana", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))
                .isInstanceOf(OutOfStockException.class);

        verify(orders, never()).save(any());
    }
}
