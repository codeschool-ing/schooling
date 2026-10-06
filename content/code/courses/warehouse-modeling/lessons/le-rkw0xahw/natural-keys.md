---
title: What is wrong with the keys the shop already has
version: 1
---

Every row in the operational database has a key: `customer_id`, `book_id`, `shop_id`, and the ISBN and
the e-mail address are unique too. The warehouse could simply use them. Lesson 2 gave each dimension a
key of its own instead, `book_key` beside `book_id`, and this section is why.

A key that comes from the business or from a source system is a **natural key**. Four things happen to
natural keys over the life of a warehouse, and each one breaks a fact table that used them directly.

**They change.** An e-mail address identifies a customer until the customer gets a new one:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT changed_at, old_value, new_value FROM staging.customer_changes WHERE field = 'email' ORDER BY change_id LIMIT 2"
┌──────────────────────────┬──────────────────────────────┬─────────────────────────────────┐
│        changed_at        │          old_value           │            new_value            │
│ timestamp with time zone │           varchar            │             varchar             │
├──────────────────────────┼──────────────────────────────┼─────────────────────────────────┤
│ 2024-09-28 14:59:00-03   │ gabriela.barbosa@example.net │ gabriela.barbosa.21@example.net │
│ 2025-12-28 17:42:32-03   │ murilo.alves@example.com     │ murilo.alves.55@example.org     │
└──────────────────────────┴──────────────────────────────┴─────────────────────────────────┘
```

825 such changes in the shop's history. A fact table keyed by e-mail would hold the first customer's
orders from before September 2024 under one address and the later ones under another, and "how much
did this customer spend" would need to know both.

**They are reused.** A shop that closes and a new one that opens under the same code; an ISBN that a
small publisher assigns twice by mistake; a product code recycled for a different item years later.
The fact rows from before and after point at the same key and mean different things.

**Systems are replaced.** When the shop moves to new till software, the new system numbers customers
from one again. Customer 2123 in the old system and customer 2123 in the new one are different
people, and a warehouse that keyed on `customer_id` alone has no way to tell their sales apart.

**Several sources disagree.** The website and a loyalty app may each know the same reader under their
own id. The warehouse is meant to be integrated (lesson 1), so it needs one identity that is neither of
theirs.

**The common thread: a natural key belongs to somebody else**, and that somebody can change it for
reasons that have nothing to do with the warehouse. The warehouse needs keys that only it controls.
