---
title: The log, in twenty-five lines of Python
version: 1
---

**A log is a sequence of records that only ever grows at one end.** Each record gets a number, its
**offset**, which is its position counting from zero, and keeps it for as long as it exists. Nobody
inserts in the middle, nobody edits, and reading a record does not remove it. That is the whole
data structure, and it is the one Kafka is built on.

The word misleads people in two directions. To a programmer a *log* is the text a server writes
about itself, `server.log`, which somebody greps when things go wrong. To many people who have used
message brokers, a stream is a **queue**: a message is handed to one reader and then it is gone.
The log in this lesson is neither. It is the data itself, kept in order, and any number of readers
can go through it, each at its own place.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A log of eight records, offsets 0 to 7, drawn left to right. New records are appended at the right-hand end. Three readers point at different places: the warehouse at offset 0, the loyalty scheme at offset 3 and the stock system at offset 8, the next record that does not exist yet. Reading moves only the reader's own pointer.\" data-fig=\"l2-log-readers\"><defs><marker id=\"l2-log-readers-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l2-log-readers-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"60\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">0</text><rect x=\"122\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"184\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><rect x=\"246\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><rect x=\"308\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><rect x=\"370\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><rect x=\"432\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><rect x=\"494\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">7</text><rect x=\"556\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"584.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">8</text><text x=\"586.0\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the next append goes here</text><line x1=\"584\" y1=\"52\" x2=\"584\" y2=\"66\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-83)\"></line><text x=\"30\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offset</text><text x=\"88\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">oldest</text><text x=\"522\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">newest</text><line x1=\"88\" y1=\"175\" x2=\"88\" y2=\"116\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-726)\"></line><text x=\"88\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">warehouse</text><text x=\"88\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads once a night</text><line x1=\"274\" y1=\"175\" x2=\"274\" y2=\"116\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-726)\"></line><text x=\"274\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">loyalty</text><text x=\"274\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">an hour behind</text><line x1=\"584\" y1=\"175\" x2=\"584\" y2=\"116\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-726)\"></line><text x=\"584\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">stock</text><text x=\"584\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">has read everything</text></svg>", "caption": "One log, three readers, three places. The log does not know where any of them is."}
```

## A log you can read in one sitting

Kafka's log is spread over machines and disks with indexes and replicas, which lessons 3 and 5
open up. The idea fits in a file. Save this as `~/work/minilog.py`:

```schooling-example
{
  "file": "minilog.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"minilog.py: an append-only log in one file, and readers that keep their own place.\n\n    python minilog.py append LOG MESSAGE   add MESSAGE at the end and print its offset\n    python minilog.py read LOG READER      print what READER has not read yet\n\"\"\"\nimport os\nimport sys\n",
      "note": "What it does. A record is one line of text, and **its offset is its line number**, counting from zero."
    },
    {
      "code": "\ndef append(log, message):\n    with open(log, \"a\", encoding=\"utf-8\") as f:\n        f.write(message + \"\\n\")\n    with open(log, encoding=\"utf-8\") as f:\n        return sum(1 for _ in f) - 1\n",
      "note": "Appending opens the file in mode `\"a\"`, which **can only write at the end**: the operating system will not let this function insert or overwrite. It then counts the lines to learn the new record's offset."
    },
    {
      "code": "\ndef read(log, start):\n    with open(log, encoding=\"utf-8\") as f:\n        for offset, line in enumerate(f):\n            if offset >= start:\n                yield offset, line.rstrip(\"\\n\")\n",
      "note": "Reading starts at an offset and goes to the end. It changes nothing in the file, so two readers cannot get in each other's way."
    },
    {
      "code": "\nif __name__ == \"__main__\":\n    command, log = sys.argv[1], sys.argv[2]\n    if command == \"append\":\n        print(append(log, sys.argv[3]))",
      "note": "The command line. `append` adds one record."
    },
    {
      "code": "    elif command == \"read\":\n        place = f\"{log}.{sys.argv[3]}\"\n        start = int(open(place).read()) if os.path.exists(place) else 0\n        for offset, message in read(log, start):\n            print(offset, message)\n            start = offset + 1\n        with open(place, \"w\") as f:\n            f.write(f\"{start}\\n\")",
      "note": "`read` is where the readers come in. **Each reader's place is a file of its own** beside the log, holding the offset of the next record it has not seen. The log never learns who has read what."
    }
  ]
}
```

Append three sales. Each `append` prints the offset its record was given:

```
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "rec-000001", "qty": 1}'
0
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "oli-000002", "qty": 2}'
1
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "rec-000003", "qty": 1}'
2
```

Now read it as the stock system, twice:

```
ubuntu@stream:~/work$ python minilog.py read demo.log stock
0 {"sale": "rec-000001", "qty": 1}
1 {"sale": "oli-000002", "qty": 2}
2 {"sale": "rec-000003", "qty": 1}
ubuntu@stream:~/work$ python minilog.py read demo.log stock
```

The second read prints nothing, because the stock reader has seen everything there is. **That is
not because the records are gone.** Add a fourth sale, and read as the stock system and then as a
loyalty scheme that has never read anything:

```
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "nat-000004", "qty": 1}'
3
ubuntu@stream:~/work$ python minilog.py read demo.log stock
3 {"sale": "nat-000004", "qty": 1}
ubuntu@stream:~/work$ python minilog.py read demo.log loyalty
0 {"sale": "rec-000001", "qty": 1}
1 {"sale": "oli-000002", "qty": 2}
2 {"sale": "rec-000003", "qty": 1}
3 {"sale": "nat-000004", "qty": 1}
```

The stock reader got only the new record; the loyalty reader got all four, from offset 0. Both
read the same file, and neither knew the other existed. Their places are two small files beside
the log:

```
ubuntu@stream:~/work$ ls demo.log*
demo.log
demo.log.loyalty
demo.log.stock
ubuntu@stream:~/work$ head demo.log.*
==> demo.log.loyalty <==
4

==> demo.log.stock <==
4
```

Each holds the offset of the next record that reader will ask for. Both say 4, because both have
now read to the end, and the log's last record is offset 3.

## What Kafka adds to the same idea

Everything above is in Kafka, with the names changed: a log is a **partition**, a reader's place is
a **committed offset**, and the reader is a **consumer group**. What `minilog.py` does badly is
also what Kafka was built to do well, and each failing is a later lesson:

| what minilog.py does | what goes wrong | where Kafka answers it |
|---|---|---|
| counts every line to find an offset | reading from offset 1 000 000 reads a million lines first | an index beside each file, lesson 3 |
| keeps every record forever | the disk fills | retention and compaction, lesson 3 |
| one file on one disk | the disk dies and the log with it | replicas on other machines, lesson 5 |
| writes a reader's place after printing | a crash in between prints some records twice | committing offsets, lessons 4 and 7 |

The last row is worth a second look before lesson 7 makes it the subject. If the program crashed
after printing record 3 and before writing the place file, the next run would start from the old
place and print record 3 again. **Where a reader writes down its place, relative to when it does
its work, decides what a crash costs**, and no log can decide it for the reader.
