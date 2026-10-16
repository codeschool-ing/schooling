---
title: What an environment costs while it waits
version: 1
---

**An MWAA environment is billed for every hour it exists, and there is no way to pause one.** It has
no stopped state: the scheduler, the web server, the metadata database and the base workers run
around the clock, because the scheduler has to be awake to notice that three in the morning has
arrived. The only way to stop paying is to delete the environment, which deletes its database and
with it the history of every run. So the honest question about MWAA is not what a pipeline costs
when it runs, but what the environment costs when nothing does.

```
ana@laptop:~/aws$ python3 prices.py mwaa
AWS public price list, sa-east-1, USD, excluding tax

MWAA, USD per hour
  small environment                                     0.84249  hour
  small extra worker                                    0.09456  hour
  medium environment                                    1.27233  hour
  medium extra worker                                   0.18913  hour
  large environment                                     1.70217  hour
  large extra worker                                    0.37826  hour
```

**An environment class is a size for the whole environment**, `mw1.small`, `mw1.medium` and
`mw1.large` in these three lines: a bigger class has a bigger scheduler and web server and bigger
workers, and handles more DAGs and more tasks at once. The "extra worker" line is what each worker
beyond the base costs per hour while autoscaling keeps it, and it is how an environment grows for
the hours it is busy.

## A small environment, one month, doing almost nothing

Quitanda's pipeline is the two Glue jobs of the DAG: about two hours of work a night. Price a small
environment for a month of 730 hours:

| | arithmetic | USD |
|---|---|---|
| small environment, the month | 0.84249 × 730 | 615.02 |
| the same, the year | 0.84249 × 8760 | 7380.21 |
| three extra small workers, two hours a night, 30 nights | 3 × 2 × 30 × 0.09456 | 17.02 |
| medium environment, the month | 1.27233 × 730 | 928.80 |
| large environment, the month | 1.70217 × 730 | 1242.58 |

**615.02 a month buys 60 hours of orchestration and 670 hours of waiting.** Divided by the hours the
pipeline works, the environment costs 615.02 ÷ 60 = 10.25 USD per hour of work, before a single Glue
DPU, which is billed on its own. The three extra workers, the part that scales with the work, add
17.02 to it; the 615.02 is the price of being awake. MWAA also charges for the storage of the metadata
database, by the gigabyte-month, and the sheet does not print that line.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A timeline of one day from 00:00 to 24:00. The billed bar covers all 24 hours: 0.84249 times 24 is 20.22 USD a day. The working bar covers only 03:00 to 05:00, the two hours of the two Glue jobs.\" data-fig=\"l25-day\"><defs><marker id=\"ah-l25-day\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"150.0\" y1=\"150\" x2=\"150.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"150.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><line x1=\"217.5\" y1=\"150\" x2=\"217.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"217.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">03:00</text><line x1=\"285.0\" y1=\"150\" x2=\"285.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"285.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><line x1=\"352.5\" y1=\"150\" x2=\"352.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"352.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"420.0\" y1=\"150\" x2=\"420.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"420.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><line x1=\"487.5\" y1=\"150\" x2=\"487.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"487.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15:00</text><line x1=\"555.0\" y1=\"150\" x2=\"555.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"555.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><line x1=\"622.5\" y1=\"150\" x2=\"622.5\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"622.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><line x1=\"690.0\" y1=\"150\" x2=\"690.0\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">billed</text><rect x=\"150\" y=\"55\" width=\"540\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24 hours: 0.84249 x 24 = 20.22 a day</text><text x=\"20\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">working</text><rect x=\"217.5\" y=\"100\" width=\"45.0\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.5\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 hours: the two Glue jobs</text><line x1=\"150\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"420.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one night of a small environment</text></svg>", "caption": "A small environment is billed all day for two hours of work; the other twenty-two are the price of being awake at three."}
```

**The shape is the opposite of the services of the last few lessons.** Glue, EMR Serverless and
Athena charge for work and nothing for waiting; an MWAA environment charges for waiting and almost
nothing more for work. That makes it cheap per pipeline when there are many pipelines, and expensive
per pipeline when there are few. Forty DAGs sharing one small environment cost 615.02 ÷ 40 = 15.38 a
month each, and nobody would call that dear for a scheduler with retries, backfills and a web server.
One DAG on its own pays the whole 615.02.

## When the waiting is worth it

**MWAA earns its price when Airflow itself is the point.** Many DAGs, written by several teams, with
dependencies between them; backfills, where re-running last Tuesday's interval is a click; sensors
that wait for a file or a partition to appear; operators for dozens of services beyond AWS's; and a
team that already knows Airflow, or a pipeline that has to move to another cloud one day, where
Airflow runs too. For that, 615.02 a month is a reasonable price for not operating a scheduler,
a database and a fleet of workers yourself.

**It does not earn it for a handful of simple pipelines**, each a short chain of AWS calls run on a
clock. That case has a cheaper answer made of two services that cost nothing while they wait, and
the next two sections build it.
