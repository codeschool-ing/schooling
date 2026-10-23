---
title: By file, the oldest integration still running
version: 1
---

Every night at about 23:30, Coleta writes one file: a header, one line for each of the roughly 1,900
farms collected that day, and a trailer. It pushes the file by SFTP to a directory on the SAP
application server, and at 02:00 an ABAP program reads it and creates a goods receipt of milk for
every line. Sebastião wrote the first version in 1996 for a different ERP, and the layout has
changed twice since. **It is the oldest integration in the company, and the one the farms' pay
depends on.**

It is easy to look down on that file. Joana did, in her first week, because at the fintech nothing
had moved by file since before she arrived. But files are still everywhere in large companies, and
for good reasons. Serra Alta's 1,900 farm payments leave as a CNAB 240 file for the bank, and the
bank's answer comes back as another file. The big supermarket chains send their orders and receive
their invoices as EDI messages through an EDI provider, in a standard such as EANCOM, the retail
subset of EDIFACT, or in a chain's own variant of it. **A file needs nothing running on the other
side at the moment it is written**, any system from any decade can produce one, and anybody can open
it and read it. That last point is worth more during an incident than it looks.

## What a file costs

The price is latency and silence. A file carries what was true when it was written. Until lesson 1's
change, the Portal B2B learnt SAP's stock from a file SAP wrote every hour, and about 30 times a week
a bakery ordered something that had sold out since the last file. **A file is a photograph, and
everybody downstream is looking at the photograph rather than the room.**

Silence is the worse half. A file integration fails in ways that do not announce themselves: the file
does not arrive, arrives twice, arrives half-written, or arrives with a line missing. Each of those has
a defence, and a safe file integration has all of them.

## Header and trailer, with control totals

The first defence is that **the file says what it contains, so the reader can check it got all of
it**. A header names the file: who wrote it, for which day, with which sequence number. A trailer
closes it with control totals: how many records came before it, and the sum of the field that matters
most. For Coleta that is the litres. A loader that adds up the lines and compares them with the
trailer knows whether the file is whole before it posts a single goods receipt.

CNAB 240 has the same shape at a larger scale. Every line is 240 characters; the file has a header
and a trailer of its own, and inside it each batch of payments has its header and its trailer, with
the number of records and the sum of the amounts. A bank that receives a file whose totals disagree
rejects it before paying anybody, which is what you want from a bank.

## The name, and the moment the file appears

The second defence is in the name. **A name carries the date and a sequence number**, so the reader
can tell a new file from a repeat and notice a gap. `coleta-20261022-0001.txt` is the first file for
22 October, and if a second one with the same name turns up, something is being sent again.

The third is about when the file becomes visible. A file written straight under its final name exists
while it is being written, and a reader that polls the directory can pick it up half-written: 1,200
lines of 1,900, a trailer it never sees. The fix is to **write under a temporary name and rename the
file when it is complete**. On the same file system a rename is atomic: the reader sees either no file
or the whole file, never part of one. A reader that only looks for names ending in `.txt` never
touches the `.tmp`.

## The program

This program writes a small Coleta file the safe way and checks one the way a loader should. It is
six farms instead of 1,900, and the layout is a simplified one, but the header, the trailer and the
rename are the real thing. Save it as `coleta_file.py` in an empty directory; it needs Python 3 and
nothing else.

