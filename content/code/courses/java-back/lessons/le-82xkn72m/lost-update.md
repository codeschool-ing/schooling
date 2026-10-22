---
title: Two orders, one copy
version: 1
---

The shop has one Frankenstein. Two customers press the button in the same instant. Each request
runs `place` in its own transaction, on its own connection, and the question is what each one reads
when it asks for the book. The wrong picture is that a transaction takes care of this by itself:
`READ COMMITTED` lets both of them read a stock of 1, both decide the copy is theirs, and both write
0. The database accepts both writes, the `CHECK` is satisfied, and two orders exist for one book.

## A detour: the order without the lock

To see it happen, take the lock out. In `OrderService.place`, replace `books.findByIdForUpdate(line.bookId())`
with `books.findById(line.bookId())`, the plain read every repository has. This is a detour: put the
original line back at the end of it. Rebuild, and restart in the second terminal with the `sql`
profile from lesson 10 so the statements are printed.

Two orders for the last copy, sent at the same moment: the `&` runs each `curl` in the background so
they leave together, and `wait` waits for both. Then the book, and the orders the database holds:

```
ana@vm:~/bookshop$ for c in ana bia; do curl -s -o /dev/null -w "$c %{http_code}\n" -H "Content-Type: application/json" -d "{\"customer\":\"$c\",\"lines\":[{\"bookId\":3,\"quantity\":1}]}" localhost:8080/orders & done; wait
ana 201
bia 201
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/3
{"id":3,"isbn":"9786500000030","title":"Frankenstein","author":"Mary Shelley","priceCents":3500,"stock":0}
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'SELECT o.id, o.customer, l.quantity FROM customer_order o JOIN order_line l ON l.order_id = o.id WHERE l.book_id = 3'
 id | customer | quantity 
----+----------+----------
  2 | ana      |        1
  3 | bia      |        1
(2 rows)
```

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E 'from book b1_0 where|update book'
2026-10-22T19:39:02.420-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:39:02.421-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=?
2026-10-22T19:39:02.503-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : update book set author_id=?,isbn=?,price_cents=?,stock=?,title=? where id=?
2026-10-22T19:39:02.504-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : update book set author_id=?,isbn=?,price_cents=?,stock=?,title=? where id=?
2026-10-22T19:39:02.563-03:00 DEBUG 1778 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=?
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 275\" role=\"img\" aria-label=\"Two timelines side by side. Left, with findById: ana and bia both read a stock of 1, both write 0 and both commit, so two orders are placed for one copy. Right, with findByIdForUpdate: ana locks the row and reads 1, bia waits for the lock, ana writes 0 and commits, bia then reads 0 and rolls back, so there is one order and one 409.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"330\" height=\"255\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">findById</text><text x=\"95\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ana</text><text x=\"255\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">bia</text><line x1=\"95\" y1=\"66\" x2=\"95\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"255\" y1=\"66\" x2=\"255\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"23\" y=\"74\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads stock 1</text><rect x=\"183\" y=\"104\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"255\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reads stock 1</text><rect x=\"23\" y=\"134\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"95\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">writes 0, commits</text><rect x=\"183\" y=\"164\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"255\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">writes 0, commits</text><text x=\"175\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">two orders, one copy</text><rect x=\"360\" y=\"10\" width=\"330\" height=\"255\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">findByIdForUpdate</text><text x=\"445\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ana</text><text x=\"605\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">bia</text><line x1=\"445\" y1=\"66\" x2=\"445\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"605\" y1=\"66\" x2=\"605\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"373\" y=\"74\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"445\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">locks the row, reads 1</text><line x1=\"605\" y1=\"104\" x2=\"605\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"3\" stroke-dasharray=\"3 3\"></line><text x=\"613\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">waits</text><rect x=\"373\" y=\"134\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"445\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">writes 0, commits</text><rect x=\"533\" y=\"164\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"605\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">locks the row, reads 0</text><rect x=\"533\" y=\"194\" width=\"144\" height=\"22\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"605\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">not enough: rolls back</text><text x=\"525\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one order, one 409</text></svg>", "caption": "The same two orders for the last Frankenstein, time running downwards. Without the lock both read 1; with it, the second read waits until the first transaction ends."}
```

Both orders were accepted. In the log, two threads each run a plain `select` and then an `update`;
the last `select` is the `curl` that read the book. Each transaction read `stock` 1, each `take(1)` left 0, and each
`update` wrote 0: the second write did not subtract from the first, it replaced it. That is the
**lost update**, and nothing in the output says anything went wrong. Here the two requests left in the
same instant on purpose. In a shop they only have to arrive within the few milliseconds one
transaction lasts, and the last copy of anything popular is exactly where that happens.

## The lock

Put `findByIdForUpdate` back. It is the method `BookRepository` gained in section 02:

```java
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from Book b where b.id = :id")
    Optional<Book> findByIdForUpdate(long id);
```

`@Lock(LockModeType.PESSIMISTIC_WRITE)` asks Hibernate to read the row **and lock it until the
transaction ends**. Hibernate turns that into PostgreSQL's locking read, which the `sql` profile shows:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar --spring.profiles.active=sql | grep -E 'for no key update'
2026-10-22T19:39:19.060-03:00 DEBUG 2369 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=? for no key update of b1_0
2026-10-22T19:39:19.067-03:00 DEBUG 2369 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 where b1_0.id=? for no key update of b1_0
```

A second transaction that asks for the same row with a locking read waits until the first one
commits or rolls back. At `READ COMMITTED` its read then sees the committed result, 0 copies, and
`take` refuses. The same two orders, with the lock, against a stock put back to 1:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'UPDATE book SET stock = 1 WHERE id = 3'
UPDATE 1
ana@vm:~/bookshop$ for c in ana bia; do curl -s -o /dev/null -w "$c %{http_code}\n" -H "Content-Type: application/json" -d "{\"customer\":\"$c\",\"lines\":[{\"bookId\":3,\"quantity\":1}]}" localhost:8080/orders & done; wait
bia 409
ana 201
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/books/3
{"id":3,"isbn":"9786500000030","title":"Frankenstein","author":"Mary Shelley","priceCents":3500,"stock":0}
```

One order and one `409`, and the stock is 0, as it should be. Which customer wins is a matter of
microseconds and changes from run to run; that exactly one does is what the lock guarantees.

## What the lock costs, and the other ways

A lock makes the second transaction wait, so **a transaction holding one must be short**. Nothing
slow belongs between the locking read and the commit: no call to a payment service, no e-mail. A
transaction that waits on the network holds the lock, and every order for that book queues behind it,
each one holding a connection while it waits, which is where section 07 picks up.

Locking before writing is called **pessimistic** locking, and it fits a row many people fight over,
like the last copy. Two other designs solve the same problem:

- **Optimistic locking**: the entity carries a version column annotated `@Version`, Hibernate adds
  `where version = ?` to its `update`, and the losing transaction fails with an exception the
  application retries. Nobody waits, which suits rows that rarely collide.
- **An atomic update**: `update book set stock = stock - ? where id = ? and stock >= ?`, and a count
  of zero rows updated means not enough copies. The database does the arithmetic on the row it is
  locking anyway, at the cost of moving the rule out of `Book.take`.

`sql-databases` lesson 8 goes deeper into locks, deadlocks and retrying.
