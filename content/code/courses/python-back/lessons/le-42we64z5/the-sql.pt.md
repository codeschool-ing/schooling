---
title: O SQL por trás de um QuerySet
version: 1
---

Um ORM poupa escrever SQL. Ele não poupa saber que SQL escreveu, porque o banco roda esse SQL e não o
Python. O Django deixa você ver de três jeitos, e o `sql.py` usa os três:

```python
# sql.py
from django.db import connection, reset_queries

from events.models import Event

events = Event.objects.filter(venue__startswith="Community").order_by("-starts_at")
print(events.query)
reset_queries()
titles = [e.title for e in events]
print(len(connection.queries), "query:", connection.queries[0]["sql"])
print(events.explain())
```

```
ana@vm:~/agenda$ uv run python manage.py shell < sql.py
14 objects imported automatically (use -v 2 for details).

SELECT "events_event"."id", "events_event"."title", "events_event"."slug", "events_event"."starts_at", "events_event"."venue", "events_event"."capacity", "events_event"."description" FROM "events_event" WHERE "events_event"."venue"::text LIKE Community% ORDER BY "events_event"."starts_at" DESC
1 query: SELECT "events_event"."id", "events_event"."title", "events_event"."slug", "events_event"."starts_at", "events_event"."venue", "events_event"."capacity", "events_event"."description" FROM "events_event" WHERE "events_event"."venue"::text LIKE 'Community%' ORDER BY "events_event"."starts_at" DESC
Sort  (cost=10.88..10.89 rows=1 width=1006)
  Sort Key: starts_at DESC
  ->  Seq Scan on events_event  (cost=0.00..10.88 rows=1 width=1006)
        Filter: ((venue)::text ~~ 'Community%'::text)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Três chamadas encadeadas, Event.objects, filter e order_by, montam um QuerySet e não mandam consulta nenhuma ao banco. Na primeira vez que o QuerySet é usado, numa compreensão de lista, o Django manda um SELECT com WHERE e ORDER BY, e transforma cada linha num objeto Event.\"> <defs><marker id=\"lz-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">montar um QuerySet não roda nada</text> <rect x=\"20\" y=\"38\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"85\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Event.objects</text> <rect x=\"170\" y=\"38\" width=\"210\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.filter(venue__startswith=…)</text> <rect x=\"400\" y=\"38\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"480\" y=\"59\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.order_by(\"-starts_at\")</text> <path d=\"M150 55 L164 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lz-a)\"></path> <path d=\"M380 55 L394 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lz-a)\"></path> <text x=\"640\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">0 consultas</text> <text x=\"640\" y=\"68\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma descrição</text> <text x=\"20\" y=\"112\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">usá-lo manda um SELECT</text> <rect x=\"20\" y=\"124\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"120\" y=\"145\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[e.title for e in events]</text> <path d=\"M220 141 L262 141\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#lz-a)\"></path> <rect x=\"268\" y=\"124\" width=\"292\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"414\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SELECT … FROM \"events_event\"</text> <text x=\"414\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WHERE venue LIKE 'Community%'</text> <text x=\"414\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ORDER BY starts_at DESC</text> <text x=\"640\" y=\"145\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1 consulta</text> <text x=\"640\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linhas viram objetos</text> <text x=\"20\" y=\"228\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Iterar, len(), list(), fatiar com passo, bool() e imprimir o rodam. Cada método encadeado devolve um QuerySet novo.</text> </svg>", "caption": "Um QuerySet é a descrição de um SELECT até algo precisar das linhas. A execução do sql.py imprimiu a descrição e depois contou exatamente uma consulta."}
```

## O que cada um dos três diz

O **`print(events.query)`** mostra o comando como o Django o montou, **antes de qualquer coisa
rodar**. Repare em `LIKE Community%`, sem aspas: os parâmetros são colados para leitura, não citados
para execução, então esse texto é para os seus olhos e nunca para o `psql`.

O **`connection.queries`** é a lista dos comandos que rodaram de fato, com os parâmetros reais,
`'Community%'` entre aspas. O Django só a mantém enquanto o `DEBUG` está ligado, e é por isso que é
uma ferramenta de desenvolvimento; o `reset_queries()` a esvazia. Montar o QuerySet não rodou nada; a
compreensão de lista rodou **exatamente uma consulta**, não importa quantas linhas voltaram.

O **`explain()`** pergunta ao PostgreSQL como ele rodaria o comando. `Seq Scan` quer dizer que ele lê
a tabela inteira, o que para três linhas é o plano mais rápido que existe; numa tabela de um milhão de
eventos filtrada por venue, a mesma linha é um motivo para acrescentar um índice. Ler planos direito
é trabalho do curso `sql-databases`, e o hábito a levar daqui é olhar.

## Quando o ORM não basta

O `Event.objects.raw("SELECT …")` roda o seu SQL e devolve objetos de modelo, e o
`django.db.connection.cursor()` roda qualquer coisa. Os dois passam os parâmetros em separado, como
`cursor.execute("… WHERE slug = %s", [slug])`, e **nunca formatando-os dentro do texto**, que é como
acontece a injeção de SQL. Tudo de que este curso precisa, o ORM consegue dizer.
