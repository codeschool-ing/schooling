---
title: Beans you cannot annotate, and the clock
version: 1
---

Component scanning finds classes you wrote and labelled. `java.time.Clock` is neither: it belongs to
the JDK, nobody can put `@Component` on it, and its instances come from static methods such as
`Clock.system` rather than from a constructor Spring could call. For an object like that, the
definition is a **`@Bean` method**, a method whose return value becomes a bean.

```schooling-example
{"language": "java", "file": "ClockConfig.java", "parts": [{"code": "package com.example.bookshop.config;\n\nimport java.time.Clock;\nimport java.time.ZoneId;\n\nimport org.springframework.context.annotation.Bean;\nimport org.springframework.context.annotation.Configuration;\n"}, {"code": "@Configuration\npublic class ClockConfig {", "note": "`@Configuration` is a stereotype too, so scanning finds this class and makes it a bean, `clockConfig`. What it is for is holding `@Bean` methods."}, {"code": "\n    @Bean\n    public Clock clock() {\n        return Clock.system(ZoneId.of(\"America/Sao_Paulo\"));\n    }", "note": "The bean is whatever the method returns, its type is the return type, and its name is the method's: `clock`. Spring calls the method once and keeps the result. A `@Bean` method may take parameters, and Spring fills them the way it fills a constructor's."}, {"code": "}"}]}
```

The beans log two sections back showed what this costs at start-up. `clock` was taken up first,
because `catalogueReport` needed it, and creating it needed `clockConfig`, since the method belongs to
an instance of that class. `Wiring.java` did the same in one line, `new ClockConfig().clock()`.

The same tool serves any object whose construction is more than `new`: a client configured from
properties, a library's builder, a choice between two implementations made at start-up. Lesson 15
declares the application's security rules as `@Bean` methods of one `@Configuration` class.

## Why the report takes a clock

`CatalogueReport` could have called `LocalDate.now()`. That method reads the computer's clock and its
time zone, a value every class can reach and no caller can replace, so the report's output would
depend on the day it runs and nothing a test does could change it. **Taking a `Clock` as a dependency
turns the current time into an input.** The application is given the real clock, in São Paulo's
zone, and any other caller can pass one that never moves. Save this beside `Wiring.java`:

```java
// FixedClock.java: the same objects, with a clock that never moves.
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import com.example.bookshop.catalogue.BookService;
import com.example.bookshop.catalogue.CatalogueReport;
import com.example.bookshop.catalogue.InMemoryBookRepository;

void main() {
    var service = new BookService(new InMemoryBookRepository());
    var clock = Clock.fixed(Instant.parse("2026-01-01T12:00:00Z"), ZoneOffset.UTC);
    var report = new CatalogueReport(service, clock);
    report.run();
}
```

```
ana@vm:~/bookshop$ java -cp target/classes:$(cat target/classpath.txt) ~/FixedClock.java
19:16:25.572 [main] INFO com.example.bookshop.catalogue.CatalogueReport -- Catalogue opened on 2026-01-01 with 3 books
```

The report says 1 January 2026 on whatever day it runs. Lesson 19's test of the order service does
exactly this: it builds the service with `Clock.fixed` and checks that the order it places carries
that instant, which would be impossible to assert against a clock that moves.

The reasoning reaches past clocks. Anything a class would otherwise fetch from the world around it,
such as a source of random numbers, an environment variable or a network address, can be injected
instead, and then whoever builds the object decides what it is.