```schooling-example
{
  "language": "python",
  "file": "coleta_file.py",
  "parts": [
    {
      "code": "# coleta_file.py: write Coleta's nightly file safely, and check one before it is loaded\nimport os\nimport pathlib\nimport sys",
      "note": "Three modules from the standard library. `os.replace` is the rename; `pathlib` reads and writes the file."
    },
    {
      "code": "\nDAY, SEQ, WIDTH = \"20261022\", 1, 40\nFARMS = [  # farm code, name, litres, fat and protein in hundredths of a percent\n    (\"004417\", \"SITIO BOA VISTA\", 1840, 362, 318),\n    (\"010233\", \"FAZ SANTA LUZIA\", 312, 405, 331),\n    (\"002981\", \"FAZ TRES PONTES\", 5120, 348, 309),\n    (\"017605\", \"SITIO DO CORREGO\", 960, 391, 322),\n    (\"008112\", \"FAZ RIO DO PEIXE\", 2275, 357, 314),\n    (\"021340\", \"SITIO PEDRA ALTA\", 730, 376, 327),\n]",
      "note": "One day's collection, fixed so that every run writes the same file. Every record is 40 characters wide. Fat and protein are whole numbers of hundredths, so 362 is 3.62%, because a fixed-width file has no room for a decimal point and no agreement about whether it is a point or a comma. The names carry no accents: in UTF-8 an accented letter takes two bytes, which would move every field after it."
    },
    {
      "code": "\n\ndef write():\n    name = f\"coleta-{DAY}-{SEQ:04d}.txt\"\n    total = sum(farm[2] for farm in FARMS)\n    lines = [f\"HCOLETA{DAY}{SEQ:04d}SERRA ALTA LATICINIOS\"]\n    for code, farm, litres, fat, protein in FARMS:\n        lines.append(f\"D{code}{farm:<18}{litres:07d}{fat:04d}{protein:04d}\")\n    lines.append(f\"T{DAY}{SEQ:04d}{len(FARMS):09d}{total:018d}\")",
      "note": "The header says which file this is: the system, the day and the sequence. Each `D` line pads the name with spaces to 18 characters and the numbers with zeros, so every field starts at the same column on every line. The trailer repeats the day and the sequence, then the two control totals: how many farm lines, and how many litres."
    },
    {
      "code": "    tmp = pathlib.Path(name + \".tmp\")\n    tmp.write_text(\"\\n\".join(lines) + \"\\n\", encoding=\"ascii\")\n    os.replace(tmp, name)\n    print(f\"wrote {name}: {len(FARMS)} farms, {total} litres\")\n    return 0",
      "note": "The file is written under a name nobody is looking for, and renamed only when the last line is down. A reader polling for `.txt` files sees nothing, then the whole file. `encoding=\"ascii\"` makes Python refuse a character outside ASCII instead of writing a line of the wrong width."
    },
    {
      "code": "\n\ndef check(path):\n    lines = pathlib.Path(path).read_text(encoding=\"ascii\").splitlines()\n    problems = [f\"line {n} has {len(line)} characters, not {WIDTH}\"\n                for n, line in enumerate(lines, 1) if len(line) != WIDTH]\n    kinds = \"\".join(line[:1] for line in lines)\n    if not problems and (len(kinds) < 2 or kinds != \"H\" + \"D\" * (len(kinds) - 2) + \"T\"):\n        problems.append(\"the file must be one header, the farm lines and one trailer\")",
      "note": "The shape first. Every line must be 40 characters, which is what catches a file cut off in the middle of a line. Then the first letters of the lines must read one `H`, any number of `D`s and one `T`: a file without its trailer stops here, before anything tries to read totals from a farm line."
    },
    {
      "code": "    if not problems:\n        head, farms, tail = lines[0], lines[1:-1], lines[-1]\n        count, litres = int(tail[13:22]), int(tail[22:40])\n        found = sum(int(line[25:32]) for line in farms)\n        if head[7:19] != tail[1:13]:\n            problems.append(\"the header and the trailer name different files\")\n        if (count, litres) != (len(farms), found):\n            problems.append(f\"trailer says {count} farms and {litres} litres; \"\n                            f\"the file has {len(farms)} farms and {found} litres\")",
      "note": "The totals. The slices are the layout: characters 13 to 21 of the trailer are the count, 22 to 39 the litres, and characters 25 to 31 of a farm line are its litres. The loader adds the farm lines up itself and compares them with what the writer promised."
    },
    {
      "code": "    if problems:\n        print(f\"REFUSED {path}\")\n        for problem in problems:\n            print(f\"  {problem}\")\n        return 1\n    print(f\"accepted {path}: {count} farms, {litres} litres\")\n    return 0",
      "note": "A refused file is reported with every reason found, and the exit status is 1, so whatever runs the loader can stop and raise an alarm. Nothing has been loaded at this point: the check comes before the first goods receipt."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    if sys.argv[1:] == [\"write\"]:\n        sys.exit(write())\n    if len(sys.argv) == 3 and sys.argv[1] == \"check\":\n        sys.exit(check(sys.argv[2]))\n    sys.exit(\"usage: python3 coleta_file.py write | check FILE\")",
      "note": "Two commands: `write` makes the day's file, `check FILE` judges one. On Windows the command is `python` rather than `python3`."
    }
  ]
}
```

Write the file, and list the directory to see that only the final name is left:

```
$ python3 coleta_file.py write
wrote coleta-20261022-0001.txt: 6 farms, 11237 litres
$ ls
coleta-20261022-0001.txt
coleta_file.py
```

Then look at it. Each line is one record, and the columns line up because every field has a fixed
width:

```
$ cat coleta-20261022-0001.txt
HCOLETA202610220001SERRA ALTA LATICINIOS
D004417SITIO BOA VISTA   000184003620318
D010233FAZ SANTA LUZIA   000031204050331
D002981FAZ TRES PONTES   000512003480309
D017605SITIO DO CORREGO  000096003910322
D008112FAZ RIO DO PEIXE  000227503570314
D021340SITIO PEDRA ALTA  000073003760327
T202610220001000000006000000000000011237
```

The first farm line reads: record type `D`, farm `004417`, the name padded to 18 characters,
`0001840` litres, fat `0362` and protein `0318`. The trailer reads: day `20261022`, sequence `0001`,
`000000006` farm lines and `000000000000011237` litres. **Nothing in the file says where one field
ends**; the layout is an agreement held outside it, and both sides must hold the same one.

Now check it as the loader would:

```
$ python3 coleta_file.py check coleta-20261022-0001.txt
accepted coleta-20261022-0001.txt: 6 farms, 11237 litres
$ echo $?
0
```

## A file with a line missing

To see a refusal, make a copy with one farm line removed. On Linux or macOS, `sed '5d'` prints the
file without its fifth line, and `>` saves that as `damaged.txt`. Anywhere else, copy the file to
`damaged.txt` and delete the line of farm `017605` in a text editor.

```
$ sed '5d' coleta-20261022-0001.txt > damaged.txt
$ python3 coleta_file.py check damaged.txt
REFUSED damaged.txt
  trailer says 6 farms and 11237 litres; the file has 5 farms and 10277 litres
