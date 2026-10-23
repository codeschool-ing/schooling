---
title: QuerySets: asking for rows in Python
version: 1
---

Every model gets a **manager**, `Event.objects`, and the manager's methods return **QuerySets**:
lists of rows that have not been fetched yet. Save this as `queries.py` in `~/agenda` and run it the
way the seed ran:

```python
# queries.py
from events.models import Event

events = Event.objects.filter(venue__startswith="Community")
print(type(events).__name__)
print([e.title for e in events])
print(Event.objects.count())
print(Event.objects.get(slug="testing-dojo").starts_at)
print(Event.objects.exclude(capacity__gte=20).values_list("title", flat=True))
print(Event.objects.order_by("-capacity").first())
```

```
ana@vm:~/agenda$ uv run python manage.py shell < queries.py
14 objects imported automatically (use -v 2 for details).

QuerySet
['Django Night', 'Testing dojo']
3
2026-11-26 22:00:00+00:00
<QuerySet ['Async Python workshop']>
Django Night
```

Line by line:

- `filter(venue__startswith="Community")` is a **QuerySet**, not a list. The double underscore
  separates a field from a **lookup**: `startswith`, here, which became `LIKE 'Community%'`.
- `count()` asks the database for a count rather than fetching three rows to count them.
- `get(slug="testing-dojo")` returns **one object**, and raises `Event.DoesNotExist` if there is
  none and `MultipleObjectsReturned` if there are several. Its `starts_at` came back as **22:00 in
  UTC**, the zone Django keeps every value in; the page will show 19:00.
- `exclude(capacity__gte=20)` is the opposite of `filter`, and `values_list("title", flat=True)`
  fetches one column instead of whole objects.
- `order_by("-capacity").first()` is the event with the most seats: the minus sign sorts descending,
  and `first()` returns an object or `None`, never an exception.

## The lookups you will use most

| lookup | SQL | example |
|---|---|---|
| `exact` (the default) | `=` | `slug="testing-dojo"` |
| `iexact`, `icontains` | `UPPER(…) =`, `UPPER(…) LIKE` | `title__icontains="django"` |
| `startswith`, `endswith` | `LIKE 'x%'`, `LIKE '%x'` | `venue__startswith="Community"` |
| `gt`, `gte`, `lt`, `lte` | `>`, `>=`, `<`, `<=` | `capacity__gte=20` |
| `in` | `IN (…)` | `slug__in=["django-night", "testing-dojo"]` |
| `isnull` | `IS NULL` | `description__isnull=True` |
| a relation, then a field | a `JOIN` | `registrations__email="bruno@example.org"` |

The list view of lesson 3 searched with a comprehension over `EVENTS`. It becomes one line, and the
filtering moves into the database:

```python
events = Event.objects.filter(title__icontains=q)
```

The whole of the new `events/views.py` is in the section on constraints and transactions, with the
rule it now calls.
