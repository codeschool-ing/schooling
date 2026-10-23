package com.example.bookshop.ordering;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;

import com.example.bookshop.catalogue.Book;

@Entity
@Table(name = "customer_order")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String customer;

    private Instant placedAt;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
    @OrderBy("id")
    private List<OrderLine> lines = new ArrayList<>();

    protected Order() {
    }

    public Order(String customer, Instant placedAt) {
        this.customer = customer;
        this.placedAt = placedAt;
    }

    public void add(Book book, int quantity) {
        lines.add(new OrderLine(this, book, quantity, book.getPriceCents()));
    }

    public int totalCents() {
        return lines.stream().mapToInt(OrderLine::totalCents).sum();
    }

    public Long getId() {
        return id;
    }

    public String getCustomer() {
        return customer;
    }

    public Instant getPlacedAt() {
        return placedAt;
    }

    public List<OrderLine> getLines() {
        return lines;
    }
}
