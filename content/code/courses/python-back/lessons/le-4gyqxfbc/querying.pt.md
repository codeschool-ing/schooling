---
title: Consultas, e a consulta por linha
version: 1
---

Uma consulta no SQLAlchemy 2 é montada com `select()` e rodada pela session. O `queries.py` pergunta
quatro coisas:

```python
# queries.py
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db import engine
from app.models import Event, Registration

with Session(engine) as session:
    night = session.scalars(select(Event).where(Event.slug == "django-night")).one()
    print(night.title, night.capacity)

    same = session.get(Event, night.id)
    print(same is night)

    room_3 = select(Event).where(Event.venue == "Community Centre, room 3").order_by(Event.starts_at)
    print([e.slug for e in session.scalars(room_3)])

    counts = (
        select(Event.slug, func.count(Registration.id))
        .outerjoin(Event.registrations)
        .group_by(Event.slug)
        .order_by(Event.slug)
    )
    print(session.execute(counts).all())
```

```
ana@vm:~/agenda-api$ uv run python queries.py
Django Night 40
True
['django-night', 'testing-dojo']
[('async-workshop', 0), ('django-night', 0), ('testing-dojo', 0)]
```

| linha | o que ela mostra |
|---|---|
| `Django Night 40` | `select(Event).where(...)` é um comando; `session.scalars` o roda e entrega objetos; `.one()` exige exatamente um |
| `True` | **o mapa de identidade**: o `session.get` pela chave primária devolveu o objeto que a session já tinha para aquela linha, não uma cópia |
| dois slugs | `where` e `order_by` se somam ao comando; nada roda até a session percorrê-lo |
| as tuplas | um `select` de colunas devolve linhas, não objetos; o `outerjoin` mantém o evento sem inscrições |

## O mesmo N+1 da aula 4

`Event.taken` é `len(self.registrations)`, e as inscrições são carregadas **na primeira vez que alguém
pede por elas**. Para uma lista de eventos, isso é uma consulta para a lista e mais uma por evento. O
`nplus1.py` imprime toda consulta que a engine manda:

```python
# nplus1.py
from sqlalchemy import event, select
from sqlalchemy.orm import Session, selectinload

from app.db import engine
from app.models import Event


@event.listens_for(engine, "before_cursor_execute")
def show(connection, cursor, statement, parameters, context, executemany):
    if "\nFROM " in statement:
        print("  query: FROM", " ".join(statement.split("\nFROM ")[1].split()), parameters)


with Session(engine) as session:
    print("lazy:")
    for e in session.scalars(select(Event)):
        print(e.slug, e.taken)

with Session(engine) as session:
    print("selectinload:")
    for e in session.scalars(select(Event).options(selectinload(Event.registrations))):
        print(e.slug, e.taken)
```

```
ana@vm:~/agenda-api$ uv run python nplus1.py
lazy:
  query: FROM events {}
  query: FROM registrations WHERE %(param_1)s::INTEGER = registrations.event_id ORDER BY registrations.id {'param_1': 1}
django-night 0
  query: FROM registrations WHERE %(param_1)s::INTEGER = registrations.event_id ORDER BY registrations.id {'param_1': 2}
async-workshop 0
  query: FROM registrations WHERE %(param_1)s::INTEGER = registrations.event_id ORDER BY registrations.id {'param_1': 3}
testing-dojo 0
selectinload:
  query: FROM events {}
  query: FROM registrations WHERE registrations.event_id IN (%(primary_keys_1)s::INTEGER, %(primary_keys_2)s::INTEGER, %(primary_keys_3)s::INTEGER) ORDER BY registrations.id {'primary_keys_1': 1, 'primary_keys_2': 2, 'primary_keys_3': 3}
django-night 0
async-workshop 0
testing-dojo 0
```

**Quatro consultas para três eventos, depois duas.** O primeiro laço é exatamente o problema da aula
4: uma lista de cem eventos custaria cento e uma consultas. O `selectinload(Event.registrations)`
carrega as inscrições de todos os eventos da página numa segunda consulta, com `IN`, que é o que o
`prefetch_related` do Django faz. O primo dele, `joinedload`, faz isso na mesma consulta com um join,
como o `select_related`, e serve melhor a um relationship com uma linha só do outro lado do que a uma
lista.

O carregamento preguiçoso continua sendo o padrão porque ele nunca está errado, só lento, e lento
aparece numa lista de consultas como esta. **Quando uma rota devolve vários objetos e toca um
relationship de cada um, carregue antecipadamente.** Para uma contagem sobre uma tabela grande, contar
no SQL, como a última linha do `queries.py` fez, é melhor do que carregar as linhas para chamar `len`
nelas.
