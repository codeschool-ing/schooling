---
title: QuerySets: pedir linhas em Python
version: 1
---

Todo modelo ganha um **manager**, `Event.objects`, e os métodos do manager devolvem **QuerySets**:
listas de linhas que ainda não foram buscadas. Salve isto como `queries.py` em `~/agenda` e rode do
jeito que o seed rodou:

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

Linha a linha:

- `filter(venue__startswith="Community")` é um **QuerySet**, não uma lista. O sublinhado duplo separa
  um campo de um **lookup**: `startswith`, aqui, que virou `LIKE 'Community%'`.
- O `count()` pede ao banco uma contagem em vez de buscar três linhas para contá-las.
- O `get(slug="testing-dojo")` devolve **um objeto**, e levanta `Event.DoesNotExist` se não houver
  nenhum e `MultipleObjectsReturned` se houver vários. O `starts_at` dele voltou como **22:00 em UTC**,
  o fuso em que o Django guarda todo valor; a página vai mostrar 19:00.
- O `exclude(capacity__gte=20)` é o oposto do `filter`, e o `values_list("title", flat=True)` busca
  uma coluna em vez de objetos inteiros.
- O `order_by("-capacity").first()` é o evento com mais lugares: o sinal de menos ordena de forma
  decrescente, e o `first()` devolve um objeto ou `None`, nunca uma exceção.

## Os lookups que você vai usar mais

| lookup | SQL | exemplo |
|---|---|---|
| `exact` (o padrão) | `=` | `slug="testing-dojo"` |
| `iexact`, `icontains` | `UPPER(…) =`, `UPPER(…) LIKE` | `title__icontains="django"` |
| `startswith`, `endswith` | `LIKE 'x%'`, `LIKE '%x'` | `venue__startswith="Community"` |
| `gt`, `gte`, `lt`, `lte` | `>`, `>=`, `<`, `<=` | `capacity__gte=20` |
| `in` | `IN (…)` | `slug__in=["django-night", "testing-dojo"]` |
| `isnull` | `IS NULL` | `description__isnull=True` |
| uma relação, depois um campo | um `JOIN` | `registrations__email="bruno@example.org"` |

A view da lista da aula 3 buscava com uma compreensão sobre `EVENTS`. Ela vira uma linha, e o filtro
vai para dentro do banco:

```python
events = Event.objects.filter(title__icontains=q)
```

O `events/views.py` novo inteiro está na seção sobre restrições e transações, com a regra que ele
agora chama.
