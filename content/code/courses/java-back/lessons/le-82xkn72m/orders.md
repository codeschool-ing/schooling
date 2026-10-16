---
title: Orders, and the stock they take
version: 1
---

Until now the bookshop has been a catalogue: books in, books out. This lesson lets somebody buy them,
and buying is the first thing the application does that changes several rows at once and **must never
change only some of them**. An order writes a row in `customer_order`, a row in `order_line` for each book, and takes
the copies out of each book's `stock`. If any step fails, none of them may stay.

This section adds the code. It starts from the bookshop as lesson 13 left it, and every file is given
whole: create the ones that are new and replace the ones that exist. The rest of the lesson is about
the two annotations the code leans on, and what happens without them.

## The migration

Lesson 13 put the schema in Flyway's hands, so a new column and two new tables are a third migration.
Create `src/main/resources/db/migration/V3__stock_and_orders.sql`:

```sql
ALTER TABLE book ADD COLUMN stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0);

UPDATE book SET stock = 5;
UPDATE book SET stock = 1 WHERE isbn = '9786500000030';

CREATE TABLE customer_order (
    id        bigserial   PRIMARY KEY,
    customer  text        NOT NULL,
    placed_at timestamptz NOT NULL
);

CREATE TABLE order_line (
    id          bigserial PRIMARY KEY,
    order_id    bigint    NOT NULL REFERENCES customer_order (id),
    book_id     bigint    NOT NULL REFERENCES book (id),
    quantity    integer   NOT NULL CHECK (quantity > 0),
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);

CREATE INDEX order_line_order_id ON order_line (order_id);
```

Every book starts with five copies except Frankenstein, which has one: that last copy is what two
customers fight over in section 06. `CHECK (stock >= 0)` is the database refusing a negative stock on
its own, a last line of defence behind the Java check below. The table is called `customer_order`
because `ORDER` is a reserved word in SQL.

## Stock on the book

`Book` gets a `stock` field and a method that takes copies out and refuses to go below zero. Replace
`src/main/java/com/example/bookshop/catalogue/Book.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(length = 13)
    private String isbn;

    private String title;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Author author;

    @Column(name = "price_cents")
    private int priceCents;

    private int stock;

    protected Book() {
    }

    public Book(String isbn, String title, Author author, int priceCents, int stock) {
        this.isbn = isbn;
        this.title = title;
        this.author = author;
        this.priceCents = priceCents;
        this.stock = stock;
    }

    public Long getId() {
        return id;
    }

    public String getIsbn() {
        return isbn;
    }

    public String getTitle() {
        return title;
    }

    public Author getAuthor() {
        return author;
    }

    public int getPriceCents() {
        return priceCents;
    }

    public int getStock() {
        return stock;
    }

    public void take(int quantity) {
        if (quantity > stock) {
            throw new OutOfStockException(this, quantity);
        }
        stock -= quantity;
    }
}
```

`take` throws rather than returning a flag, and what it throws is a `RuntimeException`. That choice
matters in the next section, because it is what tells Spring to undo the transaction. Create
`OutOfStockException.java` in the same package:

```java
package com.example.bookshop.catalogue;

public class OutOfStockException extends RuntimeException {

    public OutOfStockException(Book book, int wanted) {
        super("Only " + book.getStock() + " of '" + book.getTitle() + "' left, " + wanted + " wanted");
    }
}
```

A new book now arrives with its stock, so the request, the response and the service's `add` carry one
more value. Replace `BookRequest.java`, `BookResponse.java` and `BookService.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BookRequest(
        @NotNull @ValidIsbn String isbn,
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 120) String author,
        @NotNull @PositiveOrZero Integer priceCents,
        @NotNull @PositiveOrZero Integer stock) {
}
```

