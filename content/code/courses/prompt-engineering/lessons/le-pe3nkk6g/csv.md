---
title: CSV, and the comma inside a field
version: 1
---

CSV looks like the simplest format of the four: one row per line, the fields separated by commas,
a header line naming the columns. A spreadsheet opens it, and so does every language. It is also
the one that **fails without saying so**, and the reason is in its name. The comma separates the
fields, and the comma is also an ordinary character that fields contain.

## A reply that parses and is wrong

Here the café asked for its menu as CSV with three columns, and this is the kind of reply that
comes back. It was written into a file on the workbench and read with Python's `csv` module, which
prints how many fields it found on each line and what they were:

```
ana@lab:~/pe$ cat replies/menu.csv
item,price,notes
flat white,12.00,oat milk at no extra cost
soup of the day,18,50,tomato
cinnamon bun,9.00,contains nuts, eggs and milk
ana@lab:~/pe$ python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu.csv
3 ['item', 'price', 'notes']
3 ['flat white', '12.00', 'oat milk at no extra cost']
4 ['soup of the day', '18', '50', 'tomato']
4 ['cinnamon bun', '9.00', 'contains nuts', ' eggs and milk']
```

Read the last two rows against the header. The soup was written with a Brazilian decimal comma,
`18,50`, and so **its price came out as `18` and its notes as `50`**, with `tomato` pushed into a
fourth column the header never named. The cinnamon bun's note was cut in two at its own comma.

**Nothing failed.** There is no error message and no exit status to check: as far as the reader is
concerned these are rows of four fields, which CSV allows. A program that takes the second field
as the price charges 18 for the soup and carries on. That is the difference from the JSON replies
in this lesson's first reading section, which the parser refused at once.

## Quoting is the fix, and it has to be asked for

CSV's own rule is that a field containing a comma goes inside double quotes. The same menu,
quoted, through the same reader:

```
ana@lab:~/pe$ cat replies/menu-quoted.csv
item,price,notes
flat white,12.00,oat milk at no extra cost
soup of the day,"18,50",tomato
cinnamon bun,9.00,"contains nuts, eggs and milk"
ana@lab:~/pe$ python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu-quoted.csv
3 ['item', 'price', 'notes']
3 ['flat white', '12.00', 'oat milk at no extra cost']
3 ['soup of the day', '18,50', 'tomato']
3 ['cinnamon bun', '9.00', 'contains nuts, eggs and milk']
```

Every row has three fields, and the reader removed the quotes. A field that contains a double quote
has a rule too: the quote is written twice, `"the ""house"" blend"`. A model that has seen a lot of
CSV knows these rules, and it **applies them less reliably than a CSV library does**, because it
is writing likely text and not running the rule.

So a prompt that wants CSV says the rules out loud, and the course wrote this one as an
illustration:

```localised
Return the menu as CSV with exactly three columns: item,price,notes.
Write the header line first. Put every field that contains a comma
or a double quote inside double quotes, and write a double quote
inside a field as two double quotes. Write prices with a full stop
as the decimal separator: 18.50, not 18,50. No other text.
```

The last rule removes the commonest cause of the problem instead of quoting around it. That is
worth doing wherever you control the format, and Brazilian decimal commas are a case where you do.

## Checking a CSV reply

Because the reader will not complain, **the check is yours to write**, and it is short: every row
has as many fields as the header. The first capture would have failed it on two rows. Count the
fields per row before using a single one, and treat a mismatch the way the first reading section
treats a JSON reply that does not parse.

When the data has nesting, optional fields or long free text, that check is a warning sign about
the choice of format. JSON quotes every string by rule and refuses what it cannot read, so it is
the safer thing to ask a model for, and a program can turn it into CSV afterwards with a library
that never forgets a quote.
