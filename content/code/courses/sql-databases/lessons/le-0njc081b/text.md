---
title: Text, and the length limit that is not an optimisation
version: 2
---

Three types hold characters, and in PostgreSQL the choice between two of them is far less
interesting than people expect.

| type | what it is |
|---|---|
| `text` | any length |
| `varchar(n)` | at most `n` characters |
| `char(n)` | exactly `n`, padded with spaces |

## `text` against `varchar(n)`

**In PostgreSQL they perform identically.** There is no speed gained by declaring a limit and no
space saved — the storage is the same, and a `varchar(n)` is `text` with a length check attached.

So the question is only ever: **is there a real rule about the length?**

A country code is two characters because ISO 3166 says so — `varchar(2)` states a fact.
`varchar(50)` on a person's name states nothing except that somebody typed 50, and the day a name
does not fit, the insert is refused and a real person cannot be recorded. Names in the world are
longer than you think.

> Use `text` by default. Use `varchar(n)` when `n` comes from a specification, and be able to say
> which one.

**`char(n)` is a trap and should not be used.** It pads with spaces to the declared width, so
`'PT'` in a `char(5)` is `'PT   '` — and comparisons, concatenations and the length function then
disagree with each other about whether the spaces are there.

**And this is PostgreSQL's answer, not SQL's.** In MySQL and in Oracle the choice does have
performance and storage consequences, so schemas written for those and ported here carry
`varchar(n)` everywhere out of habit. Lesson 12.

## Equality is not as simple as it looks

Two strings are equal if the bytes are equal, which means these are all different values:

```
'Ana'   'ana'   'ANA'   'Ana '
```

Different case, and a trailing space that nobody can see. There is a fourth kind that is worse and
cannot be shown on this page: **a Cyrillic `а` is a different character from a Latin `a` and looks
exactly like one.** Paste a name from a document and the lookup finds nothing, the value is on the
screen in front of you, and the two strings are genuinely not equal. `SELECT length(name),
octet_length(name)` is how you find out — for text that is all ASCII the two numbers agree, and
for that name they do not.

**Case is the one that reaches production.** `WHERE email = 'Ana@Example.com'` does not find a row
stored as `ana@example.com`. Three ways to deal with it, in increasing order of how well they hold:

```sql
-- 1. fold at query time: works, and cannot use an ordinary index
WHERE lower(email) = lower('Ana@Example.com')

-- 2. fold at write time: the column holds one form and comparison is trivial
email text NOT NULL UNIQUE CHECK (email = lower(email))

-- 3. citext, an extension whose comparisons ignore case
CREATE EXTENSION citext;
email citext NOT NULL UNIQUE
```

The second is usually right for email addresses, and it is the one that makes `UNIQUE` mean what
you wanted: without it, `Ana@example.com` and `ana@example.com` are two rows and the constraint is
satisfied.

## Collation, in one paragraph because it will surprise you once

Sorting text is language-dependent, and the database has an opinion:

```sql
SELECT name FROM people ORDER BY name;
```

Under a Portuguese collation, `Álvaro` sorts among the As. Under `C` collation — byte order — it
sorts after `Z`, because the byte is larger. Neither is wrong; they answer different questions.
The database's default comes from how it was created, so **a query that sorts correctly on your
laptop can sort differently in production**, and the fix is to say what you mean:
`ORDER BY name COLLATE "pt-BR"`.

## Empty string and NULL are not the same

Lesson 1 made the point and it is worth repeating where the types are:

```sql
SELECT '' IS NULL;        -- false
SELECT length('');        -- 0
SELECT length(NULL);      -- null
```

`''` is a value: a piece of text with nothing in it. `NULL` is the absence of one. A table holding
both, for the same meaning, needs two conditions in every query that touches the column — and one
of them will eventually be forgotten.

**Pick one and enforce it.** If empty means unknown in your system, refuse the empty string:

```sql
middle_name text CHECK (middle_name <> '')
```

The `CHECK` accepts `NULL` — unknown is not false, from lesson 1 — and refuses `''`. Now there is
one way to say it.
