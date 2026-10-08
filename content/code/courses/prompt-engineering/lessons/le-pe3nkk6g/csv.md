---
title: CSV, and the comma inside a field
version: 2
---

CSV looks like the simplest format of the four: one row per line, the fields separated by commas,
a header line naming the columns. A spreadsheet opens it, and so does every language. It is also
the one that **fails without saying so**, and the reason is in its name. The comma separates the
fields, and the comma is also an ordinary character that fields contain.

## A reply that parses and is wrong

Here is a menu as CSV with three columns, with the mistake a writer of CSV makes most. The course
wrote this one, and it is read with Python's `csv` module, which prints how many fields it found on
each line and what they were:

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

## What the model wrote

Ask the local model for the same menu, written the way the café writes its prices:

```
ana@lab:~/pe$ cat prompts/menu.txt
Return Café Aurora's menu as CSV with three columns: item,price,notes.
The menu: flat white, R$ 12,00, oat milk at no extra cost; soup of the day,
R$ 18,50, tomato; cinnamon bun, R$ 9,00, contains nuts, eggs and milk.
ana@lab:~/pe$ ask - --temperature 0 --plain < prompts/menu.txt > replies/menu-model.csv
ana@lab:~/pe$ cat replies/menu-model.csv
Here is Café Aurora's menu in CSV format with three columns: item, price, and notes:

"item","price","notes"
"flat white","12,00","oat milk at no extra cost"
"soup of the day","18,50","tomato"
"cinnamon bun","9,00","contains nuts, eggs and milk"
ana@lab:~/pe$ python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu-model.csv
3 ["Here is Café Aurora's menu in CSV format with three columns: item", ' price', ' and notes:']
0 []
3 ['item', 'price', 'notes']
3 ['flat white', '12,00', 'oat milk at no extra cost']
3 ['soup of the day', '18,50', 'tomato']
3 ['cinnamon bun', '9,00', 'contains nuts, eggs and milk']
```

It quoted every field, so the decimal commas are safe, and it put a sentence in front. **The
sentence is a valid row of three fields**, `Here is ... item`, ` price` and ` and notes:`, cut at
its own commas, so a check that counts fields passes it. The real header arrives on the third line.

So a prompt that wants CSV says the rules out loud:

```
ana@lab:~/pe$ cat prompts/menu-rules.txt
Return the menu as CSV with exactly three columns: item,price,notes.
Write the header line first. Put every field that contains a comma
or a double quote inside double quotes, and write a double quote
inside a field as two double quotes. Write prices with a full stop
as the decimal separator: 18.50, not 18,50. No other text.

The menu: flat white, R$ 12,00, oat milk at no extra cost; soup of the day,
R$ 18,50, tomato; cinnamon bun, R$ 9,00, contains nuts, eggs and milk.
ana@lab:~/pe$ ask - --temperature 0 < prompts/menu-rules.txt
"item","price","notes"
"flat white","R$ 12,00","oat milk at no extra cost"
"soup of the day","R$ 18,50","tomato"
"cinnamon bun","R$ 9,00","contains nuts, eggs and milk"
-- llama3.2:3b, finish: stop, prompt 155 tokens, output 61 tokens
```

The sentence is gone and the quoting is right, and **the prices kept their decimal commas and their
`R$`**, the one rule the prompt gave with an example. The decimal rule removes the commonest cause of the problem instead of quoting around it, which is worth asking for wherever you control the format, and it is still a request: the check is what tells you it was ignored.

## Checking a CSV reply

Because the reader will not complain, **the check is yours to write**, and it is short: the first
row is exactly the header you asked for, and every row after it has as many fields as the header.
The first menu fails the second half on two rows, and the model's first reply fails the first half
on its first line. Check both before using a single field, and treat a failure the way the first
reading section treats a JSON reply that does not parse.

When the data has nesting, optional fields or long free text, that check is a warning sign about
the choice of format. JSON quotes every string by rule and refuses what it cannot read, so it is
the safer thing to ask a model for, and a program can turn it into CSV afterwards with a library
that never forgets a quote.
