---
title: Second normal form: the whole key
version: 1
---

First normal form got us to one value per cell. Here is where that left the enrolments:

| student_email | course_code | student_name | course_title | grade |
|---|---|---|---|---|
| ana@ex.com | SQL101 | Ana Lopes | Databases | 17 |
| ana@ex.com | NET200 | Ana Lopes | Networks | 15 |
| bruno@ex.com | SQL101 | Bruno Sá | Databases | 14 |
| celia@ex.com | SQL101 | Célia Reis | Databases | 18 |

The key is the pair `(student_email, course_code)`. Every cell is a single value. And `Ana Lopes`
is written twice, `Databases` three times.

## The question, before the rule

Ask the question this lesson keeps asking: **what can go wrong here that could not go wrong if it
were split?**

Ana marries and changes her name. Two rows hold it. Change one and the database holds two names
for one student, and nothing says which is right — because nothing in this table records that the
two rows are one person. That is the update anomaly, and it is back.

Then ask *why* the name is repeated, and the answer is precise: **`student_name` depends on
`student_email` alone, which is half of the key.** The table's rows are finer-grained than the
fact is. There is one row per (student, course) and one name per student, so the name is written
once per course she takes.

Same for `course_title`, which depends on `course_code` alone — the other half.

And `grade` is different, which is the control case. It depends on both halves: you cannot know
the grade from the student, and you cannot know it from the course. `grade` is exactly where it
belongs.

## The rule

> **A table is in second normal form when it is in 1NF and no non-key column depends on only part
> of the key.**

A dependency on part of the key is called a **partial dependency**, and 2NF is the removal of all
of them.

**It can only be broken by a composite key.** If the key is one column, no column can depend on
"part" of it — there are no parts. So a table whose key is a single generated id is in 2NF
automatically, which is most tables, which is why 2NF is the form people meet least often in
practice.

That is also a reason not to reach for a surrogate key as a way of skipping this step. Putting an
`id` on the enrolments table would make it technically 2NF and change nothing about the repetition:
`student_name` would still be written once per enrolment. The dependency is on the *real*
identity of the row, and a surrogate key hides it rather than removing it.

## The split

Each partial dependency becomes its own table, keyed by the part it depended on:

```sql
CREATE TABLE students (
    email text PRIMARY KEY,
    name  text NOT NULL
);

CREATE TABLE courses (
    code    text PRIMARY KEY,
    title   text NOT NULL,
    teacher text NOT NULL,
    teacher_room text NOT NULL
);

CREATE TABLE enrolments (
    student_email text NOT NULL REFERENCES students (email),
    course_code   text NOT NULL REFERENCES courses  (code),
    grade         integer,
    PRIMARY KEY (student_email, course_code)
);
```

Three tables. Ana's name is in one place. `Databases` is in one place. `grade` stayed, because it
was the one column that genuinely depended on the whole key.

**And the insertion and deletion anomalies went with it**, without being mentioned. CRY300 can now
exist with nobody enrolled — it is a row in `courses`. Deleting Ana's enrolment in NET200 deletes
an enrolment and nothing else, because NET200 is not stored inside it.

That is the pattern worth noticing: **you fix the dependency and the four anomalies leave
together**, because they were four symptoms of one cause.

## Reconstructing what you had

Nothing was lost. The original table is the three joined back up, which is lesson 5's subject and
is worth seeing the shape of now:

```sql
SELECT s.email, s.name, c.code, c.title, e.grade
FROM enrolments e
JOIN students s ON s.email = e.student_email
JOIN courses  c ON c.code  = e.course_code;
```

This is the trade being made, stated plainly: **writing got safer and reading got longer.** Every
question that was one table is now a join. That cost is real, it is what the last two sections of
this lesson are about, and it is almost always worth paying — because a join is work a machine
does, and an update anomaly is work a person does, badly, at some point in the future.

## `courses` is not finished

Look at the `courses` table above. It is in 2NF — its key is one column, so it cannot help being —
and it still has a problem.

`teacher_room` is written once per course. Reis teaches three courses, so `B-204` appears three
times, and moving Reis to B-310 means changing three rows again. The anomaly we just removed is
back in a smaller table.

The key determines the teacher, and the teacher determines the room. That is the transitive
dependency from the `depends on` section, and removing it is third normal form.
