package com.example.bookshop.catalogue;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

class IsbnTest {

    @ParameterizedTest
    @ValueSource(strings = {"9786500000016", "9786500000023", "9780306406157"})
    void acceptsAValidIsbn13(String isbn) {
        assertTrue(Isbn.isValid(isbn));
    }

    @ParameterizedTest(name = "{1}: {0}")
    @CsvSource({
            "9786500000017, wrong check digit",
            "978650000001, twelve digits",
            "97865000000160, fourteen digits",
            "978-6500000016, a hyphen",
            "97865000000X6, a letter"
    })
    void refusesAnythingElse(String isbn, String reason) {
        assertFalse(Isbn.isValid(isbn));
    }

    @Test
    void refusesNull() {
        assertFalse(Isbn.isValid(null));
    }
}
