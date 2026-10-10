---
title: The log, in twenty lines of Python
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

@@fig:l2-log-readers@@

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
```

Now read it as the stock system, twice:

```
ubuntu@stream:~/work$ python minilog.py read demo.log stock
```

The second read prints nothing, because the stock reader has seen everything there is. **That is
not because the records are gone.** Add a fourth sale, and read as the stock system and then as a
loyalty scheme that has never read anything:

```
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "nat-000004", "qty": 1}'
```

The stock reader got only the new record; the loyalty reader got all four, from offset 0. Both
read the same file, and neither knew the other existed. Their places are two small files beside
the log:

```
ubuntu@stream:~/work$ ls demo.log*
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