$ echo $?
1
```

**The trailer is how the reader finds out that something is missing.** Without it, the five lines
left are a perfectly valid file, the load succeeds, and one farm is paid 960 litres short at the end
of the month. A line can go missing in ways nobody chose: a transfer cut short and resumed, a
conversion that stopped at a character it did not like, somebody editing the file by hand to fix
another line.

## Back, again, and never

Three more defences cover what the trailer cannot see.

**The reader answers.** A safe file integration sends something back: an acknowledgement file naming
the file it loaded and the totals it found, or a reject file with the reasons. CNAB works this way,
because the bank's *retorno* file says, record by record, what happened to each payment. Coleta's
file had no answer. If the load refused a file, Sebastião found out when somebody phoned him.

**Loading the same file twice must change nothing.** In 2019 an operator re-ran the 02:00 load after
it timed out, not knowing it had finished, and one day's milk was counted twice for 1,870 farms. It
was caught at the payment preview, because the month's litres came out 3% above what the plants had
received. A loader that records the day and sequence of every file it has loaded, and refuses one it
has seen, makes a second run harmless. Lesson 10 calls this property idempotence and applies it to
messages.

**Absence is the failure a file integration hides.** In March 2025 the password of the account Coleta
uses for SFTP expired. For four nights no file arrived; the 02:00 load found nothing to load and
finished without an error, which is what a loader with nothing to do does. Nobody noticed until 7 April,
when the payment preview showed every farm four days short. **A file integration needs an alarm on
the file that did not come**, set at a time it should have come by. Serra Alta's now goes off at 01:30
if there is no Coleta file for the day. On Sundays SAP is down for maintenance from 01:00 to 05:00 and
the load waits until afterwards, which the file allows: it sits in the directory, whole, until its
reader is back.

## The safe file integration, in order

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-safe-file\" aria-label=\"The safe file integration in order. On the writer's side, Coleta: 1, write the file under a temporary name, with a header and a trailer carrying the count and the litres; 2, rename it when it is complete. The file then reaches the reader's directory. On the reader's side, SAP: 3, check the header, the shape and the trailer's totals; 4, refuse a file whose day and sequence were already loaded; 5, load it; 6, send an acknowledgement or a reject file back to the writer, drawn as a dashed arrow. Beside the reader, an alarm goes off at 01:30 if no file has arrived for the day.\"><defs><marker id=\"l09-safe-file-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-safe-file-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"250.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">writer: Coleta</text><rect x=\"300.0\" y=\"20.0\" width=\"410.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"505.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">reader: SAP</text><rect x=\"25.0\" y=\"63.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"78.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  write under a .tmp name,</text><text x=\"135.0\" y=\"91.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">with header and trailer</text><rect x=\"25.0\" y=\"125.0\" width=\"220.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  rename when complete</text><path d=\"M135.0 107.0 L135.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><rect x=\"315.0\" y=\"58.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  check shape and totals</text><rect x=\"315.0\" y=\"110.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  refuse a day already loaded</text><path d=\"M420.0 92.0 L420.0 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><rect x=\"315.0\" y=\"162.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5  load</text><path d=\"M420.0 144.0 L420.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><rect x=\"315.0\" y=\"214.0\" width=\"210.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">6  send ack or reject back</text><path d=\"M420.0 196.0 L420.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><path d=\"M245.0 147.0 L280.0 147.0 L280.0 75.0 L313.0 75.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-safe-file-es-ah-phosphor)\"></path><path d=\"M315.0 231.0 L135.0 231.0 L135.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l09-safe-file-es-ah-paper-dim)\"></path><rect x=\"565.0\" y=\"98.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630.0\" y=\"121.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no file by 01:30:</text><text x=\"630.0\" y=\"134.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the alarm goes off</text><text x=\"135.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the ack or the reject comes back</text></svg>", "caption": "Six steps and an alarm. Each one exists because a file went wrong somewhere: half-written, short of a line, loaded twice, refused in silence, or never sent."}
```

None of these steps is expensive, and every one of them exists because a file went wrong somewhere.
Joana's map has 41 file integrations, and when she went through them with this list, **only 9 had a
trailer that anybody checked**.
