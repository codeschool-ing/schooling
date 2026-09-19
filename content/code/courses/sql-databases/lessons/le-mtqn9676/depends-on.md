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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Four dependency arrows from the booking table. The first, highlighted differently, runs from enrolment_id to everything and is marked as the key determining every column — the one arrow you want. The other three run from student_email to student_name, from course_code to course_title and teacher, and from teacher to teacher_room, each marked as a column that is not the key determining another. A note reads that each of those is a fact stored once per booking instead of once.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Read each arrow aloud as \"determines\": knowing the left is enough to know the right, every time.</text><rect x=\"14\" y=\"44\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"56.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">enrolment_id</text><path d=\"M168 56.0 L214 56.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M214 56.0 L207 52.0 L207 60.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"218\" y=\"46\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">everything</text><text x=\"390\" y=\"56.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the key determines every column — which is the one arrow you want</text><rect x=\"14\" y=\"82\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"94.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">student_email</text><path d=\"M168 94.0 L214 94.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M214 94.0 L207 90.0 L207 98.0 Z\" fill=\"var(--amber)\"></path><rect x=\"218\" y=\"84\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">student_name</text><text x=\"390\" y=\"94.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a column that is not the key determining another</text><rect x=\"14\" y=\"120\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"142.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">course_code</text><path d=\"M168 142.0 L214 142.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M214 142.0 L207 138.0 L207 146.0 Z\" fill=\"var(--amber)\"></path><rect x=\"218\" y=\"122\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">course_title</text><rect x=\"218\" y=\"144\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"154\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">teacher</text><text x=\"390\" y=\"142.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a column that is not the key determining another</text><rect x=\"14\" y=\"178\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"89\" y=\"190.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">teacher</text><path d=\"M168 190.0 L214 190.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></path><path d=\"M214 190.0 L207 186.0 L207 194.0 Z\" fill=\"var(--amber)\"></path><rect x=\"218\" y=\"180\" width=\"150\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"293\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">teacher_room</text><text x=\"390\" y=\"190.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a column that is not the key determining another</text><text x=\"14\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Three of the four arrows start somewhere that is not the key. Each of those is a fact stored once per booking instead of once.</text><text x=\"14\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">That is the whole of the next three sections: find the arrows that do not start at the key, and give each one a table.</text></svg>", "caption": "An arrow that does not start at the key is a fact living in the wrong table. Finding them is the work; the three forms are names for which kind you found."}
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
