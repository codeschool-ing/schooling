---
title: Tasks, cores and waves
version: 1
---

**A job is cut into tasks, and a task is the unit the scheduler hands out.** Each task works on one
slice of the data, and each executor core runs one task at a time. So the arithmetic of a job's
duration starts with two numbers: how many tasks there are, and how many cores there are to run
them.

The program this lesson uses makes both numbers easy to see. It runs as many tasks as you ask for,
and each one does nothing but sleep for as long as you say, so the time a job takes is the
scheduler's doing and not the data's. Save it as `~/big/tasks.py`:

```schooling-example
{
  "language": "python",
  "file": "tasks.py",
  "parts": [
    {
      "code": "\"\"\"Run N tasks that each take S seconds, and say how long the whole job took.\"\"\"\nimport sys\nimport time\n\nfrom pyspark.sql import SparkSession\n\n"
    },
    {
      "code": "N, S = int(sys.argv[1]), float(sys.argv[2])\nspark = SparkSession.builder.appName(f\"tasks {N}x{S}\").getOrCreate()\n\n\n",
      "note": "Two numbers from the command line: how many tasks, and how long each one works."
    },
    {
      "code": "def work(slice_):\n    time.sleep(S)\n    return sum(slice_)\n\n\n",
      "note": "**This function is the task.** Spark ships it to an executor, which runs it on one slice of the data and sends back the result."
    },
    {
      "code": "start = time.time()\ntotal = (spark.sparkContext.parallelize(range(N), N)\n         .glom().map(work).sum())\nprint(f\"{N} tasks of {S:g} s: answer {total}, {time.time() - start:.1f} s\")\n",
      "note": "`parallelize` cuts the numbers 0 to N-1 into N slices, one per task, and `map` plus `sum` runs `work` on each and adds the answers. Lesson 5 explains the API."
    }
  ]
}
```

Thirty tasks of two seconds, then thirty-one, then three:

```
ana@lab:~/big$ spark-submit tasks.py 30 2
WARNING: Using incubator modules: jdk.incubator.vector
30 tasks of 2 s: answer 435, 22.0 s
ana@lab:~/big$ spark-submit tasks.py 31 2
WARNING: Using incubator modules: jdk.incubator.vector
31 tasks of 2 s: answer 465, 23.9 s
ana@lab:~/big$ spark-submit tasks.py 3 2
WARNING: Using incubator modules: jdk.incubator.vector
3 tasks of 2 s: answer 3, 3.8 s
```

**Thirty tasks on three cores run in ten *waves*** of three, and ten waves of two seconds is twenty
seconds. The run took about two more, which is the price of starting an application: asking the
master for executors, waiting for three Java processes to start, and sending them the program.
**Thirty-one tasks need an eleventh wave** for one task, and the job took two seconds longer while
two of the three cores sat idle. Three tasks fit in one wave, and the job is almost all overhead.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l02-waves\" aria-label=\"Three cores against time. Thirty tasks of two seconds fill ten waves of three and end at twenty seconds. A thirty-first task needs an eleventh wave in which one core works and two sit idle, and the job ends at twenty-two seconds.\"><text x=\"70.0\" y=\"44.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">core 1</text><rect x=\"81.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"133.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"185.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"237.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"445.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"497.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"549.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"601.0\" y=\"30.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">task 31</text><text x=\"70.0\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">core 2</text><rect x=\"81.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"133.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"185.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"237.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"445.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"497.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"549.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"601.0\" y=\"70.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"626.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">idle</text><text x=\"70.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">core 3</text><rect x=\"81.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"133.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"185.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"237.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"341.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"445.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"497.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"549.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"601.0\" y=\"110.0\" width=\"50.0\" height=\"28.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"626.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">idle</text><path d=\"M80.0 160.0 L662.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 160.0 L80.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M132.0 160.0 L132.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"132.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M184.0 160.0 L184.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"184.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M236.0 160.0 L236.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"236.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M288.0 160.0 L288.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"288.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M340.0 160.0 L340.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"340.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M392.0 160.0 L392.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"392.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M444.0 160.0 L444.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"444.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><path d=\"M496.0 160.0 L496.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"496.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M548.0 160.0 L548.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"548.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M600.0 160.0 L600.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"600.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M652.0 160.0 L652.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"652.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22</text><text x=\"366.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">seconds</text></svg>", "caption": "Thirty-one tasks on three cores: the last wave holds one task and two idle cores, and costs a whole wave of time."}
```

Two rules fall out of this, and lesson 7 leans on both:

- **The slowest wave sets the time, and the last wave is usually partly empty.** A job with as many
  tasks as cores leaves nothing to rebalance if one task is slow; a job with a few times as many
  tasks as cores spreads the work more evenly.
- **A task has a fixed cost**, scheduling it, starting it and reporting back, of a few
  milliseconds here and more on a busy cluster. Tasks that take a second each make it invisible;
  tens of thousands of tasks of a few milliseconds each spend most of the job on the overhead.

**Where a task runs is the driver's decision**, and when the data lives on particular machines, as
it does on HDFS in lesson 3, the driver prefers an executor on the machine that holds the task's
slice. Spark calls this *data locality*, and it waits a few seconds for a local core to free up
before settling for a remote one. On one machine every executor is local to everything, so the lab
never shows the waiting.
