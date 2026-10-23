---
title: Pedidos, e o estoque que eles consomem
version: 1
---

Até aqui a livraria foi um catálogo: entram livros, saem livros. Esta aula deixa alguém comprá-los, e
comprar é a primeira coisa que a aplicação faz que muda várias linhas de uma vez e **nunca pode mudar só
algumas delas**. Um pedido grava uma linha em `customer_order`, uma linha em `order_line` para cada
livro, e tira os exemplares do `stock` de cada livro. Se qualquer passo falhar, nenhum deles pode ficar.

Esta seção acrescenta o código. Ela parte da livraria como a aula 13 a deixou, e cada arquivo vem
inteiro: crie os que são novos e substitua os que já existem. O resto da aula é sobre as duas anotações
em que o código se apoia, e sobre o que acontece sem elas.

## A migração

A aula 13 pôs o esquema nas mãos do Flyway, então uma coluna nova e duas tabelas novas são uma terceira
migração. Crie `src/main/resources/db/migration/V3__stock_and_orders.sql`:

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

Todo livro começa com cinco exemplares, menos Frankenstein, que tem um: esse último exemplar é o que dois
clientes disputam na seção 06. `CHECK (stock >= 0)` é o próprio banco recusando um estoque negativo, uma
última linha de defesa atrás da verificação em Java logo abaixo. A tabela se chama `customer_order`
porque `ORDER` é uma palavra reservada em SQL.

## Estoque no livro

`Book` ganha um campo `stock` e um método que tira exemplares e se recusa a ir abaixo de zero.
Substitua `src/main/java/com/example/bookshop/catalogue/Book.java`:

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

`take` lança uma exceção em vez de devolver um indicador, e o que ele lança é uma `RuntimeException`.
Essa escolha importa na próxima seção, porque é ela que diz ao Spring para desfazer a transação. Crie
`OutOfStockException.java` no mesmo pacote:

```java
package com.example.bookshop.catalogue;

public class OutOfStockException extends RuntimeException {

    public OutOfStockException(Book book, int wanted) {
        super("Only " + book.getStock() + " of '" + book.getTitle() + "' left, " + wanted + " wanted");
    }
}
```

Um livro novo agora chega com o seu estoque, então a requisição, a resposta e o `add` do serviço
carregam um valor a mais. Substitua `BookRequest.java`, `BookResponse.java` e `BookService.java`:

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

`BookRepository.java` ganha um método, `findByIdForUpdate`. A seção 06 trata do que ele faz e do que dá
errado sem ele. Substitua o arquivo:

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

## O pacote de pedidos

Os pedidos ganham um pacote próprio, `com.example.bookshop.ordering`, ao lado de `catalogue`. Um `Order`
é dono das suas linhas, e salvar o pedido salva as linhas (`CascadeType.ALL`). Cada linha copia o preço
do livro no momento do pedido, para que uma mudança de preço no mês que vem não reescreva o que alguém
pagou. Crie `Order.java` e `OrderLine.java`:

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

O repositório lê um pedido com as linhas e os livros delas numa só consulta, com o `@EntityGraph` da
aula 11. Crie `OrderRepository.java`:

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

A requisição indica os livros pelo id, cada um com uma quantidade; a resposta devolve títulos, preços e o
total. `@Valid` no tipo dos elementos da lista faz o Bean Validation conferir cada linha, do jeito que a
aula 6 conferia um livro. Crie `OrderRequest.java`, `OrderResponse.java` e `OrderNotFoundException.java`:

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

O controller responde a `POST /orders` com `201` e um `Location`, e a `GET /orders/{id}` com o pedido.
Crie `OrderController.java`:

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

E o `ApiErrorHandler` aprende as duas exceções novas. Um pedido desconhecido é um `404`. Um livro sem
exemplares suficientes é um `409 Conflict`, o status que a aula 7 deu a um ISBN duplicado, porque a
requisição está bem formada e quem a recusa é o estado da loja. Substitua
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

## Três linhas para o pool

Por último, o `application.properties` dá nome ao pool de conexões e define dois limites dele. A seção 07
lê essas linhas; por enquanto são três linhas para copiar. Substitua `src/main/resources/application.properties`:

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

Ainda falta uma classe, `OrderService`, a que faz o pedido. É nela que mora a transação, e a próxima
seção a traz.
