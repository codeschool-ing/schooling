---
title: One instance or many: scopes
version: 1
---

Every bean so far was created once, and the log said it in its own words: "Creating shared instance
of singleton bean". There is one `bookService` in the context, and every class that asks for a
`BookService` receives that same object. That is the **singleton** scope, and it is the default. A
bean's **scope** decides how many instances the container makes of it, and when.

The name misleads people who know the singleton design pattern, where a class guarantees that only
one instance of it can ever exist. **A Spring singleton is one per application context**, and nothing
stops other code from making more: `Wiring.java` called `new InMemoryBookRepository()` and got a
perfectly good second one.

## Seeing it

Add this class to the package `com.example.bookshop` for a moment, as
`src/main/java/com/example/bookshop/ScopeCheck.java`. It receives a `BookService` through its
constructor, asks the context for two more, and compares them:

```java
package com.example.bookshop;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import com.example.bookshop.catalogue.BookService;

@Component
public class ScopeCheck implements CommandLineRunner {

    private final BookService injected;
    private final ApplicationContext context;

    public ScopeCheck(BookService injected, ApplicationContext context) {
        this.injected = injected;
        this.context = context;
    }

    @Override
    public void run(String... args) {
        BookService first = context.getBean(BookService.class);
        BookService second = context.getBean(BookService.class);
        System.out.println("asked twice, the same object: " + (first == second));
        System.out.println("the injected one is the same object: " + (injected == first));
    }
}
```

The context is itself a bean, so a constructor can ask for it, and `getBean` asks it for a bean
directly, by type. Ordinary code should not need to: a class that looks its dependencies up has gone
back to fetching them. Here it is the quickest way to ask twice.

```
!!! MISSING BLOCK scope
```

Now make `BookService` a **prototype**, a bean created anew every time it is asked for. Add
`@Scope("prototype")` under `@Service`, with its import:

```
!!! MISSING BLOCK prototype
```

Both comparisons turned false. Each `getBean` built a new `BookService`, and so did the constructor
parameter, once, when `ScopeCheck` was created. That last part is the trap: **a prototype injected
into a singleton is created once**, when the singleton is, and the singleton keeps that one object
for the rest of its life. Code that expected a fresh object on every call gets one object for ever.
Delete `ScopeCheck.java` and the `@Scope` line.

## Why a singleton must be safe to share

One object shared by everything is one object used by every thread. From lesson 6 on the bookshop
answers web requests, each on a thread of its own, and two requests can call `BookService.add` in the
same instant. That is why `InMemoryBookRepository` keeps its books in a `ConcurrentSkipListMap` and
numbers them with an `AtomicLong`. With a `HashMap` and a `long` incremented by `nextId++`, two books
saved together could now and then receive the same id, under load and in no test that runs one
request at a time.

The rule for a singleton is that it holds either no state that changes, like `BookService`, whose one
field is `final` and points at a repository, or state that is safe to use from several threads at
once, like the repository.

## Request scope, in brief

A web application adds scopes tied to HTTP. A **request** scope bean exists once per request, and a
**session** scope bean once per user session. A request-scoped bean holds what belongs to a single
request, such as who sent it. Injected into a singleton it cannot be the plain object, since the
singleton outlives every request, so Spring injects a proxy that finds the current request's instance
on each call. The bookshop never needs one. When lesson 16 wants a request's id in every log line, it
uses the logging library's per-thread context instead.
