package com.example.bookshop.ordering;

import java.time.Clock;
import java.time.temporal.ChronoUnit;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.bookshop.catalogue.Book;
import com.example.bookshop.catalogue.BookNotFoundException;
import com.example.bookshop.catalogue.BookRepository;

@Service
public class OrderService {

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
        return OrderResponse.from(orders.save(order));
    }

    @Transactional(readOnly = true)
    public OrderResponse get(long id, String customer) {
        return orders.findWithLinesById(id)
                .filter(order -> order.getCustomer().equals(customer))
                .map(OrderResponse::from)
                .orElseThrow(() -> new OrderNotFoundException(id));
    }
}
