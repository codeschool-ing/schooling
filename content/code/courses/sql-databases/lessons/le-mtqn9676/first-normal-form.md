---
title: First normal form: one value per cell
version: 1
---

The booking table of two sections ago is already in first normal form, which makes it a poor
example. So here is the shape 1NF forbids, and it is the one people actually write:

| enrolment_id | student_email | courses | grades |
|---|---|---|---|
| 1 | ana@ex.com | SQL101, NET200 | 17, 15 |
| 2 | bruno@ex.com | SQL101 | 14 |

One row per student, with their courses in a list. It is compact, it reads well, and every single
thing about it is a problem.

## What goes wrong

**Finding anything means searching inside text.** "Who takes SQL101?" becomes a search for the
characters `SQL101` inside a string, which also matches a course called `SQL1010`. There is no
notion of a whole value to compare against, because the value is not whole.

**The two lists are joined by position and nothing enforces it.** `17` is Ana's SQL101 grade
because it is first in one list and SQL101 is first in the other. Insert a course in the middle of
one list and forget the other, and every grade after it now belongs to the wrong course. Nothing
complains. This is the same failure this repository's own content format refuses — *nothing joins
by position* — and it is why.

**Adding a course means rewriting a string.** Read the row, append, write it back. Two enrolments
in the same second and one is lost.

**No constraint can reach inside.** `REFERENCES courses (code)` cannot be declared on a fragment
of a string, so nothing can guarantee that `NET200` is a course that exists. The strongest tool
from lesson 1 is simply unavailable.

**No type.** `17, 15` is text. It cannot be averaged, compared or summed without being taken apart
first, and taking it apart is a thing somebody has to write correctly every time.

## The fix, and it is the only one

Each value gets its own row:

```sql
CREATE TABLE enrolments (
    student_email text NOT NULL REFERENCES students (email),
    course_code   text NOT NULL REFERENCES courses  (code),
    grade         integer,
    PRIMARY KEY (student_email, course_code)
);
```

| student_email | course_code | grade |
|---|---|---|
| ana@ex.com | SQL101 | 17 |
| ana@ex.com | NET200 | 15 |
| bruno@ex.com | SQL101 | 14 |

Every problem above is gone, and not one of them was addressed individually. `WHERE course_code =
'SQL101'` compares whole values. The grade sits on the row it belongs to, so nothing is matched by
position. A new enrolment is an `INSERT` that cannot lose another. Both references are enforceable
and enforced. `grade` is an integer and can be averaged.

**And the primary key is the pair**, which is lesson 1's join table arriving under a new name. A
many-to-many between students and courses needs a third table; that it is also what 1NF produces
from a list-in-a-cell is not a coincidence, because a list in a cell is a many-to-many somebody
tried to avoid modelling.

## The formal statement, now that you have seen it

> **A table is in first normal form when every cell holds a single, indivisible value, and there
> are no repeating groups of columns.**

The second half names the other way people break it, which is a column per item:

| student_email | course_1 | grade_1 | course_2 | grade_2 | course_3 | grade_3 |
|---|---|---|---|---|---|---|

This is the same defect wearing the structure's clothes, and lesson 1 already gave the test for
it: **data grows in rows, structure grows in columns.** A student taking a fourth course would
need an `ALTER TABLE`, which is the giveaway. It also wastes the columns nobody uses, makes "which
students take SQL101" a search across three columns, and gives you no way to say a student may not
be enrolled in the same course twice.

## Where "indivisible" gets argued about

Two honest complications, because 1NF is where the textbook and the working database disagree
most.

**A full name in one column.** Is `'Ana Lopes'` one value or two? It depends on whether anything
in your system ever needs the parts separately. If you sort by surname, or address people by first
name, it is two facts in one column and should be two columns. If you only ever print it, it is
one value. **The question is not "can it be divided" — everything can. It is "does anything need
the parts?"**

**Arrays and JSON columns.** PostgreSQL has `text[]` and `jsonb`, and they hold several values in
one cell by design. A strict reading says they break 1NF, and the strict reading is right about
what they cost: no foreign key into an element, weaker constraints, and queries that need special
operators.

They are still sometimes correct — for a genuinely opaque blob, for a payload from somebody else's
API you store as it arrived, for a set of labels nothing joins to. What makes them a mistake is
using one to avoid making a table for something that is a thing in your system. If you ever want
to ask "how many students take each course", the courses were a table.

The rule that survives: **reach for a table first, and use an array when you can say what you are
giving up.**
