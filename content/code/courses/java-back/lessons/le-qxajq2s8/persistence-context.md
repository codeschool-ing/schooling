---
title: The persistence context, and a change nobody saved
version: 1
---

The wrong picture of a mapper is a pair of functions, one that reads rows into objects and one that
writes objects into rows, each called when you ask. The right one has a piece of state in the
middle. The **persistence context** is a map, kept for one transaction, from each entity's key to the
one object that stands for that row, together with a copy of the values the row had when it was
loaded. Two behaviours follow from it, and neither shows in the code that relies on them.

- **One object per row.** Asking twice for book 3 inside one transaction runs one `SELECT` and gives
  the same object twice. The second time, the map answers.
- **Dirty checking.** When the transaction commits, Hibernate compares each managed object with the
  copy it took on loading. Any object that differs gets an `UPDATE`, without anybody calling a save
  method. Sending the pending statements is called a **flush**, and a commit always flushes first.

## A detour you will undo

The bookshop never changes a book after adding it, so this is a demonstration rather than a feature.
Add a method to `Book`, just after `getPriceCents()`:

```java
    public void reprice(int newPriceCents) {
        this.priceCents = newPriceCents;
    }
```

and create `src/main/java/com/example/bookshop/catalogue/RepriceOnce.java`, a start-up task like the
catalogue report:

```java
package com.example.bookshop.catalogue;

import jakarta.persistence.EntityManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Order(1)
public class RepriceOnce implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(RepriceOnce.class);

    private final EntityManager em;

    public RepriceOnce(EntityManager em) {
        this.em = em;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Book first = em.find(Book.class, 3L);
        Book second = em.find(Book.class, 3L);
        log.info("the same object twice: {}", first == second);
        first.reprice(3800);
        log.info("price changed in memory, nothing saved yet");
    }
}
```

`run` is `@Transactional`, so everything in it shares one persistence context. It loads book 3,
Frankenstein, twice, compares the two references with `==`, changes the price on one of them and
returns. There is no `persist`, no `merge` and no `save` anywhere. Build, start with the `sql` profile,
and read the second terminal:

```
(capture reprice-log)
```

Read it in order. There is one `select`, for the first `find`. The second `find` ran no SQL and
returned the very same object, which is what `true` means. Both log lines come out before anything
is written: only when `run` returns does the transaction commit, the commit flush, and Hibernate
compare Frankenstein with the copy it took on loading. The price differs, so out comes an `UPDATE`
that nobody wrote. It sets every mapped column rather than only the price, because by default
Hibernate uses one `UPDATE` per entity for any change. `@Order(1)` made this task run before the
catalogue report, whose five statements follow; they are the next section's subject.

Stop the application and start it once more, changing nothing:

```
(capture reprice-again)
```

**No `UPDATE` this time.** The method set the price to 3800 again, the row already said 3800, and the
comparison found nothing to write. Dirty checking compares values; it does not count calls.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Four steps. First find: a select is sent and the price 3500 is kept twice, in the object and in a copy. Second find: nothing is sent, the same object is returned. reprice(3800): nothing is sent, the object says 3800 and the copy still 3500. Commit: the two differ, so an update is sent.\"><text x=\"16\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the code</text><text x=\"16\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQL sent</text><text x=\"16\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the object</text><text x=\"16\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">copy at load</text><text x=\"188.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"120\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"188.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">find(Book.class, 3L)</text><text x=\"188.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … where id=?</text><rect x=\"150\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"188.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3500</text><text x=\"188.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"334.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"266\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"334.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">find(Book.class, 3L)</text><text x=\"334.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing</text><rect x=\"296\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"334.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3500</text><text x=\"334.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"480.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"412\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">first.reprice(3800)</text><text x=\"480.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing</text><rect x=\"442\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3800</text><text x=\"480.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"626.0\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"558\" y=\"26\" width=\"136\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"626.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">run returns: commit</text><text x=\"626.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">update book set …</text><rect x=\"588\" y=\"128\" width=\"76\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"626.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3800</text><text x=\"626.0\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3500</text><text x=\"120\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">At the commit Hibernate compares each managed object with its copy.</text><text x=\"120\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Frankenstein differs (3800 against 3500), so it sends an UPDATE.</text></svg>", "caption": "What the persistence context does with the demonstration, step by step. The UPDATE comes from comparing the object with its copy, not from any call."}
```

The price really is in the database, and `psql`, from lesson 9, can say so:

```
(capture reprice-psql)
```

## Taking it out

Delete `RepriceOnce.java` and the `reprice` method, so that `Book.java` is again the file from the
section on entities, and put Frankenstein back at its price:

```
(capture reprice-undo)
```

## Managed, and then not

An entity in the map is **managed**: Hibernate watches it and its lazy fields can still load. When
the transaction ends, the persistence context closes, and every object it held becomes **detached**.
It keeps the values it had, so reading `getTitle()` still works. But nothing watches it any more: a
change to a detached object is never written, and a lazy field it never loaded can no longer be
loaded. The service in the last section returns records built inside the transaction precisely so
that no detached entity leaves it. The last section shows what happens when one does.
