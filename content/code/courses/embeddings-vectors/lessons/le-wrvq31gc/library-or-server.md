---
title: In your process or across a network
version: 1
---

Lessons 12 and 13 have met six tools, and the difference that matters most when you deploy one is
not in their APIs. **An index in your process is fast to reach and private to that process; a
server is one copy that every process shares, at the cost of a network hop and a program to run.**
FAISS, LanceDB, Chroma's `PersistentClient` and Qdrant's local mode are the first kind. Chroma's
`chroma run`, Qdrant's server, Weaviate and Pinecone are the second.

## Memory is per process

A FAISS index lives in the memory of the program that loaded it. The flat index of the previous
section was written to a file, and reading it back costs about the file's size:

```
ana@lab:~/emb$ ls -l random.faiss
-rw-r--r-- 1 ana ana 30720045 Oct  5 14:23 random.faiss
ana@lab:~/emb$ python mem.py
20000 vectors; 29 MB more memory in this process
```

29 MB for one process. A web application that runs four worker processes, each loading the index
at start, holds four copies, and a fifth process that adds an article changes only its own. Nothing
in FAISS tells the others; they see the change when they read the file again. For the help centre
that is a non-problem. For a catalogue of millions of vectors it decides how big the machine has to
be, and whether every worker can afford its own copy.

## Two processes, one directory

Qdrant's local mode allows one owner, and says so. LanceDB allows more, on its own terms. This
program holds each directory open and starts a second process against it:

```schooling-example
{
  "language": "python",
  "file": "two.py",
  "parts": [
    {
      "code": "import subprocess\nimport lancedb\nfrom qdrant_client import QdrantClient\n\ndef other(code):\n    r = subprocess.run([\"python\", \"-c\", code], capture_output=True, text=True)\n    return (r.stdout or r.stderr).strip().splitlines()[-1]",
      "note": "`other` runs a line of Python in a second process and returns the last line it printed, or the last line of its error."
    },
    {
      "code": "mine = QdrantClient(path=\"qdrant\")\nprint(\"qdrant, second process:\", other(\n    \"from qdrant_client import QdrantClient; QdrantClient(path='qdrant')\"))",
      "note": "This process opens the Qdrant directory, and a second process tries to open it too."
    },
    {
      "code": "table = lancedb.connect(\"lance\").open_table(\"help\")\nprint(\"lance, this process:  \", table.count_rows(), \"rows, version\", table.version)\nprint(\"lance, second process:\", other(\n    \"import lancedb; from minilm import embed; t = lancedb.connect('lance').open_table('help'); \"\n    \"t.add([{'id': 'h42', 'category': 'orders', 'lang': 'en', 'title': 'x', 'vector': embed('x')[0]}]); \"\n    \"print(t.count_rows(), 'rows, version', t.version)\"))\nprint(\"lance, this process:  \", table.count_rows(), \"rows, version\", table.version)\ntable.checkout_latest()\nprint(\"lance, after checkout:\", table.count_rows(), \"rows, version\", table.version)",
      "note": "This process opens the LanceDB table; a second process adds a row; this one counts again, then moves to the latest version."
    }
  ],
  "output": "ana@lab:~/emb$ python two.py\nqdrant, second process: RuntimeError: Storage folder qdrant is already accessed by another instance of Qdrant client. If you require concurrent access, use Qdrant server instead.\nlance, this process:   40 rows, version 3\nlance, second process: 41 rows, version 4\nlance, this process:   40 rows, version 3\nlance, after checkout: 41 rows, version 4\nException ignored in: <function QdrantClient.__del__ at 0x7f0304f28e00>\nTraceback (most recent call last):\n  File \"/opt/emb/lib/python3.11/site-packages/qdrant_client/qdrant_client.py\", line 169, in __del__\n  File \"/opt/emb/lib/python3.11/site-packages/qdrant_client/qdrant_client.py\", line 178, in close\n  File \"/opt/emb/lib/python3.11/site-packages/qdrant_client/local/qdrant_local.py\", line 109, in close\nImportError: sys.meta_path is None, Python is likely shutting down"
}
```

**Qdrant refused the second process**, and the refusal names the way out itself: a server.
Chroma's `PersistentClient` is meant for one process in the same way, which is why lesson 12 served
its directory with `chroma run` before letting several programs at it.

**LanceDB let the second process write**, and the first one did not see the new row: it was still
reading version 3, the version it had opened, and counted 40. Only `checkout_latest()` moved it to
version 4 and 41 rows. That is the versioning of the previous sections at work, and it is a choice
your program has to make on purpose: how stale a reader may be, and when it looks again.

## What each side costs

| | in your process | behind a network |
|---|---|---|
| reaching it | a function call | a request, and its round trip |
| memory | one copy per process that loads it | one copy, in the server |
| several programs | refused, or each with its own copy | the normal case |
| running it | nothing to run; your program owns the files and their backups | a process to deploy, upgrade, watch and back up |
| growing past one machine | not without your own work | the server's job, or the provider's |

**Start in your process when one program owns the data**, which is most prototypes, every test, a
command-line tool and Marginalia's help centre today. **Move behind a network when several programs
need the same vectors, or when they no longer fit beside every worker.** The move is cheaper than it
sounds when the library you started with has a server with the same API, which is the case for
Chroma and for Qdrant: lesson 12 changed one constructor, and `QdrantClient(url=...)` is the same
change. Moving from FAISS means writing the server around it, or adopting a database.

Lesson 14 adds a last option that the six tools here do not cover: the vectors stored in the
database a shop already runs, beside the orders and the customers, and queried with SQL.
