---
title: What an executor does with its memory
version: 1
---

**An executor is a Java process with a fixed heap, and Spark divides it before your job sees any of
it.** Lesson 1's `spark-defaults.conf` gave each executor 768 MB, `spark.executor.memory`. This
program asks the executors how much of that Spark can use for its own work. Save it as
`~/big/memory.py`:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "\"\"\"How much memory each executor has for Spark's own use.\"\"\"\nimport json\nimport urllib.request\n\nfrom pyspark.sql import SparkSession\n\nspark = SparkSession.builder.appName(\"memory\").getOrCreate()\nsc = spark.sparkContext\n"
    },
    {
      "code": "spark.range(30, numPartitions=3).count()\n",
      "note": "A tiny job first, so that all three executors have started and registered before they are asked about."
    },
    {
      "code": "url = f\"{sc.uiWebUrl}/api/v1/applications/{sc.applicationId}/executors\"\nfor e in json.load(urllib.request.urlopen(url)):\n    print(e[\"id\"], f\"{e['maxMemory'] / 2**20:.1f} MiB\")\n",
      "note": "The executors endpoint again, this time for `maxMemory`: the bytes each executor may use for executing tasks and caching data, together."
    },
    {
      "code": "print(\"spark.executor.memory =\", sc.getConf().get(\"spark.executor.memory\"))\n",
      "note": "The setting the executors were started with, from `spark-defaults.conf`."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit memory.py
WARNING: Using incubator modules: jdk.incubator.vector
driver 434.4 MiB
2 280.8 MiB
1 280.8 MiB
0 280.8 MiB
spark.executor.memory = 768m
```

**280.8 MiB out of 768.** The arithmetic is Spark's *unified memory* model:

| | |
|---|---|
| the heap, `spark.executor.memory` | 768 MiB |
| reserved for Spark's own objects | 300 MiB |
| left | 468 MiB |
| Spark's share, `spark.memory.fraction`, 0.6 | **280.8 MiB** |
| the rest, for user code and objects Spark does not track | 187.2 MiB |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l07-memory\" aria-label=\"The 768 MiB heap of one executor as a bar. 300 MiB are reserved. Of the 468 left, 60 percent, 280.8 MiB, is the unified region shared by execution and storage; the other 187.2 MiB is for user code. Overhead memory sits outside the heap.\"><rect x=\"30.0\" y=\"60.0\" width=\"218.8\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"139.4\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reserved</text><text x=\"139.4\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300 MiB</text><rect x=\"248.8\" y=\"60.0\" width=\"204.8\" height=\"56.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"351.1\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">execution + storage</text><text x=\"351.1\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">280.8 MiB</text><rect x=\"453.5\" y=\"60.0\" width=\"136.5\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"521.8\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">user code</text><text x=\"521.8\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">187.2 MiB</text><path d=\"M351.1 116.0 L351.1 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"254.8\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">execution</text><text x=\"447.5\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">storage</text><text x=\"310.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">768 MiB heap</text><rect x=\"600.0\" y=\"60.0\" width=\"110.0\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">overhead</text><text x=\"655.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">outside the heap</text></svg>", "caption": "Spark keeps 300 MiB for itself and shares 60 percent of the rest between running tasks and cached data."}
```

**The 280.8 MiB is shared by two uses**, which is what *unified* means. *Execution* memory holds
what a running task needs: the hash table of an aggregation, the buffer of a sort, a join's build
side. *Storage* memory holds cached data, lesson 9's subject. Either can borrow the other's half
when it is free, and execution can force cached data out when it needs the room. With one core per
executor, one task at a time has nearly all of it; with four cores, four tasks share it.

Two pieces sit outside the heap and are easy to forget:

- **Overhead**, memory the process needs beyond the Java heap: thread stacks, network buffers,
  native libraries. Spark asks the cluster manager for at least 384 MB, or a tenth of the executor's
  memory, on top; YARN and Kubernetes kill a container that goes over its total. Here the standalone
  workers enforce nothing, which is why the lab's 1 GB workers host 768 MB executors.
- **Python.** The Python processes that run UDFs and RDD functions beside each executor are separate
  processes with memory of their own, which the heap's numbers do not include at all.

The driver's line says 434.4 MiB, from its default 1 GB with the same rule. Section 10 runs it out.
