---
title: O SQLAlchemy, e a engine
version: 1
---

O Django veio com sua camada de banco de dados. O FastAPI não: ele cuida das requisições e deixa o
armazenamento com você. A biblioteca que quase todo projeto Python fora do Django usa para isso é o
**SQLAlchemy**, e a que muda as tabelas ao longo do tempo é o **Alembic**, do mesmo autor. O SQLModel,
que o próprio tutorial do FastAPI usa, é uma camada sobre o SQLAlchemy, então o que esta aula ensina
também está por baixo dele.

A API ganha um banco próprio no PostgreSQL que a aula 4 instalou. Em `~/agenda-api`, adicione as duas
bibliotecas e o mesmo driver que o Django usa, e então crie o banco:

```
ana@vm:~/agenda-api$ uv add sqlalchemy psycopg alembic
Resolved 27 packages in 259ms
Downloading sqlalchemy (4.5MiB)
 Downloaded sqlalchemy
Prepared 4 packages in 127ms
Installed 5 packages in 4ms
 + alembic==1.20.1
 + mako==1.4.3
 + markupsafe==3.0.4
 + psycopg==3.3.6
 + sqlalchemy==2.1.6
ana@vm:~/agenda-api$ createdb agenda_api
```

O `createdb` funcionou sem senha porque a aula 4 fez de `ana` um papel do PostgreSQL, e uma conexão
local como o mesmo usuário entra por **autenticação peer**: o PostgreSQL pergunta ao sistema
operacional quem está do outro lado do socket.

## Uma engine por processo

Tudo o que o SQLAlchemy manda passa por uma **engine**. Crie uma num módulo novo, `app/db.py`:

```python
# app/db.py
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg:///agenda_api")
```

A URL diz tudo sobre onde se conectar:

| parte | significado |
|---|---|
| `postgresql` | o dialeto: qual SQL escrever |
| `+psycopg` | o driver: qual biblioteca o leva |
| `///` | sem usuário, sem senha e sem host: o socket local, como o usuário do sistema operacional |
| `agenda_api` | o banco |

**O `create_engine` não se conecta.** Ele monta um **pool**, que abre conexões na primeira vez que algo
pede uma e as mantém abertas para a próxima. Um script curto, `hello_db.py`, pede uma:

```python
# hello_db.py
from sqlalchemy import text

from app.db import engine

with engine.connect() as connection:
    result = connection.execute(text("select current_user, current_database()"))
    print(result.one())
```

```
ana@vm:~/agenda-api$ uv run python hello_db.py
('ana', 'agenda_api')
```

O `text()` é SQL puro, rodado numa conexão emprestada do pool e devolvida quando o bloco `with`
termina. Isto é o **Core**, a metade do SQLAlchemy que fala em comandos SQL. A outra metade, o **ORM**,
fala em objetos, e é construída sobre o Core:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Cinco caixas da esquerda para a direita: seu código, que trabalha com objetos Event; a Session, que mantém um mapa de identidade e uma unidade de trabalho; a Engine, um pool de conexões; o psycopg, o driver; e o PostgreSQL com o banco agenda_api. Uma consulta do ORM entra pela Session; uma consulta do Core com text entra pela Engine.\"> <defs><marker id=\"ly-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"40\" width=\"100\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"70.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu código</text> <text x=\"70.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">objetos Event</text> <rect x=\"136\" y=\"40\" width=\"190\" height=\"58\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"231.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Session</text> <text x=\"231.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mapa de identidade, unidade de trabalho</text> <rect x=\"342\" y=\"40\" width=\"120\" height=\"58\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"402.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Engine</text> <text x=\"402.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um pool de conexões</text> <rect x=\"478\" y=\"40\" width=\"90\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"523.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">psycopg</text> <text x=\"523.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o driver</text> <rect x=\"584\" y=\"40\" width=\"116\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"642.0\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">PostgreSQL</text> <text x=\"642.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">agenda_api</text> <path d=\"M120 69 L132 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <path d=\"M326 69 L338 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <path d=\"M462 69 L474 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <path d=\"M568 69 L580 69\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ly-a)\"></path> <text x=\"136\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORM: session.scalars(select(Event))</text> <text x=\"342\" y=\"150\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Core: connection.execute(text(...))</text> <path d=\"M231 134 L231 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ly-a)\"></path> <path d=\"M402 156 L402 100\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ly-a)\"></path> <text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O ORM é construído sobre o Core; os dois mandam seu SQL pela mesma engine.</text> </svg>", "caption": "O SQLAlchemy em camadas. O hello_db.py entrou pela engine; o seed.py e o queries.py, pela session.", "same": ["PostgreSQL", "agenda_api"]}
```

Crie a engine **uma vez por processo**, na importação, como o `app/db.py` faz. Uma engine por
requisição abriria uma conexão por requisição, que é o custo que o pool existe para evitar. E a URL
parada no código é um problema da aula 15: lá ela vai para o ambiente, com senha, por TCP.