```java
package com.example.bookshop.catalogue;

public record BookResponse(long id, String isbn, String title, String author, int priceCents, int stock) {

    public static BookResponse from(Book book) {
        return new BookResponse(book.getId(), book.getIsbn(), book.getTitle(),
                book.getAuthor().getName(), book.getPriceCents(), book.getStock());
    }
}
```

```java
package com.example.bookshop.catalogue;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BookService {

    private final BookRepository books;
    private final AuthorRepository authors;

    public BookService(BookRepository books, AuthorRepository authors) {
        this.books = books;
        this.authors = authors;
    }

    @Transactional(readOnly = true)
    public long count() {
        return books.count();
    }

    @Transactional(readOnly = true)
    public Page<BookResponse> list(Pageable pageable) {
        return books.findAllBy(pageable).map(BookResponse::from);
    }

    @Transactional(readOnly = true)
    public List<BookResponse> search(String text) {
        return books.findByTitleContainingIgnoreCaseOrderByTitle(text).stream().map(BookResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public List<TitleAndPrice> titlesBy(String author) {
        return books.findTitlesByAuthor(author);
    }

    @Transactional(readOnly = true)
    public BookResponse get(long id) {
        return books.findById(id).map(BookResponse::from).orElseThrow(() -> new BookNotFoundException(id));
    }

    @Transactional
    public BookResponse add(BookRequest request) {
        if (books.findByIsbn(request.isbn()).isPresent()) {
            throw new DuplicateIsbnException(request.isbn());
        }
        Author author = authors.findByName(request.author())
                .orElseGet(() -> authors.save(new Author(request.author())));
        Book book = books.save(new Book(request.isbn(), request.title(), author, request.priceCents(),
                request.stock()));
        return BookResponse.from(book);
    }
}
```

`BookRepository.java` gains one method, `findByIdForUpdate`. Section 06 is about what it does and
what goes wrong without it. Replace the file:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import jakarta.persistence.LockModeType;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

public interface BookRepository extends JpaRepository<Book, Long> {

    Optional<Book> findByIsbn(String isbn);

    @EntityGraph(attributePaths = "author")
    Page<Book> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = "author")
    List<Book> findByTitleContainingIgnoreCaseOrderByTitle(String text);

    @Query("select b.title as title, b.priceCents as priceCents from Book b where b.author.name = :name order by b.title")
    List<TitleAndPrice> findTitlesByAuthor(String name);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from Book b where b.id = :id")
    Optional<Book> findByIdForUpdate(long id);
}
```

## The ordering package

Orders get a package of their own, `com.example.bookshop.ordering`, beside `catalogue`. An `Order`
owns its lines, and saving the order saves them (`CascadeType.ALL`). Each line copies the book's
price at the moment of the order, so that a price change next month does not rewrite what somebody
paid. Create `Order.java` and `OrderLine.java`:

```java
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
```

```java
package com.example.bookshop.ordering;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;

import com.example.bookshop.catalogue.Book;

@Entity
public class OrderLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    private Book book;

    private int quantity;

    @Column(name = "price_cents")
    private int priceCents;

    protected OrderLine() {
    }

    OrderLine(Order order, Book book, int quantity, int priceCents) {
        this.order = order;
        this.book = book;
        this.quantity = quantity;
        this.priceCents = priceCents;
    }

    public int totalCents() {
        return quantity * priceCents;
    }

    public Book getBook() {
        return book;
    }

    public int getQuantity() {
        return quantity;
    }

    public int getPriceCents() {
        return priceCents;
    }
}
```

The repository reads an order with its lines and their books in one query, with the `@EntityGraph`
of lesson 11. Create `OrderRepository.java`:

```java
package com.example.bookshop.ordering;

import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderRepository extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = {"lines", "lines.book"})
    Optional<Order> findWithLinesById(long id);
}
```

The request names books by id, with a quantity each; the response gives back titles, prices and the
total. `@Valid` on the list's element type makes Bean Validation check every line, the way lesson 6
checked a book. Create `OrderRequest.java`, `OrderResponse.java` and `OrderNotFoundException.java`:

```java
package com.example.bookshop.ordering;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record OrderRequest(@NotBlank String customer, @NotEmpty List<@Valid Line> lines) {

    public record Line(@NotNull Long bookId, @Positive int quantity) {
    }
}
```

```java
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
```

```java
package com.example.bookshop.ordering;

