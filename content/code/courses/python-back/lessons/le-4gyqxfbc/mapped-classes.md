---
title: Mapped classes
version: 1
---

A **mapped class** is a Python class with a table behind it, the way a Django model is. Save agenda's
two in `app/models.py`:

```schooling-example
{"language": "python", "file": "app/models.py", "parts": [{"code": "# app/models.py\nfrom datetime import datetime\n\nfrom sqlalchemy import DateTime, ForeignKey, String, Text, UniqueConstraint, func\nfrom sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship\n\n\nclass Base(DeclarativeBase):\n    pass\n\n\n", "note": "Every mapped class inherits from one `Base`, which collects their tables in `Base.metadata`."}, {"code": "class Event(Base):\n    __tablename__ = \"events\"\n\n    id: Mapped[int] = mapped_column(primary_key=True)\n    slug: Mapped[str] = mapped_column(String(50), unique=True)\n    title: Mapped[str] = mapped_column(String(200))\n    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))\n    venue: Mapped[str] = mapped_column(String(200))\n    capacity: Mapped[int]\n    description: Mapped[str] = mapped_column(Text, default=\"\")\n\n", "note": "**The annotation decides the column.** `Mapped[int]` is an integer that may not be null; `Mapped[str | None]` would allow null. `mapped_column` adds what the type cannot say: a length, a key, a uniqueness."}, {"code": "    registrations: Mapped[list[\"Registration\"]] = relationship(\n        back_populates=\"event\", order_by=\"Registration.id\"\n    )\n\n", "note": "**A relationship is not a column.** It is how an `Event` reaches its registrations in Python, through the foreign key below."}, {"code": "    @property\n    def taken(self) -> int:\n        return len(self.registrations)\n\n\n", "note": "A plain Python property, which the API will read like a field. It counts the registrations it has loaded."}, {"code": "class Registration(Base):\n    __tablename__ = \"registrations\"\n    __table_args__ = (UniqueConstraint(\"event_id\", \"email\"),)\n\n    id: Mapped[int] = mapped_column(primary_key=True)\n", "note": "Constraints over several columns go in `__table_args__`: one registration per address per event, as in lesson 4."}, {"code": "    event_id: Mapped[int] = mapped_column(ForeignKey(\"events.id\"))\n    name: Mapped[str] = mapped_column(String(100))\n    email: Mapped[str] = mapped_column(String(254))\n    created_at: Mapped[datetime] = mapped_column(\n        DateTime(timezone=True), server_default=func.now()\n    )\n\n    event: Mapped[Event] = relationship(back_populates=\"registrations\")\n", "note": "The foreign key is the column; `event` is the relationship that reads through it. `server_default` puts the default in the table itself."}]}
```

The fields of `Event` are the ones `EventIn` validates in `app/schemas.py`, plus an `id`. **The two
classes are different things on purpose**: the schema says what a client may send, the model says
what the table holds, and keeping them apart is what lets one change without the other.

SQLAlchemy can print the `CREATE TABLE` it would run, without sending anything. `show_sql.py`:

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

Every column the annotation made non-optional is `NOT NULL`. `id` became `SERIAL`, an integer the
database numbers. And the two defaults came out differently: **`created_at` has `DEFAULT now()` in
the table, `description` has no default at all**. `default=""` is applied by SQLAlchemy when it
inserts a row; a row inserted by anything else, `psql` for one, has to say it. `server_default` is
the one that belongs to the database.

## Django's words, SQLAlchemy's words

| Django | SQLAlchemy |
|---|---|
| `class Event(models.Model)` | `class Event(Base)`, with `Base(DeclarativeBase)` |
| `models.CharField(max_length=200)` | `Mapped[str] = mapped_column(String(200))` |
| `null=True` | `Mapped[str \| None]` |
| `models.ForeignKey(Event, related_name=...)` | `ForeignKey("events.id")` plus a `relationship` |
| `Meta.constraints` | `__table_args__` |
| `makemigrations`, `migrate` | `alembic revision --autogenerate`, `alembic upgrade` |

The last line is the next section. Nothing has created these tables yet.
