package com.example.bookshop.catalogue;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

class BookTest {

    private Book book;

    @BeforeEach
    void aBookWithTwoCopies() {
        book = new Book("9786500000016", "Dom Casmurro", new Author("Machado de Assis"), 3990, 2);
    }

    @Nested
    @DisplayName("take")
    class Take {

        @Test
        void lowersTheStock() {
            book.take(2);
            assertEquals(0, book.getStock());
        }

        @Test
        void refusesMoreThanThereIs() {
            OutOfStockException e = assertThrows(OutOfStockException.class, () -> book.take(3));
            assertEquals("Only 2 of 'Dom Casmurro' left, 3 wanted", e.getMessage());
        }

        @Test
        void leavesTheStockAloneWhenItRefuses() {
            assertThrows(OutOfStockException.class, () -> book.take(3));
            assertEquals(2, book.getStock());
        }
    }
}
