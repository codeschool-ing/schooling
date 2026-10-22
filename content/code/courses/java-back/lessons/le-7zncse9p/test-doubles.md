---
title: x
version: 1
---

```schooling-example
{
  "language": "java",
  "file": "OrderServiceTest.java",
  "parts": [
    {
      "code": "package com.example.bookshop.ordering;\n\nimport static org.assertj.core.api.Assertions.assertThat;\nimport static org.assertj.core.api.Assertions.assertThatThrownBy;\nimport static org.mockito.ArgumentMatchers.any;\nimport static org.mockito.Mockito.never;\nimport static org.mockito.Mockito.verify;\nimport static org.mockito.Mockito.when;\n\nimport java.time.Clock;\nimport java.time.Instant;\nimport java.time.ZoneOffset;\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.junit.jupiter.api.BeforeEach;\nimport org.junit.jupiter.api.Test;\nimport org.junit.jupiter.api.extension.ExtendWith;\nimport org.mockito.Mock;\nimport org.mockito.junit.jupiter.MockitoExtension;\nimport org.springframework.test.util.ReflectionTestUtils;\n\nimport com.example.bookshop.catalogue.Author;\nimport com.example.bookshop.catalogue.Book;\nimport com.example.bookshop.catalogue.BookRepository;\nimport com.example.bookshop.catalogue.OutOfStockException;\n",
      "note": "The static imports are the test's vocabulary. `when`, `verify`, `never` and `any` are Mockito's; `assertThat` and `assertThatThrownBy` are AssertJ's, as in lesson 18. `spring-boot-starter-test` already brings Mockito, so the pom does not change for this file."
    },
    {
      "code": "@ExtendWith(MockitoExtension.class)\nclass OrderServiceTest {\n\n    @Mock\n    BookRepository books;\n\n    @Mock\n    OrderRepository orders;\n",
      "note": "**`MockitoExtension`** creates a fresh mock for every `@Mock` field before each test. A mock of `BookRepository` implements the whole interface and answers every call with an empty value until the test says otherwise."
    },
    {
      "code": "    OrderService service;\n\n    Book frankenstein = new Book(\"9786500000030\", \"Frankenstein\", new Author(\"Mary Shelley\"), 3500, 1);\n",
      "note": "The service is the real class, the one under test. The book is a real entity too, built with its public constructor: one copy of *Frankenstein* at 3500 cents. Nothing here needs a double, because neither touches anything outside the JVM."
    },
    {
      "code": "    @BeforeEach\n    void setUp() {\n        Clock noon = Clock.fixed(Instant.parse(\"2026-10-16T15:00:00Z\"), ZoneOffset.UTC);\n        service = new OrderService(books, orders, noon);\n        ReflectionTestUtils.setField(frankenstein, \"id\", 3L);\n    }\n",
      "note": "The service gets its three collaborators through the constructor, as lesson 5 arranged. The clock is fixed at 15:00 UTC, noon in São Paulo, so the time an order is placed is a value the test can assert. `ReflectionTestUtils` gives the book the id the database would have generated."
    },
    {
      "code": "    @Test\n    void placingAnOrderTakesTheStockAndSavesTheOrder() {\n        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));",
      "note": "A **stub**: when the service asks for book 3 with a lock, the mock returns the entity above. Any other id still gets the default, an empty `Optional`."
    },
    {
      "code": "        when(orders.save(any(Order.class))).thenAnswer(call -> {\n            Order order = call.getArgument(0);\n            ReflectionTestUtils.setField(order, \"id\", 7L);\n            return order;\n        });\n",
      "note": "`thenAnswer` runs code at the moment of the call. The order is created inside `place`, so the test cannot name it in advance; the answer takes it from the call's arguments, gives it id 7 and hands it back, which is what `save` does for real."
    },
    {
      "code": "        OrderResponse placed = service.place(\"ana\", new OrderRequest(List.of(new OrderRequest.Line(3L, 1))));\n\n        assertThat(placed.id()).isEqualTo(7);\n        assertThat(placed.totalCents()).isEqualTo(3500);\n        assertThat(placed.placedAt()).isEqualTo(Instant.parse(\"2026-10-16T15:00:00Z\"));\n        assertThat(frankenstein.getStock()).isZero();\n    }\n",
      "note": "The call under test, then what it should have produced: the id that `save` gave, the total, the fixed instant, and the stock the order took from the book."
    },
    {
      "code": "    @Test\n    void anOrderForMoreThanTheStockIsNeverSaved() {\n        when(books.findByIdForUpdate(3L)).thenReturn(Optional.of(frankenstein));\n",
      "note": "The second test stubs the same lookup and asks for two copies of a book that has one."
    },
    {
      "code": "        assertThatThrownBy(() -> service.place(\"ana\", new OrderRequest(List.of(new OrderRequest.Line(3L, 2)))))\n                .isInstanceOf(OutOfStockException.class);\n",
      "note": "`Book.take` throws, and the exception leaves `place` before the order reaches `save`."
    },
    {
      "code": "        verify(orders, never()).save(any());\n    }\n}",
      "note": "**`verify`** asks the mock what happened to it. `never()` turns the question into a claim: `save` was not called, with any argument. That is the one thing a stub cannot check, because a stub only answers."
    }
  ]
}
```
