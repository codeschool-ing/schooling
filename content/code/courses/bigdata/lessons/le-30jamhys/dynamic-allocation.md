---
title: Executors that come and go
version: 1
---

**On a shared cluster an application should hold executors only while it has work for them.**
Kubernetes and YARN charge, in money or in other people's waiting, for every pod and container held,
busy or not. *Dynamic allocation* lets Spark ask for executors when tasks are waiting and give them
back when they have been idle for a while. It runs on the standalone cluster too, which is where this
section measures it. Save this as `~/big/dynamic.py`:

```schooling-example
{
  "language": "python",
  "file": "dynamic.py",
  "parts": [
    {
      "code": "\"\"\"An application that asks for executors when it has work and gives them back when it has none.\"\"\"\nimport json\nimport sys\nimport threading\nimport time\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\n"
    },
    {
      "code": "builder = (SparkSession.builder.appName(\"dynamic\")\n           .config(\"spark.dynamicAllocation.enabled\", True)\n           .config(\"spark.dynamicAllocation.shuffleTracking.enabled\", True)\n           .config(\"spark.dynamicAllocation.minExecutors\", 0)\n           .config(\"spark.dynamicAllocation.maxExecutors\", 3)\n           .config(\"spark.dynamicAllocation.executorIdleTimeout\", \"15s\"))\nif len(sys.argv) > 1:\n    builder = builder.config(\"spark.dynamicAllocation.shuffleTracking.timeout\", sys.argv[1])\nspark = builder.getOrCreate()\nsc = spark.sparkContext\nstart = time.time()\n\n\n",
      "note": "**Dynamic allocation**, from no executors up to three. An executor idle for 15 seconds is given back. *Shuffle tracking* keeps an executor that holds shuffle files a later stage may still read, which is what an external shuffle service does on clusters that have one. How long it keeps one is the program's argument, forever unless given."
    },
    {
      "code": "def watch():\n    url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/executors\"\n    held = None\n    while True:\n        executors = [e for e in json.load(urllib.request.urlopen(url)) if e[\"id\"] != \"driver\"]\n        if len(executors) != held:\n            held = len(executors)\n            print(f\"{time.time() - start:5.0f} s: {held} executors\", flush=True)\n        time.sleep(1)\n\n\nthreading.Thread(target=watch, daemon=True).start()\n\n",
      "note": "**A watcher in a thread of its own**, checking every second how many executors the application holds, from the driver's REST interface, and printing when the number changes."
    },
    {
      "code": "clicks = spark.read.parquet(\"data/silver/clicks\")\nfor round in (1, 2):\n    n = clicks.groupBy(\"visitor_id\").count().where(F.col(\"count\") > 100).count()\n    print(f\"{time.time() - start:5.0f} s: round {round} done, {n} visitors with more than 100 events\",\n          flush=True)\n    time.sleep(35)\n",
      "note": "**Work, then nothing, then work again**: a grouping of the year, half a minute of idleness, and the grouping once more."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit dynamic.py 2>/dev/null
    2 s: 0 executors
    9 s: 1 executors
   10 s: 2 executors
   11 s: 3 executors
   42 s: round 1 done, 1 visitors with more than 100 events
   87 s: round 2 done, 1 visitors with more than 100 events
```

**The application started with no executors and had three about ten seconds later**, as soon as
the first stage's tasks were waiting. **Then it never gave them back**, through two rounds and the
idle half-minute after each. Shuffle tracking is why. An executor that wrote shuffle files is the
only place those files exist, lesson 7's point, and a later stage, or a later query reusing the
same shuffle as lesson 9's ones did, may need them. Spark cannot know that nobody will, so by default
it keeps that executor for as long as the application lives.

With a limit on how long shuffle files are protected, 20 seconds here:

```
ana@lab:~/big$ spark-submit dynamic.py 20s 2>/dev/null
    2 s: 0 executors
    8 s: 1 executors
   11 s: 3 executors
   39 s: round 1 done, 1 visitors with more than 100 events
   65 s: 0 executors
   81 s: 1 executors
   83 s: 3 executors
  100 s: round 2 done, 1 visitors with more than 100 events
  125 s: 0 executors
```

**Now the executors went back to zero about half a minute after each round**, and came back for the
next one. The price showed in the second round: it took about 26 seconds from the end of the pause,
against 10 in the first run, where its executors and their shuffle files were still there. The
cluster had those three cores free for half a minute in exchange.

**On a real cluster the usual answer is an external shuffle service**: a process on each machine,
outside the executors, that serves their shuffle files after they are gone, so an executor can be
released as soon as it is idle. YARN can run one inside each NodeManager; on Kubernetes, where pods do
not share disks, Spark relies on shuffle tracking, on migrating shuffle files to other executors when
one is told to leave, or on a remote shuffle service, a separate system that holds shuffle data for
the whole cluster.
