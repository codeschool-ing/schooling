---
title: Where data becomes code
version: 1
---

A SQL statement is a small program. When the portal searches for a surname, it sends the database
a string such as `SELECT … WHERE surname LIKE '%Souza%'`, and the database **parses** that string to
decide what to do. The quotes around `Souza` are part of the program: they tell the parser where a
piece of data starts and where it ends.

**SQL injection is what happens when a value written into that string changes where the data ends.**
The code meant the value to be data, and some of its characters were read as SQL. It is not a flaw
in the database. The database did exactly what the string said; the string said something the
developer never wrote.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-split\" aria-label=\"The same search sent to the database two ways. Above, the surname D'Ávila is written into the SQL text: the parser reads the apostrophe as the end of the string, then tries to read Ávila as SQL, and fails with a syntax error. Below, the SQL text has a placeholder and the value travels beside it: the database parses the text first, with a hole where the placeholder is, and then compares each surname with the value, apostrophe included. No character of the value is ever parsed.\"><defs><marker id=\"l05-split-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-split-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">built into the text</text><rect x=\"20\" y=\"36\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">… WHERE surname LIKE '%D'Ávila%'</text><path d=\"M400 54 L440 54\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-amber)\"></path><rect x=\"440\" y=\"36\" width=\"260\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">read as SQL: syntax error</text><path d=\"M177 90 L177 74\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-amber)\"></path><text x=\"186\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">string ends here</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sent beside the text</text><rect x=\"20\" y=\"142\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">… WHERE surname LIKE ?</text><rect x=\"20\" y=\"188\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">value: %D'Ávila%</text><path d=\"M400 160 L440 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-phosphor)\"></path><rect x=\"440\" y=\"142\" width=\"260\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">parsed first, with a hole</text><path d=\"M400 206 L440 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-split-ah-phosphor)\"></path><rect x=\"440\" y=\"188\" width=\"260\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">then compared, as data</text></svg>", "caption": "A placeholder keeps the program and the data in two channels, so no value is ever parsed as SQL."}
```

The wrong idea is that injection is about hostile input, so the defence is to find and remove the
dangerous characters. The first counter-example is a patient. Brazil has plenty of surnames with an
apostrophe in them, `D'Ávila` among them, and Ireland and Italy add their own. A search that pastes
`D'Ávila` into a string sends a program with a broken quote, and the database refuses it. **The
same code that breaks on a real surname obeys whatever else somebody types**, because it cannot
tell the difference between a name and an instruction. Removing apostrophes would refuse lucia's
name and still leave every other way of closing a string, in every database's own syntax.

### Two channels

The fix is to stop building the program out of the data. The driver offers a second channel: the
program is sent with **placeholders**, `?` in `sqlite3`, and the values are sent beside it, as
values. The database parses the program **before** it sees any value, so no value can change what
the program is. `D'Ávila` arrives as eight characters to compare with, apostrophe included.

This is called a **parameterised query** (or a prepared statement, or bound parameters; the three
names describe the same idea at slightly different levels). It is the defence OWASP's SQL Injection
Prevention Cheat Sheet puts first, and lesson 20's ASVS asks for it by name.

### What a placeholder cannot hold

A placeholder holds a **value**: a string, a number, a date. It cannot hold a part of the program
itself: a table name, a column name, the direction of a sort, the word `ASC`. Those still have to be
written into the SQL text, and when they come from a request they need the defence of lesson 2: an
**allowlist** that maps what the request may ask for to text the code wrote itself.

The rest of this lesson is those two rules in the portal's patient search, one more trap that
survives the fix, and the same rules in an ORM.
