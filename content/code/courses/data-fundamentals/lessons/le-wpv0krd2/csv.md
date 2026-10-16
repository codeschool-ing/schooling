---
title: "CSV: a table with the types left out"
version: 1
---

**CSV is the format every tool can open and no two tools quite agree on.** The name says
comma-separated values, and the picture that comes with it is a file you can read by splitting each
line on its commas. That picture survives until the first field with a comma in it.

There is a specification, RFC 4180, written in 2005 to record what programs were already doing. Its
rules are short. A field that contains a comma, a double quote or a line break is wrapped in double
quotes, and a double quote inside such a field is written twice. Most readers follow them; plenty of
hand-written exports do not.

## A comma inside a field

The mechanics at Roda Livre write a free-text note on some rides. Here are three, one with a comma
in it and one with quotes. Save this as `formats/comma.py`:

```python
# formats/comma.py
import csv

NOTES = [
    ["ride_id", "station", "minutes", "note"],
    ["R000101", "Praça Tiradentes", 12, "brake loose, seat low"],
    ["R000102", "Rua XV", 7, 'rider said "fine"'],
    ["R000103", "Batel", 31, ""],
]
with open("notes.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f, lineterminator="\n").writerows(NOTES)

print("split on every comma:")
for line in open("notes.csv", encoding="utf-8"):
    print(" ", len(line.rstrip("\n").split(",")), "fields")

print("read with the csv module:")
rows = list(csv.reader(open("notes.csv", encoding="utf-8")))
for row in rows:
    print(" ", len(row), "fields")
print("minutes of R000101:", repr(rows[1][2]))
```

It writes the file with Python's `csv` module, then reads it back twice: once by splitting on commas,
once with the module. `lineterminator="\n"` ends each line the Linux way; left alone, the module
ends lines with a carriage return and a line feed, which is what RFC 4180 asks for.

```
ana@lab:~/roda/formats$ python comma.py
split on every comma:
  4 fields
  5 fields
  4 fields
  4 fields
read with the csv module:
  4 fields
  4 fields
  4 fields
  4 fields
minutes of R000101: '12'
ana@lab:~/roda/formats$ cat notes.csv
ride_id,station,minutes,note
R000101,Praça Tiradentes,12,"brake loose, seat low"
R000102,Rua XV,7,"rider said ""fine"""
R000103,Batel,31,
```

Splitting finds five fields on the first ride, because `brake loose, seat low` is two pieces to
anybody counting commas. The `csv` module finds four on every line, because it reads the quotes the
writer put there. Look at the file itself and the rules are all visible: the note with a comma is
quoted, and the quotes around `fine` have been doubled.

## What the file does not say

**A CSV file carries text and nothing else, so every type is a guess made by the reader.** The last
line of the run shows it: `minutes` was written as the number 12 and came back as the string `'12'`.
Whether `12` is a number, whether `2025-09-14` is a date and whether `007` keeps its zeros is decided
by the code that reads the file, every time, and two readers can decide differently. The empty note
on `R000103` is another guess: nothing in the file says whether the mechanic wrote nothing or
whether the note is missing.

Two more things are left out, and both cause real failures:

- **The delimiter.** A spreadsheet set to Portuguese saves its "CSV" with semicolons, because there
  the comma is the decimal separator: `4,50` is four reais and fifty centavos. A reader expecting
  commas gets one field per line.
- **The encoding.** Nothing in the file says how its characters were turned into bytes. Read the same
  file as Latin-1, an older encoding still common in exports from Windows systems, and the first
  station loses its cedilla:

```
ana@lab:~/roda/formats$ python -c "print(open('notes.csv', encoding='latin-1').read().splitlines()[1])"
R000101,PraÃ§a Tiradentes,12,"brake loose, seat low"
```

`ç` was written as two bytes in UTF-8, and Latin-1 reads each byte as a character of its own. No
error is raised. The name is simply wrong, in every row, from then on.

## What it is good for

None of this makes CSV a bad format. Anybody can open it, with any tool, including a person with a
text editor; it is the one format that a partner, a spreadsheet and a forty-year-old system all
accept. It is a row format, so appending a line is cheap. What it needs is an agreement written down
beside it: UTF-8, a header line, the delimiter, how a date is spelt and what an empty field means.
Lesson 7 checks a file against an agreement like that when it arrives.
