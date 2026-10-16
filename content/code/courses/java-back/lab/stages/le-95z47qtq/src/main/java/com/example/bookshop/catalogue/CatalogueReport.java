package com.example.bookshop.catalogue;

import java.time.Clock;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class CatalogueReport implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(CatalogueReport.class);

    private final BookService books;
    private final Clock clock;

    public CatalogueReport(BookService books, Clock clock) {
        this.books = books;
        this.clock = clock;
    }

    @Override
    public void run(String... args) {
        log.info("Catalogue opened on {} with {} books",
                LocalDateTime.now(clock).toLocalDate(), books.count());
    }
}
