---
title: Using an ORM correctly
version: 1
---

An **ORM**, an object-relational mapper, writes the SQL for you from Python objects. Used as
intended, it parameterises every value, which is one of the best reasons to use one. It also offers
a way back to raw SQL, and that way back is where injection returns in projects that thought the
ORM had removed it.

This section uses SQLAlchemy, the most widely used ORM in Python, against the same `patients.db`.
Install it:

```
(.venv) ana@vm:~/sc/search$ pip install --progress-bar off sqlalchemy==2.1.6
Collecting sqlalchemy==2.1.6
  Downloading sqlalchemy-2.1.6-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (9.7 kB)
Requirement already satisfied: typing-extensions>=4.6.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from sqlalchemy==2.1.6) (4.16.0)
Downloading sqlalchemy-2.1.6-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (4.7 MB)
Installing collected packages: sqlalchemy
Successfully installed sqlalchemy-2.1.6
```

`orm.py` maps the `patients` table to a class and asks for lucia three ways. Save it beside
`app.py`:

```schooling-example
{"language": "python", "file": "orm.py", "parts": [{"code": "# orm.py\nfrom sqlalchemy import String, create_engine, select, text\nfrom sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column\n\n\nclass Base(DeclarativeBase):\n    pass\n\n\nclass Patient(Base):\n    __tablename__ = \"patients\"\n    id: Mapped[int] = mapped_column(primary_key=True)\n    first_name: Mapped[str] = mapped_column(String(50))\n    surname: Mapped[str] = mapped_column(String(50))\n    clinic: Mapped[str] = mapped_column(String(50))\n\n\nengine = create_engine(\"sqlite:///patients.db\")\nname = \"D'Ávila\"\n", "note": "A class for the `patients` table, in SQLAlchemy 2's typed style, and the same database file the portal uses."}, {"code": "with Session(engine) as session:\n    query = select(Patient.surname).where(Patient.surname == name)\n    print(query)\n    print(session.scalars(query).all())\n", "note": "The query built from objects. `print(query)` shows the SQL the ORM will send, before it sends it."}, {"code": "    bound = text(\"SELECT surname FROM patients WHERE surname = :surname\")\n    print(session.scalars(bound, {\"surname\": name}).all())\n", "note": "Raw SQL through `text()`, with a named placeholder and the value in a dictionary."}, {"code": "    built = text(f\"SELECT surname FROM patients WHERE surname = '{name}'\")\n    print(session.scalars(built).all())", "note": "Raw SQL built with an f-string: the way back, used the wrong way."}]}
```

```
(.venv) ana@vm:~/sc/search$ python3 orm.py 2>&1 | grep -v '^ '
SELECT patients.surname 
FROM patients 
WHERE patients.surname = :surname_1
["D'Ávila"]
["D'Ávila"]
Traceback (most recent call last):
sqlite3.OperationalError: near "Ávila": syntax error

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) near "Ávila": syntax error
[SQL: SELECT surname FROM patients WHERE surname = 'D'Ávila']
(Background on this error at: https://sqlalche.me/e/21/e3q8)
```

The `grep -v '^ '` hides the indented lines of the traceback, so what is left is what each of the
three ways printed.

- **The query built from objects** printed its SQL first, and the value is a **bound parameter**,
  `:surname_1`, not the name. The second line is the result: `D'Ávila`, found.
- **`text()` with `:surname`** is raw SQL, and it is still safe, because the name travels as a value
  in the dictionary beside it. Raw SQL is not the problem.
- **`text()` with an f-string** is the flaw of the first section, written inside the ORM. SQLAlchemy
  passed the string to SQLite, and SQLite failed on the same apostrophe with the same message. The
  ORM cannot protect a value that has already been pasted into the text.

### What to look for in review

Every ORM has its own spelling of the way back, and each is safe with bound values and unsafe with a
string built from them:

| ORM | the way back to SQL |
|---|---|
| SQLAlchemy | `text(…)`, and `.where()` given a string instead of an expression |
| Django | `.raw(…)`, `.extra(…)`, `RawSQL(…)`, and `cursor.execute(…)` |
| ActiveRecord | `where("surname = '#{name}'")`, `order(params[:sort])` |

A search of a codebase for those names, followed by a look at what builds the string passed to
each, finds most injections an ORM project has. The rest of the review is the same as without an
ORM: **sort columns, table names and other identifiers come from an allowlist**, because no ORM can
bind a column name as a value either.
