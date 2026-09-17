---
title: Third normal form: nothing but the key
version: 1
---

Second normal form left this:

```sql
CREATE TABLE courses (
    code         text PRIMARY KEY,
    title        text NOT NULL,
    teacher      text NOT NULL,
    teacher_room text NOT NULL
);
```

| code | title | teacher | teacher_room |
|---|---|---|---|
| SQL101 | Databases | Reis | B-204 |
| NET200 | Networks | Dias | A-110 |
| SEC300 | Security | Reis | B-204 |
| ALG150 | Algorithms | Reis | B-204 |

One column in the key, so 2NF holds and cannot be broken. And `B-204` is written three times.

## The question again

**What can go wrong here that could not go wrong if it were split?**

Reis moves to B-310. Three rows carry the room and all three must change together. Two out of three
and the database says Reis teaches in two rooms.

Then, *why*: the room is not a fact about the course. **It is a fact about the teacher**, and it is
being stored in a table whose rows are courses, so it appears once per course that teacher happens
to teach.

The chain is the one from the `depends on` section:

```
code  →  teacher  →  teacher_room
```

The key determines the room, but **by way of** another ordinary column. That is a **transitive
dependency**, and it is the last of the three kinds.

## The rule

> **A table is in third normal form when it is in 2NF and no non-key column depends on another
> non-key column.**

Which completes the sentence:

> Every non-key column depends on the key, the whole key, and **nothing but the key**.

`nothing but the key` is exactly the ban on going through an intermediate column.

## The split

The intermediate column becomes the key of a new table:

```sql
CREATE TABLE teachers (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    room text NOT NULL
);

CREATE TABLE courses (
    code       text    PRIMARY KEY,
    title      text    NOT NULL,
    teacher_id integer NOT NULL REFERENCES teachers (id)
);
```

Reis is one row. The room is written once. Moving her is one `UPDATE` touching one row, and there
is no state in which the database holds two answers.

**Notice that `teachers` got a surrogate key** while `courses` kept `code` and `students` kept
`email`. That is lesson 1's argument arriving in practice: a course code is printed in the
prospectus and does not change, an email is at least argued about, and a teacher's name is exactly
the kind of thing that changes — so the one being invented here is the one that needed inventing.
Normalisation says *split*; it does not say what the new table's key should be, and that is still
your decision.

## The test you can apply without the vocabulary

Once you have found the split, the formal names stop being useful and one question replaces them:

> **Is this column a fact about the thing this row is about?**

`title` is a fact about the course. `teacher_id` says which teacher, which is a fact about the
course. `room` is a fact about a *teacher*, sitting in a row that is a course. Out it goes.

It is the same test as lesson 1's *"each row is one ______"*, applied one column at a time, and it
catches almost everything the three forms catch without needing to say "transitive" out loud.

## Two things 3NF does not do

**It does not remove all repetition.** `teacher_id` still repeats — `1, 2, 1, 1` down the column —
and it should. Repeating a *reference* is how the model works; what 3NF removes is repeating the
*fact*. Change nothing about Reis's room and every course still points at the one row that holds
it.

The distinction is worth being precise about, because it is where people over-apply the rules:
repeated values are fine when they are pointers, and a problem when they are copies of something
that can change independently.

**It does not make the design right.** A table can be in 3NF and still be a bad model of the
world — wrong grain, missing a concept, a status column that should have been a table.
Normalisation removes one specific class of defect. It is not a substitute for knowing what you
are modelling, and lesson 1's procedure is still how you find the things in the first place.

## Why almost everybody stops here

There are higher forms — BCNF, 4NF, 5NF — and the next section says what they are. In practice
3NF is where the return stops being obvious:

- The three anomalies are all gone. Nothing beyond 3NF removes an update, insertion or deletion
  anomaly of the kind this lesson opened with; the higher forms handle rarer shapes.
- Each split costs a join, forever, on every read.
- The shapes that need BCNF are unusual enough that meeting one is a notable event rather than a
  Tuesday.

So the working standard, in nearly every system you will touch: **design to third normal form,
know that the higher ones exist, and break 3NF only where you have measured a reason.** Both
halves of that sentence have a section ahead of them.
