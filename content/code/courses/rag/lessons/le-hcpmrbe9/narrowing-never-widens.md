---
title: Narrowing never widens
version: 1
---

Not every filter is a permission. A seller may want to search only their agreement, a developer only
the API reference, a customer only the help for e-books. Those are **scopes the reader chooses**, and
a search box with a drop-down of sections is a perfectly good feature. The rule for combining them
with permissions is one line of `access.search`: the reader's choice is intersected with what the
role allows.

```
ana@lab:~/rag$ python narrow.py customer finance "How many refunds can I get before my account is flagged?"
customer, asking for ['finance']: nothing
ana@lab:~/rag$ python narrow.py seller sellers "How long do I have to dispatch an order?"
seller, asking for ['sellers']: ['Marketplace seller agreement > 3. Dispatch', 'Marketplace seller agreement > 5. Returns', 'Marketplace seller agreement > 4. Payouts']
```

A customer asking to search the finance documents gets **nothing**: the intersection of `public` and
`finance` is empty, and an empty list matches no row. A seller asking for the seller agreement gets
its sections on dispatch, returns and payouts. The parameter came from the request in both cases, and
in neither could it add an audience the role did not already have.

## Filters a model writes

Some frameworks offer a **self-querying retriever**: a model reads the question and writes the
filter, so that "refund rules for audiobooks updated this year" becomes a search with
`updated >= 2026-01-01`. It is useful for scopes, and it has to be handled like any other input from
the reader, because the question is the reader's text and the model's filter is derived from it.

- **The model's filter is a narrowing**, intersected with the permission filter exactly as above, and
  never a replacement for it. A question that says "include the finance documents" produces a filter
  that asks for finance, and the intersection removes it.
- **The fields it may name are a fixed list.** A filter on `audience` or `status` written by a model
  is a reader choosing their own permissions; a filter on `updated` or on a product is a scope.
- **The permission filter is computed from the session alone**, by code that never sees the question.

Lesson 16 meets the general form of this rule: text from the reader, or from a document, is data to
act on, never an instruction about what the system may do.
