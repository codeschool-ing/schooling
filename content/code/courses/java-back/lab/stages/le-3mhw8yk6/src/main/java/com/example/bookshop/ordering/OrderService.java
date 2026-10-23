package com.example.bookshop.ordering;

import java.time.Clock;
import java.time.temporal.ChronoUnit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.bookshop.catalogue.Book;
import com.example.bookshop.catalogue.BookNotFoundException;
import com.example.bookshop.catalogue.BookRepository;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    private final BookRepository books;
    private final OrderRepository orders;
    private final Clock clock;

    public OrderService(BookRepository books, OrderRepository orders, Clock clock) {
        this.books = books;
        this.orders = orders;
        this.clock = clock;
    }

    @Transactional
    public OrderResponse place(String customer, OrderRequest request) {
        Order order = new Order(customer, clock.instant().truncatedTo(ChronoUnit.SECONDS));
        for (OrderRequest.Line line : request.lines()) {
            Book book = books.findByIdForUpdate(line.bookId())
                    .orElseThrow(() -> new BookNotFoundException(line.bookId()));
            book.take(line.quantity());
            order.add(book, line.quantity());
        }
        Order saved = orders.save(order);
        log.info("Order {} placed by {}: {} line(s), {} cents",
                saved.getId(), customer, saved.getLines().size(), saved.totalCents());
        return OrderResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public OrderResponse get(long id, String customer) {
        return orders.findWithLinesById(id)
                .filter(order -> order.getCustomer().equals(customer))
                .map(OrderResponse::from)
                .orElseThrow(() -> new OrderNotFoundException(id));
    }
}
