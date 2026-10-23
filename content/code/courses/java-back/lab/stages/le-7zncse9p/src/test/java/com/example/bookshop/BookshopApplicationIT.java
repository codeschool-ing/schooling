package com.example.bookshop;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

import com.example.bookshop.catalogue.BookService;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class BookshopApplicationIT {

    @Autowired
    BookService books;

    @Test
    void startsAgainstARealDatabaseWithTheMigrationsApplied() {
        assertThat(books.count()).isEqualTo(6);
    }
}
