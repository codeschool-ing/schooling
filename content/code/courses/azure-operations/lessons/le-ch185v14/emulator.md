---
title: The query engine, on your own computer
version: 1
---

**A Log Analytics workspace answers in KQL, the Kusto Query Language, and so does Azure Data Explorer,
the service KQL was written for.** Microsoft publishes Data Explorer's engine as a container, the **Kusto
emulator**, for local development. It is not a workspace: it has no Azure Monitor tables, no retention,
no billing and no connection to anything. What it has is the language, run by the real engine, which is
exactly what the next six lessons need: every query in them was run, and every answer is what the engine
printed.

It is large. The image is about 4.6 GB on disk, and the container is given at most 4 GB of memory here;
it used well under one when the course was recorded. Start it once; `--restart unless-stopped` brings it
back after a reboot:

```sh
docker run -d --name kusto --restart unless-stopped -e ACCEPT_EULA=Y -m 4g -p 8080:8080 \
  mcr.microsoft.com/azuredataexplorer/kustainer-linux:2026.10.29.1806-2643-0ef1614-master
```

`ACCEPT_EULA=Y` accepts Microsoft's licence for the emulator, which permits local development and testing
and not production use. The tag pins the build this course was recorded with.

```
ana@laptop:~/azure/kusto$ docker ps --format "{{.Names}}  {{.Status}}"
kusto  Up 6 seconds
ana@laptop:~/azure/kusto$ docker image ls --format "{{.Repository}}  {{.Size}}" | grep kustainer
mcr.microsoft.com/azuredataexplorer/kustainer-linux  4.64GB
```

## A client of your own

The emulator answers HTTP on port 8080. Rather than install a client, the course uses one small Python
program, written once and used in every lesson from here on. Create its directory:

```sh
mkdir -p ~/azure/kusto && cd ~/azure/kusto
```

and save this in it as `kql.py`:

```schooling-example
{
  "language": "python",
  "file": "kql.py",
  "parts": [
    {
      "code": "# kql.py: send one query or command to the local Kusto emulator and print the answer as a table\nimport json, sys, urllib.error, urllib.request\n\nURL = \"http://localhost:8080/v1/rest/\"\nDATABASE = \"shop\"\n\n",
      "note": "Only the standard library: nothing to install. Every query goes to the emulator on port 8080, against the database `shop`."
    },
    {
      "code": "def ask(text):\n    # a command starts with a dot; comments above it are dropped, not sent\n    lines = text.strip().splitlines()\n    while lines and lines[0].lstrip().startswith(\"//\"):\n        lines.pop(0)\n    text = \"\\n\".join(lines)\n    kind = \"mgmt\" if text.startswith(\".\") else \"query\"\n",
      "note": "Kusto has two endpoints. A **command**, which starts with a dot, such as `.create`, goes to `mgmt`; a **query** goes to `query`. A comment above a command would hide its dot, so leading comments are removed first."
    },
    {
      "code": "    body = json.dumps({\"db\": DATABASE, \"csl\": text}).encode()\n    request = urllib.request.Request(URL + kind, body, {\"Content-Type\": \"application/json\"})\n    try:\n        with urllib.request.urlopen(request) as answer:\n            return json.load(answer)[\"Tables\"][0]\n",
      "note": "The request is a small JSON document: the database and the text. The answer holds one or more tables; the first is the result."
    },
    {
      "code": "    except urllib.error.HTTPError as e:\n        text = e.read().decode()\n        try:\n            error = json.loads(text)[\"error\"]\n            sys.exit(error.get(\"@message\") or error[\"message\"])\n        except (ValueError, KeyError):\n            sys.exit(f\"{e.code} {e.reason}: {text}\")\n    except urllib.error.URLError as e:\n        sys.exit(f\"cannot reach the emulator at {URL}: {e.reason}\")\n\n",
      "note": "A query Kusto refuses comes back as an HTTP error with Kusto's own message, which is printed as it is. An emulator that is not running gets one line saying so, not a traceback."
    },
    {
      "code": "def show(table):\n    names = [c[\"ColumnName\"] for c in table[\"Columns\"]]\n    rows = [[\"\" if v is None else str(v) for v in row] for row in table[\"Rows\"]]\n    widths = [max(len(x) for x in column) for column in zip(names, *rows)]\n    for line in [names, *rows]:\n        print(\"  \".join(x.ljust(w) for x, w in zip(line, widths)).rstrip())\n\n",
      "note": "Columns padded to their widest value, two spaces apart: the tables in every transcript of this course are printed by these six lines."
    },
    {
      "code": "show(ask(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()))\n",
      "note": "The text comes from the first argument, or from standard input when there is none, which is how a long query in a file is sent: `python3 kql.py < file.kql`."
    }
  ]
}
```

Then create the database the lessons use, and ask the engine something it can answer without any data:

```
ana@laptop:~/azure/kusto$ python3 kql.py '.create database shop volatile'
DatabaseName  PersistentPath  Created  StoresMetadata  StoresData
shop                          True     True            True
ana@laptop:~/azure/kusto$ python3 kql.py 'print answer = 6 * 7'
answer
42
```

`volatile` keeps the database in the container's memory. That is the emulator's equivalent of moto's
forgetting: **a restarted container has no database and no tables**, so each lesson that needs data starts
by loading it from the `.kql` files the lessons show. The loading takes seconds.

## When it does not answer

A stopped container, or one still starting, which takes about half a minute, gives one line:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | count'
cannot reach the emulator at http://localhost:8080/v1/rest/: [Errno 111] Connection refused
```

`docker start kusto` brings it back, empty. If `docker run` itself fails with a message about memory, the
machine has less than 4 GB free for it; close other programs, or lower `-m` to `2g`, which was enough for
this course's data.
