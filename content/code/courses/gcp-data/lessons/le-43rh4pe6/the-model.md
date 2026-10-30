---
title: Rows, column families and cells
version: 1
---

**A Bigtable table looks like a spreadsheet and is not one.** The habit `sql-databases` leaves is a
table with a fixed list of columns, a type for each, and a planner that finds rows by any of them.
Bigtable has none of the three. A table is a sorted map: the **row key** is a string of bytes, the
rows are kept in the order of those bytes, and the row key is the only thing anything is ever
looked up by. Everything inside a row is a map as well, and it may be different in every row.

**Inside a row there are three levels, and only the first is declared.** A **column family** is
declared on the table, with a name and a policy for how long its data is kept. Inside a family, a
**column qualifier** is any string a program writes, and the table never hears of it in advance.
Inside a column there are **cells**, one per version, each with a timestamp. So the address of a
single value is four things long: row key, family, qualifier and timestamp. Lesson 10's Firestore
had documents with fields; here the nearest thing to a field is a qualifier, and it is data, not
schema.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"One row, key c-17, holds two column families. Family p has the column name with one cell, Ana, and the column district with three cells, Santana, Pinheiros and Mooca, newest first, each with its own timestamp. Family o has two columns named after order ids, o-10001 and o-10002, holding 4290 and 1380.\" data-fig=\"l11-model\"><rect x=\"16\" y=\"30\" width=\"688\" height=\"250\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"30\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">row key</text><text x=\"82\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-17</text><rect x=\"32\" y=\"62\" width=\"420\" height=\"204\" rx=\"5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"46\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">column family</text><text x=\"126\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">p</text><text x=\"46\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">name</text><rect x=\"150\" y=\"98\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana</text><text x=\"428\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-08-29</text><text x=\"46\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">district</text><rect x=\"150\" y=\"138\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Santana</text><text x=\"428\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-10-15</text><rect x=\"150\" y=\"172\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Pinheiros</text><text x=\"428\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-10-14</text><rect x=\"150\" y=\"206\" width=\"290\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"162\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Mooca</text><text x=\"428\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2026-09-21</text><text x=\"150\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cells, newest first</text><rect x=\"468\" y=\"62\" width=\"220\" height=\"204\" rx=\"5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"482\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">column family</text><text x=\"562\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">o</text><text x=\"482\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o-10001</text><rect x=\"560\" y=\"98\" width=\"116\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"572\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4290</text><text x=\"482\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o-10002</text><rect x=\"560\" y=\"138\" width=\"116\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"572\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1380</text><text x=\"482\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualifiers named</text><text x=\"482\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after the data</text><text x=\"30\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Families are declared on the table; qualifiers and cells are written with each row.</text></svg>", "caption": "The address of one value is row key, family, qualifier and timestamp. Drawn for illustration; the emulator keeps rows in memory and has no layout of its own."}
```

**The word for this is wide column, and it describes the qualifiers.** A row can carry a handful of
columns or hundreds of thousands, and two rows of one table share nothing but the families. A
column a row does not have costs nothing, because nothing is stored for it. That is why Bigtable is
called sparse, and it is what the rest of this lesson builds on: a qualifier can be named after an
order id or a date, which a relational column never can.

## The emulator, and a file that saves typing

The Bigtable emulator comes with the Google Cloud command line of lesson 1. In a terminal of its
own, after the two lines of "Every time you open a terminal":

```sh
cd ~/gcp
gcloud beta emulators bigtable start --host-port=localhost:8086
```

**`cbt` is Bigtable's own command line**, installed in lesson 1 beside `gcloud`, and it finds the
emulator through `BIGTABLE_EMULATOR_HOST`, which your other terminal already exports. It needs a
project and an instance on every call, and against the emulator any names will do:

```
ana@laptop:~/gcp$ cbt -project planner-dev -instance quitanda ls
2026/10/30 15:11:47 -creds flag unset, will use gcloud credential
```

`ls` lists the tables, and an empty emulator has none, so the only line is a log message: `cbt`
looked for credentials and fell back to the ones `gcloud` would use. **`cbt` reads its flags from
`~/.cbtrc` when there is one**, so write the three of them once. `~/.cbtrc`:

```ini
project = planner-dev
instance = quitanda
creds = /dev/null
```

`creds = /dev/null` points `cbt` at an empty credentials file, which silences that line. It works
because the emulator checks no credentials at all. **Against Google it would be a broken
configuration**, and the file there names a real project, a real instance and your login instead.

## A table, its families, and a row with whatever it likes

Quitanda keeps its customers in a table of their own while it learns the shape: a family `p` for
the profile and a family `o` for the customer's orders, one column per order.

```
ana@laptop:~/gcp$ cbt createtable customers families=p,o
ana@laptop:~/gcp$ cbt ls customers
Family Name	GC Policy	Value Type
-----------	---------	----------
o				{}
p				{}
ana@laptop:~/gcp$ cbt ls
customers
```

**`createtable` named the families and nothing else**, and `ls` on the table lists them with an empty
GC policy, which the next section fills in. There is no column list, because there are no columns
yet. They appear when a row is written:

```
ana@laptop:~/gcp$ cbt set customers c-17 p:name=Ana p:district=Lapa
ana@laptop:~/gcp$ cbt set customers c-18 p:name=Bruno o:o-10004=4290 o:o-10005=1380
ana@laptop:~/gcp$ cbt read customers
----------------------------------------
"c-17"
  "p:district"                             @ 2026/10/30-15:11:47.782000
    "Lapa"
  "p:name"                                 @ 2026/10/30-15:11:47.782000
    "Ana"

----------------------------------------
"c-18"
  "o:o-10004"                              @ 2026/10/30-15:11:47.796000
    "4290"
  "o:o-10005"                              @ 2026/10/30-15:11:47.796000
    "1380"
  "p:name"                                 @ 2026/10/30-15:11:47.796000
    "Bruno"

ana@laptop:~/gcp$ cbt set customers c-18 x:note=vip
2026/10/30 15:11:47 Applying mutation: rpc error: code = Unknown desc = unknown family "x"
```

**Two rows, and they do not have the same columns.** c-17 has a name and a district; c-18 has a
name and two order columns whose qualifiers are order ids, `o-10004` and `o-10005`, holding each
order's total in cents. Nothing told the table about `district` or `o-10004` first. Every cell came
back with a timestamp, the time the emulator received the write, because `cbt set` was given none.

**The family is the one thing that has to exist.** Writing to `x:note` was refused with `unknown
family "x"`, and nothing in the row changed. The message is the emulator's; Bigtable refuses the
same mutation with a sentence of its own. Families are few, a handful a table, and they are where
the decisions live: what is kept, for how long, and what is read together.

## The value has no type

**Every value is bytes**, and so is every row key and qualifier. `4290` above is the four characters
`4`, `2`, `9` and `0`, not a number; `cbt` writes what it was given as a string. A program that wants
a number stores it in a fixed width, an 8-byte big-endian integer being the usual choice, and reads
it back the same way. Bigtable does have aggregate column families that add integers inside the
cell as they are written, and they are named here so the word is not new when you meet it; this
lesson keeps to plain bytes.

**There is no join, no secondary index and no transaction across rows.** A write to one row is
atomic, however many cells it touches, and two rows are two writes that may half succeed. A read
names a row key, a range of row keys or a prefix, and filters what comes back inside that range.
Anything else is a read of the whole table. The next sections are about choosing the key so that
the reads Quitanda needs are the first kind.
