---
title: "\"Depends on\": the one tool underneath all three forms"
version: 1
---

Every normal form is stated in terms of one idea, and it is simpler than its name. If you get this
section, the three that follow are bookkeeping.

> **B depends on A** when knowing A is enough to know B. Give me A and I can tell you B, every
> time, with no further information.

The textbook calls this a **functional dependency** and writes it `A → B`. The arrow is the whole
notation, and it is worth reading aloud as *"A determines B"*.

## Reading them off the booking table

Take the table from the last section and ask, column by column, *what do I need to know in order
to know this?*

```
student_email  →  student_name
course_code    →  course_title,  teacher
teacher        →  teacher_room
enrolment_id   →  everything
```

Read the first one: tell me `ana@ex.com` and I can tell you `Ana Lopes`, without looking at which
course or which grade. The student's name depends on the student and on nothing else.

Read the third: tell me the teacher is `Reis` and I can tell you the room. The room depends on the
teacher, not on the course and not on the enrolment.

And `grade` is on none of those lists, which is the interesting part. Tell me the student and I
cannot tell you the grade — she has several. Tell me the course and I cannot either. The grade
needs **both**:

```
student_email, course_code  →  grade
```

That is a dependency on a *pair*, and it is the one that survives every split below, because the
grade is genuinely a fact about the pairing. Lesson 1 met this idea as *facts that belong to the
pairing*, in the join table. It is the same thing with a name.

## The test that keeps you honest

The trap is answering from what the table happens to contain today rather than from what is true.

Today, every row with `SQL101` also has `Reis`. Does that mean `course_code → teacher`? Only if it
will be true of every row that could ever exist. Ask it as a question about the world:

> **Could the same A ever appear with two different Bs?**

If yes, there is no dependency. If no — if that would be a mistake somebody would want to prevent
— the dependency is real.

Try it on this one: could `SQL101` ever have two teachers? For a school where a course has one
teacher, no, and `course_code → teacher` holds. For a school where courses are co-taught, yes, and
it does not — and the right model is then a different one. **The dependency is a fact about the
business, not about the data you happen to have**, which is why normalisation cannot be done by a
program looking at rows.

## Three kinds, and the three forms are named after two of them

A **full dependency** on the key is the healthy case: the column needs all of the key and nothing
else. `grade` needs both `student_email` and `course_code`.

A **partial dependency** is on *part* of a composite key. `student_name` needs only
`student_email`, which is half of the key — so the name is being stored in a table whose key is
finer-grained than the fact is. That is what **2NF** removes.

A **transitive dependency** goes through an ordinary column. The key determines `teacher`, and
`teacher` determines `teacher_room`, so the key determines the room *by way of* the teacher. That
is what **3NF** removes.

```
key  →  teacher  →  teacher_room
        └────── the step that makes it transitive
```

Both are the same disease with different plumbing: **a fact is being stored somewhere whose
identity is not the thing the fact is about.** The room is a fact about a teacher, kept in a table
whose rows are enrolments, so it is repeated once per enrolment and can disagree with itself.

## Why a key was worth all that fuss in lesson 1

Notice what every one of these definitions is stated against: **the key**. Partial means part of
the key; transitive means not directly from the key. A table with no primary key has no normal
form at all, because there is nothing for the columns to depend on.

That is the connection between the two lessons. Lesson 1 said "give every table a key" as a
practical rule. Here it turns out that the key is what makes it possible to say anything precise
about the design at all.

## The three forms, in the language you now have

You can read them now, and they should be nearly obvious:

| form | the rule |
|---|---|
| **1NF** | every cell holds a single value; there are no repeating groups |
| **2NF** | 1NF, and no non-key column depends on only *part* of the key |
| **3NF** | 2NF, and no non-key column depends on another non-key column |

Which is the sentence from the last section, one more time, and it should sound different now:

> Every non-key column depends on the key, the **whole** key, and **nothing but** the key.
