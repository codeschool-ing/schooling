---
title: Classes mapeadas
version: 1
---

Uma **classe mapeada** é uma classe Python com uma tabela por trás, como um model do Django. Salve as
duas do agenda em `app/models.py`:

```schooling-example
{"language": "python", "file": "app/models.py", "parts": [{"code": "# app/models.py\nfrom datetime import datetime\n\nfrom sqlalchemy import DateTime, ForeignKey, String, Text, UniqueConstraint, func\nfrom sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship\n\n\nclass Base(DeclarativeBase):\n    pass\n\n\n", "note": "Toda classe mapeada herda de uma única `Base`, que junta as tabelas delas em `Base.metadata`."}, {"code": "class Event(Base):\n    __tablename__ = \"events\"\n\n    id: Mapped[int] = mapped_column(primary_key=True)\n    slug: Mapped[str] = mapped_column(String(50), unique=True)\n    title: Mapped[str] = mapped_column(String(200))\n    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))\n    venue: Mapped[str] = mapped_column(String(200))\n    capacity: Mapped[int]\n    description: Mapped[str] = mapped_column(Text, default=\"\")\n\n", "note": "**A anotação decide a coluna.** `Mapped[int]` é um inteiro que não pode ser nulo; `Mapped[str | None]` permitiria nulo. O `mapped_column` acrescenta o que o tipo não consegue dizer: um tamanho, uma chave, uma unicidade."}, {"code": "    registrations: Mapped[list[\"Registration\"]] = relationship(\n        back_populates=\"event\", order_by=\"Registration.id\"\n    )\n\n", "note": "**Um relationship não é uma coluna.** É como um `Event` alcança suas inscrições em Python, pela chave estrangeira mais abaixo."}, {"code": "    @property\n    def taken(self) -> int:\n        return len(self.registrations)\n\n\n", "note": "Uma property comum do Python, que a API vai ler como um campo. Ela conta as inscrições que carregou."}, {"code": "class Registration(Base):\n    __tablename__ = \"registrations\"\n    __table_args__ = (UniqueConstraint(\"event_id\", \"email\"),)\n\n    id: Mapped[int] = mapped_column(primary_key=True)\n", "note": "Restrições sobre várias colunas vão em `__table_args__`: uma inscrição por endereço por evento, como na aula 4."}, {"code": "    event_id: Mapped[int] = mapped_column(ForeignKey(\"events.id\"))\n    name: Mapped[str] = mapped_column(String(100))\n    email: Mapped[str] = mapped_column(String(254))\n    created_at: Mapped[datetime] = mapped_column(\n        DateTime(timezone=True), server_default=func.now()\n    )\n\n    event: Mapped[Event] = relationship(back_populates=\"registrations\")\n", "note": "A chave estrangeira é a coluna; `event` é o relationship que lê através dela. O `server_default` põe o padrão na própria tabela."}]}
```

Os campos de `Event` são os que o `EventIn` valida em `app/schemas.py`, mais um `id`. **As duas classes
são coisas diferentes de propósito**: o schema diz o que um cliente pode mandar, o model diz o que a
tabela guarda, e mantê-los separados é o que deixa um mudar sem o outro.

O SQLAlchemy sabe imprimir o `CREATE TABLE` que rodaria, sem mandar nada. O `show_sql.py`:

```python
# show_sql.py
from sqlalchemy.schema import CreateTable

from app.db import engine
from app.models import Base

for table in Base.metadata.sorted_tables:
    print(CreateTable(table).compile(engine))
```

```
ana@vm:~/agenda-api$ uv run python show_sql.py

CREATE TABLE events (
	id SERIAL NOT NULL, 
	slug VARCHAR(50) NOT NULL, 
	title VARCHAR(200) NOT NULL, 
	starts_at TIMESTAMP WITH TIME ZONE NOT NULL, 
	venue VARCHAR(200) NOT NULL, 
	capacity INTEGER NOT NULL, 
	description TEXT NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (slug)
)



CREATE TABLE registrations (
	id SERIAL NOT NULL, 
	event_id INTEGER NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	email VARCHAR(254) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (event_id, email), 
	FOREIGN KEY(event_id) REFERENCES events (id)
)
```

Toda coluna que a anotação fez não opcional é `NOT NULL`. O `id` virou `SERIAL`, um inteiro que o
banco numera. E os dois padrões saíram diferentes: **`created_at` tem `DEFAULT now()` na tabela,
`description` não tem padrão nenhum**. O `default=""` é aplicado pelo SQLAlchemy quando ele insere uma
linha; uma linha inserida por qualquer outra coisa, o `psql` por exemplo, precisa informá-lo. O
`server_default` é o que pertence ao banco.

## As palavras do Django, as palavras do SQLAlchemy

| Django | SQLAlchemy |
|---|---|
| `class Event(models.Model)` | `class Event(Base)`, com `Base(DeclarativeBase)` |
| `models.CharField(max_length=200)` | `Mapped[str] = mapped_column(String(200))` |
| `null=True` | `Mapped[str \| None]` |
| `models.ForeignKey(Event, related_name=...)` | `ForeignKey("events.id")` mais um `relationship` |
| `Meta.constraints` | `__table_args__` |
| `makemigrations`, `migrate` | `alembic revision --autogenerate`, `alembic upgrade` |

A última linha é a próxima seção. Nada criou essas tabelas ainda.
