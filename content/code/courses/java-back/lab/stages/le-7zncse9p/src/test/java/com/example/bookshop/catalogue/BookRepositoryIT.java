package com.example.bookshop.catalogue;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@DataJpaTest
@Testcontainers
class BookRepositoryIT {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    BookRepository books;

    @Test
    void findsTitlesByAuthorInTitleOrder() {
        assertThat(books.findTitlesByAuthor("H. G. Wells"))
                .extracting(TitleAndPrice::getTitle)
                .containsExactly("The Time Machine", "The War of the Worlds");
    }

    @Test
    void searchIgnoresCase() {
        assertThat(books.findByTitleContainingIgnoreCaseOrderByTitle("BORBA"))
                .extracting(Book::getIsbn)
                .containsExactly("9786500000054");
    }
}
