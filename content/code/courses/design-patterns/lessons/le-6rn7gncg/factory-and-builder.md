---
title: Factory and builder: making objects without saying how
version: 1
---

**A factory decides which class to build so the caller does not have to; a builder assembles one
complicated object step by step so the caller does not need a constructor with twelve arguments.**
Both are creational patterns, and both are answers to the same complaint: the line that creates an
object knows too much.

Make `~/patterns/gof` and work there for the whole lesson:

```sh
mkdir -p ~/patterns/gof
cd ~/patterns/gof
```

## A factory: the kind decides the class

The library's stock arrives as rows from a spreadsheet, and each row says what kind of item it is.
Somewhere a string has to become a class. Without a factory, that `if` lands in whichever function
happens to read the rows, and in the next one, and in the one after.

```schooling-example
{"language": "python", "file": "factory.py", "parts": [
 {"code": "# factory.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\n\n@dataclass\nclass Book:\n    title: str\n    loan_days: int = 14\n\n\n@dataclass\nclass Film:\n    title: str\n    minutes: int\n    loan_days: int = 7", "note": "Two kinds of item and a loan, as small dataclasses. The point of the file is the code below them."},
 {"code": "\n\nKINDS = {\"book\": Book, \"film\": Film}\n\n\ndef item_from_row(row: dict):\n    fields = dict(row)\n    kind = fields.pop(\"kind\")\n    if kind not in KINDS:\n        raise ValueError(f\"unknown kind {kind!r}\")\n    return KINDS[kind](**fields)", "note": "The factory is a dictionary and a function. Adding a kind is one line in `KINDS`, and no caller changes."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    due: date\n\n    @classmethod\n    def for_item(cls, item, lent_on: date) -> \"Loan\":\n        return cls(item.title, lent_on + timedelta(days=item.loan_days))", "note": "A named constructor is the other everyday factory. `Loan.for_item` reads better than working out the due date at every call site, and it is a factory method in the plain sense: a method whose job is to create."},
 {"code": "\n\nif __name__ == \"__main__\":\n    rows = [{\"kind\": \"book\", \"title\": \"Quincas Borba\"},\n            {\"kind\": \"film\", \"title\": \"Cidade de Deus\", \"minutes\": 130},\n            {\"kind\": \"vinyl\", \"title\": \"Clube da Esquina\"}]\n    for row in rows:\n        try:\n            item = item_from_row(row)\n        except ValueError as err:\n            print(\"refused:\", err)\n            continue\n        print(item, \"->\", Loan.for_item(item, date(2026, 5, 4)).due)", "note": "The rows could come from a file; here they are a list. The third is a kind the factory does not know, and it says so by name."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 factory.py
Book(title='Quincas Borba', loan_days=14) -> 2026-05-18
Film(title='Cidade de Deus', minutes=130, loan_days=7) -> 2026-05-11
refused: unknown kind 'vinyl'
```

The film is due a week after 4 May and the book two weeks after, and neither the loop nor `Loan`
asked which was which.

The GoF book's **Factory Method** is a narrower thing: a base class calls `self.make_item(row)` and
lets each subclass decide which class that returns. It appears in frameworks, where you subclass
something and override the one method that creates your objects. In application code the
dictionary and the class method above do the same job with less machinery, and Python's standard
library is full of the second kind: `date.fromisoformat`, `dict.fromkeys`, `int.from_bytes`.

## A builder: one object, many optional parts

The catalogue search has an author filter, a year filter, an "available only" switch, an order and
a limit, and any combination may be asked for. A constructor with all of them is unreadable at the
call site: `Search(None, 1950, True, "year", None)` says nothing to the next reader.

```schooling-example
{"language": "python", "file": "builder.py", "parts": [
 {"code": "# builder.py\nimport sqlite3\nfrom dataclasses import dataclass\n\n\n@dataclass(frozen=True)\nclass Query:\n    sql: str\n    params: tuple", "note": "What the builder produces: a finished, frozen query. Nothing can change it once built."},
 {"code": "\n\nclass QueryBuilder:\n    ORDERS = (\"title\", \"year\")\n\n    def __init__(self):\n        self._where, self._params = [], []\n        self._order = \"title\"\n\n    def by_author(self, author: str) -> \"QueryBuilder\":\n        self._where.append(\"author = ?\")\n        self._params.append(author)\n        return self\n\n    def published_before(self, year: int) -> \"QueryBuilder\":\n        self._where.append(\"year < ?\")\n        self._params.append(year)\n        return self\n\n    def available_only(self) -> \"QueryBuilder\":\n        self._where.append(\"on_loan = 0\")\n        return self", "note": "Each step records one part and returns the builder itself, which is what lets the calls chain."},
 {"code": "\n    def order_by(self, column: str) -> \"QueryBuilder\":\n        if column not in self.ORDERS:\n            raise ValueError(f\"cannot order by {column!r}\")\n        self._order = column\n        return self", "note": "A step can check its input as it arrives. An order by a column nobody allowed is refused here, long before it reaches the database."},
 {"code": "\n    def build(self) -> Query:\n        sql = \"SELECT title, year FROM items\"\n        if self._where:\n            sql += \" WHERE \" + \" AND \".join(self._where)\n        sql += f\" ORDER BY {self._order}\"\n        return Query(sql, tuple(self._params))", "note": "`build` turns the collected parts into the product. The values travel as parameters, never pasted into the SQL text."},
 {"code": "\n\nif __name__ == \"__main__\":\n    db = sqlite3.connect(\":memory:\")\n    db.execute(\"CREATE TABLE items (title, author, year, on_loan)\")\n    db.executemany(\"INSERT INTO items VALUES (?, ?, ?, ?)\", [\n        (\"Dom Casmurro\", \"Machado de Assis\", 1899, 1),\n        (\"Quincas Borba\", \"Machado de Assis\", 1891, 0),\n        (\"Memórias Póstumas de Brás Cubas\", \"Machado de Assis\", 1881, 0),\n        (\"Vidas Secas\", \"Graciliano Ramos\", 1938, 0)])\n    q = (QueryBuilder().by_author(\"Machado de Assis\")\n         .available_only().order_by(\"year\").build())\n    print(q.sql)\n    print(q.params)\n    for row in db.execute(q.sql, q.params):\n        print(row)", "note": "An in-memory SQLite database with four books, so the query is shown working rather than only printed."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 builder.py
SELECT title, year FROM items WHERE author = ? AND on_loan = 0 ORDER BY year
('Machado de Assis',)
('Memórias Póstumas de Brás Cubas', 1881)
('Quincas Borba', 1891)
```

Dom Casmurro is on loan, so two of Machado's three books come back, oldest first. The call site
reads as a sentence, and each part is optional.

## When Python does not need one

**In Python, keyword arguments with defaults replace most builders.** `search(author="Machado de
Assis", available=True, order="year")` is as readable as the chain, and a dataclass with defaults
gives the same thing for plain data. A builder earns its place when the steps do real work, as
`order_by` does when it validates, or when the object is assembled in several places before it is
finished, the way a request is built up by middleware.

| language | the usual form |
|---|---|
| Java | builders everywhere: `HttpRequest.newBuilder()`, `StringBuilder`, Lombok's `@Builder` |
| Go | "functional options": `NewServer(addr, WithTimeout(5*time.Second))` |
| TypeScript | an options object: `search({ author: "Machado de Assis", available: true })` |
| Python | keyword arguments; a builder for queries and documents assembled in steps |

Java leans on builders because it has no keyword arguments, so a builder is how Java gets named,
optional parameters at all. That is a pattern doing a language's job, a theme the last reading
section of this lesson returns to.
