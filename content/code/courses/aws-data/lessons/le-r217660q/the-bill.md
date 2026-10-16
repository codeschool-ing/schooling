---
title: What a run costs, and the job that is too big
version: 1
---

**A Glue bill is an area: DPUs up, seconds across.** Every run is billed as the DPUs it was given
multiplied by the time they were up, at the line the sheet printed, and nothing else in the job
definition changes the price. So the two questions that decide it are how many workers, and how
long, and the second one has a floor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"Three runs drawn to one scale, DPUs upwards and minutes across. Ten G.1X workers for six minutes make a block ten DPUs high and six minutes wide: one DPU-hour, 0.69 dollars, or 0.45 on Flex. Two workers for twenty seconds make a small block two DPUs high, inside a dashed box one minute wide, which is what is billed: 0.023 dollars. A Python shell job of a sixteenth of a DPU for two minutes is a thin line two minutes wide: 0.0014 dollars.\" data-fig=\"l17-area\"><rect x=\"40\" y=\"30\" width=\"360\" height=\"100\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ten G.1X workers, 6 minutes</text><text x=\"412\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1 DPU-hour: 0.69 USD, Flex 0.45</text><rect x=\"40\" y=\"180\" width=\"60\" height=\"20\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"40\" y=\"180\" width=\"20.0\" height=\"20\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"112\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two workers, 20 seconds</text><text x=\"412\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">billed 1 minute: 0.023 USD</text><rect x=\"40\" y=\"242.8\" width=\"120\" height=\"1.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"172\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Python shell, 1/16 DPU, 2 minutes</text><text x=\"412\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">0.0014 USD</text><line x1=\"40\" y1=\"270\" x2=\"400\" y2=\"270\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"40\" y1=\"270\" x2=\"40\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"40\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"100\" y1=\"270\" x2=\"100\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"100\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"160\" y1=\"270\" x2=\"160\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"160\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"220\" y1=\"270\" x2=\"220\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"220\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><line x1=\"280\" y1=\"270\" x2=\"280\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"280\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"340\" y1=\"270\" x2=\"340\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"340\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"400\" y1=\"270\" x2=\"400\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"400\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"412\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutes</text><text x=\"32\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"32\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"32\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">DPUs</text></svg>", "caption": "The same price per DPU-hour, three areas. Height is DPUs and width is minutes; the dashed box is the one-minute minimum the short run pays for."}
```

## Quitanda's night, priced

Say the nightly job runs on ten `G.1X` workers and takes six minutes. That is ten DPUs for a tenth
of an hour, **one DPU-hour, 0.69 dollars a night** at the standard price, and 31 × 0.69 = 21.39
dollars in October. The same job on Flex is 0.45 a night and 13.95 for the month, for agreeing that
it may start late. A job that writes yesterday's orders for a report read at nine in the morning can
nearly always wait, and that is the case Flex exists for.

**The minimum is where small jobs lose.** A run of two workers that finishes its work in twenty
seconds is billed for a minute: 2 × 1/60 × 0.69 = 0.023 dollars, three times the twenty seconds it
used. That is still small, and it says something about the size of this job: October's whole raw
layer is 40 MB, and **a Spark job on ten workers is far more machine than 40 MB needs**.

## Three definitions of the same job

The definitions moto keeps make the choice concrete, even though none of them runs:

```
ana@laptop:~/aws$ aws glue create-job --name orders-etl-flex --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=glueetl,ScriptLocation=s3://quitanda-glue-prod/scripts/orders_etl.py,PythonVersion=3 --glue-version 5.0 --worker-type G.1X --number-of-workers 10 --execution-class FLEX
{
    "Name": "orders-etl-flex"
}
ana@laptop:~/aws$ aws glue create-job --name orders-etl-small --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=pythonshell,ScriptLocation=s3://quitanda-glue-prod/scripts/etl.py,PythonVersion=3.9 --max-capacity 0.0625
{
    "Name": "orders-etl-small"
}
ana@laptop:~/aws$ aws glue get-jobs --query 'Jobs[].[Name,Command.Name,ExecutionClass,WorkerType,NumberOfWorkers,MaxCapacity]' --output text
orders-etl	glueetl	STANDARD	G.1X	10	None
orders-etl-flex	glueetl	FLEX	G.1X	10	None
orders-etl-small	pythonshell	STANDARD	None	None	0.0625
```

**`STANDARD` and `FLEX` differ in one word and in price; the third is not Spark at all.** A
`pythonshell` job runs a plain Python program on a sixteenth of a DPU, `0.0625`, which is about what
`etl.py` needs. At that size two minutes cost 0.0625 × 2/60 × 0.69 = 0.0014 dollars, a little over
four cents for the 31 nights of October, against 21.39 for the Spark job. What that third job would
need, and this course does not set up, is for `etl.py`, `lake.py` and the libraries they import to
travel with it to Glue.

The choice turns over as the data grows. A raw layer of a few gigabytes a night no longer fits one
small Python process, and that is where Spark's workers earn their DPUs, the subject Glue was built
for. Past a certain size and steadiness, running your own Spark on EMR can cost less than Glue's
per-second rate, and lesson 24 is where that line is drawn.
