---
title: N+1, the mistake that looks like ordinary code
version: 1
---

Here is a page that lists fifty customers with their orders, written the way every tutorial
writes it:

```
customers = Customer.order('id').limit(50)
for customer in customers:
    for order in customer.orders:
        print(customer.name, order.total)
```

Four lines, and nothing in them looks like a database problem. The first line runs one query.
`customer.orders` on the third line runs one query **per customer**, because the orders were not
loaded with the customers — the ORM fetches them the first time they are asked for, which is
inside the loop. Fifty customers, fifty queries, plus the one that fetched the customers: **N+1**.

The last section captured it from the server's side:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two panels, each with an app lane above and a database lane below. On the left, headed a query inside the loop, seven pairs of arrows cross between the lanes — a statement down and its rows back up — followed by a note saying and forty-four more, totalling one plus fifty round trips. On the right, headed the relationship loaded in one go, two pairs of arrows and nothing else: two round trips.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The same page, the same fifty customers and their orders. What differs is how many times the network is crossed.</text><rect x=\"14\" y=\"38\" width=\"400\" height=\"130\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">a query inside the loop</text><text x=\"26\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app</text><text x=\"26\" y=\"142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">database</text><path d=\"M26 86 L402 86\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M26 134 L402 134\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M40 86 L40 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M40 134 L37 127 L43 127 Z\" fill=\"var(--amber)\"></path><path d=\"M46 134 L46 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M46 86 L43 93 L49 93 Z\" fill=\"var(--amber)\"></path><path d=\"M70 86 L70 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M70 134 L67 127 L73 127 Z\" fill=\"var(--amber)\"></path><path d=\"M76 134 L76 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M76 86 L73 93 L79 93 Z\" fill=\"var(--amber)\"></path><path d=\"M100 86 L100 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M100 134 L97 127 L103 127 Z\" fill=\"var(--amber)\"></path><path d=\"M106 134 L106 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M106 86 L103 93 L109 93 Z\" fill=\"var(--amber)\"></path><path d=\"M130 86 L130 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M130 134 L127 127 L133 127 Z\" fill=\"var(--amber)\"></path><path d=\"M136 134 L136 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M136 86 L133 93 L139 93 Z\" fill=\"var(--amber)\"></path><path d=\"M160 86 L160 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M160 134 L157 127 L163 127 Z\" fill=\"var(--amber)\"></path><path d=\"M166 134 L166 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M166 86 L163 93 L169 93 Z\" fill=\"var(--amber)\"></path><path d=\"M190 86 L190 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M190 134 L187 127 L193 127 Z\" fill=\"var(--amber)\"></path><path d=\"M196 134 L196 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M196 86 L193 93 L199 93 Z\" fill=\"var(--amber)\"></path><path d=\"M220 86 L220 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M220 134 L217 127 L223 127 Z\" fill=\"var(--amber)\"></path><path d=\"M226 134 L226 86\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M226 86 L223 93 L229 93 Z\" fill=\"var(--amber)\"></path><text x=\"250\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">… and forty-four more</text><text x=\"214.0\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1 + 50 round trips</text><rect x=\"444\" y=\"38\" width=\"262\" height=\"130\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">the relationship loaded in one go</text><text x=\"456\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app</text><text x=\"456\" y=\"142\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">database</text><path d=\"M456 86 L694 86\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M456 134 L694 134\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M500 86 L500 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M500 134 L497 127 L503 127 Z\" fill=\"var(--phosphor)\"></path><path d=\"M506 134 L506 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M506 86 L503 93 L509 93 Z\" fill=\"var(--phosphor)\"></path><path d=\"M540 86 L540 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M540 134 L537 127 L543 127 Z\" fill=\"var(--phosphor)\"></path><path d=\"M546 134 L546 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></path><path d=\"M546 86 L543 93 L549 93 Z\" fill=\"var(--phosphor)\"></path><text x=\"575.0\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2 round trips</text><text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Each arrow down is a statement and each dashed arrow up is its rows. The engine does about the same work in both.</text><text x=\"14\" y=\"208\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">What the loop costs is the crossing, which is why this is worse than the same mistake written as a correlated subquery.</text></svg>", "caption": "Nothing in the four lines of code says fifty. The count is a property of where the second query sits, which is why this reads as ordinary code right up until the page is slow."}
```

```
shop=# SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
 calls |                            query                             
-------+--------------------------------------------------------------
    50 | SELECT id, placed_at, total FROM orders WHERE customer_id = 
     1 | SELECT id, name FROM customers ORDER BY id LIMIT $1
(2 rows)
```

One statement ran fifty times. Lesson 7 met this shape as a correlated subquery and said the two
are the same mistake at different altitudes. This is the higher one, and it is worse, because every
one of those fifty is a round trip across a network rather than a lookup inside the engine.

## Why it is invisible

Three reasons, and each is a reason the code review does not catch it.

**Each query is fast.** Fifty index lookups at a fraction of a millisecond each look fine in
`pg_stat_statements` sorted by mean, and in the log they are fifty unremarkable lines. The cost is
the count, and lesson 10 said which column shows the count.

**It scales with the data, not with the code.** Fifty customers on the developer's machine is
fifty-one queries and a page that renders in a moment. Five thousand on production is five
thousand and one, and the same four lines take seconds. Nothing changed but N.

**It is the ORM doing what it said it would.** Lazy loading — fetching a relationship when it is
first touched — is the default in nearly every mapper because it is the right behaviour for the
common case of touching nothing. The loop is the uncommon case, and the default does not know
it is in one.

## Where it hides

The literal loop above is the textbook form, and it is the one people learn to see. The others
are the same thing wearing a template or a serialiser:

- **A template** that writes `{{ order.customer.name }}` on each row of a list of orders. The
  loop is in the template engine, and the query per row is in the property access.
- **A serialiser** that turns a list of objects into JSON, and each object has a relationship
  that the serialiser walks.
- **A method on the model** — `customer.total_spent()` — that runs a query, called once per row
  of a report.
- **Nested relationships**: customers, each with orders, each with lines. N+1 inside N+1, which is
  N + N·M + 1, and the product is what makes a page time out.

None of these has a `for` in the code that the reviewer reads, which is why the count in
`pg_stat_statements` finds them and reading finds fewer.

## The fix is one of two shapes

Ask for the orders **with** the customers, in one statement, or in one statement per level rather
than per row. Both shapes are built into every ORM under a name of its own, and the next section
is the two shapes, their SQL, and when each is the right one.

What the fix is never: denormalising, caching, or a bigger server. Lesson 2 said so from the
other side: the N+1 is the most common cause of "the database is slow" and none of those touch
it. And lesson 10 said why a bigger server does not help a problem whose cost is round trips.
