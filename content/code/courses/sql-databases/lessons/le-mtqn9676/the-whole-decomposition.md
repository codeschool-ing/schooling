---
title: The whole decomposition, in one view
version: 1
---

One table became four, in three steps, each one removing a named kind of repetition. Here is the
journey with nothing in between.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Four stages of decomposition shown left to right. Stage zero is one wide table of eight columns. First normal form splits a list out into rows. Second normal form pulls students and courses out of the enrolments table. Third normal form pulls teachers out of courses. The final stage shows four boxes: students, courses, teachers and enrolments, with the anomaly count falling from four to zero.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">0NF</text><rect x=\"14\" y=\"32\" width=\"134\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">enrolments</text><text x=\"24\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">student, name</text><text x=\"24\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">courses (a list)</text><text x=\"24\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">teacher, room</text><text x=\"24\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grades (a list)</text>\n<text x=\"196\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">1NF</text><rect x=\"196\" y=\"32\" width=\"134\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">enrolments</text><text x=\"206\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">student, name</text><text x=\"206\" y=\"86\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course, title</text><text x=\"206\" y=\"102\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">teacher, room</text><text x=\"206\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grade</text>\n<text x=\"378\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">2NF</text><rect x=\"378\" y=\"32\" width=\"134\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">students</text><rect x=\"378\" y=\"64\" width=\"134\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"74\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses</text><text x=\"388\" y=\"88\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">+ teacher, room</text><rect x=\"378\" y=\"100\" width=\"134\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"388\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enrolments</text>\n<text x=\"560\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3NF</text><rect x=\"560\" y=\"32\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">students</text><rect x=\"560\" y=\"60\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"72\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">courses</text><rect x=\"560\" y=\"88\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">teachers</text><rect x=\"560\" y=\"116\" width=\"146\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">enrolments</text>\n<path d=\"M152 80 L190 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M182 74 L190 80 L182 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path>\n<path d=\"M334 80 L372 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M364 74 L372 80 L364 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path>\n<path d=\"M516 80 L554 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M546 74 L554 80 L546 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path>\n<text x=\"81\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lists in cells</text>\n<text x=\"263\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">name, title repeat</text>\n<text x=\"445\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">room repeats</text>\n<text x=\"633\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">each fact once</text>\n<line x1=\"14\" y1=\"186\" x2=\"706\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"206\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">The four anomalies, at each step</text>\n<text x=\"14\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">update</text><text x=\"200\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"330\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"460\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">room only</text><text x=\"620\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">gone</text>\n<text x=\"14\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">insertion</text><text x=\"200\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"330\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"460\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">gone</text><text x=\"620\" y=\"248\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">gone</text>\n<text x=\"14\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">deletion</text><text x=\"200\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"330\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">yes</text><text x=\"460\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">gone</text><text x=\"620\" y=\"268\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">gone</text>\n<text x=\"14\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">searchable</text><text x=\"200\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">no</text><text x=\"330\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"460\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><text x=\"620\" y=\"288\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text>\n<text x=\"14\" y=\"316\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Each step removes one kind of repetition, and the anomalies it caused leave with it.</text>\n</svg>", "caption": "Four tables, three steps. The bottom half is the reason for each one: an anomaly that was possible before it and is not after."}
```

## The four tables, written out

```sql
CREATE TABLE teachers (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    room text NOT NULL
);

CREATE TABLE students (
    email text PRIMARY KEY,
    name  text NOT NULL
);

CREATE TABLE courses (
    code       text    PRIMARY KEY,
    title      text    NOT NULL,
    teacher_id integer NOT NULL REFERENCES teachers (id) ON DELETE RESTRICT
);

CREATE TABLE enrolments (
    student_email text NOT NULL REFERENCES students (email) ON DELETE RESTRICT,
    course_code   text NOT NULL REFERENCES courses  (code) ON DELETE RESTRICT,
    grade         integer CHECK (grade BETWEEN 0 AND 20),
    PRIMARY KEY (student_email, course_code)
);
```

Every fact appears once. Every pointer is enforced. `grade` is nullable on purpose — a student is
enrolled before they are graded, and lesson 1's test passes: you can say out loud what an empty one
means, which is *"not graded yet"*.

## What to notice

**The join table did not appear at the end — it was there from 1NF.** `enrolments` is the
many-to-many between students and courses, and it arrived the moment the list came out of the cell.
The later forms took things *off* it rather than creating it.

**`grade` never moved.** Through three decompositions, the one column that depended on the whole
key stayed exactly where it started. That is what a correctly placed fact looks like, and it is
worth remembering as the thing you are aiming for: at the end, every column is somewhere that
could not be argued with.

**The shape is the same as lesson 1's shop.** Two ends and a middle holding the pairing and what
belongs to it. Arrive at it by lesson 1's procedure or by three normal forms and you land in the
same place — which is the point of this lesson. The procedure was right, and now there is a reason.

## Doing it in the real order

Nobody builds a table in 0NF and then normalises it three times. What actually happens:

1. **Design towards 3NF directly**, using lesson 1's procedure and the one-column test — *is this
   column a fact about the thing this row is about?*
2. **Use the forms to check**, and especially to argue. When two people disagree about a table,
   "that is a transitive dependency" is a claim somebody can be wrong about, and "it feels cleaner"
   is not.
3. **Use them on tables you inherit**, which is where they earn their keep. Reading somebody
   else's schema, the repeated value in a column is the thing to look for, and the three forms tell
   you which split fixes it.

The forms are a vocabulary for talking precisely about a design more often than they are a
procedure for producing one.
