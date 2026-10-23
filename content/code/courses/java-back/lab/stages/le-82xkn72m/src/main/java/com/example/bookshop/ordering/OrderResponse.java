package com.example.bookshop.ordering;

import java.time.Instant;
import java.util.List;

public record OrderResponse(long id, String customer, Instant placedAt, List<Line> lines, int totalCents) {

    public record Line(long bookId, String title, int quantity, int priceCents) {
    }

    public static OrderResponse from(Order order) {
        List<Line> lines = order.getLines().stream()
                .map(l -> new Line(l.getBook().getId(), l.getBook().getTitle(), l.getQuantity(), l.getPriceCents()))
                .toList();
        return new OrderResponse(order.getId(), order.getCustomer(), order.getPlacedAt(), lines, order.totalCents());
    }
}
