package com.example.isbn;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class IsbnCheckTest {

    @Test
    void acceptsAnIsbn13WithHyphens() {
        assertEquals("valid, ISBN-13 9780306406157", IsbnCheck.verdict("978-0-306-40615-7"));
    }

    @Test
    void convertsAnIsbn10() {
        assertEquals("valid, ISBN-13 9780306406157", IsbnCheck.verdict("0-306-40615-2"));
    }

    @Test
    void refusesAWrongCheckDigit() {
        assertEquals("invalid", IsbnCheck.verdict("978-0-306-40615-8"));
    }
}
