---
title: Case ids, and tracing a case to a requirement
version: 1
---

Every case in this lesson has an id and names a requirement. Both look like bookkeeping, and both
answer questions nobody can answer without them: **which requirements has nobody tested, and when
a requirement changes, which cases change with it?**

## An id is a name, not a position

The obvious way to number cases is in the order they are written: case 1, case 2, case 3. It works
until a case is inserted. Put a new sign-up case between 2 and 3, renumber, and every defect report,
run log and conversation that said *case 3 fails* now points at a different case. Nothing warns
anybody. The report still reads perfectly; it is about the wrong thing.

**A case id is assigned once and never changes, and never moves to another case.** The scheme in
this course is `TC-`, the area of the application, and a number within that area: `TC-SIGNUP-01`,
`TC-BOOK-03`. The area tells a reader where to look before they open the case. The number only has
to be unique. When TC-BOOK-02 is deleted one day, its id is retired with it and the next booking case
is TC-BOOK-04, even though there is a gap.

The title is for people, and it can be rewritten whenever a better one comes along. The id is what
everything else refers to, which is why it must not depend on the title or on the order of the
list. Lesson 18's case management tools hand out ids the same way, and for the same reason.

## Tracing cases to requirements

Each case names the requirement it checks, and requirements have ids too, R1 to R9 in lesson 1's
list. Put the two side by side and you have a **traceability matrix**: which cases check which
requirement. For the cases of this lesson it looks like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 350\" role=\"img\" data-fig=\"l02-trace\" aria-label=\"A traceability matrix drawn as two columns joined by lines. On the left the nine requirements R1 to R9, on the right the seven cases of this lesson. TC-SIGNUP-01 joins R2 and R3; TC-SIGNUP-02 joins R2 and R7; TC-CONFIRM-01 joins R3; TC-CONFIRM-02 joins R3 and R7; TC-BOOK-01 joins R4 and R5; TC-BOOK-02 joins R4 and R7; TC-BOOK-03 joins R3, R4 and R5. R1, R6, R8 and R9 have no line and are drawn dashed.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirements</text><text x=\"480.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cases</text><path d=\"M270.0 88.0 C370.0 88.0 380.0 72.0 480.0 72.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 72.0 480.0 72.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 88.0 C370.0 88.0 380.0 110.0 480.0 110.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 248.0 C370.0 248.0 380.0 110.0 480.0 110.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 148.0 480.0 148.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 186.0 480.0 186.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 248.0 C370.0 248.0 380.0 186.0 480.0 186.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 152.0 C370.0 152.0 380.0 224.0 480.0 224.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 184.0 C370.0 184.0 380.0 224.0 480.0 224.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 152.0 C370.0 152.0 380.0 262.0 480.0 262.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 248.0 C370.0 248.0 380.0 262.0 480.0 262.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 300.0 480.0 300.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 152.0 C370.0 152.0 380.0 300.0 480.0 300.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 184.0 C370.0 184.0 380.0 300.0 480.0 300.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20.0\" y=\"44.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R1</text><text x=\"62.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the shows list</text><rect x=\"20.0\" y=\"76.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R2</text><text x=\"62.0\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sign-up</text><rect x=\"20.0\" y=\"108.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R3</text><text x=\"62.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirmation e-mail</text><rect x=\"20.0\" y=\"140.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R4</text><text x=\"62.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">booking</text><rect x=\"20.0\" y=\"172.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R5</text><text x=\"62.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prices and discounts</text><rect x=\"20.0\" y=\"204.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R6</text><text x=\"62.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">order states</text><rect x=\"20.0\" y=\"236.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R7</text><text x=\"62.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">error messages</text><rect x=\"20.0\" y=\"268.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R8</text><text x=\"62.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">phones and browsers</text><rect x=\"20.0\" y=\"300.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"312.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R9</text><text x=\"62.0\" y=\"312.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">keyboard, screen reader</text><rect x=\"480.0\" y=\"60.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-SIGNUP-01</text><rect x=\"480.0\" y=\"98.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-SIGNUP-02</text><rect x=\"480.0\" y=\"136.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-CONFIRM-01</text><rect x=\"480.0\" y=\"174.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-CONFIRM-02</text><rect x=\"480.0\" y=\"212.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-BOOK-01</text><rect x=\"480.0\" y=\"250.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-BOOK-02</text><rect x=\"480.0\" y=\"288.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-BOOK-03</text><rect x=\"480.0\" y=\"322.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"510.0\" y=\"328.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no case yet</text></svg>", "caption": "The traceability matrix of this lesson's cases. Read from the left it is coverage; read from the right, every case is evidence about a requirement. The dashed boxes are what nobody has tested yet."}
```

The lines go both ways, and each direction answers its own question.

**From a requirement to its cases, forward**, the matrix shows coverage. R2, R3 and R4 each have at
least two cases, and R7 has three, because every refusal in this lesson is a sentence R7 asked for.
R1, R6, R8 and R9 have none, and the matrix says so without anybody having to remember. That gap is not a mistake today, because this lesson set out to test R2 to R4, and
the later lessons of this course test the rest. It would be a mistake on release day, and the
matrix is how somebody would notice in time.

**From a case to its requirements, backward**, the matrix shows that every case is evidence about
something the theatre asked for. A case that traces to no requirement is one of two things. Either
it tests something nobody wanted, and its time is better spent elsewhere, or it has found a
requirement that nobody wrote down. Ana once drafted a case that checked that every page has a link
back to Shows. No line of R1 to R9 asks for that link, so she took the question to the theatre's
manager, who wanted it kept, and the requirement was written down.

## When a requirement changes

Suppose the theatre decides that an order may hold up to eight tickets, and R4 changes. **The
matrix lists the cases to look at again**: every case traced to R4, which today is TC-BOOK-01,
TC-BOOK-02 and TC-BOOK-03, and every case later lessons add to R4. Without it, finding them means
reading every case and guessing. With it, the answer is one row.

A change can break a case in two ways, and the matrix only finds the cases, not the damage.
Some cases are still correct after the change and simply need running again. Others now expect the
wrong thing, like a case that expected seven tickets to be refused. Reading the cases the matrix
lists is still a tester's job.

## What coverage does not mean

**A requirement with a case is covered; it is not necessarily tested well.** R4 has three cases,
and all three book two tickets. Nothing in them tries one ticket, six, seven or none, and nothing
books a show an hour before it starts. The matrix would show R4 as covered whether it had three
cases or thirty.

So the matrix finds the holes that are entirely empty, which is worth a great deal and is all it
finds. How many cases a requirement needs, and which ones, is decided by the techniques of lessons
4 and 5. Counting lines in the matrix is not a substitute for them.

## Where the matrix lives

For seven cases, the matrix is a column in the spreadsheet of cases: each row is a case, and one
cell lists its requirements. Sorting by that column gives the forward view. A case management
tool keeps the same link as a field and draws the matrix on request, which lesson 18 shows.
Whatever holds it, the matrix only stays true if the requirement field is filled in **when the case
is written**, because nobody goes back to add it later.