public class OrderNotFoundException extends RuntimeException {

    public OrderNotFoundException(long id) {
        super("No order has id " + id);
    }
}
```

The controller answers `POST /orders` with `201` and a `Location`, and `GET /orders/{id}` with the
order. Create `OrderController.java`:

```java
package com.example.bookshop.ordering;

import java.net.URI;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderService orders;

    public OrderController(OrderService orders) {
        this.orders = orders;
    }

    @PostMapping
    public ResponseEntity<OrderResponse> place(@Valid @RequestBody OrderRequest request) {
        OrderResponse order = orders.place(request);
        return ResponseEntity.created(URI.create("/orders/" + order.id())).body(order);
    }

    @GetMapping("/{id}")
    public OrderResponse get(@PathVariable long id) {
        return orders.get(id);
    }
}
```

And `ApiErrorHandler` learns the two new exceptions. An unknown order is a `404`. A book without
enough copies is a `409 Conflict`, the status lesson 7 gave a duplicate ISBN, because the request is
well formed and it is the state of the shop that refuses it. Replace
`src/main/java/com/example/bookshop/web/ApiErrorHandler.java`:

```java
package com.example.bookshop.web;

import java.net.URI;
import java.util.Map;
import java.util.TreeMap;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import com.example.bookshop.catalogue.BookNotFoundException;
import com.example.bookshop.catalogue.DuplicateIsbnException;
import com.example.bookshop.catalogue.OutOfStockException;
import com.example.bookshop.ordering.OrderNotFoundException;

@RestControllerAdvice
public class ApiErrorHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(BookNotFoundException.class)
    public ProblemDetail notFound(BookNotFoundException e) {
        return problem(HttpStatus.NOT_FOUND, "book-not-found", "Book not found", e.getMessage());
    }

    @ExceptionHandler(DuplicateIsbnException.class)
    public ProblemDetail duplicate(DuplicateIsbnException e) {
        return problem(HttpStatus.CONFLICT, "duplicate-isbn", "Duplicate ISBN", e.getMessage());
    }

    @ExceptionHandler(OrderNotFoundException.class)
    public ProblemDetail orderNotFound(OrderNotFoundException e) {
        return problem(HttpStatus.NOT_FOUND, "order-not-found", "Order not found", e.getMessage());
    }

    @ExceptionHandler(OutOfStockException.class)
    public ProblemDetail outOfStock(OutOfStockException e) {
        return problem(HttpStatus.CONFLICT, "out-of-stock", "Out of stock", e.getMessage());
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> errors = new TreeMap<>();
        e.getBindingResult().getFieldErrors()
                .forEach(f -> errors.put(f.getField(), f.getDefaultMessage()));
        ProblemDetail body = problem(HttpStatus.BAD_REQUEST, "invalid-request", "Invalid request",
                errors.size() + " field(s) failed validation");
        body.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(body);
    }

    private static ProblemDetail problem(HttpStatus status, String type, String title, String detail) {
        ProblemDetail body = ProblemDetail.forStatusAndDetail(status, detail);
        body.setType(URI.create("https://bookshop.example/problems/" + type));
        body.setTitle(title);
        return body;
    }
}
```

## Three lines for the pool

Last, `application.properties` names the connection pool and sets two of its limits. Section 07 reads
them; for now they are three lines to copy. Replace `src/main/resources/application.properties`:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop
spring.datasource.hikari.pool-name=bookshop-pool
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.connection-timeout=5000

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
```

One class is still missing, `OrderService`, the one that places an order. It is where the transaction
lives, and the next section gives it.
