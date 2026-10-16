---
title: Relações, e a consulta que roda uma vez por linha
version: 1
---

`Registration.event` é uma **chave estrangeira**: uma coluna, `event_id`, com o id de um evento. O
Django dá às duas pontas um caminho até a outra. Uma inscrição tem `.event`, o objeto do evento; um
evento tem `.registrations`, um manager das inscrições dele, com o nome dado pelo `related_name`:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from events.models import Event; e = Event.objects.get(slug=\"testing-dojo\"); print(e.registrations.all()); print(e.registrations.first().event.venue)"
14 objects imported automatically (use -v 2 for details).

<QuerySet [<Registration: Carla for Testing dojo>, <Registration: Davi for Testing dojo>]>
Community Centre, room 3
```

O `e.registrations.all()` é um QuerySet como outro qualquer, filtrado para este evento. E
`e.registrations.first().event.venue` foi da inscrição de volta ao evento, com uma consulta em cada
sentido.

## Uma consulta por linha

Essa "consulta em cada sentido" é barata uma vez e cara num laço. Este script lista cada evento com o
número de inscrições, primeiro do jeito óbvio, depois do jeito que escala:

```python
# nplus1.py
from django.db import connection, reset_queries
from django.db.models import Count

from events.models import Event

reset_queries()
for event in Event.objects.all():
    print(event.title, event.registrations.count())
print(len(connection.queries), "queries")

reset_queries()
for event in Event.objects.annotate(taken=Count("registrations")):
    print(event.title, event.taken)
print(len(connection.queries), "query")
```

```
ana@vm:~/agenda$ uv run python manage.py shell < nplus1.py
14 objects imported automatically (use -v 2 for details).

Django Night 1
Async Python workshop 12
Testing dojo 2
4 queries
Async Python workshop 12
Testing dojo 2
Django Night 1
1 query
```

**O laço mandou quatro consultas para três eventos**: uma para os eventos e um `COUNT` por evento. Com
mil eventos mandaria 1.001, e a página que lista eventos com os lugares ocupados é exatamente onde
esse laço é escrito. O `annotate(taken=Count("registrations"))` pediu os mesmos números em **uma
consulta**, com um join e um `GROUP BY`, e pôs a contagem em cada objeto como `taken`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"À esquerda, um laço que pede a cada evento a contagem de inscrições manda uma consulta para os eventos e depois uma consulta COUNT por evento: quatro para três eventos, e 1.001 para mil. À direita, o annotate com Count manda uma consulta só, que junta as inscrições e agrupa por evento.\"> <defs><marker id=\"np-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">event.registrations.count() num laço</text> <rect x=\"40\" y=\"36\" width=\"280\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT … FROM events_event</text> <rect x=\"60\" y=\"68\" width=\"260\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"190\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT COUNT(*) … event_id = 1</text> <rect x=\"60\" y=\"98\" width=\"260\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"190\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT COUNT(*) … event_id = 2</text> <rect x=\"60\" y=\"128\" width=\"260\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"190\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT COUNT(*) … event_id = 3</text> <text x=\"180\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 + N consultas: 4 aqui, 1.001 para 1.000 eventos</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">annotate(taken=Count(\"registrations\"))</text> <rect x=\"390\" y=\"36\" width=\"310\" height=\"84\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"545\" y=\"58\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT events_event.*,</text> <text x=\"545\" y=\"75\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">COUNT(events_registration.id)</text> <text x=\"545\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">LEFT OUTER JOIN … GROUP BY id</text> <text x=\"545\" y=\"174\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1 consulta, não importa quantos eventos</text> </svg>", "caption": "O custo do laço cresce com o número de linhas; o da anotação, não. A página que lista eventos com os lugares ocupados é exatamente onde o primeiro formato se esconde."}
```

**A ordem também mudou**: a lista anotada voltou como Async, Testing, Django. O Django deixa o
`Meta.ordering` de fora de uma consulta com `GROUP BY`, desde a versão 3.1, então uma consulta que
agrega deve dizer `order_by()` ela mesma se a ordem importar.

## As duas ferramentas para linhas relacionadas

| | o que faz | para |
|---|---|---|
| `select_related("event")` | uma consulta com `JOIN` | seguir uma chave estrangeira para a frente: inscrições com seus eventos |
| `prefetch_related("registrations")` | uma segunda consulta, depois casada no Python | o lado reverso, ou muitos-para-muitos: eventos com as listas de inscrições |
| `annotate(Count(…))` | um `JOIN` com `GROUP BY` | um número por linha, sem buscar as linhas relacionadas |

O hábito que acha esses casos é o da seção anterior: contar as consultas que uma página faz. O
`connection.queries` num script, e na aula 14 um teste que falha quando uma página faz mais consultas
do que deveria.
